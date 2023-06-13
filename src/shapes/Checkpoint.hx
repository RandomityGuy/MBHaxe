package shapes;

import collision.CollisionInfo;
import mis.MisParser;
import src.DtsObject;
import src.ResourceLoader;
import mis.MissionElement.MissionElementStaticShape;

class Checkpoint extends DtsObject {
	public var disableOOB = false;

	var element:MissionElementStaticShape;

	public function new(element:MissionElementStaticShape) {
		super();
		this.dtsPath = "data/shapes/pads/checkpad.dts";
		this.isCollideable = true;
		this.isTSStatic = false;
		this.identifier = "Checkpoint";
		this.element = element;
		this.animateSubObjectOpacities = true;

		this.disableOOB = element.fields.exists('disableOob') ? MisParser.parseBoolean(element.fields['disableOob'][0]) : false;
	}

	public override function init(level:src.MarbleWorld, onFinish:() -> Void) {
		super.init(level, () -> {
			ResourceLoader.load("sound/checkpoint.wav").entry.load(onFinish);
		});
	}

	public override function onMarbleContact(time:src.TimeState, ?contact:CollisionInfo) {
		this.level.saveCheckpointState({
			obj: this,
			elem: this.element
		}, null);
	}

	override function postProcessMaterial(matName:String, material:h3d.mat.Material) {
		if (matName == "sigil") {
			var diffuseTex = ResourceLoader.getTexture("data/shapes/pads/sigil.png").resource;
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
			glowpass.setBlendMode(Alpha);
			material.addPass(glowpass);

			material.mainPass.setPassName("glowPre");
			material.mainPass.addShader(trivialShader);
			dtsshader = material.mainPass.getShader(shaders.DtsTexture);
			if (dtsshader != null)
				material.mainPass.removeShader(dtsshader);
			material.mainPass.enableLights = false;
			material.mainPass.setBlendMode(Alpha);
		}
		if (matName == "sigiloff") {
			var diffuseTex = ResourceLoader.getTexture("data/shapes/pads/sigiloff.png").resource;
			diffuseTex.wrap = Repeat;
			diffuseTex.mipMap = Nearest;
			var shader = new shaders.DefaultDiffuseMaterial(diffuseTex);
			var dtsTex = material.mainPass.getShader(shaders.DtsTexture);
			dtsTex.passThrough = true;
			material.mainPass.removeShader(material.textureShader);
			material.mainPass.addShader(shader);
			var thisprops:Dynamic = material.getDefaultProps();
			thisprops.light = false; // We will calculate our own lighting
			material.props = thisprops;
			material.shadows = false;
			material.receiveShadows = true;
			material.blendMode = Alpha;
		}
		if (matName == "corona") {
			material.blendMode = Alpha;
			material.mainPass.enableLights = false;
		}
	}
}
