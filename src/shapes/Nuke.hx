package shapes;

import src.AudioManager;
import src.TimeState;
import collision.CollisionHull;
import collision.CollisionInfo;
import src.DtsObject;
import src.Util;
import src.ParticleSystem.ParticleEmitterOptions;
import src.ParticleSystem.ParticleData;
import h3d.Vector;
import src.ResourceLoader;
import src.MarbleWorld;

final nukeParticle:ParticleEmitterOptions = {
	ejectionPeriod: 0.2,
	ambientVelocity: new Vector(0, 0, 0),
	ejectionVelocity: 2,
	velocityVariance: 1,
	emitterLifetime: 50,
	inheritedVelFactor: 0.2,
	particleOptions: {
		texture: 'particles/smoke.png',
		blending: Add,
		spinSpeed: 40,
		spinRandomMin: -90,
		spinRandomMax: 90,
		lifetime: 1000,
		lifetimeVariance: 150,
		dragCoefficient: 0.8,
		acceleration: 0,
		colors: [new Vector(0.56, 0.36, 0.26, 1), new Vector(0.56, 0.36, 0.26, 0)],
		sizes: [0.5, 1],
		times: [0, 1]
	}
};

final nukeSmokeParticle:ParticleEmitterOptions = {
	ejectionPeriod: 0.5,
	ambientVelocity: new Vector(0, 0, 0),
	ejectionVelocity: 1.3,
	velocityVariance: 0.5,
	emitterLifetime: 50,
	inheritedVelFactor: 0.25,
	particleOptions: {
		texture: 'particles/smoke.png',
		blending: Alpha,
		spinSpeed: 40,
		spinRandomMin: -90,
		spinRandomMax: 90,
		lifetime: 2500,
		lifetimeVariance: 300,
		dragCoefficient: 0.7,
		acceleration: -8,
		colors: [
			new Vector(0.56, 0.36, 0.26, 1),
			new Vector(0.2, 0.2, 0.2, 1),
			new Vector(0, 0, 0, 0)
		],
		sizes: [1, 1.5, 2],
		times: [0, 0.5, 1]
	}
};

final nukeSparksParticle:ParticleEmitterOptions = {
	ejectionPeriod: 1.7,
	ambientVelocity: new Vector(0, -0.5, 0),
	ejectionVelocity: 13 / 1.5,
	velocityVariance: 5,
	emitterLifetime: 5000,
	inheritedVelFactor: 0.2,
	particleOptions: {
		texture: 'particles/spark.png',
		blending: Add,
		spinSpeed: 40,
		spinRandomMin: -90,
		spinRandomMax: 90,
		lifetime: 4500,
		lifetimeVariance: 2500,
		dragCoefficient: 0.5,
		acceleration: 0,
		colors: [
			new Vector(0.6, 0.4, 0.3, 1),
			new Vector(0.6, 0.4, 0.3, 1),
			new Vector(1, 0.4, 0.3, 0)
		],
		sizes: [0.5, 0.4, 0.2],
		times: [0, 0.5, 1]
	}
};

class Nuke extends DtsObject {
	var disappearTime = -1e8;

	var nukeParticleData:ParticleData;
	var nukeSmokeParticleData:ParticleData;
	var nukeSparkParticleData:ParticleData;

	public function new() {
		super();
		dtsPath = "data/shapes/hazards/nuke/nuke.dts";
		this.identifier = "Nuke";
		this.isCollideable = true;

		nukeParticleData = new ParticleData();
		nukeParticleData.identifier = "nukeParticle";
		nukeParticleData.texture = ResourceLoader.getResource("data/particles/smoke.png", ResourceLoader.getTexture, this.textureResources);

		nukeSmokeParticleData = new ParticleData();
		nukeSmokeParticleData.identifier = "nukeSmokeParticle";
		nukeSmokeParticleData.texture = ResourceLoader.getResource("data/particles/smoke.png", ResourceLoader.getTexture, this.textureResources);

		nukeSparkParticleData = new ParticleData();
		nukeSparkParticleData.identifier = "nukeSparkParticle";
		nukeSparkParticleData.texture = ResourceLoader.getResource("data/particles/spark.png", ResourceLoader.getTexture, this.textureResources);
	}

	public override function init(level:MarbleWorld, onFinish:Void->Void) {
		super.init(level, () -> {
			ResourceLoader.load("sound/nukeexplode.wav").entry.load(onFinish);
		});
	}

	override function onMarbleContact(timeState:TimeState, ?contact:CollisionInfo) {
		if (this.isCollideable) {
			// marble.velocity = marble.velocity.add(vec);
			this.disappearTime = timeState.timeSinceLoad;
			this.setCollisionEnabled(false);

			// if (!this.level.rewinding)
			AudioManager.playSound(ResourceLoader.getResource("data/sound/nukeexplode.wav", ResourceLoader.getAudio, this.soundResources));
			this.level.particleManager.createEmitter(nukeParticle, nukeParticleData, this.getAbsPos().getPosition());
			this.level.particleManager.createEmitter(nukeSmokeParticle, nukeSmokeParticleData, this.getAbsPos().getPosition());
			this.level.particleManager.createEmitter(nukeSparksParticle, nukeSparkParticleData, this.getAbsPos().getPosition());

			var marble = this.level.marble;
			var minePos = this.getAbsPos().getPosition();
			var off = marble.getAbsPos().getPosition().sub(minePos);

			var force = computeExplosionForce(off);

			marble.applyImpulse(force);

			// for (collider in this.colliders) {
			// 	var hull:CollisionHull = cast collider;
			// 	hull.force = strength;
			// }
		}
		// Normally, we would add a light here, but that's too expensive for THREE, apparently.

		// this.level.replay.recordMarbleContact(this);
	}

	function computeExplosionForce(distVec:Vector) {
		var range = 10;
		var power = 100;

		var dist = distVec.length();
		if (dist < range) {
			var scalar = (1 - dist / range) * power;
			distVec = distVec.multiply(scalar);
		}

		return distVec;
	}

	override function update(timeState:TimeState) {
		super.update(timeState);
		if (timeState.timeSinceLoad >= this.disappearTime + 15 || timeState.timeSinceLoad < this.disappearTime) {
			this.setHide(false);
		} else {
			this.setHide(true);
		}

		var opacity = Util.clamp((timeState.timeSinceLoad - (this.disappearTime + 15)), 0, 1);
		this.setOpacity(opacity);
	}
}
