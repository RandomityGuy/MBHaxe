package shapes;

import h3d.mat.Material;
import src.DtsObject;
import src.ResourceLoader;

class HelicopterImage extends DtsObject {
	public function new() {
		super();
		this.dtsPath = "data/shapes/images/helicopter_image.dts";
		this.isCollideable = false;
		this.isTSStatic = false;
		this.identifier = "HelicopterImage";
		this.useInstancing = true;
	}

	public override function init(level:src.MarbleWorld, onFinish:() -> Void) {
		super.init(level, onFinish);
	}

	override function postProcessMaterial(matName:String, material:Material) {
		if (matName == "copter_skin") {
			var diffuseTex = ResourceLoader.getTexture("data/shapes/images/copter_skin.png").resource;
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
	}
}
