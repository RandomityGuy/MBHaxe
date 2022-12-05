package shapes;

import src.MarbleWorld;
import src.ResourceLoader;
import src.TimeState;
import mis.MissionElement.MissionElementItem;

class MegaMarble extends PowerUp {
	public function new(element:MissionElementItem) {
		super(element);
		this.dtsPath = "data/shapes/items/megamarble.dts";
		this.isCollideable = false;
		this.isTSStatic = false;
		this.showSequences = true;
		this.identifier = "MegaMarble";
		this.pickUpName = "Mega Marble PowerUp";
	}

	public override function init(level:MarbleWorld, onFinish:Void->Void) {
		super.init(level, () -> {
			ResourceLoader.load("sound/pumegamarblevoice.wav").entry.load(() -> {
				this.pickupSound = ResourceLoader.getResource("data/sound/pumegamarblevoice.wav", ResourceLoader.getAudio, this.soundResources);
				onFinish();
			});
		});
	}

	public function pickUp():Bool {
		return this.level.pickUpPowerUp(this);
	}

	public function use(timeState:TimeState) {
		this.level.deselectPowerUp();
	}
}
