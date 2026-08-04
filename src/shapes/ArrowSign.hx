package shapes;

import mis.MissionElement.MissionElementStaticShape;
import src.DtsObject;

class ArrowSign extends DtsObject {
	public function new(element:MissionElementStaticShape) {
		super();
		var datablockLower = element.datablock.toLowerCase();
		this.dtsPath = switch (datablockLower) {
			case "arrowup": "data/shapes_mbu/signs/arrowsign_up.dts";
			case "arrowside": "data/shapes_mbu/signs/arrowsign_side.dts";
			case "arrowdown": "data/shapes_mbu/signs/arrowsign_down.dts";
			default: "data/shapes_mbu/signs/arrowsign_up.dts";
		}
		this.isCollideable = true;
		this.useInstancing = true;
		this.identifier = "ArrowSign" + datablockLower;
	}
}
