package shapes;

import src.DtsObject;

class Astrolabe extends DtsObject {
	public function new() {
		super();
		this.dtsPath = "data/shapes/astrolabe/astrolabe.dts";
		this.sequencePath = "data/shapes/astrolabe/astrolabe_root.dsq";
		this.isCollideable = false;
		this.isTSStatic = false;
		this.identifier = "Astrolabe";
		this.useInstancing = false;
	}

	public override function init(level:src.MarbleWorld, onFinish:() -> Void) {
		super.init(level, onFinish);
		for (mat in this.materials) {
			var thisprops:Dynamic = mat.getDefaultProps();
			thisprops.light = false; // We will calculate our own lighting
			mat.props = thisprops;
			mat.shadows = false;
			mat.receiveShadows = false;
			mat.blendMode = Alpha;
			mat.mainPass.depthWrite = false;
			mat.mainPass.culling = h3d.mat.Data.Face.None;
			mat.mainPass.setPassName("skyshape");
		}
	}
}
