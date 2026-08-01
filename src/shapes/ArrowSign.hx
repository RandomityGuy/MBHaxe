package shapes;

import mis.MissionElement.MissionElementStaticShape;
import src.DtsObject;

/** Ported from `signs.cs`'s `ArrowUp`/`ArrowSide`/`ArrowDown` datablocks (`platinum/server/scripts/`)
	- purely decorative directional signage from MBU, one static mesh per direction (no shared base
	mesh + material-swap like `SignCaution`/`SignPlain`, since each direction is modeled separately).
	Real source's `onAdd` explicitly calls `playThread(0, "ambient")` for the little sway animation,
	but that's already what `showSequences` (true by default on `DtsObject`) gives for free via the
	generic DTS sequence system - no extra code needed here. */
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
