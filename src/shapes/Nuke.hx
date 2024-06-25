package shapes;

import net.BitStream.OutputBitStream;
import net.NetPacket.ExplodableUpdatePacket;
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
import net.Net;

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

class Nuke extends Explodable {
	public function new() {
		super();
		dtsPath = "data/shapes/hazards/nuke/nuke.dts";
		this.identifier = "Nuke";
		this.isCollideable = true;

		particleData = new ParticleData();
		particleData.identifier = "nukeParticle";
		particleData.texture = ResourceLoader.getResource("data/particles/smoke.png", ResourceLoader.getTexture, this.textureResources);

		smokeParticleData = new ParticleData();
		smokeParticleData.identifier = "nukeSmokeParticle";
		smokeParticleData.texture = ResourceLoader.getResource("data/particles/smoke.png", ResourceLoader.getTexture, this.textureResources);

		sparkParticleData = new ParticleData();
		sparkParticleData.identifier = "nukeSparkParticle";
		sparkParticleData.texture = ResourceLoader.getResource("data/particles/spark.png", ResourceLoader.getTexture, this.textureResources);

		particle = nukeParticle;
		smokeParticle = nukeSmokeParticle;
		sparksParticle = nukeSparksParticle;

		renewTime = 15000;
		explodeSoundFile = "data/sound/nukeexplode.wav";
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

	public function applyImpulse(marble:src.Marble) {
		var minePos = this.getAbsPos().getPosition();
		var dtsCenter = this.dts.bounds.center();
		var off = marble.getAbsPos().getPosition().sub(minePos);

		var force = computeExplosionForce(off);
		marble.applyImpulse(force, true);
	}
}
