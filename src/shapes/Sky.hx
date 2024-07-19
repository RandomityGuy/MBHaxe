package shapes;

import src.DtsObject;

class Sky extends DtsObject {
	public function new(type:String) {
		super();

		this.dtsPath = 'data/shapes/skies/${type}/${type}.dts';

		this.isCollideable = false;
		this.useInstancing = false;

		this.identifier = type + "Sky";
	}

	override function computeMaterials() {
		super.computeMaterials();
		for (mat in materials) {
			mat.mainPass.setPassName("skyshape");
		}
	}
}
