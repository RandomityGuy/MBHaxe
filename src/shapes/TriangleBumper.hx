package shapes;

import src.DtsObject;

class TriangleBumper extends AbstractBumper {
	public function new() {
		super();
		dtsPath = "data/shapes/bumpers/pball_tri.dts";
		identifier = "TriangleBumper";
		isCollideable = true;
	}
}
