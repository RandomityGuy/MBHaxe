package triggers;

import src.TimeState;

class InBoundsTrigger extends Trigger {
	override function onMarbleLeave(timeState:TimeState) {
		this.level.goOutOfBounds();
		// this.level.replay.recordMarbleLeave(this);
	}
}
