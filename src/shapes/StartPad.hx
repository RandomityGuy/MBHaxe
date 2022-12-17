package shapes;

import src.DtsObject;

class StartPad extends DtsObject {
	public function new() {
		super();
		dtsPath = "data/shapes/pads/startarea.dts";
		useInstancing = false;
		isCollideable = true;
		identifier = "StartPad";
		useInstancing = false;
	}
}
