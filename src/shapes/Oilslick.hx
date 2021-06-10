package shapes;

import src.DtsObject;

class Oilslick extends DtsObject {
	public function new() {
		super();
		this.dtsPath = "data/shapes/hazards/oilslick.dts";
		this.identifier = "Oilslick";
		this.useInstancing = true;
		this.isCollideable = true;
		this.isTSStatic = false;
	}
}
