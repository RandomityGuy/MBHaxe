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
		this.pickUpName = "Anti-Recoil PowerUp";
	}

	public override function init(level:MarbleWorld, onFinish:Void->Void) {
		super.init(level, () -> {
			ResourceLoader.load("sound/pushockabsorbervoice.wav").entry.load(() -> {
				this.pickupSound = ResourceLoader.getResource("data/sound/pushockabsorbervoice.wav", ResourceLoader.getAudio, this.soundResources);
				onFinish();
			});
		});
	}

	public function pickUp(marble:src.Marble):Bool {
		return this.level.pickUpPowerUp(marble, this);
	}

	public function use(marble:src.Marble, timeState:TimeState) {
		marble.enableShockAbsorber(timeState);
		this.level.deselectPowerUp(marble);
	}
}
