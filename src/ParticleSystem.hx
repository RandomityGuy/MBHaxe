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
	var parts:src.ParticlesMesh.ParticlesMesh;

	var x:Float;
	var y:Float;
	var z:Float;
	var w:Float; // used for sorting by ParticlesMesh.draw()
	var r:Float;
	var g:Float;
	var b:Float;
	var a:Float;
	var size:Float;
	var ratio:Float;
	var rotation:Float;

	var prev:Particle;
	var next:Particle;

	var simPrev:Particle;
	var simNext:Particle;

	var data:ParticleData;
	var manager:ParticleManager;
	var o:ParticleOptions;
	var velX:Float;
	var velY:Float;
	var velZ:Float;
	var lifeTime:Float;
	var initialSpin:Float;
	var spawnTime:Float;

	var initialPosX:Float;
	var initialPosY:Float;
	var initialPosZ:Float;
	var initialVelX:Float;
	var initialVelY:Float;
	var initialVelZ:Float;

	var constantForceX:Float;
	var constantForceY:Float;
	var constantForceZ:Float;

	public function new() {
		r = 1;
		g = 1;
		b = 1;
		a = 1;
	}

	public inline function clear() {
		r = 1;
		g = 1;
		b = 1;
		a = 1;
		x = y = z = w = 0;
	}

	public function init(options:ParticleOptions, manager:ParticleManager, data:ParticleData, spawnTime:Float, pos:Vector, vel:Vector) {
		this.o = options;
		this.manager = manager;
		this.data = data;
		this.spawnTime = spawnTime;
		this.initialPosX = pos.x;
		this.initialPosY = pos.y;
		this.initialPosZ = pos.z;
		this.initialVelX = vel.x;
		this.initialVelY = vel.y;
		this.initialVelZ = vel.z;
		this.x = pos.x;
		this.y = pos.y;
		this.z = pos.z;
		this.velX = vel.x;
		this.velY = vel.y;
		this.velZ = vel.z;

		this.constantForceX = vel.x * options.constantAcceleration - manager.windVelocity.x * options.windCoefficient;
		this.constantForceY = vel.y * options.constantAcceleration - manager.windVelocity.y * options.windCoefficient;
		this.constantForceZ = vel.z * options.constantAcceleration + (-9.81) * options.gravityCoefficient - manager.windVelocity.z * options.windCoefficient;

		this.lifeTime = this.o.lifetime + this.o.lifetimeVariance * (Math.random() * 2 - 1);
		this.initialSpin = Util.lerp(this.o.spinRandomMin, this.o.spinRandomMax, Math.random());
	}

	public function update(time:Float, dt:Float) {
		var elapsed = time - this.spawnTime; // milliseconds - matches `lifeTime`/`o.times`
		var completion = Util.clamp(elapsed / this.lifeTime, 0, 1);

		if (completion >= 1 || completion < 0 || elapsed < 0) {
			// The particle can die
			this.manager.removeParticle(this.data, this);
			return;
		}

		var elapsedSec = elapsed / 1000;
		var drag = this.o.dragCoefficient;
		if (drag > 0.0001) {
			var decay = Math.exp(-drag * elapsedSec);
			var invDrag = 1 / drag;
			var offsetFactor = (1 - decay) * invDrag;

			var vTerminalX = this.constantForceX * invDrag;
			var vTerminalY = this.constantForceY * invDrag;
			var vTerminalZ = this.constantForceZ * invDrag;

			var velOffsetX = this.initialVelX - vTerminalX;
			var velOffsetY = this.initialVelY - vTerminalY;
			var velOffsetZ = this.initialVelZ - vTerminalZ;

			this.velX = vTerminalX + velOffsetX * decay;
			this.velY = vTerminalY + velOffsetY * decay;
			this.velZ = vTerminalZ + velOffsetZ * decay;

			this.x = this.initialPosX + vTerminalX * elapsedSec + velOffsetX * offsetFactor;
			this.y = this.initialPosY + vTerminalY * elapsedSec + velOffsetY * offsetFactor;
			this.z = this.initialPosZ + vTerminalZ * elapsedSec + velOffsetZ * offsetFactor;
		} else {
			this.velX = this.initialVelX + this.constantForceX * elapsedSec;
			this.velY = this.initialVelY + this.constantForceY * elapsedSec;
			this.velZ = this.initialVelZ + this.constantForceZ * elapsedSec;

			var halfSq = 0.5 * elapsedSec * elapsedSec;
			this.x = this.initialPosX + this.initialVelX * elapsedSec + this.constantForceX * halfSq;
			this.y = this.initialPosY + this.initialVelY * elapsedSec + this.constantForceY * halfSq;
			this.z = this.initialPosZ + this.initialVelZ * elapsedSec + this.constantForceZ * halfSq;
		}

		this.rotation = (this.initialSpin + this.o.spinSpeed * elapsed / 1000) * Math.PI / 180;

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

		var scale:Float;
		if (found) {
			var lowTime = indexLow == 0 ? 0 : this.o.times[indexLow];
			var t = (completion - lowTime) / (this.o.times[indexHigh] - lowTime);
			var colorLow = this.o.colors[indexLow];
			var colorHigh = this.o.colors[indexHigh];
			this.r = Util.lerp(colorLow.r, colorHigh.r, t);
			this.g = Util.lerp(colorLow.g, colorHigh.g, t);
			this.b = Util.lerp(colorLow.b, colorHigh.b, t);
			this.a = Util.lerp(colorLow.a, colorHigh.a, t);
			scale = Util.lerp(this.o.sizes[indexLow], this.o.sizes[indexHigh], t);
		} else {
			var color = this.o.colors[this.o.colors.length - 1];
			this.r = color.r;
			this.g = color.g;
			this.b = color.b;
			this.a = color.a;
			scale = this.o.sizes[this.o.sizes.length - 1];
		}

		this.ratio = 1;
		this.size = scale / 2;
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

	public var blending:h3d.mat.BlendMode;

	/** The spinning speed in degrees per second. */
	public var spinSpeed:Float;

	public var spinRandomMin:Float;
	public var spinRandomMax:Float;
	public var lifetime:Float;
	public var lifetimeVariance:Float;

	public var dragCoefficient:Float;

	public var constantAcceleration:Float;
	public var gravityCoefficient:Float;
	public var windCoefficient:Float;

	public var colors:Array<Vector>;
	public var sizes:Array<Float>;

	/** Determines at what percentage of lifetime the corresponding colors and sizes are in effect. */
	public var times:Array<Float>;
}

@:structInit
class ParticleEmitterOptions {
	/** The time between particle ejections. */
	public var ejectionPeriod:Float;

	public var periodVariance:Float = 0;

	/** A fixed velocity to add to each particle. */
	public var ambientVelocity:Vector;

	public var ejectionVelocity:Float;

	public var velocityVariance:Float;
	public var emitterLifetime:Float;

	/** How much of the emitter's own velocity the particle should inherit. */
	public var inheritedVelFactor:Float;

	public var axis:Vector = null;

	public var thetaMin:Float;
	public var thetaMax:Float;
	public var phiReferenceVel:Float;
	public var phiVariance:Float;

	public var ejectionOffset:Float;

	/** Computes a spawn offset for each particle. */
	public var spawnOffset:Void->Vector = null;

	public var velocity:Vector = null;

	public var particleOptions:ParticleOptions;

	public function clone():ParticleEmitterOptions {
		var clone:ParticleEmitterOptions = {
			ejectionPeriod: ejectionPeriod,
			particleOptions: particleOptions,
			spawnOffset: spawnOffset,
			ejectionOffset: ejectionOffset,
			phiVariance: phiVariance,
			phiReferenceVel: phiReferenceVel,
			thetaMax: thetaMax,
			thetaMin: thetaMin,
			axis: axis,
			inheritedVelFactor: inheritedVelFactor,
			emitterLifetime: emitterLifetime,
			velocityVariance: velocityVariance,
			ejectionVelocity: ejectionVelocity,
			ambientVelocity: ambientVelocity,
			periodVariance: periodVariance,
			velocity: velocity
		};
		return clone;
	}
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

	// var emittedParticles:Array<Particle> = [];

	public function new(options:ParticleEmitterOptions, data:ParticleData, manager:ParticleManager, ?getPos:Void->Vector) {
		this.o = options;
		this.manager = manager;
		this.getPos = getPos;
		this.data = data;
		if (this.o.velocity != null)
			this.vel = this.o.velocity.clone();
	}

	public function spawn(time:Float) {
		this.spawnTime = time;
		this.emit(time);
	}

	public function tick(time:Float, dt:Float) {
		// Cap the amount of particles emitted in such a case to prevent lag
		if (time < this.lastEmitTime)
			this.lastEmitTime = time - 1000;
		if (@:privateAccess this.manager.level.rewinding)
			return;
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
		var particle = this.manager.spawnParticle(this.data, this.o.particleOptions, time, pos, vel);
		// this.emittedParticles.push(particle);
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

	public var windVelocity:Vector = new Vector(0, 0, 0);

	var particleGroups:Map<String, src.ParticlesMesh.ParticlesMesh> = [];
	var particleHead:Particle;
	var particleTail:Particle;

	var emitters:Array<ParticleEmitter> = [];

	public function new(level:MarbleWorld) {
		Console.log("Initializing Particle Manager");
		this.level = level;
		this.scene = level.scene;
	}

	public function update(currentTime:Float, dt:Float) {
		this.currentTime = currentTime;
		var particle = this.particleHead;
		while (particle != null) {
			var nextParticle = particle.simNext;
			particle.update(currentTime, dt);
			particle = nextParticle;
		}
		this.tick(dt);
	}

	public function spawnParticle(particleData:ParticleData, options:ParticleOptions, spawnTime:Float, pos:Vector, vel:Vector):Particle {
		var pGroup = particleGroups.get(particleData.identifier);
		if (pGroup == null) {
			pGroup = new src.ParticlesMesh.ParticlesMesh(particleData.texture, this.scene);
			pGroup.hasColor = true;
			pGroup.material.setDefaultProps("ui");
			// var pdts = new DtsTexture(pGroup.material.texture);
			// pdts.currentOpacity = 1;
			pGroup.material.blendMode = options.blending;
			pGroup.material.mainPass.depthWrite = false;
			// pGroup.material.mainPass.removeShader(pGroup.material.textureShader);
			// pGroup.material.mainPass.addShader(pdts);
			particleGroups.set(particleData.identifier, pGroup);
		}
		var particle = pGroup.alloc();
		particle.init(options, this, particleData, spawnTime, pos, vel);

		particle.simPrev = this.particleTail;
		particle.simNext = null;
		if (this.particleTail != null)
			this.particleTail.simNext = particle;
		else
			this.particleHead = particle;
		this.particleTail = particle;
		return particle;
	}

	public function removeParticle(particleData:ParticleData, particle:Particle) {
		var pGroup = particleGroups.get(particleData.identifier);
		if (pGroup != null) {
			@:privateAccess pGroup.kill(particle);
		}
		if (particle.simPrev != null)
			particle.simPrev.simNext = particle.simNext;
		else
			this.particleHead = particle.simNext;
		if (particle.simNext != null)
			particle.simNext.simPrev = particle.simPrev;
		else
			this.particleTail = particle.simPrev;
		particle.simPrev = null;
		particle.simNext = null;
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
		// for (particle in emitter.emittedParticles)
		// 	this.removeParticle(particle.data, particle);
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
