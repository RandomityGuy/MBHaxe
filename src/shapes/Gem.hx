package shapes;

import h3d.shader.pbr.PropsValues;
import src.MarbleWorld;
import mis.MissionElement.MissionElementItem;
import src.TimeState;
import src.DtsObject;
import src.ResourceLoaderWorker;
import src.ResourceLoader;
import src.Marble;

class Gem extends DtsObject {
	public var pickedUp:Bool;
	public var netIndex:Int;
	public var pickUpClient:Int = -1;
	public var radarGemColor:Int;
	public var radarGemIndex:Int;

	var gemColor:String;

	public function new(element:MissionElementItem) {
		super();
		dtsPath = "data/shapes/items/gem.dts";
		ambientRotate = true;
		isCollideable = false;
		this.isBoundingBoxCollideable = true;
		pickedUp = false;
		useInstancing = true;
		showSequences = false; // Gems actually have an animation for the little shiny thing, but the actual game ignores that. I get it, it was annoying as hell.

		var GEM_COLORS = ["blue", "red", "yellow", "purple", "green", "turquoise", "orange", "black"];
		var color = element.datablock.substring("GemItem".length);
		if (color.length == 0)
			color = GEM_COLORS[Math.floor(Math.random() * GEM_COLORS.length)];
		this.identifier = "Gem" + color;
		this.matNameOverride.set('base.gem', color + ".gem");
		gemColor = color + ".gem";
		var colLower = color.toLowerCase();
		switch (colLower) {
			case "red":
				radarGemColor = 0xFF0000;
				radarGemIndex = 0;
			case "blue":
				radarGemColor = 0x6666E6;
				radarGemIndex = 2;

			case "yellow":
				radarGemColor = 0xFEFF00;
				radarGemIndex = 1;

			case "green":
				radarGemColor = 0x66E666;
				radarGemIndex = 3;

			case "orange":
				radarGemColor = 0xE6BA66;
				radarGemIndex = 4;

			case "pink":
				radarGemColor = 0xE666E5;
				radarGemIndex = 5;

			case "purple":
				radarGemColor = 0xC566E6;
				radarGemIndex = 6;

			case "turquoise":
				radarGemColor = 0x66E5E6;
				radarGemIndex = 7;

			case "black":
				radarGemColor = 0x666666;
				radarGemIndex = 8;

			case "platinum":
				radarGemColor = 0xA5A5A5;
				radarGemIndex = 9;
		}
	}

	public override function init(level:MarbleWorld, onFinish:Void->Void) {
		super.init(level, () -> {
			var worker = new ResourceLoaderWorker(onFinish);
			worker.loadFile('sound/gotgem.wav');
			worker.loadFile('sound/gotallgems.wav');
			worker.run();
		});
	}

	public override function setHide(hide:Bool) {
		if (hide) {
			this.pickedUp = true;
			this.setOpacity(0);
		} else {
			this.pickedUp = false;
			this.setOpacity(1);
		}
	}

	override function onMarbleInside(marble:Marble, timeState:TimeState) {
		super.onMarbleInside(marble, timeState);
		if (this.pickedUp || this.level.rewinding)
			return;
		this.pickedUp = true;
		this.setOpacity(0); // Hide the gem
		this.level.pickUpGem(marble, this);
		// this.level.replay.recordMarbleInside(this);
	}

	override function reset() {
		this.pickedUp = false;
		this.pickUpClient = -1;
		this.setOpacity(1);
	}
}
