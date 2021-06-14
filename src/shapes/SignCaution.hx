package shapes;

import mis.MissionElement.MissionElementStaticShape;
import src.DtsObject;

class SignCaution extends DtsObject {
	public function new(element:MissionElementStaticShape) {
		super();
		this.dtsPath = "data/shapes/signs/cautionsign.dts";
		this.isCollideable = true;

		var type = element.datablock.substring("SignCaution".length);
		switch (type) {
			case "Caution":
				this.matNameOverride.set("base.cautionsign", "caution.cautionsign");
			case "Danger":
				this.matNameOverride.set("base.cautionsign", "danger.cautionsign");
		}
		this.identifier = "CautionSign" + type;
	}
}
