package shapes;

import src.Settings;
import mis.MissionElement.MissionElementItem;
import src.ResourceLoader;

class EasterEgg extends PowerUp {
	public function new(element:MissionElementItem) {
		super(element);
		this.dtsPath = "data/shapes/items/egg.dts";
		this.isCollideable = false;
		this.isTSStatic = false;
		this.identifier = "EasterEgg";
		this.pickUpName = "Easter Egg";
		this.autoUse = true;
	}

	public function pickUp():Bool {
		var found:Bool = false;
		if (Settings.easterEggs.exists(this.level.mission.path)) {
			found = true;
		}
		if (!found) {
			Settings.easterEggs.set(this.level.mission.path, this.level.timeState.currentAttemptTime);
			this.pickupSound = ResourceLoader.getResource("data/sound/easter_egg.wav", ResourceLoader.getAudio, this.soundResources);
			this.customPickupMessage = "You picked up an Easter Egg!";
		} else {
			this.pickupSound = ResourceLoader.getResource("data/sound/pu_easter.wav", ResourceLoader.getAudio, this.soundResources);
			this.customPickupMessage = "You picked up an Easter Egg!.";
		}

		return true;
	}

	public override function init(level:src.MarbleWorld, onFinish:() -> Void) {
		super.init(level, () -> {
			ResourceLoader.load("sound/easter_egg.wav").entry.load(() -> {
				ResourceLoader.load("sound/pu_easter.wav").entry.load(onFinish);
			});
		});
	}

	public function use(timeState:src.TimeState) {}

	override function getPreloadMaterials(dts:dts.DtsFile) {
		var mats = super.getPreloadMaterials(dts);
		mats.push("data/skies/gemCubemapUp.png");
		return mats;
	}

	override function postProcessMaterial(matName:String, material:h3d.mat.Material) {
		if (matName == "egg_skin") {
			var diffuseTex = ResourceLoader.getTexture("data/shapes/items/egg_skin.png").resource;
			diffuseTex.wrap = Repeat;
			diffuseTex.mipMap = Nearest;

			var cubemapTex = new h3d.mat.Texture(64, 64, [Cube]);
			var cubemapFace = ResourceLoader.getImage('data/skies/gemCubemapUp.png').resource;
			for (i in 0...6) {
				cubemapTex.uploadPixels(cubemapFace.getPixels(), 0, i);
			}

			var shader = new shaders.DefaultCubemapNormalMaterial(diffuseTex, cubemapTex, 32, new h3d.Vector(1, 1, 1, 1), 1);
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
	}
}
