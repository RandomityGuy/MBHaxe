package shapes;

import src.ResourceLoader;
import mis.MissionElement.MissionElementItem;
import src.TimeState;
import src.DtsObject;

class ShockAbsorber extends PowerUp {
	public function new(element:MissionElementItem) {
		super(element);
		this.dtsPath = "data/shapes/items/shockabsorber.dts";
		this.isCollideable = false;
		this.isTSStatic = false;
		this.identifier = "ShockAbsorber";
		this.pickUpName = "Shock Absorber PowerUp";
		this.pickupSound = ResourceLoader.getAudio("data/sound/pushockabsorbervoice.wav");
	}

	public function pickUp():Bool {
		return this.level.pickUpPowerUp(this);
	}

	public function use(timeState:TimeState) {
		var marble = this.level.marble;
		marble.enableShockAbsorber(timeState.currentAttemptTime);
		this.level.deselectPowerUp();
	}
}
