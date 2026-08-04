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
import mis.MissionElement.MissionElementStaticShape;

final nukeParticle:ParticleEmitterOptions = {
	ejectionPeriod: 7,
	periodVariance: 0,
	ambientVelocity: new Vector(0, 0, 0),
	ejectionVelocity: 2,
	velocityVariance: 1,
	emitterLifetime: 120 * 7,
	ejectionOffset: 0,
	thetaMin: 0,
	thetaMax: 60,
	phiReferenceVel: 0,
	phiVariance: 360,
	inheritedVelFactor: 0.2,
	spawnOffset: () -> {
		var dir = new Vector(Math.random() * 2 - 1, Math.random() * 2 - 1, Math.random() * 2 - 1);
		if (dir.lengthSq() < 0.0001)
			dir.set(0, 0, 1);
		dir.normalize();
		var radius = Math.pow(Math.random(), 1 / 3) * 3;
		return dir.multiply(radius);
	},
	particleOptions: {
		texture: 'particles/smoke.png',
		blending: Add,
		spinSpeed: 0,
		spinRandomMin: 0,
		spinRandomMax: 0,
		lifetime: 1000,
		lifetimeVariance: 150,
		dragCoefficient: 2,
		constantAcceleration: 0,
		gravityCoefficient: 0.2,
		windCoefficient: 0,
		colors: [new Vector(0.56, 0.36, 0.26, 1), new Vector(0.56, 0.36, 0.26, 0)],
		sizes: [0.5, 1],
		times: [0, 1]
	}
};

final nukeSmokeParticle:ParticleEmitterOptions = {
	ejectionPeriod: 10,
	periodVariance: 0,
	ambientVelocity: new Vector(0, 0, 0),
	ejectionVelocity: 4,
	velocityVariance: 0.5,
	emitterLifetime: 250,
	ejectionOffset: 0,
	thetaMin: 0,
	thetaMax: 180,
	phiReferenceVel: 0,
	phiVariance: 360,
	inheritedVelFactor: 0.25,
	particleOptions: {
		texture: 'particles/smoke.png',
		blending: Alpha,
		spinSpeed: 0,
		spinRandomMin: -80,
		spinRandomMax: 80,
		lifetime: 10000,
		lifetimeVariance: 3000,
		dragCoefficient: 10,
		constantAcceleration: -0.8,
		gravityCoefficient: -0.5,
		windCoefficient: 0,
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
	ejectionPeriod: 3,
	periodVariance: 0,
	ambientVelocity: new Vector(0, 0, 0),
	ejectionVelocity: 13,
	velocityVariance: 6.75,
	emitterLifetime: 5000,
	ejectionOffset: 0,
	thetaMin: 0,
	thetaMax: 180,
	phiReferenceVel: 0,
	phiVariance: 360,
	inheritedVelFactor: 0.2,
	particleOptions: {
		texture: 'particles/spark.png',
		blending: Add,
		spinSpeed: 0,
		spinRandomMin: 0,
		spinRandomMax: 0,
		lifetime: 5000,
		lifetimeVariance: 2000,
		dragCoefficient: 1,
		constantAcceleration: 0,
		gravityCoefficient: 0,
		windCoefficient: 0,
		colors: [
			new Vector(0.6, 0.4, 0.3, 1),
			new Vector(0.6, 0.4, 0.3, 1),
			new Vector(1, 0.4, 0.3, 0)
		],
		sizes: [0.5, 0.25, 0.25],
		times: [0, 0.5, 1]
	}
};

class Nuke extends Explodable {
	public function new(?element:MissionElementStaticShape) {
		super();
		if (element != null && element.datablock.toLowerCase() == "nuke_pq") {
			// PQ's own Nuke_PQ datablock literally reuses the landmine model, reskinned.
			dtsPath = "data/shapes_pq/gameplay/hazards/mine/landmine.dts";
			this.skinOverride = "nuke";
		} else
			dtsPath = "data/shapes/hazards/nuke/nuke.dts";
		this.identifier = "Nuke" + this.dtsPath + (this.skinOverride != null ? this.skinOverride : "");
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
		explodeSoundFile = "data/sound/NukeExplode.wav";
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
