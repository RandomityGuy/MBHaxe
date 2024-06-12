package shapes;

import src.Marble;
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
		this.sharedNodeTransforms = true;
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

	public function pickUp(marble:Marble):Bool {
		return this.level.pickUpPowerUp(marble, this);
	}

	public function use(marble:Marble, timeState:TimeState) {
		var movementVector = marble.getMarbleAxis()[0];

		var boostVec = movementVector.clone();

		var contactDot = movementVector.dot(marble.lastContactNormal);
		boostVec.load(boostVec.sub(marble.lastContactNormal.multiply(contactDot)));
		if (boostVec.lengthSq() > 0.01) {
			boostVec.normalize();
		} else {
			boostVec.load(movementVector);
		}

		var masslessFactor = marble.getMass() * 0.7 + 1 - 0.7;
		marble.velocity = marble.velocity.add(boostVec.multiply(-25 * masslessFactor / marble.getMass()));

		if (level.marble == marble && @:privateAccess !marble.isNetUpdate)
			AudioManager.playSound(ResourceLoader.getResource("data/sound/use_speed.wav", ResourceLoader.getAudio, this.soundResources));
		if (@:privateAccess !marble.isNetUpdate)
			this.level.particleManager.createEmitter(superSpeedParticleOptions, this.ssEmitterParticleData, null, () -> marble.getAbsPos().getPosition());
		this.level.deselectPowerUp(marble);
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
