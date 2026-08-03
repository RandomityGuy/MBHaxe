package triggers;

import src.TimeState;
import src.Marble;
import src.MarbleWorld;
import mis.MisParser;
import mis.MissionElement.MissionElementTrigger;
import modes.GameMode.GameModeFactory;
import modes.special.WhiteNoiseMode;

/** Ported from `WhiteNoise.mcs`'s `SMBTrigger` `TriggerData` - a White-Noise-mission-only trigger
	that hands its `impulse`/`upwards` fields to the active `WhiteNoiseMode` (see
	`WhiteNoiseMode.smbTriggerEnter`/`smbTriggerLeave` for the actual jump-time effect and the
	300ms-debounce reasoning), rather than doing anything itself - matches real PQ, where the
	trigger only relays `commandToClient('SMBTrigger', ...)` and the actual behavior lives in
	`Marble::onJump`. Registered directly in `DatablockRegistry` rather than via the mission file's
	own (never-loaded-here) `datablock TriggerData(SMBTrigger)` definition, since nothing about it
	is mission-specific except the field values on each placed instance. */
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
