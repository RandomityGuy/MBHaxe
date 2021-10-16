package shapes;

import src.ResourceLoader;
import mis.MissionElement.MissionElementItem;
import src.TimeState;
import mis.MisParser;

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

		this.pickUpName = '${this.timeBonus} second Time Travel bonus';
		this.cooldownDuration = 1e8;
		this.useInstancing = true;
		this.autoUse = true;
		this.pickupSound = ResourceLoader.getResource("data/sound/putimetravelvoice.wav", ResourceLoader.getAudio, this.soundResources);
	}

	public function pickUp():Bool {
		return true;
	}

	public function use(time:TimeState) {
		level.bonusTime += this.timeBonus;
	}
}
