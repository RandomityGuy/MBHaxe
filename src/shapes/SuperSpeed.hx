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
	ambientVelocity: new Vector(0, 0, 0),
	ejectionVelocity: 1,
	velocityVariance: 0.25,
	emitterLifetime: 1100,
	inheritedVelFactor: 0.25,
	particleOptions: {
		texture: 'particles/smoke.png',
		blending: Add,
		spinSpeed: 0,
		spinRandomMin: 0,
		spinRandomMax: 0,
		lifetime: 1500,
		lifetimeVariance: 750,
		dragCoefficient: 4,
		acceleration: 0,
		colors: [
			new Vector(0.42, 0.42, 0.38, 0.1),
			new Vector(0.34, 0.34, 0.34, 0.1),
			new Vector(0.30, 0.30, 0.30, 0.1)
		],
		sizes: [0.3, 0.7, 1.4],
		times: [0, 0.5, 1]
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
		this.pickUpName = "a Super Speed powerup";
		this.useInstancing = true;
		ssEmitterParticleData = new ParticleData();
		ssEmitterParticleData.identifier = "superSpeedParticle";
		ssEmitterParticleData.texture = ResourceLoader.getResource("data/particles/smoke.png", ResourceLoader.getTexture, this.textureResources);
	}

	public override function init(level:MarbleWorld, onFinish:Void->Void) {
		super.init(level, () -> {
			ResourceLoader.load("sound/super_speed.wav").entry.load(() -> {
				this.pickupSound = ResourceLoader.getResource("data/sound/super_speed.wav", ResourceLoader.getAudio, this.soundResources);
				ResourceLoader.load("sound/use_speed.wav").entry.load(onFinish);
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
		marble.velocity = marble.velocity.add(movementVector.multiply(-25));

		// marble.body.addLinearVelocity(Util.vecThreeToOimo(movementVector).scale(24.7)); // Whirligig's determined value
		// marble.body.addLinearVelocity(this.level.currentUp.scale(20)); // Simply add to vertical velocity
		// if (!this.level.rewinding)
		AudioManager.playSound(ResourceLoader.getResource("data/sound/use_speed.wav", ResourceLoader.getAudio, this.soundResources));
		this.level.particleManager.createEmitter(superSpeedParticleOptions, this.ssEmitterParticleData, null, () -> marble.getAbsPos().getPosition());
		this.level.deselectPowerUp();
	}

	override function postProcessMaterial(matName:String, material:h3d.mat.Material) {
		if (matName == "superSpeed_skin") {
			var diffuseTex = ResourceLoader.getTexture("data/shapes/items/superSpeed_skin.png").resource;
			diffuseTex.wrap = Repeat;
			diffuseTex.mipMap = Nearest;
			var shader = new shaders.DefaultNormalMaterial(diffuseTex, 32, new h3d.Vector(1, 1, 1, 1), 1);
			shader.doGammaRamp = false;
			var dtsTex = material.mainPass.getShader(shaders.DtsTexture);
			dtsTex.passThrough = true;
			material.mainPass.removeShader(material.textureShader);
			material.mainPass.addShader(shader);
			var thisprops:Dynamic = material.getDefaultProps();
			thisprops.light = false; // We will calculate our own lighting
			material.props = thisprops;
			material.shadows = false;
			material.receiveShadows = true;
		}
		if (matName == "superSpeed_star") {
			var diffuseTex = ResourceLoader.getTexture("data/shapes/items/superSpeed_star.png").resource;
			diffuseTex.wrap = Repeat;
			diffuseTex.mipMap = Nearest;

			var trivialShader = new shaders.TrivialMaterial(diffuseTex);

			var glowpass = material.mainPass.clone();
			glowpass.addShader(trivialShader);
			var dtsshader = glowpass.getShader(shaders.DtsTexture);
			if (dtsshader != null)
				glowpass.removeShader(dtsshader);
			glowpass.setPassName("glow");
			glowpass.depthTest = LessEqual;
			glowpass.enableLights = false;
			material.addPass(glowpass);

			material.mainPass.setPassName("glowPre");
			material.mainPass.addShader(trivialShader);
			dtsshader = material.mainPass.getShader(shaders.DtsTexture);
			if (dtsshader != null)
				material.mainPass.removeShader(dtsshader);
			material.mainPass.enableLights = false;

			var thisprops:Dynamic = material.getDefaultProps();
			thisprops.light = false; // We will calculate our own lighting
			material.props = thisprops;
			material.shadows = false;
		}
	}
}
