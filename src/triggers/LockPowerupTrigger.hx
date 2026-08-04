package triggers;

import src.TimeState;
import src.Marble;

class LockPowerupTrigger extends Trigger {
	override function onMarbleEnter(marble:Marble, timeState:TimeState) {
		marble.lockPowerupUse();
	}

	override function onMarbleLeave(marble:Marble, timeState:TimeState) {
		marble.unlockPowerupUse();
	}
}
