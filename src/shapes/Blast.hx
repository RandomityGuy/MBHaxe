package shapes;

import src.MarbleWorld;
import src.ResourceLoader;
import src.TimeState;
import mis.MissionElement.MissionElementItem;

class Blast extends PowerUp {
	public function new(element:MissionElementItem) {
		super(element);
		this.dtsPath = "data/shapes/items/blast.dts";
		this.isCollideable = false;
		this.isTSStatic = false;
		this.showSequences = true;
		this.identifier = "Blast";
		this.pickUpName = "Blast PowerUp";
		this.autoUse = true;
	}

	public override function init(level:MarbleWorld, onFinish:Void->Void) {
		super.init(level, () -> {
			ResourceLoader.load("sound/publastvoice.wav").entry.load(() -> {
				this.pickupSound = ResourceLoader.getResource("data/sound/publastvoice.wav", ResourceLoader.getAudio, this.soundResources);
				onFinish();
			});
		});
	}

	public function pickUp():Bool {
		return true;
	}

	public function use(timeState:TimeState) {
		var marble = this.level.marble;
		this.level.deselectPowerUp();
	}
}
