package shapes;

import src.ResourceLoader;
import mis.MissionElement.MissionElementItem;
import src.TimeState;
import src.MarbleWorld;

class AnvilItem extends PowerUp {
	public function new(element:MissionElementItem) {
		super(element);
		this.dtsPath = "data/shapes_pq/gameplay/powerups/anvil.dts";
		this.isCollideable = false;
		this.isTSStatic = false;
		this.identifier = "AnvilItem";
		this.pickUpName = "Anvil PowerUp";
	}

	public override function init(level:MarbleWorld, onFinish:Void->Void) {
		super.init(level, () -> {
			ResourceLoader.load("sound/puanvilvoice.wav").entry.load(() -> {
				this.pickupSound = ResourceLoader.getResource("data/sound/puanvilvoice.wav", ResourceLoader.getAudio, this.soundResources);
				onFinish();
			});
		});
	}

	public function pickUp(marble:src.Marble):Bool {
		return this.level.pickUpPowerUp(marble, this);
	}

	public function use(marble:src.Marble, timeState:TimeState) {
		marble.applyImpulse(marble.currentUp.multiply(-20));
		this.level.deselectPowerUp(marble);
		return true;
	}
}
