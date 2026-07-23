package shapes;

import src.DtsObject;
import mis.MissionElement.MissionElementStaticShape;

class TriangleBumper extends AbstractBumper {
	public function new(?element:MissionElementStaticShape) {
		super();
		dtsPath = (element != null && element.datablock.toLowerCase() == "trianglebumper_pq") ? "data/shapes_pq/gameplay/hazards/bumpers/tribumper.dts" :
			"data/shapes/bumpers/pball_tri.dts";
		// Instancing batches by `identifier`, and the PQ variant uses a different mesh - keep the
		// dtsPath in the identifier so it doesn't get batched with the vanilla mesh.
		identifier = "TriangleBumper" + dtsPath;
		isCollideable = true;
	}
}
