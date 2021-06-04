package shapes;

import src.DtsObject;

class AntiGravity extends DtsObject {
	public function new() {
		super();
		this.dtsPath = "data/shapes/items/antigravity.dts";
		this.isCollideable = false;
		this.isTSStatic = false;
		this.identifier = "AntiGravity";
	}
}
