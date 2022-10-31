package shapes;

import src.ResourceLoader;
import mis.MissionElement.MissionElementItem;
import src.TimeState;
import src.DtsObject;
import src.MarbleWorld;

class ShockAbsorber extends PowerUp {
	public function new(element:MissionElementItem) {
		super(element);
		this.dtsPath = "data/shapes/items/shockabsorber.dts";
		this.isCollideable = false;
		this.isTSStatic = false;
		this.identifier = "ShockAbsorber";
		this.pickUpName = "Shock Absorber PowerUp";
	}

	public override function init(level:MarbleWorld, onFinish:Void->Void) {
		super.init(level, () -> {
			ResourceLoader.load("sound/pushockabsorbervoice.wav").entry.load(() -> {
				this.pickupSound = ResourceLoader.getResource("data/sound/pushockabsorbervoice.wav", ResourceLoader.getAudio, this.soundResources);
				onFinish();
			});
		});
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
