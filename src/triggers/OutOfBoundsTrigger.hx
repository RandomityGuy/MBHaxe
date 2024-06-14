package triggers;

import src.TimeState;
import src.ResourceLoader;

class OutOfBoundsTrigger extends Trigger {
	override function onMarbleInside(marble:src.Marble, time:TimeState) {
		this.level.goOutOfBounds(marble);
		// this.level.replay.recordMarbleInside(this);
	}

	public override function init(onFinish:Void->Void) {
		ResourceLoader.load("sound/whoosh.wav").entry.load(onFinish);
	}
}
