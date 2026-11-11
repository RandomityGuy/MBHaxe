package shapes;

import mis.MissionElement.MissionElementStaticShape;
import src.DtsObject;

class Glass extends DtsObject {
	public function new(element:MissionElementStaticShape) {
		super();

		var datablockLowercase = element.datablock.toLowerCase();
		switch (datablockLowercase) {
			case "glass_3shape":
				this.dtsPath = "data/shapes/glass/3x3.dts";
			case "glass_6shape":
				this.dtsPath = "data/shapes/glass/6x3.dts";
			case "glass_9shape":
				this.dtsPath = "data/shapes/glass/9x3.dts";
			case "glass_12shape":
				this.dtsPath = "data/shapes/glass/12x3.dts";
			case "glass_15shape":
				this.dtsPath = "data/shapes/glass/15x3.dts";
			case "glass_18shape":
				this.dtsPath = "data/shapes/glass/18x3.dts";
			case "glass_3shape_mbu":
				this.dtsPath = "data/shapes_mbu/structures/glass_3.dts";
			case "glass_6shape_mbu":
				this.dtsPath = "data/shapes_mbu/structures/glass_6.dts";
			case "glass_9shape_mbu":
				this.dtsPath = "data/shapes_mbu/structures/glass_9.dts";
			case "glass_12shape_mbu":
				this.dtsPath = "data/shapes_mbu/structures/glass_12.dts";
			case "glass_15shape_mbu":
				this.dtsPath = "data/shapes_mbu/structures/glass_15.dts";
			case "glass_18shape_mbu":
				this.dtsPath = "data/shapes_mbu/structures/glass_18.dts";
		}

		this.isCollideable = true;
		this.useInstancing = true;

		this.identifier = datablockLowercase;
	}
}
