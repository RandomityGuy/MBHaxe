package shapes;

import h3d.scene.RenderContext;
import h3d.mat.Material;
import h3d.Vector;
import mis.MisParser;
import mis.MissionElement.MissionElementStaticShape;
import src.DtsObject;
import src.ResourceLoader;

class Glass extends DtsObject {
	var shader:shaders.RefractMaterial;

	public function new(element:MissionElementStaticShape) {
		super();

		var datablockLowercase = element.datablock.toLowerCase();
		switch (datablockLowercase) {
			case "glass_3shape":
				this.dtsPath = "data/shapes/structures/glass_3.dts";
			case "glass_6shape":
				this.dtsPath = "data/shapes/structures/glass_6.dts";
			case "glass_9shape":
				this.dtsPath = "data/shapes/structures/glass_9.dts";
			case "glass_12shape":
				this.dtsPath = "data/shapes/structures/glass_12.dts";
			case "glass_15shape":
				this.dtsPath = "data/shapes/structures/glass_15.dts";
			case "glass_18shape":
				this.dtsPath = "data/shapes/structures/glass_18.dts";
		}

		this.isCollideable = true;
		this.useInstancing = true;

		this.identifier = datablockLowercase;
	}

	override function getPreloadMaterials(dts:dts.DtsFile) {
		var mats = super.getPreloadMaterials(dts);
		mats.push("data/shapes/structures/glass.png");
		mats.push("data/shapes/structures/glass2.png");
		mats.push("data/shapes/structures/glass.normal.png");
		return mats;
	}

	override function postProcessMaterial(matName:String, material:Material) {
		var refractTex = ResourceLoader.getTexture('data/shapes/structures/glass.png').resource;
		refractTex.wrap = Repeat;
		refractTex.mipMap = Nearest;
		var diffuseTex = ResourceLoader.getTexture('data/shapes/structures/glass2.png').resource;
		diffuseTex.wrap = Repeat;
		diffuseTex.mipMap = Nearest;
		var normalTex = ResourceLoader.getTexture("data/shapes/structures/glass.normal.png").resource;
		normalTex.wrap = Repeat;
		normalTex.mipMap = Nearest;

		var trivialShader = new shaders.TrivialMaterial(diffuseTex);

		shader = new shaders.RefractMaterial(refractTex, normalTex, 12, new h3d.Vector(1, 1, 1, 1), 1);
		shader.refractMap = src.Renderer.getSfxBuffer();

		// var phonshader = new shaders.PhongMaterial(diffuseTex, normalTex2, 12, new h3d.Vector(1, 1, 1, 1), src.MarbleGame.instance.world.ambient,
		// 	src.MarbleGame.instance.world.dirLight, src.MarbleGame.instance.world.dirLightDir, 1);

		var refractPass = material.mainPass.clone();

		material.texture = diffuseTex;
		var dtsshader = material.mainPass.getShader(shaders.DtsTexture);
		if (dtsshader != null)
			material.mainPass.removeShader(dtsshader);
		material.mainPass.removeShader(material.textureShader);
		material.mainPass.addShader(trivialShader);
		material.mainPass.setBlendMode(Alpha);
		material.mainPass.enableLights = false;
		material.mainPass.depthWrite = false;
		material.shadows = false;
		material.mainPass.setPassName("glowPre");

		refractPass.setPassName("refract");
		refractPass.addShader(shader);
		dtsshader = refractPass.getShader(shaders.DtsTexture);
		if (dtsshader != null)
			material.mainPass.removeShader(dtsshader);
		refractPass.removeShader(material.textureShader);
		refractPass.enableLights = false;

		// refractPass.blendSrc = One;
		// refractPass.blendDst = One;
		// refractPass.blendAlphaSrc = One;
		// refractPass.blendAlphaDst = One;
		// refractPass.blendOp = Add;
		// refractPass.blendAlphaOp = Add;
		refractPass.blend(One, Zero); // disable blend
		refractPass.depthWrite = true;
		refractPass.depthTest = LessEqual;
		material.addPass(refractPass);
	}
}
