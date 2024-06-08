package triggers;

import mis.MissionElement.MissionElementTrigger;
import src.TimeState;
import src.ResourceLoader;
import src.Marble;
import src.MarbleWorld;

class InBoundsTrigger extends Trigger {
	public function new(element:MissionElementTrigger, level:MarbleWorld) {
		super(element, level);
		this.accountForGravity = true;
	}

	override function onMarbleLeave(marble:Marble, timeState:TimeState) {
		this.level.goOutOfBounds(marble);
		// this.level.replay.recordMarbleLeave(this);
	}

	public override function init(onFinish:Void->Void) {
		ResourceLoader.load("sound/whoosh.wav").entry.load(onFinish);
	}
}
