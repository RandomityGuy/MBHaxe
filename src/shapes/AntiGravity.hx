package shapes;

import src.Marble;
import mis.MisParser;
import dts.DtsFile;
import src.ResourceLoader;
import mis.MissionElement.MissionElementItem;
import src.TimeState;
import h3d.Vector;
import src.DtsObject;
import src.MarbleWorld;

class AntiGravity extends PowerUp {
	public function new(element:MissionElementItem, norespawn:Bool = false) {
		super(element);
		this.dtsPath = "data/shapes/items/antigravity.dts";
		this.isCollideable = false;
		this.isTSStatic = false;
		this.identifier = "AntiGravity";
		this.pickUpName = "a Gravity Modifier";
		this.autoUse = true;
		this.useInstancing = true;
		this.animateSubObjectOpacities = true;
		this.sharedNodeTransforms = true;
		if (MisParser.parseBoolean(element.permanent))
			norespawn = true;
		if (norespawn)
			this.cooldownDuration = Math.NEGATIVE_INFINITY;
	}

	public function pickUp(marble:Marble):Bool {
		var direction = new Vector(0, 0, -1);
		direction.transform(this.getRotationQuat().toMatrix());
		return !direction.equals(this.level.marble.currentUp);
	}

	public function use(marble:Marble, timeState:TimeState) {
		if (!this.level.rewinding) {
			var direction = new Vector(0, 0, -1);
			direction.transform(this.getRotationQuat().toMatrix());
			if (marble == level.marble)
				this.level.setUp(marble, direction, timeState);
			else
				marble.currentUp.load(direction);
		}
	}

	public override function init(level:MarbleWorld, onFinish:Void->Void) {
		super.init(level, () -> {
			ResourceLoader.load("sound/pu_gravity.wav").entry.load(() -> {
				this.pickupSound = ResourceLoader.getResource("data/sound/pu_gravity.wav", ResourceLoader.getAudio, this.soundResources);
				onFinish();
			});
		});
	}

	override function getPreloadMaterials(dts:dts.DtsFile) {
		var mats = super.getPreloadMaterials(dts);
		mats.push("data/shapes/items/antigrav_bump.png");
		mats.push("data/shapes/items/antigrav_glow.png");
		return mats;
	}

	override function postProcessMaterial(matName:String, material:h3d.mat.Material) {
		if (matName == "antigrav_skin") {
			var diffuseTex = ResourceLoader.getTexture("data/shapes/items/antigrav_skin.png").resource;
			diffuseTex.wrap = Repeat;
			diffuseTex.mipMap = Nearest;
			var normalTex = ResourceLoader.getTexture("data/shapes/items/antigrav_bump.png").resource;
			normalTex.wrap = Repeat;
			normalTex.mipMap = None;
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
			var diffuseTex = ResourceLoader.getTexture("data/shapes/items/antigrav_glow.png").resource;
			diffuseTex.wrap = Repeat;
			diffuseTex.mipMap = Nearest;

			var trivialShader = new shaders.TrivialMaterial(diffuseTex);

			var glowpass = material.mainPass.clone();
			glowpass.addShader(trivialShader);
			var dtsshader = glowpass.getShader(shaders.DtsTexture);
			dtsshader.passThrough = true;
			glowpass.setPassName("glow");
			glowpass.depthTest = LessEqual;
			glowpass.enableLights = false;
			material.addPass(glowpass);

			material.mainPass.setPassName("glowPre");
			material.mainPass.addShader(trivialShader);
			dtsshader = material.mainPass.getShader(shaders.DtsTexture);
			dtsshader.passThrough = true;
			material.mainPass.enableLights = false;

			var thisprops:Dynamic = material.getDefaultProps();
			thisprops.light = false; // We will calculate our own lighting
			material.props = thisprops;
			material.shadows = false;
		}
	}
}
