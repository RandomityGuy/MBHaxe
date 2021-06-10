package shapes;

import src.DtsObject;

class EndPad extends DtsObject {
	public function new() {
		super();
		this.dtsPath = "data/shapes/pads/endarea.dts";
		this.useInstancing = false;
		this.isCollideable = true;
		this.identifier = "EndPad";
	}
}
