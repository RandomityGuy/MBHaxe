package shapes;

import h3d.mat.Material;
import src.DtsObject;
import src.ResourceLoader;

class BlastWave extends DtsObject {
	public function new() {
		super();
		this.dtsPath = "data/shapes/images/distort.dts";
		this.isCollideable = false;
		this.isTSStatic = false;
		this.identifier = "BlastWave";
		this.useInstancing = true;
		this.animateSubObjectOpacities = true;
		this.doSequenceOnce = true;
	}

	public override function init(level:src.MarbleWorld, onFinish:() -> Void) {
		super.init(level, onFinish);
	}

	override function update(timeState:src.TimeState) {
		super.update(timeState);
	}

	override function postProcessMaterial(matName:String, material:Material) {
		if (matName == "refract") {
			var diffuseTex = ResourceLoader.getTexture("data/shapes/images/blast_glow.png").resource;
			diffuseTex.wrap = Repeat;
			diffuseTex.mipMap = Nearest;
			// aa
			var trivialShader = new shaders.TrivialMaterial(diffuseTex);
			material.mainPass.removeShader(material.textureShader);
			var glowpass = material.mainPass.clone();

			glowpass.addShader(trivialShader);
			var dtsshader = glowpass.getShader(shaders.DtsTexture);
			dtsshader.passThrough = true;
			glowpass.setPassName("glow");
			glowpass.depthTest = LessEqual;
			glowpass.depthWrite = false;
			glowpass.enableLights = false;
			glowpass.setBlendMode(Alpha);
			// glowpass.blendSrc = SrcAlpha;
			// glowpass.blendDst = OneMinusSrcAlpha;
			material.addPass(glowpass);

			material.mainPass.setPassName("glowPreNoRender");
			material.mainPass.removeShader(material.textureShader);
			material.mainPass.addShader(trivialShader);
			dtsshader = material.mainPass.getShader(shaders.DtsTexture);
			dtsshader.passThrough = true;
			material.mainPass.enableLights = false;

			// var thisprops:Dynamic = material.getDefaultProps();
			// thisprops.light = false; // We will calculate our own lighting
			// material.props = thisprops;
			material.shadows = false;
			// material.blendMode = Alpha;
			material.mainPass.depthWrite = false;
		}

		if (matName == "blastwave") {
			var diffuseTex = ResourceLoader.getTexture("data/shapes/images/blastwave.png").resource;
			diffuseTex.wrap = Repeat;
			diffuseTex.mipMap = Nearest;
			// aa
			var trivialShader = new shaders.TrivialMaterial(diffuseTex);
			material.mainPass.removeShader(material.textureShader);
			var glowpass = material.mainPass.clone();

			glowpass.addShader(trivialShader);
			var dtsshader = glowpass.getShader(shaders.DtsTexture);
			dtsshader.passThrough = true;
			glowpass.setPassName("glow");
			glowpass.depthTest = LessEqual;
			glowpass.depthWrite = false;
			glowpass.enableLights = false;
			glowpass.setBlendMode(Alpha);
			// glowpass.blendSrc = SrcAlpha;
			// glowpass.blendDst = OneMinusSrcAlpha;
			material.addPass(glowpass);

			material.mainPass.setPassName("glowPreNoRender");
			material.mainPass.removeShader(material.textureShader);
			material.mainPass.addShader(trivialShader);
			dtsshader = material.mainPass.getShader(shaders.DtsTexture);
			dtsshader.passThrough = true;
			material.mainPass.enableLights = false;

			// var thisprops:Dynamic = material.getDefaultProps();
			// thisprops.light = false; // We will calculate our own lighting
			// material.props = thisprops;
			material.shadows = false;
			// material.blendMode = Alpha;
			material.mainPass.depthWrite = false;
		}

		if (matName == "endpad_glow") {
			var diffuseTex = ResourceLoader.getTexture("data/shapes/pads/endpad_glow.png").resource;
			diffuseTex.wrap = Repeat;
			diffuseTex.mipMap = Nearest;
			// aa
			var trivialShader = new shaders.TrivialMaterial(diffuseTex);
			material.mainPass.removeShader(material.textureShader);
			var glowpass = material.mainPass.clone();

			glowpass.addShader(trivialShader);
			var dtsshader = glowpass.getShader(shaders.DtsTexture);
			dtsshader.passThrough = true;
			glowpass.setPassName("glow");
			glowpass.depthTest = LessEqual;
			glowpass.depthWrite = false;
			glowpass.enableLights = false;
			glowpass.setBlendMode(Alpha);
			// glowpass.blendSrc = SrcAlpha;
			// glowpass.blendDst = OneMinusSrcAlpha;
			material.addPass(glowpass);

			material.mainPass.setPassName("glowPreNoRender");
			material.mainPass.removeShader(material.textureShader);
			material.mainPass.addShader(trivialShader);
			dtsshader = material.mainPass.getShader(shaders.DtsTexture);
			dtsshader.passThrough = true;
			material.mainPass.enableLights = false;

			// var thisprops:Dynamic = material.getDefaultProps();
			// thisprops.light = false; // We will calculate our own lighting
			// material.props = thisprops;
			material.shadows = false;
			// material.blendMode = Alpha;
			material.mainPass.depthWrite = false;
		}

		if (matName == "corona") {
			var diffuseTex = ResourceLoader.getTexture("data/shapes/images/corona.png").resource;
			diffuseTex.wrap = Repeat;
			diffuseTex.mipMap = Nearest;
			// aa
			var trivialShader = new shaders.TrivialMaterial(diffuseTex);
			material.mainPass.removeShader(material.textureShader);
			var glowpass = material.mainPass.clone();

			glowpass.addShader(trivialShader);
			var dtsshader = glowpass.getShader(shaders.DtsTexture);
			dtsshader.passThrough = true;
			glowpass.setPassName("glow");
			glowpass.depthTest = LessEqual;
			glowpass.depthWrite = false;
			glowpass.enableLights = false;
			glowpass.setBlendMode(Alpha);
			// glowpass.blendSrc = SrcAlpha;
			// glowpass.blendDst = OneMinusSrcAlpha;
			material.addPass(glowpass);

			material.mainPass.setPassName("glowPreNoRender");
			material.mainPass.removeShader(material.textureShader);
			material.mainPass.addShader(trivialShader);
			dtsshader = material.mainPass.getShader(shaders.DtsTexture);
			dtsshader.passThrough = true;
			material.mainPass.enableLights = false;

			// var thisprops:Dynamic = material.getDefaultProps();
			// thisprops.light = false; // We will calculate our own lighting
			// material.props = thisprops;
			material.shadows = false;
			// material.blendMode = Alpha;
			material.mainPass.depthWrite = false;
		}
	}
}
