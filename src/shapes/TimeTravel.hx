package shapes;

import src.ResourceLoader;
import mis.MissionElement.MissionElementItem;
import src.TimeState;
import mis.MisParser;
import src.MarbleWorld;

class TimeTravel extends PowerUp {
	var timeBonus:Float = 5;
	var shader:shaders.RefractMaterial;

	public function new(element:MissionElementItem) {
		super(element);
		this.dtsPath = "data/shapes/items/timetravel.dts";
		this.isCollideable = false;
		this.isTSStatic = false;
		this.identifier = "TimeTravel";

		if (element.timebonus != null) {
			this.timeBonus = MisParser.parseNumber(element.timebonus) / 1000;
		}
		if (element.timepenalty != null) {
			this.timeBonus = -MisParser.parseNumber(element.timepenalty) / 1000;
		}

		this.pickUpName = '${this.timeBonus} seconds of Time Travel ${this.timeBonus >= 0 ? 'bonus' : 'Penalty'}';
		this.cooldownDuration = 1e8;
		this.useInstancing = true;
		this.autoUse = true;
	}

	public override function init(level:MarbleWorld, onFinish:Void->Void) {
		super.init(level, () -> {
			ResourceLoader.load("sound/time_travel.wav").entry.load(() -> {
				this.pickupSound = ResourceLoader.getResource("data/sound/time_travel.wav", ResourceLoader.getAudio, this.soundResources);
				ResourceLoader.load("sound/timetravelactive.wav").entry.load(onFinish);
			});
		});
	}

	public function pickUp():Bool {
		return true;
	}

	public function use(time:TimeState) {
		if (!this.level.rewinding)
			level.addBonusTime(this.timeBonus);
	}

	override function getPreloadMaterials(dts:dts.DtsFile) {
		var mats = super.getPreloadMaterials(dts);
		mats.push("data/shapes/structures/glass.png");
		mats.push("data/shapes/structures/time.normal.jpg");
		return mats;
	}

	override function postProcessMaterial(matName:String, material:h3d.mat.Material) {
		if (matName == "timeTravel_skin") {
			var diffuseTex = ResourceLoader.getTexture("data/shapes/items/timeTravel_skin.png").resource;
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
		if (matName == "timeTravel_glass") {
			var thisprops:Dynamic = material.getDefaultProps();
			thisprops.light = false; // We will calculate our own lighting
			material.props = thisprops;
			material.shadows = false;
			material.receiveShadows = true;
			material.mainPass.depthWrite = false;
			material.blendMode = Alpha;

			var refractTex = ResourceLoader.getTexture('data/shapes/structures/glass.png').resource;
			refractTex.wrap = Repeat;
			refractTex.mipMap = Nearest;
			var normalTex = ResourceLoader.getTexture("data/shapes/structures/time.normal.jpg").resource;
			normalTex.wrap = Repeat;
			normalTex.mipMap = Nearest;
			shader = new shaders.RefractMaterial(refractTex, normalTex, 10, new h3d.Vector(1, 1, 1, 1), 1);
			shader.refractMap = src.Renderer.getSfxBuffer();

			var dtsshader = material.mainPass.getShader(shaders.DtsTexture);
			if (dtsshader != null)
				material.mainPass.removeShader(dtsshader);
			material.mainPass.removeShader(material.textureShader);
			material.mainPass.addShader(shader);
			material.mainPass.setPassName("refract");
		}
	}
}
