package shapes;

import mis.MissionElement.MissionElementStaticShape;
import src.DtsObject;

class PQProp extends DtsObject {
	public function new(element:MissionElementStaticShape, dtsPath:String) {
		super();
		this.dtsPath = dtsPath;
		this.isCollideable = true;
		this.useInstancing = true;

		var skinField = element.fields.get("skin");
		if (skinField != null && skinField[0] != "")
			this.skinOverride = skinField[0];

		this.identifier = dtsPath + (this.skinOverride != null ? this.skinOverride : "");
	}
}
