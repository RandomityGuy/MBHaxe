package shapes;

import src.ResourceLoaderWorker;
import src.MarbleWorld;
import src.ResourceLoader;
import src.TimeState;
import mis.MissionElement.MissionElementItem;
import src.AudioManager;

class MegaMarble extends PowerUp {
	public function new(element:MissionElementItem) {
		super(element);
		this.dtsPath = "data/shapes/images/grow.dts";
		this.isCollideable = false;
		this.isTSStatic = false;
		this.showSequences = true;
		this.identifier = "MegaMarble";
		this.pickUpName = "Mega Marble PowerUp";
	}

	public override function init(level:MarbleWorld, onFinish:Void->Void) {
		super.init(level, () -> {
			ResourceLoader.load("sound/mega_marble.wav").entry.load(() -> {
				var worker = new ResourceLoaderWorker(onFinish);
				worker.loadFile("sound/mega_bouncehard1.wav");
				worker.loadFile("sound/mega_bouncehard2.wav");
				worker.loadFile("sound/mega_bouncehard3.wav");
				worker.loadFile("sound/mega_bouncehard4.wav");
				worker.loadFile("sound/mega_roll.wav");
				worker.loadFile("sound/use_mega.wav");
				this.pickupSound = ResourceLoader.getResource("data/sound/mega_marble.wav", ResourceLoader.getAudio, this.soundResources);
				worker.run();
			});
		});
	}

	public function pickUp():Bool {
		return this.level.pickUpPowerUp(this);
	}

	public function use(timeState:TimeState) {
		this.level.marble.enableMegaMarble(timeState.currentAttemptTime);
		this.level.deselectPowerUp();
		AudioManager.playSound(ResourceLoader.getResource('data/sound/use_mega.wav', ResourceLoader.getAudio, this.soundResources));
	}

	override function postProcessMaterial(matName:String, material:h3d.mat.Material) {
		if (matName == "grow") {
			var diffuseTex = ResourceLoader.getTexture("data/shapes/images/grow.png").resource;
			diffuseTex.wrap = Repeat;
			diffuseTex.mipMap = Nearest;
			var normalTex = ResourceLoader.getTexture("data/shapes/images/grow_bump.png").resource;
			normalTex.wrap = Repeat;
			normalTex.mipMap = Nearest;
			var shader = new shaders.DefaultMaterial(diffuseTex, normalTex, 32, new h3d.Vector(0.8, 0.8, 0.6, 1), 1);
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
		if (matName == "item_glow") {
			var diffuseTex = ResourceLoader.getTexture("data/shapes/images/grow_glow.png").resource;
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
