package shapes;

import h3d.shader.UVScroll;
import h3d.shader.UVAnim;
import src.DtsObject;
import src.ResourceLoader;

class StartPad extends DtsObject {
	public function new() {
		super();
		dtsPath = "data/shapes/pads/startarea.dts";
		isCollideable = true;
		identifier = "StartPad";
		useInstancing = false;
	}

	override function postProcessMaterial(matName:String, material:h3d.mat.Material) {
		if (matName == "ringglass") {
			var diffuseTex = ResourceLoader.getTexture("data/shapes/pads/ringglass.png").resource;
			diffuseTex.wrap = Repeat;
			diffuseTex.mipMap = Nearest;
			var normalTex = ResourceLoader.getTexture("data/shapes/pads/ringnormal.png").resource;
			normalTex.wrap = Repeat;
			normalTex.mipMap = Nearest;

			var cubemapTex = new h3d.mat.Texture(64, 64, [Cube]);
			var cubemapFace1 = ResourceLoader.getImage('data/skies/env_SO.png').resource;
			var cubemapFace2 = ResourceLoader.getImage('data/skies/env_NO.png').resource;
			var cubemapFace3 = ResourceLoader.getImage('data/skies/env_EA.png').resource;
			var cubemapFace4 = ResourceLoader.getImage('data/skies/env_WE.png').resource;
			var cubemapFace5 = ResourceLoader.getImage('data/skies/env_UP.png').resource;
			var cubemapFace6 = ResourceLoader.getImage('data/skies/env_DN.png').resource;
			cubemapTex.uploadPixels(cubemapFace1.getPixels(), 0, 0);
			cubemapTex.uploadPixels(cubemapFace2.getPixels(), 0, 1);
			cubemapTex.uploadPixels(cubemapFace3.getPixels(), 0, 2);
			cubemapTex.uploadPixels(cubemapFace4.getPixels(), 0, 3);
			cubemapTex.uploadPixels(cubemapFace5.getPixels(), 0, 4);
			cubemapTex.uploadPixels(cubemapFace6.getPixels(), 0, 5);

			var shader = new shaders.DefaultCubemapMaterial(diffuseTex, normalTex, 12, new h3d.Vector(0.8, 0.8, 0.8, 1), 1, cubemapTex);
			shader.doGammaRamp = false;
			var dtsshader = material.mainPass.getShader(shaders.DtsTexture);
			if (dtsshader != null)
				material.mainPass.removeShader(dtsshader);
			// var dtsTex = material.mainPass.getShader(shaders.DtsTexture);
			// dtsTex.passThrough = true;
			material.mainPass.removeShader(material.textureShader);
			material.mainPass.addShader(shader);
			var thisprops:Dynamic = material.getDefaultProps();
			thisprops.light = false; // We will calculate our own lighting
			material.props = thisprops;
			material.shadows = false;
			material.receiveShadows = true;
			material.blendMode = Alpha;
			material.mainPass.culling = None;
			// material.blendMode = Alpha;
		}

		if (matName == "ringtex") {
			var diffuseTex = ResourceLoader.getTexture("data/shapes/pads/ringtex.png").resource;
			diffuseTex.wrap = Repeat;
			diffuseTex.mipMap = Nearest;
			var shader = new shaders.DefaultNormalMaterial(diffuseTex, 14, new h3d.Vector(0.3, 0.3, 0.3, 7), 1);
			shader.doGammaRamp = false;
			var dtsshader = material.mainPass.getShader(shaders.DtsTexture);
			if (dtsshader != null)
				material.mainPass.removeShader(dtsshader);
			// var dtsTex = material.mainPass.getShader(shaders.DtsTexture);
			// dtsTex.passThrough = true;
			material.mainPass.removeShader(material.textureShader);
			material.mainPass.addShader(shader);
			var thisprops:Dynamic = material.getDefaultProps();
			thisprops.light = false; // We will calculate our own lighting
			material.props = thisprops;
			material.shadows = false;
			material.receiveShadows = true;
		}

		if (matName == "abyss") {
			var thisprops:Dynamic = material.getDefaultProps();
			thisprops.light = false; // We will calculate our own lighting
			material.props = thisprops;
			material.shadows = false;
			material.receiveShadows = true;
			var rotshader = new shaders.UVRotAnim(-0.5, -0.5, 1);
			material.mainPass.addShader(rotshader);
		}

		if (matName == "abyss2") {
			var glowpass = material.mainPass.clone();
			glowpass.setPassName("glow");
			glowpass.depthTest = LessEqual;
			glowpass.enableLights = false;
			material.addPass(glowpass);

			material.mainPass.setPassName("glowPre");
			material.mainPass.enableLights = false;

			var rotshader = new shaders.UVRotAnim(-0.5, -0.5, 1);
			material.mainPass.addShader(rotshader);

			var thisprops:Dynamic = material.getDefaultProps();
			thisprops.light = false; // We will calculate our own lighting
			material.props = thisprops;
			material.shadows = false;
		}

		if (matName == "misty") {
			var diffuseTex = ResourceLoader.getTexture("data/shapes/pads/misty.png").resource;
			diffuseTex.wrap = Repeat;
			diffuseTex.mipMap = Nearest;

			var trivialShader = new shaders.TrivialMaterial(diffuseTex);
			var scrollShader = new h3d.shader.UVScroll(0, 0.5);

			var glowpass = material.mainPass.clone();
			glowpass.addShader(trivialShader);
			glowpass.addShader(scrollShader);
			var dtsshader = glowpass.getShader(shaders.DtsTexture);
			if (dtsshader != null)
				glowpass.removeShader(dtsshader);
			glowpass.setPassName("glow");
			glowpass.depthTest = LessEqual;
			glowpass.depthWrite = false;
			glowpass.enableLights = false;
			glowpass.blendSrc = SrcAlpha;
			glowpass.blendDst = OneMinusSrcAlpha;
			material.addPass(glowpass);

			material.mainPass.setPassName("glowPreNoRender");
			material.mainPass.addShader(trivialShader);
			dtsshader = material.mainPass.getShader(shaders.DtsTexture);
			if (dtsshader != null)
				material.mainPass.removeShader(dtsshader);
			material.mainPass.enableLights = false;

			// var thisprops:Dynamic = material.getDefaultProps();
			// thisprops.light = false; // We will calculate our own lighting
			// material.props = thisprops;
			// material.shadows = false;
			// material.blendMode = Alpha;
			// material.mainPass.depthWrite = false;
			// material.mainPass.blendSrc = SrcAlpha;
			// material.mainPass.blendDst = OneMinusSrcAlpha;
		}
	}
}
