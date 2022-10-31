package triggers;

import src.TimeState;
import src.ResourceLoader;

class InBoundsTrigger extends Trigger {
	override function onMarbleLeave(timeState:TimeState) {
		this.level.goOutOfBounds();
		// this.level.replay.recordMarbleLeave(this);
	}

	public override function init(onFinish:Void->Void) {
		ResourceLoader.loader.load("sound/whoosh.wav").entry.load(onFinish);
	}
}
