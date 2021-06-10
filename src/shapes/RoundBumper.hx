package shapes;

import src.DtsObject;

class RoundBumper extends DtsObject {
	public function new() {
		super();
		dtsPath = "data/shapes/bumpers/pball_round.dts";
		isCollideable = true;
		identifier = "RoundBumper";
	}
}
