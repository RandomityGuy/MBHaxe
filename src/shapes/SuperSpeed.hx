package shapes;

import src.DtsObject;

class SuperSpeed extends PowerUp {
	public function new() {
		super();
		this.dtsPath = "data/shapes/items/superspeed.dts";
		this.isCollideable = false;
		this.isTSStatic = false;
		this.identifier = "SuperSpeed";
		this.useInstancing = true;
	}
}
