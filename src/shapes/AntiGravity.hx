package shapes;

import src.DtsObject;

class AntiGravity extends PowerUp {
	public function new() {
		super();
		this.dtsPath = "data/shapes/items/antigravity.dts";
		this.isCollideable = false;
		this.isTSStatic = false;
		this.identifier = "AntiGravity";
	}
}
