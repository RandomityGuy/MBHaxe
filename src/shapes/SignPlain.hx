package shapes;

import mis.MissionElement.MissionElementStaticShape;
import src.DtsObject;

class SignPlain extends DtsObject {
	public function new(element:MissionElementStaticShape) {
		super();

		this.dtsPath = "data/shapes/signs/plainsign.dts";
		this.isCollideable = true;

		// Determine the direction to show
		var direction = element.datablock.substring("SignPlain".length);
		switch (direction) {
			case "Right":
				this.matNameOverride.set("base.plainsign", "right.plainsign");
			case "Left":
				this.matNameOverride.set("base.plainsign", "left.plainsign");
			case "Up":
				this.matNameOverride.set("base.plainsign", "up.plainsign");
			case "Down":
				this.matNameOverride.set("base.plainsign", "down.plainsign");
		}

		this.identifier = "SignPlain" + direction;
	}
}
