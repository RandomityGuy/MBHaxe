package shapes;

import src.ResourceLoader;
import mis.MissionElement.MissionElementItem;
import src.TimeState;
import src.ResourceLoader;
import src.ParticleSystem.ParticleData;
import h3d.Vector;
import src.AudioManager;
import src.DtsObject;

final superJumpParticleOptions:src.ParticleSystem.ParticleEmitterOptions = {
	ejectionPeriod: 10,
	ambientVelocity: new Vector(0, 0, 0.05),
	ejectionVelocity: 0.5,
	velocityVariance: 0.125,
	emitterLifetime: 1000,
	inheritedVelFactor: 0.1,
	particleOptions: {
		texture: 'particles/twirl.png',
		blending: Add,
		spinSpeed: 90,
		spinRandomMin: -90,
		spinRandomMax: 90,
		lifetime: 1000,
		lifetimeVariance: 150,
		dragCoefficient: 0.25,
		acceleration: 0,
		colors: [new Vector(0, 0.5, 1, 0), new Vector(0, 0.6, 1, 1), new Vector(0, 0.6, 1, 0)],
		sizes: [0.25, 0.25, 0.5],
		times: [0, 0.75, 1]
	}
};

class SuperJump extends PowerUp {
	var sjEmitterParticleData:ParticleData;

	public function new(element:MissionElementItem) {
		super(element);
		this.dtsPath = "data/shapes/items/superjump.dts";
		this.isCollideable = false;
		this.isTSStatic = false;
		this.identifier = "SuperJump";
		this.pickUpName = "Super Jump PowerUp";
		sjEmitterParticleData = new ParticleData();
		sjEmitterParticleData.identifier = "superJumpParticle";
		sjEmitterParticleData.texture = ResourceLoader.getResource("data/particles/twirl.png", ResourceLoader.getTexture, this.textureResources);
		this.pickupSound = ResourceLoader.getResource("data/sound/pusuperjumpvoice.wav", ResourceLoader.getAudio, this.soundResources);
	}

	public function pickUp():Bool {
		return this.level.pickUpPowerUp(this);
	}

	public function use(timeState:TimeState) {
		var marble = this.level.marble;
		marble.velocity = marble.velocity.add(this.level.currentUp.multiply(20));
		this.level.particleManager.createEmitter(superJumpParticleOptions, this.sjEmitterParticleData, null, () -> marble.getAbsPos().getPosition());
		// marble.body.addLinearVelocity(this.level.currentUp.scale(20)); // Simply add to vertical velocity
		// if (!this.level.rewinding)
		AudioManager.playSound(ResourceLoader.getResource("data/sound/dosuperjump.wav", ResourceLoader.getAudio, this.soundResources));
		// this.level.particles.createEmitter(superJumpParticleOptions, null, () => Util.vecOimoToThree(marble.body.getPosition()));
		this.level.deselectPowerUp();
	}
}
