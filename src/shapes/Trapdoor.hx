package shapes;

import src.DtsObject;
import h3d.Vector;
import src.ForceObject;

class Trapdoor extends DtsObject {
	public function new() {
		super();
		this.dtsPath = "data/shapes/hazards/trapdoor.dts";
		this.isCollideable = true;
		this.isTSStatic = false;
		this.identifier = "Trapdoor";
	}
}
