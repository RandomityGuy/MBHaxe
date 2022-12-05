package shapes;

import src.DtsObject;

class Sky extends DtsObject {
	public function new(type:String) {
		super();

		this.dtsPath = 'data/shapes/skies/${type}/${type}.dts';

		this.isCollideable = false;
		this.useInstancing = true;

		this.identifier = type + "Sky";
	}
}
