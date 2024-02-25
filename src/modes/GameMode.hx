package modes;

import src.Marble;
import rewind.RewindableState;
import shapes.Gem;
import h3d.Quat;
import h3d.Vector;
import src.MarbleWorld;
import src.Mission;

enum ScoreType {
	Time;
	Score;
}

interface GameMode {
	public function getSpawnTransform():{position:Vector, orientation:Quat, up:Vector};
	public function getRespawnTransform():{position:Vector, orientation:Quat, up:Vector};
	public function missionScan(mission:Mission):Void;
	public function getStartTime():Float;
	public function timeMultiplier():Float;
	public function getScoreType():ScoreType;
	public function getFinishScore():Float;
	public function getRewindState():RewindableState;
	public function applyRewindState(state:RewindableState):Void;
	public function onTimeExpire():Void;
	public function onRestart():Void;
	public function onRespawn(marble:Marble):Void;
	public function onGemPickup(gem:Gem):Void;

	public function getPreloadFiles():Array<String>;
	public function constructRewindState():RewindableState;
}

class GameModeFactory {
	public static function getGameMode(level:MarbleWorld, mode:String):GameMode {
		if (mode != null)
			switch (mode.toLowerCase()) {
				case "scrum":
					return new HuntMode(level);
			}
		return new NullMode(level);
	}
}
