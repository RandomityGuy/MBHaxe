package shapes;

import src.DtsObject;
import mis.MissionElement.MissionElementStaticShape;

class TriangleBumper extends AbstractBumper {
	public function new(?element:MissionElementStaticShape) {
		super();
		dtsPath = (element != null && element.datablock.toLowerCase() == "trianglebumper_pq") ? "data/shapes_pq/gameplay/hazards/bumpers/tribumper.dts" :
			"data/shapes/bumpers/pball_tri.dts";
		identifier = "TriangleBumper";
		isCollideable = true;
	}
}
