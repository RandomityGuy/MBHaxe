package modes;

import src.Marble;
import rewind.RewindableState;
import shapes.Gem;
import h3d.Quat;
import h3d.Vector;
import src.MarbleWorld;
import src.Mission;
import src.Marble;
import src.TimeState;

enum ScoreType {
	Time;
	Score;
}

interface GameMode {
	public function getSpawnTransform():{position:Vector, orientation:Quat, up:Vector};
	public function getRespawnTransform(marble:Marble):{position:Vector, orientation:Quat, up:Vector};
	public function missionScan(mission:Mission):Void;
	public function getStartTime():Float;
	public function timeMultiplier():Float;
	public function getScoreType():ScoreType;
	public function getFinishScore():Float;
	public function getRewindState():RewindableState;
	public function applyRewindState(state:RewindableState):Void;
	public function onTimeExpire():Void;
	public function onRestart():Void;
	public function onClientRestart():Void;
	public function onRespawn(marble:Marble):Void;
	public function onGemPickup(marble:Marble, gem:Gem):Void;
	public function update(t:TimeState):Void;

	// Called every server tick on the host during multiplayer
	public function onHostTick(timeState:TimeState):Void;

	// Called on the host when marble `attacker` physically contacts or blasts marble `victim`
	public function onMarbleContact(attacker:Marble, victim:Marble):Void;

	// Called when multiplayer gameplay officially begins (countdown finished)
	public function onMultiplayerStart():Void;

	// Returns mode-specific packets to send to a client joining mid-game
	public function getWorldJoinPackets():Array<haxe.io.Bytes>;

	public function transmitAnyNetCommands(client:net.ClientConnection.GameConnection):Void;

	public function getPreloadFiles():Array<String>;
	public function constructRewindState():RewindableState;
}

class GameModeFactory {
	public static function getGameMode(level:MarbleWorld, mode:String):GameMode {
		if (mode != null)
			switch (mode.toLowerCase()) {
				case "scrum":
					return new HuntMode(level, false);
				case "competitive":
					return new HuntMode(level, true);
				case "king":
					return new KingMode(level);
			}
		return new NullMode(level);
	}
}
