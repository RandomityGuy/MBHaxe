package src;

import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import dif.io.BytesReader;
import dif.io.BytesWriter;
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

	public function write(bw:BytesWriter) {
		bw.writeFloat(this.time);
		bw.writeFloat(this.clockTime);
		bw.writeFloat(this.bonusTime);
		bw.writeFloat(this.marblePosition.x);
		bw.writeFloat(this.marblePosition.y);
		bw.writeFloat(this.marblePosition.z);
		bw.writeFloat(this.marbleVelocity.x);
		bw.writeFloat(this.marbleVelocity.y);
		bw.writeFloat(this.marbleVelocity.z);
		bw.writeFloat(this.marbleOrientation.x);
		bw.writeFloat(this.marbleOrientation.y);
		bw.writeFloat(this.marbleOrientation.z);
		bw.writeFloat(this.marbleOrientation.w);
		bw.writeFloat(this.marbleAngularVelocity.x);
		bw.writeFloat(this.marbleAngularVelocity.y);
		bw.writeFloat(this.marbleAngularVelocity.z);
		bw.writeByte(this.marbleStateFlags.toInt());
		bw.writeFloat(this.cameraPitch);
		bw.writeFloat(this.cameraYaw);
		bw.writeFloat(this.marbleX);
		bw.writeFloat(this.marbleY);
	}

	public function read(br:BytesReader) {
		this.time = br.readFloat();
		this.clockTime = br.readFloat();
		this.bonusTime = br.readFloat();
		this.marblePosition = new Vector(br.readFloat(), br.readFloat(), br.readFloat());
		this.marbleVelocity = new Vector(br.readFloat(), br.readFloat(), br.readFloat());
		this.marbleOrientation = new Quat(br.readFloat(), br.readFloat(), br.readFloat(), br.readFloat());
		this.marbleAngularVelocity = new Vector(br.readFloat(), br.readFloat(), br.readFloat());
		this.marbleStateFlags = EnumFlags.ofInt(br.readByte());
		this.cameraPitch = br.readFloat();
		this.cameraYaw = br.readFloat();
		this.marbleX = br.readFloat();
		this.marbleY = br.readFloat();
	}
}

@:publicFields
class ReplayInitialState {
	var trapdoorLastContactTimes:Array<Float> = [];
	var trapdoorLastDirections:Array<Int> = [];
	var trapdoorLastCompletions:Array<Float> = [];
	var landMineDisappearTimes:Array<Float> = [];

	public function new() {}

	public function write(bw:BytesWriter) {
		bw.writeInt16(this.trapdoorLastContactTimes.length);
		for (time in this.trapdoorLastContactTimes) {
			bw.writeFloat(time);
		}
		for (dir in this.trapdoorLastDirections) {
			bw.writeByte(dir);
		}
		for (completion in this.trapdoorLastCompletions) {
			bw.writeFloat(completion);
		}
		bw.writeInt16(this.landMineDisappearTimes.length);
		for (time in this.landMineDisappearTimes) {
			bw.writeFloat(time);
		}
	}

	public function read(br:BytesReader) {
		var trapdoorCount = br.readInt16();
		for (i in 0...trapdoorCount) {
			this.trapdoorLastContactTimes.push(br.readFloat());
		}
		for (i in 0...trapdoorCount) {
			this.trapdoorLastDirections.push(br.readByte());
		}
		for (i in 0...trapdoorCount) {
			this.trapdoorLastCompletions.push(br.readFloat());
		}
		var landMineCount = br.readInt16();
		for (i in 0...landMineCount) {
			this.landMineDisappearTimes.push(br.readFloat());
		}
	}
}

class Replay {
	public var mission:String;

	var frames:Array<ReplayFrame>;
	var initialState:ReplayInitialState;
	var currentRecordFrame:ReplayFrame;

	public var currentPlaybackFrame:ReplayFrame;

	var currentPlaybackFrameIdx:Int;
	var currentPlaybackTime:Float;

	public function new(mission:String) {
		this.mission = mission;
		this.initialState = new ReplayInitialState();
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

	public function recordTrapdoorState(lastContactTime:Float, lastDirection:Int, lastCompletion:Float) {
		initialState.trapdoorLastContactTimes.push(lastContactTime);
		initialState.trapdoorLastDirections.push(lastDirection);
		initialState.trapdoorLastCompletions.push(lastCompletion);
	}

	public function recordLandMineState(disappearTime:Float) {
		initialState.landMineDisappearTimes.push(disappearTime);
	}

	public function getTrapdoorState(idx:Int) {
		return {
			lastContactTime: initialState.trapdoorLastContactTimes[idx],
			lastDirection: initialState.trapdoorLastDirections[idx],
			lastCompletion: initialState.trapdoorLastCompletions[idx]
		};
	}

	public function getLandMineState(idx:Int) {
		return initialState.landMineDisappearTimes[idx];
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

	public function write() {
		var bw = new BytesWriter();

		bw.writeStr(this.mission);
		this.initialState.write(bw);
		bw.writeInt32(this.frames.length);
		for (frame in this.frames) {
			frame.write(bw);
		}

		var buf = bw.getBuffer();
		var bufsize = buf.length;
		var compressed = haxe.zip.Compress.run(bw.getBuffer(), 7);

		var finalB = new BytesBuffer();
		finalB.addInt32(bufsize);
		finalB.addBytes(compressed, 4, compressed.length);

		return finalB.getBytes();
	}

	public function read(data:Bytes) {
		var uncompressedLength = data.getInt32(0);
		var compressedData = data.sub(4, data.length - 4);

		var uncompressed = haxe.zip.Uncompress.run(compressedData, uncompressedLength);
		var br = new BytesReader(uncompressed);
		this.mission = br.readStr();
		this.initialState.read(br);
		var frameCount = br.readInt32();
		this.frames = [];
		for (i in 0...frameCount) {
			var frame = new ReplayFrame();
			frame.read(br);
			this.frames.push(frame);
		}
	}
}
