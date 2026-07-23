package triggers;

import src.TimeState;
import src.Marble;

class NoMovementKeysTrigger extends Trigger {
	override function onMarbleEnter(marble:Marble, timeState:TimeState) {
		marble.movementTriggerCount++;
	}

	override function onMarbleLeave(marble:Marble, timeState:TimeState) {
		marble.movementTriggerCount--;
		if (marble.movementTriggerCount < 0)
			marble.movementTriggerCount = 0;
	}
}
