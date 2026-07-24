package modes;

import h3d.Quat;
import h3d.Vector;
import src.Marble;
import src.MarbleWorld;
import src.AudioManager;
import mis.MisParser;
import triggers.LapsCheckpoint;
import triggers.LapsCounterTrigger;
import triggers.ILapsRespawnTrigger;
import rewind.RewindableState;

/** Ported from PQ's `modes/laps.cs` - full lap-based circuit racing. Live progress
	(`lapsCPCheck`/`lapsHitLastCP`) advances as `LapsCheckpoint`/`LapsCounterTrigger` are hit in
	sequence; a *separate* snapshot (`checkpointLaps*`) is only updated when a checkpoint is
	actually "activated" (a genuine forward hit, not a same-checkpoint re-touch) and is what
	actually gets restored on respawn - matching `Mode_laps::onActivateCheckpoint`/
	`onRespawnOnCheckpoint` exactly, including the subtlety that re-touching the checkpoint you're
	already at doesn't reset anything. */
class LapsMode extends NullMode {
	var lapsNumber:Int;
	var noLapsCheckpoint:Bool;

	// Live progress.
	var lapsCounter:Int = 1;
	var lapsCPCheck:Int = 1;
	var lapsHitLastCP:Bool = false;
	var lapsStartTime:Float = 0;

	// Respawn point tracked by the most recently *activated* checkpoint (see class doc).
	var lapsCheckpoint:ILapsRespawnTrigger;
	var lapsPosition:Vector;
	var lapsCameraYaw:Float;
	var lapsUp:Vector = new Vector(0, 0, 1);

	// Snapshot of live progress at the point the respawn point above was last activated.
	var checkpointLapsCounter:Int = 1;
	var checkpointLapsCPCheck:Int = 1;
	var checkpointLapsHitLastCP:Bool = false;
	var checkpointLapsStartTime:Float = 0;

	public function new(level:MarbleWorld) {
		super(level);
		var field = level.mission.missionInfo.lapsnumber;
		this.lapsNumber = field != null && field != "" ? Std.parseInt(field) : 1;
		var noCp = level.mission.missionInfo.nolapscheckpoint;
		this.noLapsCheckpoint = noCp != null && noCp != "" && MisParser.parseBoolean(noCp);
	}

	override function onMissionLoad() {
		this.resetLaps();
	}

	override function onRestart() {
		this.resetLaps();
	}

	function resetLaps() {
		this.lapsCounter = 1;
		this.lapsCPCheck = 1;
		this.lapsHitLastCP = false;
		this.lapsStartTime = 0;
		this.lapsCheckpoint = null;
		this.checkpointLapsCounter = 1;
		this.checkpointLapsCPCheck = 1;
		this.checkpointLapsHitLastCP = false;
		this.checkpointLapsStartTime = 0;
	}

	/** Ported from `GameConnection::onNextLap` - always advances/resets progress regardless of
		whether this lap actually finishes the mission (matches the original: the increment isn't
		gated behind the finish check), and always returns true so the calling trigger always also
		activates this line as a checkpoint. */
	function onNextLap():Bool {
		if (this.lapsCounter >= this.lapsNumber) {
			if (level.gemCount != level.totalGems) {
				@:privateAccess level.playGui.addMiddleMessage("You need to collect all the gems to finish!", 0xff6666);
				AudioManager.playPitchedSound("missinggems", @:privateAccess level.soundResources);
			} else {
				@:privateAccess level.touchFinish();
			}
		}

		this.lapsCounter++;
		this.lapsCPCheck = 1;
		this.lapsHitLastCP = false;
		this.lapsStartTime = level.timeState.currentAttemptTime;
		return true;
	}

	/** Called by `LapsCounterTrigger`. */
	public function onCounterTrigger(trigger:LapsCounterTrigger, marble:Marble) {
		if (this.lapsHitLastCP) {
			if (this.onNextLap())
				this.activateCheckpoint(trigger);
		} else if (this.lapsCPCheck != 1) {
			@:privateAccess level.playGui.addMiddleMessage("Wrong way!", 0xff6666);
		}
	}

	/** Called by `LapsCheckpoint`. */
	public function onCheckpointTrigger(trigger:LapsCheckpoint, marble:Marble) {
		var highest = level.lapsLastCheckpointNumber;
		if (trigger.checkpointNumber == this.lapsCPCheck) {
			if (this.lapsCPCheck == highest) {
				this.lapsCPCheck = 0;
				this.lapsHitLastCP = true;
			} else {
				this.lapsCPCheck++;
			}
			this.activateCheckpoint(trigger);
		} else if (!((trigger.checkpointNumber + 1 == this.lapsCPCheck) || (trigger.checkpointNumber == highest && this.lapsCPCheck == 0))) {
			@:privateAccess level.playGui.addMiddleMessage("Wrong way!", 0xff6666);
		}
	}

	/** Ported from `GameConnection::activateLapsCheckpoint` - snapshots the marble's current spot
		(or the trigger's fixed `spawnPoint` field, if it has one configured) as the respawn point,
		along with a gravity override from the trigger's `forceGravity` field if set (else the
		marble's current up vector), and snapshots live lap progress into the `checkpointLaps*`
		fields at the same time (`Mode_laps::onActivateCheckpoint`). */
	function activateCheckpoint(trigger:ILapsRespawnTrigger) {
		if (this.noLapsCheckpoint || !trigger.enableRespawning)
			return;

		this.lapsCheckpoint = trigger;

		var forceGravity = trigger.forceGravity;
		if (forceGravity != null && forceGravity != "") {
			var quat = MisParser.parseRotation(forceGravity);
			var dir = new Vector(0, 0, -1);
			dir.transform(quat.toMatrix());
			this.lapsUp = dir;
		} else {
			this.lapsUp = level.marble.currentUp.clone();
		}

		var customSpawnPoint = trigger.customSpawnPoint;
		var spawnPoint = trigger.spawnPoint;
		if (customSpawnPoint && spawnPoint != null && spawnPoint != "") {
			var words = spawnPoint.split(' ').map(w -> Std.parseFloat(w));
			this.lapsPosition = new Vector(-words[0], words[1], words[2]);
			var rotQuat = new Quat();
			rotQuat.initRotateAxis(words[3], words[4], words[5], -words[6] * Math.PI / 180);
			var yawAxis = new Vector(0, 0, 1);
			yawAxis.transform(rotQuat.toMatrix());
			this.lapsCameraYaw = Math.atan2(yawAxis.y, yawAxis.x);
		} else {
			this.lapsPosition = level.marble.getAbsPos().getPosition().clone();
			this.lapsCameraYaw = level.marble.camera.CameraYaw;
		}

		this.checkpointLapsCounter = this.lapsCounter;
		this.checkpointLapsCPCheck = this.lapsCPCheck;
		this.checkpointLapsHitLastCP = this.lapsHitLastCP;
		this.checkpointLapsStartTime = this.lapsStartTime;
	}

	/** Ported from `Mode_laps::getCheckpointPos`/`onRespawnOnCheckpoint` - restores progress to
		whatever it was at the last *activated* checkpoint (not necessarily the live progress, if
		the marble progressed further and then went OOB without touching another checkpoint), and
		supplies the respawn position/facing/gravity captured at that same checkpoint. */
	override function getRespawnTransform(marble:Marble):{position:Vector, orientation:Quat, up:Vector} {
		if (this.noLapsCheckpoint || this.lapsCheckpoint == null)
			return null;

		this.lapsCPCheck = this.checkpointLapsCPCheck;
		this.lapsCounter = this.checkpointLapsCounter;
		this.lapsHitLastCP = this.checkpointLapsHitLastCP;
		this.lapsStartTime = this.checkpointLapsStartTime;

		var orientation = new Quat();
		orientation.initRotateAxis(0, 0, 1, this.lapsCameraYaw);
		return {position: this.lapsPosition.clone(), orientation: orientation, up: this.lapsUp.clone()};
	}

	override function onRespawn(marble:Marble) {
		if (this.lapsCheckpoint != null)
			marble.camera.CameraYaw = this.lapsCameraYaw;
	}

	override function getRewindState():RewindableState {
		var s = new LapsState();
		s.lapsCounter = this.lapsCounter;
		s.lapsCPCheck = this.lapsCPCheck;
		s.lapsHitLastCP = this.lapsHitLastCP;
		s.lapsStartTime = this.lapsStartTime;
		s.checkpointLapsCounter = this.checkpointLapsCounter;
		s.checkpointLapsCPCheck = this.checkpointLapsCPCheck;
		s.checkpointLapsHitLastCP = this.checkpointLapsHitLastCP;
		s.checkpointLapsStartTime = this.checkpointLapsStartTime;
		s.lapsCheckpoint = this.lapsCheckpoint;
		s.lapsPosition = this.lapsPosition != null ? this.lapsPosition.clone() : null;
		s.lapsCameraYaw = this.lapsCameraYaw;
		s.lapsUp = this.lapsUp != null ? this.lapsUp.clone() : null;
		return s;
	}

	override function applyRewindState(state:RewindableState) {
		var s:LapsState = cast state;
		this.lapsCounter = s.lapsCounter;
		this.lapsCPCheck = s.lapsCPCheck;
		this.lapsHitLastCP = s.lapsHitLastCP;
		this.lapsStartTime = s.lapsStartTime;
		this.checkpointLapsCounter = s.checkpointLapsCounter;
		this.checkpointLapsCPCheck = s.checkpointLapsCPCheck;
		this.checkpointLapsHitLastCP = s.checkpointLapsHitLastCP;
		this.checkpointLapsStartTime = s.checkpointLapsStartTime;
		this.lapsCheckpoint = s.lapsCheckpoint;
		this.lapsPosition = s.lapsPosition != null ? s.lapsPosition.clone() : null;
		this.lapsCameraYaw = s.lapsCameraYaw;
		this.lapsUp = s.lapsUp != null ? s.lapsUp.clone() : this.lapsUp;
	}

	override function constructRewindState():RewindableState {
		return new LapsState();
	}
}
