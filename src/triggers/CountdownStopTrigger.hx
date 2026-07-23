package triggers;

import src.TimeState;
import src.Marble;

class CountdownStopTrigger extends Trigger {
	override function onMarbleEnter(marble:Marble, timeState:TimeState) {
		this.level.stopCountdown();
	}
}
