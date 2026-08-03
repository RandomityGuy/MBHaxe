package modes;

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

	public function getPreloadFiles():Array<String>;

	/** Whether touching the finish right now is allowed - `NullMode`'s default is the base rule
		(every gem collected); `QuotaMode` checks its gem quota instead, `HasteMode` checks minimum
		speed instead. A mission with multiple modes active (`"Quota Haste"`) requires ALL of them
		to allow it (`CompositeMode` ANDs every child) - matches "collect quota gems AND be above
		the speed limit". */
	public function canFinish(marble:Marble):Bool;

	/** Message to show when `canFinish` returns false. */
	public function getFinishMessage(marble:Marble):String;

	/** Called when a marble goes out of bounds, before the default restart-after-a-few-seconds
		behavior is scheduled - return `true` to take over entirely (matches PQ's `MadnessMode`,
		which ends the level immediately with the current gem score instead of restarting) and
		suppress the default; `false` (`NullMode`'s default) to let the normal OOB/restart flow
		happen as usual. */
	public function onOutOfBounds(marble:Marble):Bool;

	/** Ported from the `mbu-port` branch's rewind design - modes with actual per-tick state
		(`MadnessMode`, `ConsistencyMode`, `LapsMode`, `TwoDMode`) return a `RewindableState` here;
		`NullMode`'s default (and any mode with nothing to snapshot) returns `null`. Keeps
		`RewindFrame` a single `modeState` field regardless of which mode is active, rather than a
		flat field per mode. */
	public function getRewindState():RewindableState;

	public function applyRewindState(state:RewindableState):Void;

	/** Builds an empty instance of this mode's concrete `RewindableState` subclass so
		`RewindFrame.deserialize` has something to call `deserialize` on - it can't know the
		concrete type ahead of time otherwise. */
	public function constructRewindState():RewindableState;
}

class GameModeFactory {
	/** A mission's `gameMode` field is a space-separated list of independently-active modes
		(confirmed against PQ's `shared/mission.cs::resolveMissionGameModes` - e.g. `"Hunt Laps"`),
		not a single mode name - split it and delegate through `CompositeMode` whenever more than
		one word is present, so every listed mode's hooks actually run. */
	public static function getGameMode(level:MarbleWorld, mode:String):GameMode {
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

	/** Finds an active instance of a specific mode class, whether `level.gameMode` is that mode
		directly or it's one of several modes combined via `CompositeMode` (e.g. triggers belonging
		to a specific mode - `LapsCounterTrigger`/`LapsCheckpoint` need to reach the active
		`LapsMode` regardless of what else is active alongside it). */
	public static function findMode<T:GameMode>(mode:GameMode, cl:Class<T>):T {
		if (Std.isOfType(mode, cl))
			return cast mode;
		if (Std.isOfType(mode, CompositeMode)) {
			for (child in (cast mode : CompositeMode).children)
				if (Std.isOfType(child, cl))
					return cast child;
		}
		return null;
	}
}
