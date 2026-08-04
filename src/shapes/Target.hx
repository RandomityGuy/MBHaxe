package shapes;

import src.DtsObject;
import mis.MissionElement.MissionElementStaticShape;

class Target extends DtsObject {
	public function new(?element:MissionElementStaticShape) {
		super();
		this.dtsPath = "data/shapes_pq/gameplay/cannon/target.dts";
		this.isCollideable = true;

		var skinField = element != null ? element.fields.get("skin") : null;
		if (skinField != null && skinField[0] != "")
			this.skinOverride = skinField[0].toLowerCase();

		this.identifier = "Target" + (this.skinOverride != null ? this.skinOverride : "");
	}
}
