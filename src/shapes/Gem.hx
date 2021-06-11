package shapes;

import src.TimeState;
import src.DtsObject;

class Gem extends DtsObject {
	public var pickedUp:Bool;

	public function new() {
		super();
		dtsPath = "data/shapes/items/gem.dts";
		ambientRotate = true;
		isCollideable = false;
		pickedUp = false;
		showSequences = false; // Gems actually have an animation for the little shiny thing, but the actual game ignores that. I get it, it was annoying as hell.

		var GEM_COLORS = ["blue", "red", "yellow", "purple", "green", "turquoise", "orange", "black"];
		var color = GEM_COLORS[Math.floor(Math.random() * GEM_COLORS.length)];
		this.identifier = "Gem" + color;
		this.matNameOverride.set('base.gem', color + ".gem");
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

	override function onMarbleInside(timeState:TimeState) {
		super.onMarbleInside(timeState);
		if (this.pickedUp)
			return;
		this.pickedUp = true;
		this.setOpacity(0); // Hide the gem
		// this.level.pickUpGem(this);
		// this.level.replay.recordMarbleInside(this);
	}

	override function reset() {
		this.pickedUp = false;
		this.setOpacity(1);
	}
}
