package shapes;

import src.ResourceLoader;
import mis.MissionElement.MissionElementItem;
import src.TimeState;
import src.DtsObject;
import src.AudioManager;
import src.MarbleWorld;
import src.Marble;

class Helicopter extends PowerUp {
	public function new(element:MissionElementItem) {
		super(element);
		var datablockLower = element.datablock.toLowerCase();
		this.dtsPath = switch (datablockLower) {
			case "helicopteritem": "data/shapes/images/helicopter.dts";
			case "helicopteritem_mbu": "data/shapes_mbu/images/helicopter.dts";
			case "helicopteritem_pq": "data/shapes_pq/gameplay/powerups/gyrocopter.dts";
			default: "data/shapes/images/helicopter.dts";
		};

		this.isCollideable = false;
		this.isTSStatic = false;
		this.showSequences = false;
		this.radarIndex = 24;
		this.identifier = "Helicopter" + this.dtsPath;
		this.pickUpName = "Gyrocopter PowerUp";
	}

	public override function init(level:MarbleWorld, onFinish:Void->Void) {
		super.init(level, () -> {
			ResourceLoader.load("sound/pugyrocoptervoice.wav").entry.load(() -> {
				this.pickupSound = ResourceLoader.getResource("data/sound/pugyrocoptervoice.wav", ResourceLoader.getAudio, this.soundResources);
				onFinish();
			});
		});
	}

	public function pickUp(marble:Marble):Bool {
		return this.level.pickUpPowerUp(marble, this);
	}

	public function use(marble:Marble, timeState:TimeState) {
		marble.enableHelicopter(timeState, StringTools.endsWith(dtsPath, "gyrocopter.dts"));
		this.level.deselectPowerUp(marble);
		return true;
	}
}
