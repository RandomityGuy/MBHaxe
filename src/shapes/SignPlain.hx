package shapes;

import mis.MissionElement.MissionElementStaticShape;
import src.DtsObject;
import src.ResourceLoader;

class SignPlain extends DtsObject {
	public function new(element:MissionElementStaticShape) {
		super();

		this.isCollideable = true;
		this.useInstancing = true;

		// Determine the direction to show
		var direction = element.datablock.substring("Arrow".length).toLowerCase();
		switch (direction) {
			case "side":
				this.dtsPath = 'data/shapes/signs/arrowsign_side.dts';
			case "up":
				this.dtsPath = 'data/shapes/signs/arrowsign_up.dts';
			case "down":
				this.dtsPath = 'data/shapes/signs/arrowsign_down.dts';
		}

		this.identifier = "SignPlain" + direction;
	}

	override function getPreloadMaterials(dts:dts.DtsFile) {
		var mats = super.getPreloadMaterials(dts);
		mats.push("data/shapes/signs/arrowsign_post_bump.png");
		return mats;
	}

	override function postProcessMaterial(matName:String, material:h3d.mat.Material) {
		if (matName == "arrowsign_arrow") {
			var diffuseTex = ResourceLoader.getTexture('data/shapes/signs/arrowsign_arrow.png').resource;
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

		if (matName == "arrowsign_arrow_glow") {
			var diffuseTex = ResourceLoader.getTexture('data/shapes/signs/arrowsign_arrow.png').resource;
			diffuseTex.wrap = Repeat;
			diffuseTex.mipMap = Nearest;
			var shader = new shaders.DefaultNormalMaterial(diffuseTex, 32, new h3d.Vector(1, 1, 1, 1), 1);
			shader.doGammaRamp = false;
			var dtsTex = material.mainPass.getShader(shaders.DtsTexture);
			dtsTex.passThrough = true;
			material.mainPass.removeShader(material.textureShader);
			material.mainPass.addShader(shader);

			var glowpass = material.mainPass.clone();
			var dtsshader = glowpass.getShader(shaders.DtsTexture);
			if (dtsshader != null)
				glowpass.removeShader(dtsshader);
			glowpass.setPassName("glow");
			glowpass.depthTest = LessEqual;
			glowpass.enableLights = false;
			material.addPass(glowpass);

			material.mainPass.setPassName("glowPre");
			dtsshader = material.mainPass.getShader(shaders.DtsTexture);
			if (dtsshader != null)
				material.mainPass.removeShader(dtsshader);
			material.mainPass.enableLights = false;

			var thisprops:Dynamic = material.getDefaultProps();
			thisprops.light = false; // We will calculate our own lighting
			material.props = thisprops;
			material.shadows = false;
		}

		if (matName == "ArrowPostUVW") {
			var diffuseTex = ResourceLoader.getTexture('data/shapes/signs/arrowpostUVW.png').resource;
			diffuseTex.wrap = Repeat;
			diffuseTex.mipMap = Nearest;
			var shader = new shaders.DefaultNormalMaterial(diffuseTex, 32, new h3d.Vector(0.8, 0.8, 0.6, 1), 1);
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

		if (matName == "arrowsign_chain") {
			var diffuseTex = ResourceLoader.getTexture("data/shapes/signs/arrowsign_chain.png").resource;
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

			var thisprops:Dynamic = material.getDefaultProps();
			thisprops.light = false; // We will calculate our own lighting
			material.props = thisprops;
			material.shadows = false;
			material.blendMode = Alpha;
			material.mainPass.depthWrite = false;
			material.mainPass.blendSrc = SrcAlpha;
			material.mainPass.blendDst = OneMinusSrcAlpha;
		}

		if (matName == "arrowsign_post") {
			var diffuseTex = ResourceLoader.getTexture('data/shapes/signs/arrowsign_post.png').resource;
			diffuseTex.wrap = Repeat;
			diffuseTex.mipMap = Nearest;
			var normalTex = ResourceLoader.getTexture("data/shapes/signs/arrowsign_post_bump.png").resource;
			normalTex.wrap = Repeat;
			normalTex.mipMap = Nearest;
			var shader = new shaders.DefaultMaterial(diffuseTex, normalTex, 12, new h3d.Vector(0.8, 0.8, 0.6, 1), 1);
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
