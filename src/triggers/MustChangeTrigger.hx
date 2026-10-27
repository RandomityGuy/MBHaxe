package triggers;

import src.PathedInterior;
import mis.MissionElement.MissionElementTrigger;
import src.TimeState;
import mis.MisParser;

class MustChangeTrigger extends Trigger {
	public var interiors:Array<PathedInterior> = [];

	public function new(element:MissionElementTrigger, levelOrInterior:Dynamic, ?interior:PathedInterior) {
		if (Std.isOfType(levelOrInterior, PathedInterior)) {
			var pi:PathedInterior = cast levelOrInterior;
			super(element, pi.level);
			this.interiors.push(pi);
		} else {
			super(element, cast levelOrInterior);
		}
		if (interior != null && !this.interiors.contains(interior)) {
			this.interiors.push(interior);
		}
	}

	public function addInterior(interior:PathedInterior) {
		if (interior != null && !this.interiors.contains(interior)) {
			this.interiors.push(interior);
		}
	}

	public override function onMarbleEnter(marble:src.Marble, time:TimeState) {
		var ttime = MisParser.parseNumber(this.element.targettime);
		if (ttime > 0)
			ttime /= 1000;
		for (interior in this.interiors) {
			interior.setTargetTime(time, ttime);
			if (this.element.instant == "1") {
				if (this.element.icontinuetottime != null && this.element.icontinuetottime != "0") {
					// Absolutely strange, and not sure if it's even a thing in MBG, but is implement nonetheless.
					interior.currentTime = interior.targetTime;
					interior.targetTime = MisParser.parseNumber(this.element.icontinuetottime) / 1000;
				}
			}
		}
		// this.level.replay.recordMarbleEnter(this);
	}
}
