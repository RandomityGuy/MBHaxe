package shapes;

import collision.CollisionInfo;
import src.DtsObject;
import src.TimeState;
import src.Util;
import mis.MissionElement.MissionElementStaticShape;

class RoundBumper extends AbstractBumper {
	public function new(?element:MissionElementStaticShape) {
		super();
		var datablockLower = element != null ? element.datablock.toLowerCase() : "";
		dtsPath = switch (datablockLower) {
			case "roundbumper_pq": "data/shapes_pq/gameplay/hazards/bumpers/roundbumper.dts";
			case "roundbumper_mbu": "data/shapes_mbu/bumpers/pball_round.dts";
			case "roundbumper_original": "data/shapes_mbu/bumpers/mbgbumperedit.dts";
			default: "data/shapes/bumpers/pball_round.dts";
		}
		isCollideable = true;
		// Instancing batches by `identifier`, and the PQ variant uses a different mesh - keep the
		// dtsPath in the identifier so it doesn't get batched with the vanilla mesh.
		identifier = "RoundBumper" + dtsPath;
	}
}
