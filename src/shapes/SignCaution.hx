package shapes;

import mis.MissionElement.MissionElementStaticShape;
import src.DtsObject;

class SignCaution extends DtsObject {
	public function new(element:MissionElementStaticShape) {
		super();
		this.dtsPath = "data/shapes/signs/cautionsign.dts";
		this.isCollideable = true;
		this.useInstancing = true;

		var type = element.datablock.substring("SignCaution".length).toLowerCase();
		switch (type) {
			case "caution":
				this.matNameOverride.set("base.cautionsign", "caution.cautionsign");
			case "danger":
				this.matNameOverride.set("base.cautionsign", "danger.cautionsign");
		}
		this.identifier = "CautionSign" + type;
	}
}
