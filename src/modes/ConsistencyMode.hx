package modes;

import src.TimeState;
import src.Marble;
import src.MarbleWorld;
import rewind.RewindableState;
import rewind.RewindManager;

@:publicFields
class ConsistencyState implements RewindableState {
	var belowSpeedSince:Float;
	var failing:Bool;
	var failed:Bool;
	var lastSpawnTime:Float;

	public function new() {}

	public function clone():RewindableState {
		var c = new ConsistencyState();
		c.belowSpeedSince = belowSpeedSince;
		c.failing = failing;
		c.failed = failed;
		c.lastSpawnTime = lastSpawnTime;
		return c;
	}

	public function getSize():Int {
		return 8 + 1 + 1 + 8;
	}

	public function serialize(rm:RewindManager, bw:haxe.io.BytesOutput) {
		bw.writeDouble(belowSpeedSince);
		bw.writeByte(failing ? 1 : 0);
		bw.writeByte(failed ? 1 : 0);
		bw.writeDouble(lastSpawnTime);
	}

	public function deserialize(rm:RewindManager, br:haxe.io.BytesInput) {
		belowSpeedSince = br.readDouble();
		failing = br.readByte() != 0;
		failed = br.readByte() != 0;
		lastSpawnTime = br.readDouble();
	}
}

/** Ported from PQ's `modes/consistency.cs` - fail if speed drops below `MissionInfo.minimumspeed`
	for longer than `MissionInfo.penaltydelay` (default 2000ms), after an initial `MissionInfo.
	graceperiod` at mission start (and, for countdown-timer modes like Hunt, another grace window
	near time-up) and after respawning. Per the standing rule against `level.schedule(...)` for
	gameplay, the "how long have they been too slow" timer is tracked as a plain timestamp
	(`belowSpeedSince`) and checked every `update()` tick rather than scheduled. */
class ConsistencyMode extends NullMode {
	var minimumSpeed:Float;
	var gracePeriod:Float;
	var penaltyDelay:Float;

	var belowSpeedSince:Float = -1;
	var failing:Bool = false;
	var failed:Bool = false;
	var lastSpawnTime:Float = -1e8;

	public function new(level:MarbleWorld) {
		super(level);
		var minSpeed = level.mission.missionInfo.minimumspeed;
		this.minimumSpeed = minSpeed != null && minSpeed != "" ? Std.parseFloat(minSpeed) : 0;
		var grace = level.mission.missionInfo.graceperiod;
		this.gracePeriod = grace != null && grace != "" ? Std.parseFloat(grace) / 1000 : 0;
		var penalty = level.mission.missionInfo.penaltydelay;
		this.penaltyDelay = penalty != null && penalty != "" ? Std.parseFloat(penalty) / 1000 : 2.0;
	}

	// `level.playGui` doesn't exist yet at construction time (`GameModeFactory.getGameMode` runs
	// before `MarbleWorld.initScene`/`postInit` create and initialize it) - register the HUD
	// threshold once it's actually safe to reach `level.playGui`.
	override function onMissionLoad() {
		@:privateAccess level.playGui.setConsistencyThreshold(this.minimumSpeed);
	}

	override function onRespawn(marble:Marble) {
		this.failing = false;
		this.failed = false;
		this.belowSpeedSince = -1;
		this.lastSpawnTime = level.timeState.currentAttemptTime;
	}

	override function onRestart() {
		this.failing = false;
		this.failed = false;
		this.belowSpeedSince = -1;
		this.lastSpawnTime = -1e8;
	}

	override function update(t:TimeState) {
		if (this.failed || level.finishTime != null)
			return;

		if (t.currentAttemptTime < this.gracePeriod)
			return;
		// Countdown-timer modes (Hunt/Madness) also get a grace window right before time runs out.
		if (level.gameMode.timeMultiplier() < 0 && level.gameMode.getStartTime() - t.currentAttemptTime < this.gracePeriod)
			return;
		if (t.currentAttemptTime - this.lastSpawnTime < this.gracePeriod)
			return;

		var speed = level.marble.velocity.length();
		if (speed < this.minimumSpeed) {
			if (!this.failing) {
				this.failing = true;
				this.belowSpeedSince = t.currentAttemptTime;
				@:privateAccess level.displayAlert("Too slow!");
			} else if (t.currentAttemptTime - this.belowSpeedSince >= this.penaltyDelay) {
				this.onConsistencyFail();
			}
		} else {
			this.failing = false;
			this.belowSpeedSince = -1;
		}
	}

	function onConsistencyFail() {
		this.failed = true;
		@:privateAccess level.playGui.displayAlert("Consistency failed!");

		var isHuntFamily = level.mission.gameMode != null && level.mission.gameMode.toLowerCase().indexOf("hunt") != -1;
		if (isHuntFamily) {
			level.restart(level.marble);
		} else {
			level.goOutOfBounds(level.marble);
		}
	}

	override function getRewindState():RewindableState {
		var s = new ConsistencyState();
		s.belowSpeedSince = this.belowSpeedSince;
		s.failing = this.failing;
		s.failed = this.failed;
		s.lastSpawnTime = this.lastSpawnTime;
		return s;
	}

	override function applyRewindState(state:RewindableState) {
		var s:ConsistencyState = cast state;
		this.belowSpeedSince = s.belowSpeedSince;
		this.failing = s.failing;
		this.failed = s.failed;
		this.lastSpawnTime = s.lastSpawnTime;
	}

	override function constructRewindState():RewindableState {
		return new ConsistencyState();
	}
}
