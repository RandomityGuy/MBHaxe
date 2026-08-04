package triggers;

import src.TimeState;
import src.Marble;
import src.MarbleWorld;
import mis.MisParser;
import mis.MissionElement.MissionElementTrigger;

class WaterPhysicsTrigger extends Trigger {
	public var velocityMultiplier:Float;

	public function new(element:MissionElementTrigger, level:MarbleWorld) {
		super(element, level);
		var field = element.fields.get("velocitymultiplier");
		this.velocityMultiplier = field != null && field[0] != "" ? MisParser.parseNumber(field[0]) : 0.5;
	}

	override function onMarbleEnter(marble:Marble, timeState:TimeState) {
		if (marble.waterTriggers.indexOf(this) < 0)
			marble.waterTriggers.push(this);
	}

	override function onMarbleLeave(marble:Marble, timeState:TimeState) {
		marble.waterTriggers.remove(this);
	}
}
