package shapes;

import src.Marble;
import src.MarbleWorld;
import src.ResourceLoader;
import src.TimeState;
import mis.MissionElement.MissionElementItem;

class Blast extends PowerUp {
	public function new(element:MissionElementItem) {
		super(element);
		this.dtsPath = "data/shapes/images/blast.dts";
		this.isCollideable = false;
		this.isTSStatic = false;
		this.showSequences = true;
		this.identifier = "Blast";
		this.pickUpName = "a Blast powerup";
		this.ambientRotate = false;
		this.autoUse = true;
	}

	public override function init(level:MarbleWorld, onFinish:Void->Void) {
		super.init(level, () -> {
			ResourceLoader.load("sound/ultrablast.wav").entry.load(() -> {
				this.pickupSound = ResourceLoader.getResource("data/sound/ultrablast.wav", ResourceLoader.getAudio, this.soundResources);
				onFinish();
			});
		});
	}

	public function pickUp(marble:Marble):Bool {
		return true;
	}

	public function use(marble:Marble, timeState:TimeState) {
		this.level.blastAmount = 1.2;
	}

	override function getPreloadMaterials(dts:dts.DtsFile) {
		var mats = super.getPreloadMaterials(dts);
		mats.push("data/shapes/images/blast_orbit_bump.png");
		mats.push("data/shapes/items/item_glow.png");
		return mats;
	}

	override function postProcessMaterial(matName:String, material:h3d.mat.Material) {
		if (matName == "blast_orbit_skin") {
			var diffuseTex = ResourceLoader.getTexture("data/shapes/images/blast_orbit_skin.png").resource;
			diffuseTex.wrap = Repeat;
			diffuseTex.mipMap = Nearest;
			var normalTex = ResourceLoader.getTexture("data/shapes/images/blast_orbit_bump.png").resource;
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
			var diffuseTex = ResourceLoader.getTexture("data/shapes/items/item_glow.png").resource;
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
