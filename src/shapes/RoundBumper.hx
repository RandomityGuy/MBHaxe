package shapes;

import shaders.DtsTexture;
import collision.CollisionInfo;
import src.DtsObject;
import src.TimeState;
import src.Util;
import src.ResourceLoader;

class RoundBumper extends AbstractBumper {
	public function new() {
		super();
		dtsPath = "data/shapes/bumpers/pball_round.dts";
		isCollideable = true;
		identifier = "RoundBumper";
		animateSubObjectOpacities = true;
	}

	override function postProcessMaterial(matName:String, material:h3d.mat.Material) {
		if (matName == "bumper") {
			var diffuseTex = ResourceLoader.getTexture("data/shapes/bumpers/bumper.png").resource;
			diffuseTex.wrap = Repeat;
			diffuseTex.mipMap = Nearest;
			var shader = new shaders.DefaultNormalMaterial(diffuseTex, 12, new h3d.Vector(0.8, 0.8, 0.8, 1), 1);
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
		if (matName == "antigrav_glow") {
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
			if (dtsshader != null)
				material.mainPass.removeShader(dtsshader);
			material.mainPass.enableLights = false;

			var thisprops:Dynamic = material.getDefaultProps();
			thisprops.light = false; // We will calculate our own lighting
			material.props = thisprops;
			material.shadows = false;
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
	}
}
