package src;

import shaders.DtsTexture;
import h3d.parts.Particles;
import h3d.Matrix;
import src.TimeState;
import h3d.prim.UV;
import h3d.parts.Data.BlendMode;
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

@:publicFields
class ParticleData {
	var texture:Texture;
	var identifier:String;

	public function new() {}
}

@:publicFields
class Particle {
	public var part:h3d.parts.Particle;

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
	var currentAge:Float = 0;
	var acc:Vector = new Vector();

	public function new(options:ParticleOptions, manager:ParticleManager, data:ParticleData, spawnTime:Float, pos:Vector, vel:Vector) {
		this.o = options;
		this.manager = manager;
		this.data = data;
		this.spawnTime = spawnTime;
		this.position = pos;
		this.vel = vel;
		this.acc = this.vel.multiply(options.acceleration);

		this.lifeTime = this.o.lifetime + this.o.lifetimeVariance * (Math.random() * 2 - 1);
		this.initialSpin = Util.lerp(this.o.spinRandomMin, this.o.spinRandomMax, Math.random());

		this.part = new h3d.parts.Particle();
	}

	public function update(time:Float, dt:Float) {
		var t = dt;
		var a = this.acc;
		a = a.sub(this.vel.multiply(this.o.dragCoefficient));
		this.vel = this.vel.add(a.multiply(dt));
		this.position = this.position.add(this.vel.multiply(dt));

		this.currentAge += dt;

		var elapsed = time - this.spawnTime;
		var completion = Util.clamp(elapsed / this.lifeTime, 0, 1);

		if (currentAge > this.lifeTime) // Again, rewind needs this
		{
			this.manager.removeParticle(this.data, this);
			return;
		}

		if (completion == 1) {
			// The particle can die
			this.manager.removeParticle(this.data, this);
			return;
		}

		var t = this.currentAge / (this.lifeTime / 1000);

		// for (i in 1...4) {
		// 	if (this.o.times.length > i) {
		// 		if (this.o.times[i] >= t) {
		// 			var firstPart = t - this.o.times[i - 1];
		// 			var total = this.o.times[i] - this.o.times[i - 1];

		// 			firstPart /= total;

		// 			// if (this.o.texture == 'particles/spark.png') {
		// 			// 	if (this.o.colors[0].r == 1 && this.o.colors[0].g == 1) {
		// 			// 		trace("HEREEEE");
		// 			// 	}
		// 			// }

		// 			this.color = Util.lerpThreeVectors(this.o.colors[i - 1], this.o.colors[i], firstPart);
		// 			this.scale = Util.lerp(this.o.sizes[i - 1], this.o.sizes[i], firstPart);
		// 			break;
		// 		}
		// 	}
		// }

		// var velElapsed = elapsed / 1000;
		// // velElapsed *= 0.001;
		// velElapsed = Math.pow(velElapsed, (1 - this.o.dragCoefficient)); // Somehow slow down velocity over time based on the drag coefficient

		// // Compute the position
		// // var pos = this.position.add(this.vel.multiply(velElapsed + this.o.acceleration * (velElapsed * velElapsed) / 2));
		// // this.position = pos;

		this.rotation = (this.initialSpin + this.o.spinSpeed * elapsed / 1000) * Math.PI / 180;

		// Check where we are in the times array
		var indexLow = 0;
		var indexHigh = 1;
		for (i in 2...this.o.times.length) {
			if (this.o.times[indexHigh] >= completion)
				break;

			indexLow = indexHigh;
			indexHigh = i;
		}

		if (this.o.times.length == 1)
			indexHigh = indexLow;
		var t = (completion - this.o.times[indexLow]) / (this.o.times[indexHigh] - this.o.times[indexLow]);

		// Adjust color
		var color = Util.lerpThreeVectors(this.o.colors[indexLow], this.o.colors[indexHigh], t);
		this.color = color;
		// this.material.opacity = color.a * * 1.5; // Adjusted because additive mixing can be kind of extreme

		// Adjust sizing
		this.scale = Util.lerp(this.o.sizes[indexLow], this.o.sizes[indexHigh], t);

		this.part.x = this.position.x;
		this.part.y = this.position.y;
		this.part.z = this.position.z;
		this.part.r = this.color.r;
		this.part.g = this.color.g;
		this.part.b = this.color.b;
		this.part.ratio = 1;
		this.part.size = this.scale / 2;
	}
}

typedef ParticleBatch = {
	var instances:Array<Particle>;
	var meshBatch:MeshBatch;
}

/** The options for a single particle. */
typedef ParticleOptions = {
	var texture:String;

	/** Which blending mode to use. */
	var blending:h3d.mat.BlendMode;

	/** The spinning speed in degrees per second. */
	var spinSpeed:Float;

	var spinRandomMin:Float;
	var spinRandomMax:Float;
	var lifetime:Float;
	var lifetimeVariance:Float;
	var dragCoefficient:Float;

	/** Acceleration along the velocity vector. */
	var acceleration:Float;

	var colors:Array<Vector>;
	var sizes:Array<Float>;

	/** Determines at what percentage of lifetime the corresponding colors and sizes are in effect. */
	var times:Array<Float>;
};

/** The options for a particle emitter. */
typedef ParticleEmitterOptions = {
	/** The time between particle ejections. */
	var ejectionPeriod:Float; /** A fixed velocity to add to each particle. */

	var ambientVelocity:Vector; /** The particle is ejected in a random direction with this velocity. */

	var ejectionVelocity:Float;

	var velocityVariance:Float;
	var emitterLifetime:Float;

	/** How much of the emitter's own velocity the particle should inherit. */
	var inheritedVelFactor:Float; /** Computes a spawn offset for each particle. */

	var ?spawnOffset:Void->Vector;

	var particleOptions:ParticleOptions;
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
	var spawnSphereSquish:Vector;

	public function new(options:ParticleEmitterOptions, data:ParticleData, manager:ParticleManager, ?getPos:Void->Vector, ?spawnSphereSquish:Vector) {
		this.o = options;
		this.manager = manager;
		this.getPos = getPos;
		this.data = data;
		this.spawnSphereSquish = spawnSphereSquish != null ? spawnSphereSquish : new Vector(1, 1, 1);
	}

	public function spawn(time:Float) {
		this.spawnTime = time;
		this.emit(time);
	}

	public function tick(time:Float, dt:Float) {
		// Cap the amount of particles emitted in such a case to prevent lag
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

	/** Emit a single particle. */
	public function emit(time:Float) {
		this.lastEmitTime = time;
		this.currentWaitPeriod = this.o.ejectionPeriod;
		var pos = this.getPosAtTime(time).clone();
		if (this.o.spawnOffset != null)
			pos = pos.add(this.o.spawnOffset()); // Call the spawnOffset function if it's there
		// This isn't necessarily uniform but it's fine for the purpose.
		var randomPointOnSphere = new Vector(Math.random() * 2 - 1, Math.random() * 2 - 1, Math.random() * 2 - 1).normalized();
		randomPointOnSphere.x *= this.spawnSphereSquish.x;
		randomPointOnSphere.y *= this.spawnSphereSquish.y;
		randomPointOnSphere.z *= this.spawnSphereSquish.z;
		// Compute the total velocity
		var initialVel = this.o.ejectionVelocity;
		initialVel += (this.o.velocityVariance * 2 * Math.random()) - this.o.velocityVariance;
		var vel = this.vel.multiply(this.o.inheritedVelFactor).add(randomPointOnSphere.multiply(initialVel)).add(this.o.ambientVelocity);
		// var vel = this.vel.multiply(this.o.inheritedVelFactor)
		// 	.add(randomPointOnSphere.multiply(this.o.ejectionVelocity + this.o.velocityVariance * (Math.random() * 2 - 1)))
		// 	.add(this.o.ambientVelocity);
		var particle = new Particle(this.o.particleOptions, this.manager, this.data, time, pos, vel);
		this.manager.addParticle(data, particle);
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

	var particleGroups:Map<String, Particles> = [];
	var particles:Array<Particle> = [];

	var emitters:Array<ParticleEmitter> = [];

	public function new(level:MarbleWorld) {
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
			var pGroup = new Particles(particle.data.texture, this.scene);
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

	public function createEmitter(options:ParticleEmitterOptions, data:ParticleData, initialPos:Vector, ?getPos:Void->Vector, ?spawnSphereSquish:Vector) {
		var emitter = new ParticleEmitter(options, data, cast this, getPos, spawnSphereSquish);
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
