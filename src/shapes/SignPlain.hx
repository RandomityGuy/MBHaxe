package shapes;

import mis.MissionElement.MissionElementStaticShape;
import src.DtsObject;

class SignPlain extends DtsObject {
	public function new(element:MissionElementStaticShape) {
		super();

		this.dtsPath = "data/shapes/signs/plainsign.dts";
		this.isCollideable = true;
		this.useInstancing = true;

		// Determine the direction to show
		var direction = element.datablock.substring("SignPlain".length).toLowerCase();
		switch (direction) {
			case "right":
				this.matNameOverride.set("base.plainsign", "right.plainsign");
			case "left":
				this.matNameOverride.set("base.plainsign", "left.plainsign");
			case "up":
				this.matNameOverride.set("base.plainsign", "up.plainsign");
			case "down":
				this.matNameOverride.set("base.plainsign", "down.plainsign");
		}

		this.identifier = "SignPlain" + direction;
	}
}
