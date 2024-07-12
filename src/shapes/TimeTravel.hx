package shapes;

import src.ResourceLoader;
import mis.MissionElement.MissionElementItem;
import src.TimeState;
import mis.MisParser;
import src.MarbleWorld;

class TimeTravel extends PowerUp {
	var timeBonus:Float = 5;

	public function new(element:MissionElementItem) {
		super(element);
		this.dtsPath = "data/shapes/items/timetravel.dts";
		this.isCollideable = false;
		this.isTSStatic = false;
		this.identifier = "TimeTravel";

		if (element.timebonus != null) {
			this.timeBonus = MisParser.parseNumber(element.timebonus) / 1000;
		}
		if (element.timepenalty != null) {
			this.timeBonus = -MisParser.parseNumber(element.timepenalty) / 1000;
		}

		this.pickUpName = '${this.timeBonus} second Time ${this.timeBonus >= 0 ? 'Modifier' : 'Penalty'}';
		this.cooldownDuration = 1e8;
		this.useInstancing = true;
		this.autoUse = true;
	}

	public override function init(level:MarbleWorld, onFinish:Void->Void) {
		super.init(level, () -> {
			ResourceLoader.load("sound/putimetravelvoice.wav").entry.load(() -> {
				this.pickupSound = ResourceLoader.getResource("data/sound/putimetravelvoice.wav", ResourceLoader.getAudio, this.soundResources);
				ResourceLoader.load("sound/timetravelactive.wav").entry.load(onFinish);
			});
		});
	}

	public function pickUp(marble:src.Marble):Bool {
		return true;
	}

	public function use(marble:src.Marble, time:TimeState) {
		if (!this.level.rewinding)
			level.addBonusTime(this.timeBonus);
	}
}
