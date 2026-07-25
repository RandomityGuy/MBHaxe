package triggers;

import src.TimeState;
import src.Marble;
import mis.MisParser;

class CountdownStartTrigger extends Trigger {
	var activated:Bool = false;

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
			this.level.schedule(timeState.currentAttemptTime + startDelay, () -> {
				this.level.startCountdown(time, icon);
				return 0;
			});
		} else {
			this.level.startCountdown(time, icon);
		}
	}

	override function reset() {
		this.activated = false;
	}
}
