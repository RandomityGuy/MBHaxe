package shapes;

import h3d.scene.RenderContext;
import h3d.mat.Material;
import h3d.Vector;
import mis.MisParser;
import mis.MissionElement.MissionElementStaticShape;
import src.DtsObject;
import src.ResourceLoader;

class Glass extends DtsObject {
	public function new(element:MissionElementStaticShape) {
		super();

		var datablockLowercase = element.datablock.toLowerCase();
		switch (datablockLowercase) {
			case "glass_3shape":
				this.dtsPath = "data/shapes/structures/glass_3.dts";
			case "glass_6shape":
				this.dtsPath = "data/shapes/structures/glass_6.dts";
			case "glass_9shape":
				this.dtsPath = "data/shapes/structures/glass_9.dts";
			case "glass_12shape":
				this.dtsPath = "data/shapes/structures/glass_12.dts";
			case "glass_15shape":
				this.dtsPath = "data/shapes/structures/glass_15.dts";
			case "glass_18shape":
				this.dtsPath = "data/shapes/structures/glass_18.dts";
		}

		this.isCollideable = true;
		this.useInstancing = false;

		this.identifier = datablockLowercase;
	}
}
