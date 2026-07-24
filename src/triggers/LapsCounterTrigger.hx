package triggers;

import src.Marble;
import src.TimeState;
import src.MarbleWorld;
import mis.MisParser;
import mis.MissionElement.MissionElementTrigger;
import modes.GameMode.GameModeFactory;
import modes.LapsMode;

/** Ported from PQ's `LapsCounterTrigger` datablock (`modes/laps.cs`) - the finish line of a lap:
	only advances the lap counter if the last checkpoint in the sequence has already been hit
	(`lapsHitLastCP`), otherwise it's just a "wrong way" trip-wire like `LapsCheckpoint`. */
class LapsCounterTrigger extends Trigger implements ILapsRespawnTrigger {
	public var enableRespawning:Bool;
	public var customSpawnPoint:Bool;
	public var spawnPoint:String;
	public var forceGravity:String;

	public function new(element:MissionElementTrigger, level:MarbleWorld) {
		super(element, level);

		var respawnField = element.fields.get("enablerespawning");
		this.enableRespawning = respawnField == null || MisParser.parseBoolean(respawnField[0]);

		var customField = element.fields.get("customspawnpoint");
		this.customSpawnPoint = customField != null && MisParser.parseBoolean(customField[0]);

		var spawnField = element.fields.get("spawnpoint");
		this.spawnPoint = spawnField != null ? spawnField[0] : "";

		var gravField = element.fields.get("forcegravity");
		this.forceGravity = gravField != null ? gravField[0] : "";
	}

	override function onMarbleEnter(marble:Marble, time:TimeState) {
		var laps = GameModeFactory.findMode(this.level.gameMode, LapsMode);
		if (laps != null)
			laps.onCounterTrigger(this, marble);
	}
}
