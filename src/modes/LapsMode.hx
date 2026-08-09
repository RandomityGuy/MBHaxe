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
import rewind.RewindManager;
import triggers.ILapsRespawnTrigger;
import src.Util;

@:publicFields
class LapsState implements RewindableState {
	var lapsCounter:Int;
	var lapsCPCheck:Int;
	var lapsHitLastCP:Bool;
	var lapsStartTime:Float;
	var checkpointLapsCounter:Int;
	var checkpointLapsCPCheck:Int;
	var checkpointLapsHitLastCP:Bool;
	var checkpointLapsStartTime:Float;
	var lapsCheckpoint:ILapsRespawnTrigger;
	var lapsPosition:Vector;
	var lapsCameraYaw:Float;
	var lapsUp:Vector;

	public function new() {}

	public function clone():RewindableState {
		var c = new LapsState();
		c.lapsCounter = lapsCounter;
		c.lapsCPCheck = lapsCPCheck;
		c.lapsHitLastCP = lapsHitLastCP;
		c.lapsStartTime = lapsStartTime;
		c.checkpointLapsCounter = checkpointLapsCounter;
		c.checkpointLapsCPCheck = checkpointLapsCPCheck;
		c.checkpointLapsHitLastCP = checkpointLapsHitLastCP;
		c.checkpointLapsStartTime = checkpointLapsStartTime;
		c.lapsCheckpoint = lapsCheckpoint;
		c.lapsPosition = lapsPosition != null ? lapsPosition.clone() : null;
		c.lapsCameraYaw = lapsCameraYaw;
		c.lapsUp = lapsUp != null ? lapsUp.clone() : null;
		return c;
	}

	public function getSize():Int {
		var size = 2 + 2 + 1 + 8; // lapsCounter, lapsCPCheck, lapsHitLastCP, lapsStartTime
		size += 2 + 2 + 1 + 8; // checkpointLaps*
		size += 2; // lapsCheckpoint id
		size += 1; // Null<lapsPosition>
		if (lapsPosition != null)
			size += 24;
		size += 8; // lapsCameraYaw
		size += 1; // Null<lapsUp>
		if (lapsUp != null)
			size += 24;
		return size;
	}

	public function serialize(rm:RewindManager, bw:haxe.io.BytesOutput) {
		bw.writeInt16(lapsCounter);
		bw.writeInt16(lapsCPCheck);
		bw.writeByte(lapsHitLastCP ? 1 : 0);
		bw.writeDouble(lapsStartTime);
		bw.writeInt16(checkpointLapsCounter);
		bw.writeInt16(checkpointLapsCPCheck);
		bw.writeByte(checkpointLapsHitLastCP ? 1 : 0);
		bw.writeDouble(checkpointLapsStartTime);
		bw.writeInt16(rm.allocGO(lapsCheckpoint != null ? cast lapsCheckpoint : null));
		bw.writeByte(lapsPosition == null ? 0 : 1);
		if (lapsPosition != null) {
			bw.writeDouble(lapsPosition.x);
			bw.writeDouble(lapsPosition.y);
			bw.writeDouble(lapsPosition.z);
		}
		bw.writeDouble(lapsCameraYaw);
		bw.writeByte(lapsUp == null ? 0 : 1);
		if (lapsUp != null) {
			bw.writeDouble(lapsUp.x);
			bw.writeDouble(lapsUp.y);
			bw.writeDouble(lapsUp.z);
		}
	}

	public function deserialize(rm:RewindManager, br:haxe.io.BytesInput) {
		lapsCounter = br.readInt16();
		lapsCPCheck = br.readInt16();
		lapsHitLastCP = br.readByte() != 0;
		lapsStartTime = br.readDouble();
		checkpointLapsCounter = br.readInt16();
		checkpointLapsCPCheck = br.readInt16();
		checkpointLapsHitLastCP = br.readByte() != 0;
		checkpointLapsStartTime = br.readDouble();
		var go = rm.getGO(br.readInt16());
		lapsCheckpoint = go != null ? cast(go, ILapsRespawnTrigger) : null;
		if (br.readByte() != 0) {
			lapsPosition = new Vector();
			lapsPosition.x = br.readDouble();
			lapsPosition.y = br.readDouble();
			lapsPosition.z = br.readDouble();
		} else {
			lapsPosition = null;
		}
		lapsCameraYaw = br.readDouble();
		if (br.readByte() != 0) {
			lapsUp = new Vector();
			lapsUp.x = br.readDouble();
			lapsUp.y = br.readDouble();
			lapsUp.z = br.readDouble();
		} else {
			lapsUp = null;
		}
	}
}

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

		@:privateAccess level.playGui.setLapsCounterVisible(true);
		this.updateLapsHud();
	}

	function updateLapsHud() {
		@:privateAccess level.playGui.formatLapsCounter(Std.int(Math.min(this.lapsCounter, this.lapsNumber)), this.lapsNumber);
	}

	function onNextLap():Bool {
		if (this.lapsCounter >= this.lapsNumber) {
			if (level.gemCount != level.totalGems) {
				level.displayHelp("You need to collect all the gems to finish!", 5);
				AudioManager.playPitchedSound("missinggems", @:privateAccess level.soundResources);
			} else {
				@:privateAccess level.touchFinish();
			}
		}

		var timeDiff = level.timeState.currentAttemptTime - this.lapsStartTime;
		level.displayHelp('Lap ${this.lapsCounter}\'s Time: ${Util.formatTime(timeDiff)}', 5);

		this.lapsCounter++;
		this.lapsCPCheck = 1;
		this.lapsHitLastCP = false;
		this.lapsStartTime = level.timeState.currentAttemptTime;
		this.updateLapsHud();
		return true;
	}

	public function onCounterTrigger(trigger:LapsCounterTrigger, marble:Marble) {
		if (this.lapsHitLastCP) {
			if (this.onNextLap())
				this.activateCheckpoint(trigger);
		} else if (this.lapsCPCheck != 1) {
			level.displayHelp("Wrong way!", 5);
		}
	}

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
		} else if (!((trigger.checkpointNumber + 1 == this.lapsCPCheck)
			|| (trigger.checkpointNumber == highest && this.lapsCPCheck == 0))) {
			level.displayHelp("Wrong way!", 5);
		}
	}

	function activateCheckpoint(trigger:ILapsRespawnTrigger) {
		if (this.noLapsCheckpoint || !trigger.enableRespawning)
			return;

		this.lapsCheckpoint = trigger;

		var forceGravity = trigger.forceGravity;
		if (forceGravity != null && forceGravity != "") {
			var quat = MisParser.parseRotation(forceGravity);
			quat.x = -quat.x;
			quat.w = -quat.w;
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
			this.lapsCameraYaw = Math.atan2(yawAxis.y, yawAxis.x) + Math.PI;
		} else {
			this.lapsPosition = level.marble.getAbsPos().getPosition().clone();
			this.lapsCameraYaw = level.marble.camera.CameraYaw;
		}

		this.checkpointLapsCounter = this.lapsCounter;
		this.checkpointLapsCPCheck = this.lapsCPCheck;
		this.checkpointLapsHitLastCP = this.lapsHitLastCP;
		this.checkpointLapsStartTime = this.lapsStartTime;
	}

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
