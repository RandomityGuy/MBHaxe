package triggers;

import src.PathedInterior;
import mis.MissionElement.MissionElementTrigger;
import src.TimeState;
import mis.MisParser;

class MustChangeTrigger extends Trigger {
	var interior:PathedInterior;

	public function new(element:MissionElementTrigger, interior:PathedInterior) {
		super(element, interior.level);
		this.interior = interior;
	}

	public override function onMarbleEnter(time:TimeState) {
		this.interior.setTargetTime(time, MisParser.parseNumber(this.element.targettime));
		if (this.element.instant == "1") {
			if (this.element.icontinuetottime != null && this.element.icontinuetottime != "0") {
				// Absolutely strange, and not sure if it's even a thing in MBG, but is implement nonetheless.
				this.interior.currentTime = this.interior.targetTime;
				this.interior.targetTime = MisParser.parseNumber(this.element.icontinuetottime);
			} else {
				this.interior.changeTime = Math.NEGATIVE_INFINITY; // "If instant is 1, the MP will warp to targetTime instantly."
			}
		}
		// this.level.replay.recordMarbleEnter(this);
	}
}
