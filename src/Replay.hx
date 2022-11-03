package src;

import haxe.EnumFlags;
import h3d.Quat;
import h3d.Vector;
import src.Util;

enum ReplayMarbleState {
	UsedPowerup;
	Jumped;
	InstantTeleport;
}

@:publicFields
class ReplayFrame {
	// Time
	var time:Float;
	var clockTime:Float;
	var bonusTime:Float;
	// Marble
	var marblePosition:Vector;
	var marbleVelocity:Vector;
	var marbleOrientation:Quat;
	var marbleAngularVelocity:Vector;
	var marbleStateFlags:EnumFlags<ReplayMarbleState>;
	// Camera
	var cameraPitch:Float;
	var cameraYaw:Float;
	// Input
	var marbleX:Float;
	var marbleY:Float;

	public function new() {}

	public function interpolate(next:ReplayFrame, time:Float) {
		var t = (time - this.time) / (next.time - this.time);

		var dt = time - this.time;

		var interpFrame = new ReplayFrame();

		// Interpolate time
		interpFrame.time = time;
		interpFrame.bonusTime = this.bonusTime;
		interpFrame.clockTime = this.clockTime;
		if (interpFrame.bonusTime != 0 && time >= 3.5) {
			if (dt <= this.bonusTime) {
				interpFrame.bonusTime -= dt;
			} else {
				interpFrame.clockTime += dt - this.bonusTime;
				interpFrame.bonusTime = 0;
			}
		} else {
			if (this.time >= 3.5)
				interpFrame.clockTime += dt;
			else if (this.time + dt >= 3.5) {
				interpFrame.clockTime += (this.time + dt) - 3.5;
			}
		}

		// Interpolate marble
		if (this.marbleStateFlags.has(InstantTeleport)) {
			interpFrame.marblePosition = this.marblePosition.clone();
			interpFrame.marbleVelocity = this.marbleVelocity.clone();
			interpFrame.marbleOrientation = this.marbleOrientation.clone();
			interpFrame.marbleAngularVelocity = this.marbleAngularVelocity.clone();
			interpFrame.marbleStateFlags.set(InstantTeleport);
		} else {
			interpFrame.marblePosition = Util.lerpThreeVectors(this.marblePosition, next.marblePosition, t);
			interpFrame.marbleVelocity = Util.lerpThreeVectors(this.marbleVelocity, next.marbleVelocity, t);
			interpFrame.marbleOrientation = new Quat();
			interpFrame.marbleOrientation.slerp(this.marbleOrientation, next.marbleOrientation, t);
			interpFrame.marbleAngularVelocity = Util.lerpThreeVectors(this.marbleAngularVelocity, next.marbleAngularVelocity, t);
		}

		// Interpolate camera
		if (this.marbleStateFlags.has(InstantTeleport)) {
			interpFrame.cameraYaw = this.cameraYaw;
			interpFrame.cameraPitch = this.cameraPitch;
		} else {
			interpFrame.cameraYaw = Util.lerp(this.cameraYaw, next.cameraYaw, t);
			interpFrame.cameraPitch = Util.lerp(this.cameraPitch, next.cameraPitch, t);
		}

		// State flags
		if (this.marbleStateFlags.has(UsedPowerup))
			interpFrame.marbleStateFlags.set(UsedPowerup);
		if (this.marbleStateFlags.has(Jumped))
			interpFrame.marbleStateFlags.set(Jumped);

		// Input
		interpFrame.marbleX = this.marbleX;
		interpFrame.marbleY = this.marbleY;

		return interpFrame;
	}
}

class Replay {
	public var mission:String;

	var frames:Array<ReplayFrame>;

	var currentRecordFrame:ReplayFrame;

	public var currentPlaybackFrame:ReplayFrame;

	var currentPlaybackFrameIdx:Int;
	var currentPlaybackTime:Float;

	public function new(mission:String) {
		this.mission = mission;
	}

	public function startFrame() {
		currentRecordFrame = new ReplayFrame();
	}

	public function endFrame() {
		frames.push(currentRecordFrame);
		currentRecordFrame = null;
	}

	public function recordTimeState(time:Float, clockTime:Float, bonusTime:Float) {
		currentRecordFrame.time = time;
		currentRecordFrame.clockTime = clockTime;
		currentRecordFrame.bonusTime = bonusTime;
	}

	public function recordMarbleState(position:Vector, velocity:Vector, orientation:Quat, angularVelocity:Vector) {
		currentRecordFrame.marblePosition = position.clone();
		currentRecordFrame.marbleVelocity = velocity.clone();
		currentRecordFrame.marbleOrientation = orientation.clone();
		currentRecordFrame.marbleAngularVelocity = angularVelocity.clone();
	}

	public function recordMarbleStateFlags(jumped:Bool, usedPowerup:Bool, instantTeleport:Bool) {
		if (jumped)
			currentRecordFrame.marbleStateFlags.set(Jumped);
		if (usedPowerup)
			currentRecordFrame.marbleStateFlags.set(UsedPowerup);
		if (instantTeleport)
			currentRecordFrame.marbleStateFlags.set(InstantTeleport);
	}

	public function recordMarbleInput(x:Float, y:Float) {
		currentRecordFrame.marbleX = x;
		currentRecordFrame.marbleY = y;
	}

	public function recordCameraState(pitch:Float, yaw:Float) {
		currentRecordFrame.cameraPitch = pitch;
		currentRecordFrame.cameraYaw = yaw;
	}

	public function clear() {
		this.frames = [];
		currentRecordFrame = null;
	}

	public function advance(dt:Float) {
		if (this.currentPlaybackFrame == null) {
			this.currentPlaybackFrame = this.frames[this.currentPlaybackFrameIdx];
		}

		var nextT = this.currentPlaybackTime + dt;
		var startFrame = this.frames[this.currentPlaybackFrameIdx];
		if (this.currentPlaybackFrameIdx + 1 >= this.frames.length) {
			return false;
		}
		var nextFrame = this.frames[this.currentPlaybackFrameIdx + 1];
		while (nextFrame.time <= nextT) {
			this.currentPlaybackFrameIdx++;
			if (this.currentPlaybackFrameIdx + 1 >= this.frames.length) {
				return false;
			}
			var testNextFrame = this.frames[this.currentPlaybackFrameIdx + 1];
			startFrame = nextFrame;
			nextFrame = testNextFrame;
		}
		this.currentPlaybackFrame = startFrame.interpolate(nextFrame, nextT);
		this.currentPlaybackTime += dt;
		return true;
	}

	public function rewind() {
		this.currentPlaybackTime = 0;
		this.currentPlaybackFrame = null;
		this.currentPlaybackFrameIdx = 0;
	}
}
