package shapes;

import collision.CollisionInfo;
import src.DtsObject;
import src.TimeState;
import src.Util;
import mis.MissionElement.MissionElementStaticShape;

class RoundBumper extends AbstractBumper {
	public function new(?element:MissionElementStaticShape) {
		super();
		dtsPath = (element != null && element.datablock.toLowerCase() == "roundbumper_pq") ? "data/shapes_pq/gameplay/hazards/bumpers/roundbumper.dts" :
			"data/shapes/bumpers/pball_round.dts";
		isCollideable = true;
		identifier = "RoundBumper";
	}
}
