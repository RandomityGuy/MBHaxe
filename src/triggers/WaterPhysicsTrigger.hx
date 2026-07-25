package triggers;

import src.TimeState;
import src.Marble;
import src.MarbleWorld;
import mis.MisParser;
import mis.MissionElement.MissionElementTrigger;

/** Ported from PQ's `WaterPhysicsTrigger` (`server/scripts/water.cs` + `client/scripts/water.cs`).
	Registration only - all the "am I in water, did I just enter/leave, how deep am I" logic is
	centralized on `Marble` (`updateWater`, called once per tick), matching PQ's own split between
	this trigger's on-enter/leave callbacks (which just add/remove from a set,
	`WaterPhysicsTrigger_onClientEnterTrigger`/`onClientLeaveTrigger`) and the separate
	`updateClientWater()` function that does the actual work every frame. */
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
