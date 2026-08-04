package triggers;

import src.TimeState;
import src.Marble;
import mis.MisParser;

class CountdownStartTrigger extends Trigger {
	public var activated:Bool = false;

	public var pendingStartTime:Float = -1;
	public var pendingTime:Float = 0;
	public var pendingIcon:String = "";

	override function onMarbleEnter(marble:Marble, timeState:TimeState) {
		var activateOnceField = this.element.fields.get("activateonce");
		var activateOnce = activateOnceField != null && MisParser.parseBoolean(activateOnceField[0]);
		if (activateOnce && this.activated)
			return;
		this.activated = true;

		var timeField = this.element.fields.get("time");
		var time = timeField != null ? MisParser.parseNumber(timeField[0]) / 1000 : 10;
		var startDelayField = this.element.fields.get("startdelay");
		var startDelay = startDelayField != null ? MisParser.parseNumber(startDelayField[0]) / 1000 : 0;
		var iconField = this.element.fields.get("icon");
		var icon = iconField != null && iconField[0] != "" ? iconField[0] : "timerTimeTravel";

		if (startDelay > 0) {
			this.pendingStartTime = timeState.currentAttemptTime + startDelay;
			this.pendingTime = time;
			this.pendingIcon = icon;
		} else {
			this.level.startCountdown(time, icon);
		}
	}

	override function update(timeState:TimeState) {
		super.update(timeState);
		if (this.pendingStartTime >= 0 && timeState.currentAttemptTime >= this.pendingStartTime) {
			this.level.startCountdown(this.pendingTime, this.pendingIcon);
			this.pendingStartTime = -1;
		}
	}

	override function reset() {
		super.reset();
		this.activated = false;
		this.pendingStartTime = -1;
	}
}
