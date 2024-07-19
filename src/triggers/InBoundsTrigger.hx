package triggers;

import src.TimeState;
import src.ResourceLoader;

class InBoundsTrigger extends Trigger {
	override function onMarbleLeave(marble:src.Marble, timeState:TimeState) {
		this.level.goOutOfBounds(marble);
		// this.level.replay.recordMarbleLeave(this);
	}

	public override function init(onFinish:Void->Void) {
		ResourceLoader.load("sound/whoosh.wav").entry.load(onFinish);
	}
}
