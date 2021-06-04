package shapes;

import src.DtsObject;

class SignFinish extends DtsObject {
	public function new() {
		super();
		this.dtsPath = "data/shapes/signs/finishlinesign.dts";
		this.isCollideable = true;
		this.identifier = "SignFinish";
		this.useInstancing = false;
	}
}
