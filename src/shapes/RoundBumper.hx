package shapes;

import collision.CollisionInfo;
import src.DtsObject;
import src.TimeState;
import src.Util;

class RoundBumper extends AbstractBumper {
	public function new() {
		super();
		dtsPath = "data/shapes/bumpers/pball_round.dts";
		isCollideable = true;
		identifier = "RoundBumper";
	}
}
