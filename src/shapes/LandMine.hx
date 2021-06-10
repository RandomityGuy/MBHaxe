package shapes;

import collision.CollisionInfo;
import src.DtsObject;
import src.Util;
import src.ParticleSystem.ParticleEmitterOptions;
import src.ParticleSystem.ParticleData;
import h3d.Vector;
import src.ResourceLoader;

final landMineParticle:ParticleEmitterOptions = {
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

final landMineSmokeParticle:ParticleEmitterOptions = {
	ejectionPeriod: 0.5,
	ambientVelocity: new Vector(0, 0, 0),
	ejectionVelocity: 0.8,
	velocityVariance: 0.4,
	emitterLifetime: 50,
	inheritedVelFactor: 0.25,
	particleOptions: {
		texture: 'particles/smoke.png',
		blending: Alpha,
		spinSpeed: 40,
		spinRandomMin: -90,
		spinRandomMax: 90,
		lifetime: 1200,
		lifetimeVariance: 300,
		dragCoefficient: 0.85,
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

final landMineSparksParticle:ParticleEmitterOptions = {
	ejectionPeriod: 0.4,
	ambientVelocity: new Vector(0, 0, 0),
	ejectionVelocity: 13 / 4,
	velocityVariance: 6.75 / 4,
	emitterLifetime: 100,
	inheritedVelFactor: 0.2,
	particleOptions: {
		texture: 'particles/spark.png',
		blending: Add,
		spinSpeed: 40,
		spinRandomMin: -90,
		spinRandomMax: 90,
		lifetime: 500,
		lifetimeVariance: 350,
		dragCoefficient: 0.75,
		acceleration: -8,
		colors: [
			new Vector(0.6, 0.4, 0.3, 1),
			new Vector(0.6, 0.4, 0.3, 1),
			new Vector(1, 0.4, 0.3, 0)
		],
		sizes: [0.5, 0.25, 0.25],
		times: [0, 0.5, 1]
	}
};

class LandMine extends DtsObject {
	var disappearTime = -1e8;

	var landMineParticleData:ParticleData;
	var landMineSmokeParticleData:ParticleData;
	var landMineSparkParticleData:ParticleData;

	public function new() {
		super();
		dtsPath = "data/shapes/hazards/landmine.dts";
		this.identifier = "LandMine";
		this.isCollideable = true;

		landMineParticleData = new ParticleData();
		landMineParticleData.identifier = "landMineParticle";
		landMineParticleData.texture = ResourceLoader.getTexture("data/particles/smoke.png");

		landMineSmokeParticleData = new ParticleData();
		landMineSmokeParticleData.identifier = "landMineSmokeParticle";
		landMineSmokeParticleData.texture = ResourceLoader.getTexture("data/particles/smoke.png");

		landMineSparkParticleData = new ParticleData();
		landMineSparkParticleData.identifier = "landMineSparkParticle";
		landMineSparkParticleData.texture = ResourceLoader.getTexture("data/particles/spark.png");
	}

	function computeExplosionStrength(r:Float) {
		// Figured out through testing by RandomityGuy
		if (r >= 10.25)
			return 0.0;
		if (r >= 10)
			return Util.lerp(30.0087, 30.7555, r - 10);

		// The explosion first becomes stronger the further you are away from it, then becomes weaker again (parabolic).
		var a = 0.071436222;
		var v = (Math.pow((r - 5), 2)) / (-4 * a) + 87.5;

		return v;
	}

	override function onMarbleContact(time:Float, ?contact:CollisionInfo) {
		var marble = this.level.marble;
		var minePos = this.getAbsPos().getPosition();
		var off = marble.getAbsPos().getPosition().sub(minePos);
		var vec = off.normalized(); // Use the last pos so that it's a little less RNG

		// Add velocity to the marble
		var explosionStrength = this.computeExplosionStrength(off.length());
		marble.velocity = marble.velocity.add(vec.multiply(explosionStrength));
		this.disappearTime = level.currentTime;
		this.isCollideable = false;
		// this.setCollisionEnabled(false);

		// if (!this.level.rewinding)
		// 	AudioManager.play(this.sounds[0]);
		this.level.particleManager.createEmitter(landMineParticle, landMineParticleData, this.getAbsPos().getPosition());
		this.level.particleManager.createEmitter(landMineSmokeParticle, landMineSmokeParticleData, this.getAbsPos().getPosition());
		this.level.particleManager.createEmitter(landMineSparksParticle, landMineSparkParticleData, this.getAbsPos().getPosition());
		// Normally, we would add a light here, but that's too expensive for THREE, apparently.

		// this.level.replay.recordMarbleContact(this);
	}

	override function update(currentTime:Float, dt:Float) {
		super.update(currentTime, dt);
		if (currentTime >= this.disappearTime + 5 || currentTime < this.disappearTime) {
			this.setHide(false);
		} else {
			this.setHide(true);
		}

		var opacity = Util.clamp((currentTime - (this.disappearTime + 5)), 0, 1);
		this.setOpacity(opacity);
	}
}