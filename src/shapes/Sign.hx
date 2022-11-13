package shapes;

import hxd.Direction;
import mis.MissionElement.MissionElementStaticShape;
import src.DtsObject;

class Sign extends DtsObject {
	public function new(element:MissionElementStaticShape) {
		super();
		this.dtsPath = "data/shapes/signs/sign.dts";
		this.isCollideable = true;
		this.useInstancing = true;

		var d = "";
		if (element.datablock.toLowerCase() != 'arrow') {
			// Determine the direction to show
			var direction = element.datablock.substring("Sign".length).toLowerCase();
			switch (direction) {
				case "":
					this.dtsPath = "data/shapes/signs/sign.dts";
				case "down":
					this.dtsPath = "data/shapes/signs/signdown.dts";
				case "up":
					this.dtsPath = "data/shapes/signs/signup.dts";
				case "side":
					this.dtsPath = "data/shapes/signs/signside.dts";
				case "downside":
					this.dtsPath = "data/shapes/signs/signdown-side.dts";
				case "upside":
					this.dtsPath = "data/shapes/signs/signup-side.dts";
			}
			d = direction;
		}

		this.identifier = "Sign" + d;
	}
}
