package triggers;

import src.PathedInterior;
import mis.MissionElement.MissionElementTrigger;
import src.TimeState;

class TriggerGotoDelayTarget extends Trigger {
	var interior:PathedInterior;

	public function new(element:MissionElementTrigger, interior:PathedInterior) {
		super(element, interior.level);
		this.interior = interior;
	}

	public override function onMarbleEnter(marble:src.Marble, time:TimeState) {
		this.interior.setTargetTime(time, this.interior.delayTargetTime);
	}
}
