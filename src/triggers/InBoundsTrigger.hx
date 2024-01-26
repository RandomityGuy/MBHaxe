package triggers;

import src.TimeState;
import src.ResourceLoader;
import src.Marble;

class InBoundsTrigger extends Trigger {
	override function onMarbleLeave(marble:Marble, timeState:TimeState) {
		this.level.goOutOfBounds();
		// this.level.replay.recordMarbleLeave(this);
	}

	public override function init(onFinish:Void->Void) {
		ResourceLoader.load("sound/whoosh.wav").entry.load(onFinish);
	}
}
