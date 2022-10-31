package triggers;

import src.TimeState;
import src.ResourceLoader;

class OutOfBoundsTrigger extends Trigger {
	override function onMarbleInside(time:TimeState) {
		this.level.goOutOfBounds();
		// this.level.replay.recordMarbleInside(this);
	}

	public override function init(onFinish:Void->Void) {
		ResourceLoader.loader.load("sound/whoosh.wav").entry.load(onFinish);
	}
}
