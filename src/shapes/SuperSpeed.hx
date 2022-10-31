package shapes;

import mis.MissionElement.MissionElementItem;
import src.TimeState;
import src.ResourceLoader;
import src.ParticleSystem.ParticleData;
import src.ParticleSystem.ParticleEmitterOptions;
import h3d.Quat;
import h3d.Vector;
import src.DtsObject;
import src.AudioManager;
import src.MarbleWorld;

final superSpeedParticleOptions:ParticleEmitterOptions = {
	ejectionPeriod: 5,
	ambientVelocity: new Vector(0, 0, 0.2),
	ejectionVelocity: 1,
	velocityVariance: 0.25,
	emitterLifetime: 1100,
	inheritedVelFactor: 0.25,
	particleOptions: {
		texture: 'particles/spark.png',
		blending: Add,
		spinSpeed: 0,
		spinRandomMin: 0,
		spinRandomMax: 0,
		lifetime: 1500,
		lifetimeVariance: 150,
		dragCoefficient: 0.25,
		acceleration: 0,
		colors: [
			new Vector(0.8, 0.8, 0, 0),
			new Vector(0.8, 0.8, 0, 1),
			new Vector(0.8, 0.8, 0, 0)
		],
		sizes: [0.25, 0.25, 1],
		times: [0, 0.25, 1]
	}
};

class SuperSpeed extends PowerUp {
	var ssEmitterParticleData:ParticleData;

	public function new(element:MissionElementItem) {
		super(element);
		this.dtsPath = "data/shapes/items/superspeed.dts";
		this.isCollideable = false;
		this.isTSStatic = false;
		this.identifier = "SuperSpeed";
		this.pickUpName = "Super Speed PowerUp";
		this.useInstancing = true;
		ssEmitterParticleData = new ParticleData();
		ssEmitterParticleData.identifier = "superSpeedParticle";
		ssEmitterParticleData.texture = ResourceLoader.getResource("data/particles/spark.png", ResourceLoader.getTexture, this.textureResources);
	}

	public override function init(level:MarbleWorld, onFinish:Void->Void) {
		super.init(level, () -> {
			ResourceLoader.load("sound/pusuperspeedvoice.wav").entry.load(() -> {
				this.pickupSound = ResourceLoader.getResource("data/sound/pusuperspeedvoice.wav", ResourceLoader.getAudio, this.soundResources);
				ResourceLoader.load("sound/dosuperspeed.wav").entry.load(onFinish);
			});
		});
	}

	public function pickUp():Bool {
		return this.level.pickUpPowerUp(this);
	}

	public function use(timeState:TimeState) {
		var marble = this.level.marble;
		var movementVector = marble.getMarbleAxis()[0];

		// Okay, so super speed directionality is a bit strange. In general, the direction is based on the normal vector of the last surface you had contact with.

		// var quat = level.newOrientationQuat;
		// movementVector.applyQuaternion(quat);

		var quat2 = new Quat();
		// Determine the necessary rotation to rotate the up vector to the contact normal.
		quat2.initMoveTo(this.level.currentUp, marble.lastContactNormal);
		movementVector.transform(quat2.toMatrix());
		marble.velocity = marble.velocity.add(movementVector.multiply(-24.7));

		// marble.body.addLinearVelocity(Util.vecThreeToOimo(movementVector).scale(24.7)); // Whirligig's determined value
		// marble.body.addLinearVelocity(this.level.currentUp.scale(20)); // Simply add to vertical velocity
		// if (!this.level.rewinding)
		AudioManager.playSound(ResourceLoader.getResource("data/sound/dosuperspeed.wav", ResourceLoader.getAudio, this.soundResources));
		this.level.particleManager.createEmitter(superSpeedParticleOptions, this.ssEmitterParticleData, null, () -> marble.getAbsPos().getPosition());
		this.level.deselectPowerUp();
	}
}
