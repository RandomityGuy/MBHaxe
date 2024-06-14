package shapes;

import src.Marble;
import src.Settings;
import mis.MissionElement.MissionElementItem;
import src.ResourceLoader;

class EasterEgg extends PowerUp {
	public function new(element:MissionElementItem) {
		super(element);
		this.dtsPath = "data/shapes/items/easteregg.dts";
		this.isCollideable = false;
		this.isTSStatic = false;
		this.identifier = "EasterEgg";
		this.pickUpName = "Easter Egg";
		this.autoUse = true;
		this.cooldownDuration = 1e8;
	}

	public function pickUp(marble:Marble):Bool {
		var found:Bool = false;
		if (Settings.easterEggs.exists(this.level.mission.path)) {
			found = true;
		}
		if (!found) {
			Settings.easterEggs.set(this.level.mission.path, this.level.timeState.currentAttemptTime);
			this.pickupSound = ResourceLoader.getResource("data/sound/easter.wav", ResourceLoader.getAudio, this.soundResources);
			this.customPickupMessage = "You found an Easter Egg!";
		} else {
			this.pickupSound = ResourceLoader.getResource("data/sound/easterfound.wav", ResourceLoader.getAudio, this.soundResources);
			this.customPickupMessage = "You already found this Easter Egg.";
		}

		return true;
	}

	public override function init(level:src.MarbleWorld, onFinish:() -> Void) {
		super.init(level, () -> {
			ResourceLoader.load("sound/easter.wav").entry.load(() -> {
				ResourceLoader.load("sound/easterfound.wav").entry.load(onFinish);
			});
		});
	}

	public function use(marble:Marble, timeState:src.TimeState) {}
}
