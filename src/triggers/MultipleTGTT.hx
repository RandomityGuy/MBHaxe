package triggers;

import src.TimeState;
import src.Marble;
import src.MarbleWorld;
import src.PathedInterior;
import mis.MisParser;
import mis.MissionElement.MissionElementTrigger;

class MultipleTGTT extends Trigger {
	static final TARGET_NAMES = ["plat1", "plat2", "plat3", "plat4", "plat5", "plat6", "plat7", "plat8", "plat9"];

	var targetTime:Float;

	public function new(element:MissionElementTrigger, level:MarbleWorld) {
		super(element, level);
		var field = element.fields.get("targettime");
		this.targetTime = field != null && field[0] != "" ? MisParser.parseNumber(field[0]) / 1000 : 0;
	}

	override function onMarbleEnter(marble:Marble, timeState:TimeState) {
		if (this.targetTime < 0)
			return;
		for (name in TARGET_NAMES) {
			var target = this.level.namedGameObjects.get(name);
			if (target != null && (target is PathedInterior))
				(cast target : PathedInterior).setTargetTime(timeState, this.targetTime);
		}
	}
}
