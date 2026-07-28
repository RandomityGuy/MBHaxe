package shapes;

import modes.TwoDMode;
import modes.GameMode.GameModeFactory;
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

/** Ported from `marble.cs`'s `SuperSpeedParticle`/`MarbleSuperSpeedEmitter`. */
final superSpeedParticleOptions:ParticleEmitterOptions = {
	ejectionPeriod: 5,
	periodVariance: 0,
	ambientVelocity: new Vector(0, 0, 0.2),
	ejectionVelocity: 1,
	velocityVariance: 0.25,
	emitterLifetime: 1100,
	ejectionOffset: 0,
	thetaMin: 130,
	thetaMax: 170,
	phiReferenceVel: 0,
	phiVariance: 360,
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
		constantAcceleration: 0,
		gravityCoefficient: 0,
		windCoefficient: 0,
		colors: [
			new Vector(0.8, 0.8, 0.2, 0),
			new Vector(0.8, 0.8, 0.2, 1),
			new Vector(0.8, 0.8, 0.2, 0)
		],
		sizes: [0.25, 0.25, 1],
		times: [0, 0.25, 1]
	}
};

class SuperSpeed extends PowerUp {
	var ssEmitterParticleData:ParticleData;

	public function new(element:MissionElementItem) {
		super(element);
		this.dtsPath = StringTools.endsWith(element.datablock, "_PQ") ? "data/shapes_pq/gameplay/powerups/superspeed.dts" : "data/shapes/items/superspeed.dts";
		this.isCollideable = false;
		this.isTSStatic = false;
		// Instancing batches by `identifier`, and the PQ variant uses a different mesh - keep the
		// dtsPath in the identifier so it doesn't get batched with the vanilla mesh.
		this.identifier = "SuperSpeed" + this.dtsPath;
		this.pickUpName = "Super Speed PowerUp";
		this.useInstancing = true;
		ssEmitterParticleData = new ParticleData();
		ssEmitterParticleData.identifier = "superSpeedParticle";
		ssEmitterParticleData.texture = ResourceLoader.getResource("data/particles/spark.png", ResourceLoader.getTexture, this.textureResources);
		this.radarIndex = 30;
	}

	public override function init(level:MarbleWorld, onFinish:Void->Void) {
		super.init(level, () -> {
			ResourceLoader.load("sound/pusuperspeedvoice.wav").entry.load(() -> {
				this.pickupSound = ResourceLoader.getResource("data/sound/pusuperspeedvoice.wav", ResourceLoader.getAudio, this.soundResources);
				ResourceLoader.load("sound/dosuperspeed.wav").entry.load(onFinish);
			});
		});
	}

	public function pickUp(marble:src.Marble):Bool {
		return this.level.pickUpPowerUp(marble, this);
	}

	public function use(marble:src.Marble, timeState:TimeState) {
		var marbleAxis = marble.getMarbleAxis();

		var movementVector = marbleAxis[0];

		var twoDMode = GameModeFactory.findMode(this.level.gameMode, TwoDMode);
		if (twoDMode != null) {
			movementVector = marbleAxis[1].multiply(twoDMode.lastPressedLR ? 1 : -1);
		}

		var boostVec = movementVector.clone();

		var contactDot = movementVector.dot(marble.lastContactNormal);
		boostVec.load(boostVec.sub(marble.lastContactNormal.multiply(contactDot)));
		if (boostVec.lengthSq() > 0.01) {
			boostVec.normalize();
		} else {
			boostVec.load(movementVector);
		}

		marble.velocity.load(marble.velocity.add(boostVec.multiply(-25)));

		// marble.body.addLinearVelocity(Util.vecThreeToOimo(movementVector).scale(24.7)); // Whirligig's determined value
		// marble.body.addLinearVelocity(this.level.currentUp.scale(20)); // Simply add to vertical velocity
		// if (!this.level.rewinding)
		if (level.marble == marble && @:privateAccess !marble.isNetUpdate)
			AudioManager.playSound(ResourceLoader.getResource("data/sound/dosuperspeed.wav", ResourceLoader.getAudio, this.soundResources));
		if (@:privateAccess !marble.isNetUpdate)
			this.level.particleManager.createEmitter(superSpeedParticleOptions, this.ssEmitterParticleData, null, () -> marble.getAbsPos().getPosition());
		this.level.deselectPowerUp(marble);
		return true;
	}
}
