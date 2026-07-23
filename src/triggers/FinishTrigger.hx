package triggers;

import src.TimeState;
import src.Marble;

class FinishTrigger extends Trigger {
	override function onMarbleEnter(marble:Marble, timeState:TimeState) {
		if (marble == this.level.marble)
			@:privateAccess this.level.touchFinish();
	}
}
