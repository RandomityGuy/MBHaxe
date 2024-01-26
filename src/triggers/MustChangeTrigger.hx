package triggers;

import src.PathedInterior;
import mis.MissionElement.MissionElementTrigger;
import src.TimeState;
import mis.MisParser;
import src.Marble;

class MustChangeTrigger extends Trigger {
	var interior:PathedInterior;

	public function new(element:MissionElementTrigger, interior:PathedInterior) {
		super(element, interior.level);
		this.interior = interior;
	}

	public override function onMarbleEnter(marble:Marble, time:TimeState) {
		var ttime = MisParser.parseNumber(this.element.targettime);
		if (ttime > 0)
			ttime /= 1000;
		this.interior.setTargetTime(time, ttime);
		if (this.element.instant == "1") {
			if (this.element.icontinuetottime != null && this.element.icontinuetottime != "0") {
				// Absolutely strange, and not sure if it's even a thing in MBG, but is implement nonetheless.
				this.interior.currentTime = this.interior.targetTime;
				this.interior.targetTime = MisParser.parseNumber(this.element.icontinuetottime) / 1000;
			}
		}
		// this.level.replay.recordMarbleEnter(this);
	}
}
