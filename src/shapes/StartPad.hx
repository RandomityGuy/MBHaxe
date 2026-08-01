package shapes;

import src.DtsObject;
import mis.MissionElement.MissionElementStaticShape;

class StartPad extends DtsObject {
	public function new(?element:MissionElementStaticShape) {
		super();
		var datablockLower = element != null ? element.datablock.toLowerCase() : "";
		dtsPath = switch (datablockLower) {
			case "startpad_pq": "data/shapes_pq/gameplay/pads/startpad.dts";
			case "startpad_pq_construction": "data/shapes_pq/gameplay/pads/startpadconst.dts";
			case "startpad_mbu": "data/shapes_mbu/pads/mbu/startarea.dts";
			default: "data/shapes/pads/startarea.dts";
		}
		isCollideable = true;
		identifier = "StartPad";
		useInstancing = false;
	}
}
