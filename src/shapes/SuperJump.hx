package shapes;

import src.DtsObject;

class SuperJump extends DtsObject {
	public function new() {
		super();
		this.dtsPath = "data/shapes/items/superjump.dts";
		this.isCollideable = false;
		this.isTSStatic = false;
		this.identifier = "SuperJump";
	}
}
