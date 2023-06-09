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
	}
}
