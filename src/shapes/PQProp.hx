package shapes;

import mis.MissionElement.MissionElementStaticShape;
import src.DtsObject;

/** Generic non-interactive PlatinumQuest decoration (fences, plants, signs, windows, holiday
	props, etc). Behavior is identical across all of these in PQ's own scripts: place the dts,
	optionally apply a skin. */
class PQProp extends DtsObject {
	public function new(element:MissionElementStaticShape, dtsPath:String) {
		super();
		this.dtsPath = dtsPath;
		this.isCollideable = true;
		this.useInstancing = true;

		var skinField = element.fields.get("skin");
		if (skinField != null && skinField[0] != "")
			this.skinOverride = skinField[0];
	}
}
