package triggers;

import src.Marble;
import src.TimeState;
import src.MarbleWorld;
import mis.MisParser;
import mis.MissionElement.MissionElementTrigger;
import modes.GameMode.GameModeFactory;
import modes.LapsMode;

class LapsCheckpoint extends Trigger implements ILapsRespawnTrigger {
	public var checkpointNumber:Int;
	public var enableRespawning:Bool;
	public var customSpawnPoint:Bool;
	public var spawnPoint:String;
	public var forceGravity:String;

	public function new(element:MissionElementTrigger, level:MarbleWorld) {
		super(element, level);

		var cpField = element.fields.get("checkpointnumber");
		if (cpField != null && cpField[0] != "") {
			this.checkpointNumber = Std.parseInt(cpField[0]);
			level.lapsLastCheckpointNumber = Std.int(Math.max(level.lapsLastCheckpointNumber, this.checkpointNumber));
		} else {
			this.checkpointNumber = level.lapsLastCheckpointNumber;
			level.lapsLastCheckpointNumber++;
		}

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
			laps.onCheckpointTrigger(this, marble);
	}
}
