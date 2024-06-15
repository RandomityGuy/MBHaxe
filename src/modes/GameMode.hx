package modes;

import src.Marble;
import shapes.Gem;
import h3d.Quat;
import h3d.Vector;
import src.MarbleWorld;
import src.Mission;
import src.Marble;

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
	public function onTimeExpire():Void;
	public function onRestart():Void;
	public function onClientRestart():Void;
	public function onRespawn(marble:Marble):Void;
	public function onGemPickup(marble:Marble, gem:Gem):Void;

	public function getPreloadFiles():Array<String>;
}

class GameModeFactory {
	public static function getGameMode(level:MarbleWorld, mode:String):GameMode {
		return new NullMode(level);
	}
}
