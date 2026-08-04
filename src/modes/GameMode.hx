package modes;

import collision.CollisionInfo;
import net.Move;
import src.TimeState;
import src.Marble;
import shapes.Gem;
import h3d.Quat;
import h3d.Vector;
import src.MarbleWorld;
import src.Mission;
import src.Marble;
import rewind.RewindableState;
import modes.special.ArkanoidMode;
import modes.special.SacredGroundMode;
import modes.special.ViceVersaMode;
import modes.special.WhiteNoiseMode;
import modes.special.TakeTheGoldMode;
import modes.special.BagOfSecretsMode;
import modes.special.BlastToTheBeatMode;

enum ScoreType {
	Time;
	Score;
}

interface GameMode {
	public function getSpawnTransform():{position:Vector, orientation:Quat, up:Vector};
	public function getRespawnTransform(marble:Marble):{position:Vector, orientation:Quat, up:Vector};
	public function missionScan(mission:Mission):Void;
	public function onMissionLoad():Void;
	public function getStartTime():Float;
	public function timeMultiplier():Float;
	public function getScoreType():ScoreType;
	public function getFinishScore():{score:Float, type:ScoreType};
	public function onTimeExpire():Void;
	public function onRestart():Void;
	public function onClientRestart():Void;
	public function onRespawn(marble:Marble):Void;
	public function onGemPickup(marble:Marble, gem:Gem):Bool;
	public function update(t:TimeState):Void;

	public function processMove(marble:Marble, move:Move):Void;

	public function processMaterialContact(marble:Marble, contact:CollisionInfo):Void;

	public function onJump(marble:Marble):Void;

	public function getPreloadFiles():Array<String>;

	public function canFinish(marble:Marble):Bool;

	public function getFinishMessage(marble:Marble):String;

	public function onOutOfBounds(marble:Marble):Bool;

	public function getRewindState():RewindableState;

	public function applyRewindState(state:RewindableState):Void;

	public function constructRewindState():RewindableState;

	public function saveReplayData(bw:haxe.io.BytesOutput):Void;

	public function loadReplayData(br:haxe.io.BytesInput):Void;
}

class GameModeFactory {
	public static function getGameMode(level:MarbleWorld, mode:String, activatedPackages:Array<String>):GameMode {
		var missionPath = level.mission != null && level.mission.path != null ? level.mission.path.toLowerCase() : "";
		if (StringTools.endsWith(missionPath, "bagofsecrets.mcs"))
			return new BagOfSecretsMode(level);
		if (StringTools.endsWith(missionPath, "blasttothebeat.mcs"))
			return new BlastToTheBeatMode(level);

		if (activatedPackages.length != 0) {
			// Special mis-mod game modes used by PQ bonus
			if (activatedPackages.contains("arkanoid"))
				return new ArkanoidMode(level);
			if (activatedPackages.contains("sacredgroundb1"))
				return new SacredGroundMode(level);
			if (activatedPackages.contains("whitenoise"))
				return new WhiteNoiseMode(level);
			if (activatedPackages.contains("viceendnext"))
				return new ViceVersaMode(level, false);
			if (activatedPackages.contains("versa"))
				return new ViceVersaMode(level, true);
			if (activatedPackages.contains("ttg"))
				return new TakeTheGoldMode(level);
		}

		if (mode == null || StringTools.trim(mode) == "")
			return new NullMode(level);

		var words = ~/\s+/g.split(StringTools.trim(mode)).filter(w -> w != "");
		var modes = words.map(w -> getSingleGameMode(level, w));

		if (modes.length == 0)
			return new NullMode(level);
		if (modes.length == 1)
			return modes[0];
		return new CompositeMode(level, modes);
	}

	static function getSingleGameMode(level:MarbleWorld, mode:String):GameMode {
		return switch (mode.toLowerCase()) {
			case "hunt": new HuntMode(level);
			case "2d": new TwoDMode(level);
			case "quota": new QuotaMode(level);
			case "gemmadness", "madness": new MadnessMode(level);
			case "consistency": new ConsistencyMode(level);
			case "laps": new LapsMode(level);
			case "haste": new HasteMode(level);
			default: new NullMode(level);
		}
	}

	public static function getGameModeDescription(mode:String) {
		return switch (mode.toLowerCase()) {
			case "hunt": {name: "Gem Hunt", desc: "Collect Gems and earn as many points as you can!"};
			case "2d": {name: "2D", desc: "Lose a dimension but none of the challenge."};
			case "quota": {name: "Gem Quota", desc: "Grab the required amount of Gems or go for 100%!"};
			case "gemmadness", "madness": {name: "Gem Madness", desc: "Collect as many gems as you can before time runs out!"};
			case "consistency": {name: "Consistency", desc: "Stay above the target speed!"};
			case "laps": {name: "Laps", desc: "Complete laps around the level to finish!"};
			case "haste": {name: "Haste", desc: "Build up speed to activate the finish!"};
			default: {name: "Normal", desc: "Collect the Gems and finish!"};
		}
	}

	public static function findMode<T:GameMode>(mode:GameMode, cl:Class<T>):T {
		if (Std.isOfType(mode, cl))
			return cast mode;
		if (mode is CompositeMode) {
			for (child in (cast mode : CompositeMode).children)
				if (Std.isOfType(child, cl))
					return cast child;
		}
		return null;
	}
}
