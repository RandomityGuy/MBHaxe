package shapes;

import src.DtsObject;

class Sky extends DtsObject {
	public function new(type:String) {
		super();

		if (type == "astrolabecloudsbeginnershape")
			this.dtsPath = 'data/shapes/astrolabe/astrolabe_clouds_beginner.dts';
		if (type == "astrolabecloudsintermediateshape")
			this.dtsPath = 'data/shapes/astrolabe/astrolabe_clouds_intermediate.dts';
		if (type == "astrolabecloudsadvancedshape")
			this.dtsPath = 'data/shapes/astrolabe/astrolabe_clouds_advanced.dts';

		this.isCollideable = false;
		this.useInstancing = false;

		this.identifier = type + "Sky";
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
			mat.mainPass.culling = h3d.mat.Data.Face.None;
			mat.mainPass.setPassName("skyshape");
		}
	}
}
