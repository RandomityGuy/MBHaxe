package triggers;

import src.PathedInterior;
import mis.MissionElement.MissionElementTrigger;
import src.TimeState;
import mis.MisParser;
import src.Marble;

class RepetitiveTriggerGotoTarget extends Trigger {
	var interior:PathedInterior;
	var enterCounts:Map<Marble, Int> = [];
	var triggered:Bool = false;

	public function new(element:MissionElementTrigger, interior:PathedInterior) {
		super(element, interior.level);
		this.interior = interior;
	}

	public override function onMarbleEnter(marble:Marble, time:TimeState) {
		// PQ's own default for an unset NumTimesToTrigger is a literal " " string, which
		// TorqueScript coerces to 0 in numeric comparisons - reproduced here as 0, not the
		// misleading "default" shown in the mission editor's customField hint.
		var numTimesToTriggerField = this.element.fields.get("numtimestotrigger");
		var numTimesToTrigger = numTimesToTriggerField != null ? MisParser.parseNumber(numTimesToTriggerField[0]) : 0;
		var triggerOnceField = this.element.fields.get("triggeronce");
		var triggerOnce = triggerOnceField == null || MisParser.parseBoolean(triggerOnceField[0]);
		var numTimesToRepeatField = this.element.fields.get("numtimestorepeat");
		var numTimesToRepeat = numTimesToRepeatField != null ? Std.int(MisParser.parseNumber(numTimesToRepeatField[0])) : 0;

		var count = (this.enterCounts.exists(marble) ? this.enterCounts.get(marble) : 0) + 1;
		this.enterCounts.set(marble, count);

		if (count < numTimesToTrigger)
			return;
		if (triggerOnce && count > numTimesToTrigger)
			return;
		if (this.triggered && numTimesToRepeat != 0 && (count - numTimesToTrigger) % numTimesToRepeat != 0)
			return;

		var delayField = this.element.fields.get("delaytargettime");
		if (delayField != null && delayField[0] != "")
			this.interior.delayTargetTime = MisParser.parseNumber(delayField[0]) / 1000;

		var targetTimeField = this.element.fields.get("targettime");
		var targetTime = targetTimeField != null ? MisParser.parseNumber(targetTimeField[0]) : 999999;
		if (targetTime > 0)
			targetTime /= 1000;
		this.interior.setTargetTime(time, targetTime);
		this.triggered = true;
	}
}
