package triggers;

import src.TimeState;
import src.Marble;

class TimeStopTrigger extends Trigger {
	override function onMarbleEnter(marble:Marble, timeState:TimeState) {
		this.level.timeStopTriggerCount++;
	}

	override function onMarbleLeave(marble:Marble, timeState:TimeState) {
		this.level.timeStopTriggerCount--;
		if (this.level.timeStopTriggerCount < 0)
			this.level.timeStopTriggerCount = 0;
	}
}
