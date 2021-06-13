package triggers;

import src.TimeState;

class OutOfBoundsTrigger extends Trigger {
	override function onMarbleInside(time:TimeState) {
		this.level.goOutOfBounds();
		// this.level.replay.recordMarbleInside(this);
	}
}
