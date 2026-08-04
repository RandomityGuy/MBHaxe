package triggers;

import src.TimeState;
import src.Marble;
import src.MarbleWorld;
import mis.MisParser;
import mis.MissionElement.MissionElementTrigger;
import modes.GameMode.GameModeFactory;
import modes.special.WhiteNoiseMode;

class SMBTrigger extends Trigger {
	var impulse:Float;
	var upwards:Float;

	public function new(element:MissionElementTrigger, level:MarbleWorld) {
		super(element, level);
		var impulseField = element.fields.get("impulse");
		this.impulse = impulseField != null && impulseField[0] != "" ? MisParser.parseNumber(impulseField[0]) : 0;
		var upwardsField = element.fields.get("upwards");
		this.upwards = upwardsField != null && upwardsField[0] != "" ? MisParser.parseNumber(upwardsField[0]) : 0;
	}

	override function onMarbleEnter(marble:Marble, timeState:TimeState) {
		var mode = GameModeFactory.findMode(this.level.gameMode, WhiteNoiseMode);
		if (mode != null)
			mode.smbTriggerEnter(this.impulse, this.upwards, timeState.currentAttemptTime);
	}

	override function onMarbleLeave(marble:Marble, timeState:TimeState) {
		var mode = GameModeFactory.findMode(this.level.gameMode, WhiteNoiseMode);
		if (mode != null)
			mode.smbTriggerLeave(timeState.currentAttemptTime);
	}
}
