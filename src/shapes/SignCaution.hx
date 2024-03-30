package shapes;

import mis.MissionElement.MissionElementStaticShape;
import src.DtsObject;
import src.ResourceLoader;

class SignCaution extends DtsObject {
	public function new(element:MissionElementStaticShape) {
		super();
		this.dtsPath = "data/shapes/signs/cautionsign.dts";
		this.isCollideable = true;
		this.useInstancing = true;
		this.sharedNodeTransforms = true;

		var type = element.datablock.substring("SignCaution".length).toLowerCase();
		switch (type) {
			case "caution":
				this.matNameOverride.set("base.cautionsign", "caution.cautionsign");
			case "danger":
				this.matNameOverride.set("base.cautionsign", "danger.cautionsign");
		}
		this.identifier = "CautionSign" + type;
	}

	override function postProcessMaterial(matName:String, material:h3d.mat.Material) {
		if (matName == "base.cautionsign") {
			var diffuseTex = ResourceLoader.getTexture("data/shapes/signs/base.cautionsign.jpg").resource;
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
		}

		if (matName == "caution.cautionsign") {
			var diffuseTex = ResourceLoader.getTexture("data/shapes/signs/caution.cautionsign.jpg").resource;
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
		}

		if (matName == "danger.cautionsign") {
			var diffuseTex = ResourceLoader.getTexture("data/shapes/signs/danger.cautionsign.jpg").resource;
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
		}

		if (matName == "cautionsignwood") {
			var diffuseTex = ResourceLoader.getTexture("data/shapes/signs/cautionsignwood.jpg").resource;
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
		}

		if (matName == "cautionsign_pole") {
			var diffuseTex = ResourceLoader.getTexture("data/shapes/signs/cautionsign_pole.jpg").resource;
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
		}
	}
}
