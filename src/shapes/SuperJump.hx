package shapes;

import src.ResourceLoader;
import mis.MissionElement.MissionElementItem;
import src.TimeState;
import src.ResourceLoader;
import src.ParticleSystem.ParticleData;
import h3d.Vector;
import src.AudioManager;
import src.DtsObject;
import src.MarbleWorld;

final superJumpParticleOptions:src.ParticleSystem.ParticleEmitterOptions = {
	ejectionPeriod: 10,
	ambientVelocity: new Vector(0, 0, 0.05),
	ejectionVelocity: 1,
	velocityVariance: 0.25,
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
		this.pickUpName = "Jump Boost PowerUp";
		sjEmitterParticleData = new ParticleData();
		sjEmitterParticleData.identifier = "superJumpParticle";
		sjEmitterParticleData.texture = ResourceLoader.getResource("data/particles/twirl.png", ResourceLoader.getTexture, this.textureResources);
	}

	public override function init(level:MarbleWorld, onFinish:Void->Void) {
		super.init(level, () -> {
			ResourceLoader.load("sound/pusuperjumpvoice.wav").entry.load(() -> {
				this.pickupSound = ResourceLoader.getResource("data/sound/pusuperjumpvoice.wav", ResourceLoader.getAudio, this.soundResources);
				ResourceLoader.load("sound/dosuperjump.wav").entry.load(onFinish);
			});
		});
	}

	public function pickUp(marble:src.Marble):Bool {
		return this.level.pickUpPowerUp(marble, this);
	}

	public function use(marble:src.Marble, timeState:TimeState) {
		marble.velocity.load(marble.velocity.add(marble.currentUp.multiply(20)));
		if (@:privateAccess !marble.isNetUpdate)
			this.level.particleManager.createEmitter(superJumpParticleOptions, this.sjEmitterParticleData, null, () -> marble.getAbsPos().getPosition());
		// marble.body.addLinearVelocity(this.level.currentUp.scale(20)); // Simply add to vertical velocity
		// if (!this.level.rewinding)
		if (level.marble == marble && @:privateAccess !marble.isNetUpdate)
			AudioManager.playSound(ResourceLoader.getResource("data/sound/dosuperjump.wav", ResourceLoader.getAudio, this.soundResources));
		// this.level.particles.createEmitter(superJumpParticleOptions, null, () => Util.vecOimoToThree(marble.body.getPosition()));
		this.level.deselectPowerUp(marble);
	}
}
