package src;

import shaders.DtsTexture;
import h3d.Matrix;
import src.TimeState;
import h3d.prim.UV;
import src.MarbleWorld;
import src.Util;
import h3d.mat.Data.Wrap;
import shaders.Billboard;
import hxd.IndexBuffer;
import h3d.col.Point;
import h3d.prim.Polygon;
import h3d.prim.MeshPrimitive;
import h3d.mat.Texture;
import h3d.scene.Scene;
import h3d.mat.Material;
import h3d.Vector;
import h3d.scene.MeshBatch;
import h3d.scene.Mesh;
import src.ResourceLoader;
import src.Console;

@:publicFields
class ParticleData {
	var texture:Texture;
	var identifier:String;

	public function new() {}
}

@:publicFields
class Particle {
	public var part:src.ParticlesMesh.ParticleElement;

	var data:ParticleData;
	var manager:ParticleManager;
	var o:ParticleOptions;
	var position:Vector;
	var vel:Vector;
	var rotation:Float;
	var color:Vector;
	var scale:Float;
	var lifeTime:Float;
	var initialSpin:Float;
	var spawnTime:Float;

	// Everything below is fixed at spawn time and never mutated afterward - `position`/`vel` above
	// are just cached *outputs* of `update()`, recomputed fresh from these constants and the
	// current absolute time every call (see `update`), not accumulated frame-to-frame. A rewound
	// particle needs nothing but `spawnTime` (already here) to jump to any point in its life.
	var initialPos:Vector;
	var initialVel:Vector;

	/** Combined constant acceleration term - ported from `PEngine::updateSingleParticle`
		(`particleEngine.cc`): `a = acc - vel*dragCoefficient - windVelocity*windCoefficient +
		(0,0,-9.81)*gravityCoefficient`, where `acc` (`init->acc = init->vel * constantAcceleration`
		in `ParticleData::initializeParticle`) is itself fixed at spawn from the particle's *initial*
		velocity, not recomputed from the live velocity - so besides drag (velocity-dependent, kept
		separate below), every other term here is a fixed vector for the particle's whole life. */
	var constantForce:Vector;

	public function new(options:ParticleOptions, manager:ParticleManager, data:ParticleData, spawnTime:Float, pos:Vector, vel:Vector) {
		this.o = options;
		this.manager = manager;
		this.data = data;
		this.spawnTime = spawnTime;
		this.initialPos = pos;
		this.initialVel = vel;
		this.position = pos;
		this.vel = vel;

		var constantAccel = vel.multiply(options.constantAcceleration);
		var gravity = new Vector(0, 0, -9.81).multiply(options.gravityCoefficient);
		var wind = manager.windVelocity.multiply(-options.windCoefficient);
		this.constantForce = constantAccel.add(gravity).add(wind);

		this.lifeTime = this.o.lifetime + this.o.lifetimeVariance * (Math.random() * 2 - 1);
		this.initialSpin = Util.lerp(this.o.spinRandomMin, this.o.spinRandomMax, Math.random());

		this.part = new src.ParticlesMesh.ParticleElement();
	}

	public function update(time:Float, dt:Float) {
		var elapsed = time - this.spawnTime; // milliseconds - matches `lifeTime`/`o.times`
		var completion = Util.clamp(elapsed / this.lifeTime, 0, 1);

		if (completion >= 1 || completion < 0 || elapsed < 0) {
			// The particle can die
			this.manager.removeParticle(this.data, this);
			return;
		}

		// Closed-form solution of `dv/dt = constantForce - dragCoefficient * v` (the same ODE
		// `PEngine::updateSingleParticle` Euler-steps every tick) - computed directly from elapsed
		// time rather than integrated incrementally, so it's exact regardless of frame rate and
		// trivially reproducible after a rewind jump. `t` is in seconds to match how
		// `dragCoefficient`/`constantAcceleration`/etc. were already calibrated (the old incremental
		// version multiplied by a seconds-based `dt`).
		var elapsedSec = elapsed / 1000;
		var drag = this.o.dragCoefficient;
		if (drag > 0.0001) {
			var decay = Math.exp(-drag * elapsedSec);
			var vTerminal = this.constantForce.multiply(1 / drag);
			var velOffset = this.initialVel.sub(vTerminal);
			this.vel = vTerminal.add(velOffset.multiply(decay));
			this.position = this.initialPos.add(vTerminal.multiply(elapsedSec)).add(velOffset.multiply((1 - decay) / drag));
		} else {
			this.vel = this.initialVel.add(this.constantForce.multiply(elapsedSec));
			this.position = this.initialPos.add(this.initialVel.multiply(elapsedSec)).add(this.constantForce.multiply(0.5 * elapsedSec * elapsedSec));
		}

		this.rotation = (this.initialSpin + this.o.spinSpeed * elapsed / 1000) * Math.PI / 180;

		// Find which [times[i-1], times[i]] segment `completion` falls in - ported from
		// `PEngine::updateSingleParticle`'s `for (i = 1; i < 4; i++) if (times[i] >= t) ...` loop
		// (`particleEngine.cc`): scan forward and take the *first* upper bound that's >= completion.
		// If none match (`completion` exceeds every keyframe - possible since `times` here isn't
		// padded to a fixed 4 slots like the real engine's array), the real engine falls through to
		// the flat *last* keyframe with no interpolation - MBHaxe's previous version had no such
		// fallback and would keep dividing by the last segment's span, silently extrapolating past
		// the final keyframe instead of clamping to it.
		var indexLow = 0;
		var indexHigh = 0;
		var found = false;
		for (i in 1...this.o.times.length) {
			if (this.o.times[i] >= completion) {
				indexLow = i - 1;
				indexHigh = i;
				found = true;
				break;
			}
		}

		if (found) {
			// `ParticleData::loadParameters` unconditionally forces `times[0] = 0.0f` at load time,
			// discarding whatever the datablock script itself authored for that slot (e.g.
			// `PhysModParticle`'s `times[0] = 1` in the source is silently never honored) - applied
			// here rather than baked into any particular port's data, since it's a universal engine
			// behavior, not a per-datablock quirk.
			var lowTime = indexLow == 0 ? 0 : this.o.times[indexLow];
			var t = (completion - lowTime) / (this.o.times[indexHigh] - lowTime);
			this.color = Util.lerpThreeVectors(this.o.colors[indexLow], this.o.colors[indexHigh], t);
			this.scale = Util.lerp(this.o.sizes[indexLow], this.o.sizes[indexHigh], t);
		} else {
			this.color = this.o.colors[this.o.colors.length - 1];
			this.scale = this.o.sizes[this.o.sizes.length - 1];
		}

		this.part.x = this.position.x;
		this.part.y = this.position.y;
		this.part.z = this.position.z;
		this.part.r = this.color.r;
		this.part.g = this.color.g;
		this.part.b = this.color.b;
		this.part.a = this.color.a;
		this.part.ratio = 1;
		this.part.size = this.scale / 2;
	}
}

typedef ParticleBatch = {
	var instances:Array<Particle>;
	var meshBatch:MeshBatch;
}

/** The options for a single particle. */
@:structInit
class ParticleOptions {
	public var texture:String;

	/** Which blending mode to use - when porting a value from a real PQ `ParticleData` datablock,
		map its `useInvAlpha` field as: `useInvAlpha = false` (or unset - that's the C++ default) ->
		`Add`; `useInvAlpha = true` -> `Alpha`. Confirmed directly against the real engine, not a
		guess - don't assume `Alpha` as a safe default when a datablock's `useInvAlpha` is unknown. */
	public var blending:h3d.mat.BlendMode;

	/** The spinning speed in degrees per second. */
	public var spinSpeed:Float;

	public var spinRandomMin:Float;
	public var spinRandomMax:Float;
	public var lifetime:Float;
	public var lifetimeVariance:Float;

	/** Ported from `ParticleData`/`PEngine::updateSingleParticle` (`particleEngine.cc`) - all three
		of these are independent terms in the same acceleration sum, not variations on one concept:
		`dragCoefficient` opposes the particle's *current* velocity every frame; `constantAcceleration`
		is fixed at spawn from the particle's *initial* velocity direction/magnitude only
		(`init->acc = init->vel * constantAcceleration`, never recomputed afterward);
		`gravityCoefficient` multiplies a fixed world-down vector `(0,0,-9.81)`; `windCoefficient`
		multiplies `ParticleManager.windVelocity` (a global, not per-particle, wind vector). */
	public var dragCoefficient:Float;

	public var constantAcceleration:Float;
	public var gravityCoefficient:Float;
	public var windCoefficient:Float;

	public var colors:Array<Vector>;
	public var sizes:Array<Float>;

	/** Determines at what percentage of lifetime the corresponding colors and sizes are in effect. */
	public var times:Array<Float>;
}

/** The options for a particle emitter. Ejection direction is ported from `ParticleEmitter::
	addParticle` (`particleEngine.cc`): a random `theta` (degrees off `axis`, within
	[`thetaMin`,`thetaMax`]) tilts the ejection direction away from `axis` around a perpendicular
	`axisx`, then a `phi` (degrees, `phiReferenceVel * elapsedSeconds` plus a random amount up to
	`phiVariance`) spins that tilted direction back around `axis` itself - a true cone spread, not
	MBHaxe's old squished-random-sphere-point approximation. */
@:structInit
class ParticleEmitterOptions {
	/** The time between particle ejections. */
	public var ejectionPeriod:Float;

	/** Randomizes each ejection's wait period by up to this much (ms) in either direction - ported
		from `periodVarianceMS` (`ParticleEmitterData`); defaults to 0 (no variance) matching the
		real engine's own default, since most datablocks never set this. */
	public var periodVariance:Float = 0;

	/** A fixed velocity to add to each particle. */
	public var ambientVelocity:Vector;

	public var ejectionVelocity:Float;

	public var velocityVariance:Float;
	public var emitterLifetime:Float;

	/** How much of the emitter's own velocity the particle should inherit. */
	public var inheritedVelFactor:Float;

	/** The reference direction the ejection cone is centered on - defaults to world-up `(0,0,1)`
		when unset, matching most ambient/decorative emitters (nothing currently ports a
		non-default `axis`, since none of the original datablocks needed one - `emitParticles`'s
		`axis` argument comes from the calling C++ code, e.g. a collision normal, not the
		datablock itself). */
	public var axis:Vector = null;

	public var thetaMin:Float;
	public var thetaMax:Float;
	public var phiReferenceVel:Float;
	public var phiVariance:Float;

	/** Spawn position offset along the (post-rotation) ejection direction, not a raw fixed vector -
		see `addParticle`'s `pos + ejectionAxis * ejectionOffset`. */
	public var ejectionOffset:Float;

	/** Computes a spawn offset for each particle. */
	public var spawnOffset:Void->Vector = null;

	public var particleOptions:ParticleOptions;
}

@:publicFields
class ParticleEmitter {
	var o:ParticleEmitterOptions;
	var data:ParticleData;
	var manager:ParticleManager;
	var spawnTime:Float;
	var lastEmitTime:Float;
	var currentWaitPeriod:Float;
	var lastPos:Vector;
	var lastPosTime:Float;
	var currPos:Vector;
	var currPosTime:Float;
	var creationTime:Float;
	var vel = new Vector();
	var getPos:Void->Vector;

	var emittedParticles:Array<Particle> = [];

	public function new(options:ParticleEmitterOptions, data:ParticleData, manager:ParticleManager, ?getPos:Void->Vector) {
		this.o = options;
		this.manager = manager;
		this.getPos = getPos;
		this.data = data;
	}

	public function spawn(time:Float) {
		this.spawnTime = time;
		this.emit(time);
	}

	public function tick(time:Float, dt:Float) {
		// Cap the amount of particles emitted in such a case to prevent lag
		if (this.lastEmitTime > time)
			this.lastEmitTime = time - 1000;
		if (time - this.lastEmitTime >= 1000)
			this.lastEmitTime = time - 1000;
		// Spawn as many particles as needed
		while (this.lastEmitTime + this.currentWaitPeriod <= time) {
			this.emit(this.lastEmitTime + this.currentWaitPeriod);
			var completion = Util.clamp((this.lastEmitTime - this.spawnTime) / this.o.emitterLifetime, 0, 1);
			if (completion == 1) {
				this.manager.removeEmitter(this);
				return;
			}
		}
	}

	/** Emit a single particle - ejection direction ported from `ParticleEmitter::addParticle`
		(`particleEngine.cc`), see `ParticleEmitterOptions`'s doc comment for the theta/phi cone
		math. */
	public function emit(time:Float) {
		this.lastEmitTime = time;
		this.currentWaitPeriod = this.o.ejectionPeriod + (Math.random() * 2 - 1) * this.o.periodVariance;
		var pos = this.getPosAtTime(time).clone();

		var axis = this.o.axis != null ? this.o.axis : new Vector(0, 0, 1);
		var axisx = Math.abs(axis.z) < 0.9 ? axis.cross(new Vector(0, 0, 1)) : axis.cross(new Vector(0, 1, 0));
		axisx.normalize();

		var theta = (this.o.thetaMax - this.o.thetaMin) * Math.random() + this.o.thetaMin;
		var internalClockSec = (time - this.creationTime) / 1000;
		var phi = internalClockSec * this.o.phiReferenceVel + Math.random() * this.o.phiVariance;

		var thetaMat = new Matrix();
		thetaMat.initRotationAxis(axisx, theta * Math.PI / 180);
		var phiMat = new Matrix();
		phiMat.initRotationAxis(axis, phi * Math.PI / 180);

		var ejectionAxis = axis.clone();
		ejectionAxis.transform(thetaMat);
		ejectionAxis.transform(phiMat);

		pos = pos.add(ejectionAxis.multiply(this.o.ejectionOffset));
		if (this.o.spawnOffset != null)
			pos.load(pos.add(this.o.spawnOffset())); // Call the spawnOffset function if it's there

		// Compute the total velocity
		var initialVel = this.o.ejectionVelocity;
		initialVel += (this.o.velocityVariance * 2 * Math.random()) - this.o.velocityVariance;
		var vel = this.vel.multiply(this.o.inheritedVelFactor).add(ejectionAxis.multiply(initialVel)).add(this.o.ambientVelocity);
		var particle = new Particle(this.o.particleOptions, this.manager, this.data, time, pos, vel);
		this.manager.addParticle(data, particle);
		this.emittedParticles.push(particle);
	}

	/** Computes the interpolated emitter position at a point in time. */
	public function getPosAtTime(time:Float) {
		if (this.lastPos == null)
			return this.currPos;
		var completion = Util.clamp((time - this.lastPosTime) / (this.currPosTime - this.lastPosTime), 0, 1);
		return Util.lerpThreeVectors(this.lastPos, this.currPos, completion);
	}

	public function setPos(pos:Vector, time:Float) {
		this.lastPos = this.currPos;
		this.lastPosTime = this.currPosTime;
		this.currPos = pos.clone();
		this.currPosTime = time;
		this.vel = this.currPos.sub(this.lastPos).multiply(1000 / (this.currPosTime - this.lastPosTime));
	}
}

class ParticleManager {
	// var particlebatches:Array<ParticleBatch> = [];
	// var particlebatchMap:Map<String, Int> = [];
	var level:MarbleWorld;
	var scene:Scene;
	var currentTime:Float;

	/** Ported from `ParticleEngine::windVelocity` (`particleEngine.cc`) - a single global wind
		vector every particle's `windCoefficient` multiplies against, not a per-emitter setting. */
	public var windVelocity:Vector = new Vector(0, 0, 0);

	var particleGroups:Map<String, src.ParticlesMesh.ParticlesMesh> = [];
	var particles:Array<Particle> = [];

	var emitters:Array<ParticleEmitter> = [];

	public function new(level:MarbleWorld) {
		Console.log("Initializing Particle Manager");
		this.level = level;
		this.scene = level.scene;
	}

	public function update(currentTime:Float, dt:Float) {
		this.currentTime = currentTime;
		for (particle in this.particles) {
			particle.update(currentTime, dt);
		}
		this.tick(dt);
	}

	public function addParticle(particleData:ParticleData, particle:Particle) {
		if (particleGroups.exists(particleData.identifier)) {
			particleGroups[particleData.identifier].add(particle.part);
		} else {
			var pGroup = new src.ParticlesMesh.ParticlesMesh(particle.data.texture, this.scene);
			pGroup.hasColor = true;
			pGroup.material.setDefaultProps("ui");
			// var pdts = new DtsTexture(pGroup.material.texture);
			// pdts.currentOpacity = 1;
			pGroup.material.blendMode = particle.o.blending;
			pGroup.material.mainPass.depthWrite = false;
			// pGroup.material.mainPass.removeShader(pGroup.material.textureShader);
			// pGroup.material.mainPass.addShader(pdts);
			pGroup.add(particle.part);
			particleGroups.set(particleData.identifier, pGroup);
		}
		this.particles.push(particle);
	}

	public function removeParticle(particleData:ParticleData, particle:Particle) {
		if (particleGroups.exists(particleData.identifier)) {
			@:privateAccess particleGroups[particleData.identifier].kill(particle.part);
		}
		this.particles.remove(particle);
	}

	public function getTime() {
		return this.currentTime;
	}

	public function createEmitter(options:ParticleEmitterOptions, data:ParticleData, initialPos:Vector, ?getPos:Void->Vector) {
		var emitter = new ParticleEmitter(options, data, cast this, getPos);
		emitter.currPos = (getPos != null) ? getPos() : initialPos.clone();
		if (emitter.currPos == null)
			emitter.currPos = initialPos.clone();
		emitter.currPosTime = this.getTime();
		emitter.creationTime = this.getTime();
		emitter.spawn(this.getTime());
		this.emitters.push(emitter);
		return emitter;
	}

	public function removeEmitter(emitter:ParticleEmitter) {
		this.emitters.remove(emitter);
	}

	public function removeEmitterWithParticles(emitter:ParticleEmitter) {
		this.removeEmitter(emitter);
		for (particle in emitter.emittedParticles)
			this.removeParticle(particle.data, particle);
	}

	public function removeEverything() {
		for (ident => particles in this.particleGroups) {
			particles.remove();
		}
		this.particleGroups = [];
		for (emitter in this.emitters)
			this.removeEmitter(emitter);
	}

	public function tick(dt:Float) {
		var time = this.getTime();
		for (emitter in this.emitters) {
			if (emitter.getPos != null)
				emitter.setPos(emitter.getPos(), time);
			emitter.tick(time, dt);
			// Remove the artifact that was created in a different future cause we rewinded and now we shifted timelines
			if (emitter.creationTime > time) {
				this.removeEmitter(emitter);
			}
		}
	}
}
