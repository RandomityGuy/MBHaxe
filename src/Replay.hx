package src;

import hxd.fs.FileEntry;
import shapes.PowerUp;
import haxe.io.BytesInput;
import haxe.zip.Huffman;
import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import dif.io.BytesReader;
import dif.io.BytesWriter;
import haxe.EnumFlags;
import h3d.Quat;
import h3d.Vector;
import src.Util;
import src.Console;
import src.MarbleGame;
import modes.GameMode;

enum ReplayMarbleState {
	UsedPowerup;
	Jumped;
	InstantTeleport;
	UsedBlast;
}

/** A single decoded/interpolated frame's worth of fields - purely a "view" struct now, never itself
	the unit of storage (see `Replay.frameData`). Every `Vector`/`Quat` sub-field is allocated exactly
	once, in the constructor, and mutated in place for the rest of this object's lifetime - callers
	(`Replay.recordScratch`/`playbackFrameA`/`playbackFrameB`/`currentPlaybackFrame`) are long-lived,
	reused instances, never reallocated per tick. */
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
	var powerupPickup:String;
	// Camera
	var cameraPitch:Float;
	var cameraYaw:Float;
	// Input
	var marbleX:Float;
	var marbleY:Float;
	// Continuous hold input (Move.powerupHeld) - drives Bubble's hold-to-use and Cannon's
	// charge/fire state machines (`Marble.updateBubble`/`updateCannonFiring`). Unlike `jump`/
	// `powerup`/`blast` (one-shot click-edge events, tracked via `marbleStateFlags`), this is a
	// plain per-frame level, recorded/replayed every tick like `marbleX`/`marbleY` - added after
	// Cannon/Bubble were ported, since without it neither mechanic's replay could ever actually
	// charge/fire the cannon or activate the bubble (the position/orientation still play back fine
	// regardless, since those are snapshotted+snapped every frame independent of move
	// reconstruction - only the side effects tied to holding the key were silently never triggering).
	var powerupHeld:Bool;
	// Gravity
	var gravity:Vector;
	var gravityInstant:Bool;
	var gravityChange:Bool;

	public function new() {
		marblePosition = new Vector();
		marbleVelocity = new Vector();
		marbleOrientation = new Quat();
		marbleAngularVelocity = new Vector();
		gravity = new Vector();
	}
}

@:publicFields
class ReplayInitialState {
	var trapdoorLastContactTimes:Array<Float> = [];
	var trapdoorLastDirections:Array<Int> = [];
	var trapdoorLastCompletions:Array<Float> = [];
	var landMineDisappearTimes:Array<Float> = [];
	var pushButtonContactTimes:Array<Float> = [];
	var randomGens:Array<Int> = [];
	var randomGenTimes:Array<Float> = [];
	// Same idea as `randomGens`, but for `Math.random()`-style [0,1) draws (e.g. Hunt's per-gem
	// spawn-chance rolls) that don't fit in an Int index. Kept as a fully separate FIFO rather than
	// interleaved with `randomGens` into one queue - each call site always draws from the one queue
	// matching its own draw type, so two independent per-type FIFOs are exactly equivalent to one
	// interleaved queue here (deterministic resimulation means the Nth "int draw" and Nth "float
	// draw" are always the same calls in the same order either way), and it's simpler.
	var randomFloats:Array<Float> = [];
	var randomFloatTimes:Array<Float> = [];

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
		bw.writeInt16(this.pushButtonContactTimes.length);
		for (time in this.pushButtonContactTimes) {
			bw.writeFloat(time);
		}
		// Was `writeInt16` count + `writeByte` per entry - a real bug for any consumer (like Hunt's
		// gem/spawn-point index draws) whose value can exceed 255, silently truncating. Widened to
		// Int32 for both the count and each entry as of version 8; old files are still read back
		// correctly via the version-gated branch below.
		bw.writeInt32(this.randomGens.length);
		for (ri in this.randomGens) {
			bw.writeInt32(ri);
		}
		bw.writeInt32(this.randomFloats.length);
		for (rf in this.randomFloats) {
			bw.writeFloat(rf);
		}
	}

	public function read(br:BytesReader, version:Int) {
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
		if (version > 5) {
			var pushButtonCount = br.readInt16();
			for (i in 0...pushButtonCount) {
				this.pushButtonContactTimes.push(br.readFloat());
			}
			if (version > 7) {
				var rcount = br.readInt32();
				for (i in 0...rcount) {
					this.randomGens.push(br.readInt32());
				}
				var fcount = br.readInt32();
				for (i in 0...fcount) {
					this.randomFloats.push(br.readFloat());
				}
			} else {
				var rcount = br.readInt16();
				for (i in 0...rcount) {
					this.randomGens.push(br.readByte());
				}
			}
		}
	}
}

/** Records/plays back a single-player attempt. Ported behavior-for-behavior from the original
	object-per-tick design, but the actual per-tick storage (`frameData`) is a flat `Array<Float>`
	(one contiguous run of `STRIDE` floats per recorded tick) instead of an `Array<ReplayFrame>` of
	heap objects each holding 4 further `Vector`/`Quat` sub-objects - a multi-minute attempt at full
	tick rate was allocating 5 heap objects every single tick purely to record, which is real,
	measurable GC pressure. Recording now just pushes scalars into that flat array (no allocation
	beyond the array's own amortized growth); playback decodes into a small, fixed set of persistent
	`ReplayFrame` "view" objects (`playbackFrameA`/`B`, `currentPlaybackFrame`) that get their fields
	mutated in place every tick instead of being reallocated. `powerupPickup` (a String, set on rare
	ticks only) is kept out of the flat numeric layout entirely, in a sparse `frameIndex -> path` map,
	so it doesn't cost anything on the ticks that don't have one. */
class Replay {
	public var mission:String;
	public var name:String;
	public var customId:Int;

	// Field layout within one frame's slice of `frameData` - single source of truth for both the
	// write side (`endFrame`) and the read side (`decodeFrameInto`).
	static inline var OFF_TIME = 0;
	static inline var OFF_CLOCK = 1;
	static inline var OFF_BONUS = 2;
	static inline var OFF_POS = 3; // +0/+1/+2 = x/y/z
	static inline var OFF_VEL = 6;
	static inline var OFF_ORIENT = 9; // +0/+1/+2/+3 = x/y/z/w
	static inline var OFF_ANGVEL = 13;
	static inline var OFF_FLAGS = 16;
	static inline var OFF_CAM_PITCH = 17;
	static inline var OFF_CAM_YAW = 18;
	static inline var OFF_MARBLE_X = 19;
	static inline var OFF_MARBLE_Y = 20;
	static inline var OFF_POWERUP_HELD = 21;
	static inline var OFF_GRAVITY = 22; // +0/+1/+2 = x/y/z
	static inline var OFF_GRAVITY_INSTANT = 25;
	static inline var OFF_GRAVITY_CHANGE = 26;
	static inline var STRIDE = 27;

	var frameData:Array<Float> = [];
	var frameCount:Int = 0;
	var powerupPickups:Map<Int, String> = new Map();

	var initialState:ReplayInitialState;

	// Recording: one persistent scratch frame, mutated in place by the various `recordXXX` calls
	// throughout a tick, flushed into `frameData` by `endFrame`. `recordingActive` mirrors the old
	// "currentRecordFrame != null" guard without needing a nullable object.
	var recordScratch:ReplayFrame = new ReplayFrame();
	var recordingActive:Bool = false;

	// Playback: two persistent decode targets for the "surrounding" recorded frames (swapped, not
	// reallocated, when `advance()` steps forward), plus the persistent interpolated result every
	// consumer actually reads.
	var playbackFrameA:ReplayFrame = new ReplayFrame();
	var playbackFrameB:ReplayFrame = new ReplayFrame();

	public var currentPlaybackFrame:ReplayFrame = new ReplayFrame();

	var currentPlaybackFrameIdx:Int;
	var currentPlaybackTime:Float;

	var version:Int = 9;
	var readFullEntry:FileEntry;

	/** Raw `GameMode.saveReplayData` bytes decoded by `read()` - can't be handed to the mode itself
		yet (no mission is loaded, so no `MarbleWorld`/`GameMode` exists at that point - `read()` can
		run standalone, e.g. `MainMenuGui`'s "load a replay file" flow, well before any mission is
		chosen). Stashed here and applied later via `applyModeData` once a mission has actually
		loaded for playback. */
	public var modeData:Bytes;

	/** Captured by `captureModeData` (called once, from `MarbleWorld.touchFinish`, while the level
		is still guaranteed alive) rather than read lazily from inside `write()` - `write()` itself
		can end up called well after finishing, from deferred/async code (`EndGameGui`'s leaderboard
		submission callbacks) that may run after the level's already been disposed, so there's no
		reliable `GameMode` to reach for at that point. `null` if never captured (e.g. this replay's
		mode has nothing to save, or the attempt never actually finished). */
	var savedModeData:Bytes;

	/** Ported from the need to keep a Versa replay reproducible even if external state (e.g.
		`ViceVersaState`'s save file) changes between recording and later playback - see
		`GameMode.saveReplayData`'s doc comment. Called once, at the moment a level is finished. */
	public function captureModeData(gameMode:GameMode) {
		var out = new haxe.io.BytesOutput();
		gameMode.saveReplayData(out);
		this.savedModeData = out.getBytes();
	}

	public function new(mission:String, customId:Int = 0) {
		this.mission = mission;
		this.customId = customId;
		this.initialState = new ReplayInitialState();
	}

	public function startFrame() {
		recordingActive = true;
		// One-shot fields need an explicit reset every tick, matching what a fresh `new ReplayFrame()`
		// used to give for free - continuous fields (position, camera, input, ...) don't, since every
		// `recordXXX` for those is called unconditionally each tick anyway.
		recordScratch.marbleStateFlags = new EnumFlags();
		recordScratch.gravityChange = false;
		recordScratch.powerupPickup = null;
	}

	public function endFrame() {
		if (!recordingActive)
			return;
		recordingActive = false;
		// Do not record frames beyond par time/10 minutes to limit file size, if we aren't explicitly recording
		if (!MarbleGame.instance.toRecord && recordScratch.clockTime > Math.min(600, MarbleGame.instance.world.mission.qualifyTime))
			return;
		frameData.push(recordScratch.time);
		frameData.push(recordScratch.clockTime);
		frameData.push(recordScratch.bonusTime);
		frameData.push(recordScratch.marblePosition.x);
		frameData.push(recordScratch.marblePosition.y);
		frameData.push(recordScratch.marblePosition.z);
		frameData.push(recordScratch.marbleVelocity.x);
		frameData.push(recordScratch.marbleVelocity.y);
		frameData.push(recordScratch.marbleVelocity.z);
		frameData.push(recordScratch.marbleOrientation.x);
		frameData.push(recordScratch.marbleOrientation.y);
		frameData.push(recordScratch.marbleOrientation.z);
		frameData.push(recordScratch.marbleOrientation.w);
		frameData.push(recordScratch.marbleAngularVelocity.x);
		frameData.push(recordScratch.marbleAngularVelocity.y);
		frameData.push(recordScratch.marbleAngularVelocity.z);
		frameData.push(recordScratch.marbleStateFlags.toInt());
		frameData.push(recordScratch.cameraPitch);
		frameData.push(recordScratch.cameraYaw);
		frameData.push(recordScratch.marbleX);
		frameData.push(recordScratch.marbleY);
		frameData.push(recordScratch.powerupHeld ? 1 : 0);
		frameData.push(recordScratch.gravity.x);
		frameData.push(recordScratch.gravity.y);
		frameData.push(recordScratch.gravity.z);
		frameData.push(recordScratch.gravityInstant ? 1 : 0);
		frameData.push(recordScratch.gravityChange ? 1 : 0);
		// Explicitly clear (not just conditionally set) so a frame index that's being re-recorded
		// after a `spliceReplay` doesn't inherit a stale pickup from whatever used to occupy this slot.
		if (recordScratch.powerupPickup != null)
			powerupPickups.set(frameCount, recordScratch.powerupPickup);
		else
			powerupPickups.remove(frameCount);
		frameCount++;
	}

	public function recordTimeState(time:Float, clockTime:Float, bonusTime:Float) {
		if (!recordingActive)
			return;
		recordScratch.time = time;
		recordScratch.clockTime = clockTime;
		recordScratch.bonusTime = bonusTime;
	}

	public function recordMarbleState(position:Vector, velocity:Vector, orientation:Quat, angularVelocity:Vector) {
		if (!recordingActive)
			return;
		recordScratch.marblePosition.x = position.x;
		recordScratch.marblePosition.y = position.y;
		recordScratch.marblePosition.z = position.z;
		recordScratch.marbleVelocity.x = velocity.x;
		recordScratch.marbleVelocity.y = velocity.y;
		recordScratch.marbleVelocity.z = velocity.z;
		recordScratch.marbleOrientation.x = orientation.x;
		recordScratch.marbleOrientation.y = orientation.y;
		recordScratch.marbleOrientation.z = orientation.z;
		recordScratch.marbleOrientation.w = orientation.w;
		recordScratch.marbleAngularVelocity.x = angularVelocity.x;
		recordScratch.marbleAngularVelocity.y = angularVelocity.y;
		recordScratch.marbleAngularVelocity.z = angularVelocity.z;
	}

	public function recordMarbleStateFlags(jumped:Bool, usedPowerup:Bool, instantTeleport:Bool, usedBlast:Bool) {
		if (!recordingActive)
			return;
		if (jumped)
			recordScratch.marbleStateFlags.set(Jumped);
		if (usedPowerup)
			recordScratch.marbleStateFlags.set(UsedPowerup);
		if (instantTeleport)
			recordScratch.marbleStateFlags.set(InstantTeleport);
		if (usedBlast)
			recordScratch.marbleStateFlags.set(UsedBlast);
	}

	public function recordPowerupPickup(powerup:PowerUp) {
		if (!recordingActive)
			return;
		if (powerup == null)
			recordScratch.powerupPickup = ""; // Use powerup
		else
			recordScratch.powerupPickup = powerup.dtsPath;
	}

	public function recordMarbleInput(x:Float, y:Float, powerupHeld:Bool = false) {
		if (!recordingActive)
			return;
		recordScratch.marbleX = x;
		recordScratch.marbleY = y;
		recordScratch.powerupHeld = powerupHeld;
	}

	public function recordCameraState(pitch:Float, yaw:Float) {
		if (!recordingActive)
			return;
		recordScratch.cameraPitch = pitch;
		recordScratch.cameraYaw = yaw;
	}

	public function recordGravity(gravity:Vector, instant:Bool) {
		if (!recordingActive)
			return;
		recordScratch.gravityChange = true;
		recordScratch.gravity.x = gravity.x;
		recordScratch.gravity.y = gravity.y;
		recordScratch.gravity.z = gravity.z;
		if (instant)
			recordScratch.gravityInstant = instant;
	}

	public function recordTrapdoorState(lastContactTime:Float, lastDirection:Int, lastCompletion:Float) {
		initialState.trapdoorLastContactTimes.push(lastContactTime);
		initialState.trapdoorLastDirections.push(lastDirection);
		initialState.trapdoorLastCompletions.push(lastCompletion);
	}

	public function recordLandMineState(disappearTime:Float) {
		initialState.landMineDisappearTimes.push(disappearTime);
	}

	public function recordPushButtonState(lastContactTime:Float) {
		initialState.pushButtonContactTimes.push(lastContactTime);
	}

	public function recordRandomGenState(ri:Int) {
		initialState.randomGens.push(ri);
		initialState.randomGenTimes.push(recordScratch.time);
	}

	public function getRandomGenState() {
		return initialState.randomGens.shift();
	}

	public function recordRandomFloatState(rf:Float) {
		initialState.randomFloats.push(rf);
		initialState.randomFloatTimes.push(recordScratch.time);
	}

	public function getRandomFloatState() {
		return initialState.randomFloats.shift();
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

	public function getPushButtonState(idx:Int) {
		return initialState.pushButtonContactTimes[idx];
	}

	public function clear() {
		this.frameData = [];
		this.frameCount = 0;
		this.powerupPickups = new Map();
		this.initialState.randomGens = [];
		this.initialState.randomGenTimes = [];
		this.initialState.randomFloats = [];
		this.initialState.randomFloatTimes = [];
		this.recordingActive = false;
	}

	/** Decodes recorded frame `i` into `target`, mutating its fields in place (never allocates a new
		`Vector`/`Quat`). */
	function decodeFrameInto(i:Int, target:ReplayFrame) {
		var o = i * STRIDE;
		target.time = frameData[o + OFF_TIME];
		target.clockTime = frameData[o + OFF_CLOCK];
		target.bonusTime = frameData[o + OFF_BONUS];
		target.marblePosition.x = frameData[o + OFF_POS];
		target.marblePosition.y = frameData[o + OFF_POS + 1];
		target.marblePosition.z = frameData[o + OFF_POS + 2];
		target.marbleVelocity.x = frameData[o + OFF_VEL];
		target.marbleVelocity.y = frameData[o + OFF_VEL + 1];
		target.marbleVelocity.z = frameData[o + OFF_VEL + 2];
		target.marbleOrientation.x = frameData[o + OFF_ORIENT];
		target.marbleOrientation.y = frameData[o + OFF_ORIENT + 1];
		target.marbleOrientation.z = frameData[o + OFF_ORIENT + 2];
		target.marbleOrientation.w = frameData[o + OFF_ORIENT + 3];
		target.marbleAngularVelocity.x = frameData[o + OFF_ANGVEL];
		target.marbleAngularVelocity.y = frameData[o + OFF_ANGVEL + 1];
		target.marbleAngularVelocity.z = frameData[o + OFF_ANGVEL + 2];
		target.marbleStateFlags = EnumFlags.ofInt(Std.int(frameData[o + OFF_FLAGS]));
		target.cameraPitch = frameData[o + OFF_CAM_PITCH];
		target.cameraYaw = frameData[o + OFF_CAM_YAW];
		target.marbleX = frameData[o + OFF_MARBLE_X];
		target.marbleY = frameData[o + OFF_MARBLE_Y];
		target.powerupHeld = frameData[o + OFF_POWERUP_HELD] != 0;
		target.gravityChange = frameData[o + OFF_GRAVITY_CHANGE] != 0;
		target.gravity.x = frameData[o + OFF_GRAVITY];
		target.gravity.y = frameData[o + OFF_GRAVITY + 1];
		target.gravity.z = frameData[o + OFF_GRAVITY + 2];
		target.gravityInstant = frameData[o + OFF_GRAVITY_INSTANT] != 0;
		target.powerupPickup = powerupPickups.get(i);
	}

	/** Same math as the original `ReplayFrame.interpolate`, just writing into a persistent `out`
		instead of allocating+returning a new frame - see class doc comment. */
	function interpolateInto(a:ReplayFrame, b:ReplayFrame, time:Float, out:ReplayFrame) {
		var t = (time - a.time) / (b.time - a.time);
		var dt = time - a.time;
		var clockDt = b.clockTime - a.clockTime;

		out.time = time;
		out.bonusTime = a.bonusTime;
		out.clockTime = a.clockTime;
		if (clockDt > 0) {
			if (out.bonusTime != 0 && time >= 3.5) {
				if (dt <= a.bonusTime) {
					out.bonusTime -= dt;
				} else {
					out.clockTime += dt - a.bonusTime;
					out.bonusTime = 0;
				}
			} else {
				if (a.time >= 3.5)
					out.clockTime += dt;
				else if (a.time + dt >= 3.5) {
					out.clockTime += (a.time + dt) - 3.5;
				}
			}
		}

		var teleport = a.marbleStateFlags.has(InstantTeleport);
		if (teleport) {
			out.marblePosition.x = a.marblePosition.x;
			out.marblePosition.y = a.marblePosition.y;
			out.marblePosition.z = a.marblePosition.z;
			out.marbleVelocity.x = a.marbleVelocity.x;
			out.marbleVelocity.y = a.marbleVelocity.y;
			out.marbleVelocity.z = a.marbleVelocity.z;
			out.marbleOrientation.x = a.marbleOrientation.x;
			out.marbleOrientation.y = a.marbleOrientation.y;
			out.marbleOrientation.z = a.marbleOrientation.z;
			out.marbleOrientation.w = a.marbleOrientation.w;
			out.marbleAngularVelocity.x = a.marbleAngularVelocity.x;
			out.marbleAngularVelocity.y = a.marbleAngularVelocity.y;
			out.marbleAngularVelocity.z = a.marbleAngularVelocity.z;
			out.cameraYaw = a.cameraYaw;
			out.cameraPitch = a.cameraPitch;
		} else {
			out.marblePosition.x = a.marblePosition.x + (b.marblePosition.x - a.marblePosition.x) * t;
			out.marblePosition.y = a.marblePosition.y + (b.marblePosition.y - a.marblePosition.y) * t;
			out.marblePosition.z = a.marblePosition.z + (b.marblePosition.z - a.marblePosition.z) * t;
			out.marbleVelocity.x = a.marbleVelocity.x + (b.marbleVelocity.x - a.marbleVelocity.x) * t;
			out.marbleVelocity.y = a.marbleVelocity.y + (b.marbleVelocity.y - a.marbleVelocity.y) * t;
			out.marbleVelocity.z = a.marbleVelocity.z + (b.marbleVelocity.z - a.marbleVelocity.z) * t;
			out.marbleOrientation.slerp(a.marbleOrientation, b.marbleOrientation, t);
			out.marbleOrientation.normalize();
			out.marbleAngularVelocity.x = a.marbleAngularVelocity.x + (b.marbleAngularVelocity.x - a.marbleAngularVelocity.x) * t;
			out.marbleAngularVelocity.y = a.marbleAngularVelocity.y + (b.marbleAngularVelocity.y - a.marbleAngularVelocity.y) * t;
			out.marbleAngularVelocity.z = a.marbleAngularVelocity.z + (b.marbleAngularVelocity.z - a.marbleAngularVelocity.z) * t;
			out.cameraYaw = Util.lerp(a.cameraYaw, b.cameraYaw, t);
			out.cameraPitch = Util.lerp(a.cameraPitch, b.cameraPitch, t);
		}

		out.marbleStateFlags = EnumFlags.ofInt(0);
		if (teleport)
			out.marbleStateFlags.set(InstantTeleport);
		if (a.marbleStateFlags.has(UsedPowerup))
			out.marbleStateFlags.set(UsedPowerup);
		if (a.marbleStateFlags.has(Jumped))
			out.marbleStateFlags.set(Jumped);
		if (a.marbleStateFlags.has(UsedBlast))
			out.marbleStateFlags.set(UsedBlast);

		out.marbleX = a.marbleX;
		out.marbleY = a.marbleY;
		out.powerupHeld = a.powerupHeld;

		out.gravityChange = false;
		if (a.gravityChange) {
			out.gravity.x = a.gravity.x;
			out.gravity.y = a.gravity.y;
			out.gravity.z = a.gravity.z;
			out.gravityInstant = a.gravityInstant;
			out.gravityChange = true;
		}
		if (b.gravityChange) {
			out.gravity.x = b.gravity.x;
			out.gravity.y = b.gravity.y;
			out.gravity.z = b.gravity.z;
			out.gravityInstant = b.gravityInstant;
			out.gravityChange = true;
		}

		out.powerupPickup = a.powerupPickup;
	}

	public function advance(dt:Float) {
		if (this.currentPlaybackFrameIdx + 1 >= this.frameCount)
			return false;

		decodeFrameInto(this.currentPlaybackFrameIdx, playbackFrameA);
		var nextT = this.currentPlaybackTime + dt;
		decodeFrameInto(this.currentPlaybackFrameIdx + 1, playbackFrameB);

		var stateFlags = 0;
		var nextGravityChange = false;
		var nextGravityInstant = false;
		var nextGravityX = 0.0;
		var nextGravityY = 0.0;
		var nextGravityZ = 0.0;
		var powerup:String = null;

		while (playbackFrameB.time <= nextT) {
			this.currentPlaybackFrameIdx++;
			if (this.currentPlaybackFrameIdx + 1 >= this.frameCount)
				return false;
			// The "next" frame we just examined becomes the new "start" frame - swap the scratch
			// references instead of decoding it a second time.
			var tmp = playbackFrameA;
			playbackFrameA = playbackFrameB;
			playbackFrameB = tmp;
			decodeFrameInto(this.currentPlaybackFrameIdx + 1, playbackFrameB);

			stateFlags |= playbackFrameB.marbleStateFlags.toInt();
			if (playbackFrameB.gravityChange) {
				nextGravityChange = true;
				nextGravityInstant = playbackFrameB.gravityInstant;
				nextGravityX = playbackFrameB.gravity.x;
				nextGravityY = playbackFrameB.gravity.y;
				nextGravityZ = playbackFrameB.gravity.z;
			}
			if (playbackFrameB.powerupPickup != null) {
				powerup = playbackFrameB.powerupPickup;
			}
		}
		playbackFrameB.marbleStateFlags = EnumFlags.ofInt(stateFlags);
		if (nextGravityChange) {
			playbackFrameB.gravityChange = true;
			playbackFrameB.gravityInstant = nextGravityInstant;
			playbackFrameB.gravity.x = nextGravityX;
			playbackFrameB.gravity.y = nextGravityY;
			playbackFrameB.gravity.z = nextGravityZ;
		}
		if (powerup != null) {
			playbackFrameB.powerupPickup = powerup;
		}

		interpolateInto(playbackFrameA, playbackFrameB, nextT, this.currentPlaybackFrame);
		this.currentPlaybackTime += dt;
		return true;
	}

	public function rewind() {
		this.currentPlaybackTime = 0;
		this.currentPlaybackFrameIdx = 0;
	}

	public function spliceReplay(cutAfterTime:Float) {
		while (frameCount > 0 && frameData[(frameCount - 1) * STRIDE + OFF_TIME] > cutAfterTime) {
			frameCount--;
		}
		if (this.initialState.randomGenTimes.length > 0) {
			var rtimeIdx = this.initialState.randomGenTimes.length - 1;
			while (this.initialState.randomGenTimes[rtimeIdx] > cutAfterTime && this.initialState.randomGenTimes.length > 0) {
				this.initialState.randomGenTimes.pop();
				this.initialState.randomGens.pop();
				rtimeIdx = this.initialState.randomGenTimes.length - 1;
			}
		}
		if (this.initialState.randomFloatTimes.length > 0) {
			var ftimeIdx = this.initialState.randomFloatTimes.length - 1;
			while (this.initialState.randomFloatTimes[ftimeIdx] > cutAfterTime && this.initialState.randomFloatTimes.length > 0) {
				this.initialState.randomFloatTimes.pop();
				this.initialState.randomFloats.pop();
				ftimeIdx = this.initialState.randomFloatTimes.length - 1;
			}
		}
	}

	public function write() {
		var bw = new BytesWriter();

		this.initialState.write(bw);
		// Once per recording (not per-frame) - see `captureModeData`'s doc comment for why this reads
		// the already-captured bytes rather than pulling from a `GameMode` here.
		var modeBytes = this.savedModeData != null ? this.savedModeData : haxe.io.Bytes.alloc(0);
		bw.writeInt32(modeBytes.length);
		@:privateAccess bw.bytes.addBytes(modeBytes, 0, modeBytes.length);
		bw.writeInt32(this.frameCount);
		for (i in 0...frameCount) {
			var o = i * STRIDE;
			bw.writeFloat(frameData[o + OFF_TIME]);
			bw.writeFloat(frameData[o + OFF_CLOCK]);
			bw.writeFloat(frameData[o + OFF_BONUS]);
			bw.writeFloat(frameData[o + OFF_POS]);
			bw.writeFloat(frameData[o + OFF_POS + 1]);
			bw.writeFloat(frameData[o + OFF_POS + 2]);
			bw.writeFloat(frameData[o + OFF_VEL]);
			bw.writeFloat(frameData[o + OFF_VEL + 1]);
			bw.writeFloat(frameData[o + OFF_VEL + 2]);
			bw.writeFloat(frameData[o + OFF_ORIENT]);
			bw.writeFloat(frameData[o + OFF_ORIENT + 1]);
			bw.writeFloat(frameData[o + OFF_ORIENT + 2]);
			bw.writeFloat(frameData[o + OFF_ORIENT + 3]);
			bw.writeFloat(frameData[o + OFF_ANGVEL]);
			bw.writeFloat(frameData[o + OFF_ANGVEL + 1]);
			bw.writeFloat(frameData[o + OFF_ANGVEL + 2]);
			bw.writeByte(Std.int(frameData[o + OFF_FLAGS]));
			bw.writeFloat(frameData[o + OFF_CAM_PITCH]);
			bw.writeFloat(frameData[o + OFF_CAM_YAW]);
			bw.writeFloat(frameData[o + OFF_MARBLE_X]);
			bw.writeFloat(frameData[o + OFF_MARBLE_Y]);
			bw.writeByte(Std.int(frameData[o + OFF_POWERUP_HELD]));
			if (frameData[o + OFF_GRAVITY_CHANGE] != 0) {
				bw.writeByte(1);
				bw.writeFloat(frameData[o + OFF_GRAVITY]);
				bw.writeFloat(frameData[o + OFF_GRAVITY + 1]);
				bw.writeFloat(frameData[o + OFF_GRAVITY + 2]);
				bw.writeByte(Std.int(frameData[o + OFF_GRAVITY_INSTANT]));
			} else {
				bw.writeByte(0);
			}
			var pickup = powerupPickups.get(i);
			if (pickup != null) {
				bw.writeByte(1);
				bw.writeStr(pickup);
			} else {
				bw.writeByte(0);
			}
		}

		var buf = bw.getBuffer();
		var bufsize = buf.length;
		#if hl
		var compressed = haxe.zip.Compress.run(bw.getBuffer(), 9);
		#end
		#if js
		var stream = zip.DeflateStream.create(zip.DeflateStream.CompressionLevel.GOOD, true);
		stream.write(new BytesInput(bw.getBuffer()));
		var compressed = stream.finalize();
		#end

		if (this.name == null)
			this.name = this.mission;

		var finalB = new BytesBuffer();
		finalB.addByte(version);
		finalB.addByte(this.name.length);
		finalB.addString(this.name);
		finalB.addByte(this.mission.length);
		finalB.addString(this.mission);
		finalB.addInt32(this.customId);
		finalB.addInt32(bufsize);
		finalB.addBytes(compressed, 0, compressed.length);

		return finalB.getBytes();
	}

	/** Hands `modeData` (decoded standalone by `read()`, before any mission/`GameMode` existed) to
		the now-loaded mission's actual `GameMode` - call once, after the mission has finished
		loading, when about to watch this replay. No-op if this replay predates version 9 or its mode
		wrote nothing. */
	public function applyModeData(level:MarbleWorld) {
		if (this.modeData != null)
			level.gameMode.loadReplayData(new BytesInput(this.modeData));
	}

	public function read(data:Bytes) {
		Console.log("Loading replay");
		var replayVersion = data.get(0);
		if (replayVersion > version) {
			Console.log("Replay loading failed: unknown version");
			return false;
		}
		if (replayVersion < 5) { // first version with headers
			Console.log('Replay loading failed: version ${replayVersion} does not have a header');
			return false;
		}
		var nameLength = data.get(1);
		this.name = data.getString(2, nameLength);
		var missionLength = data.get(2 + nameLength);
		this.mission = data.getString(3 + nameLength, missionLength);
		var uncompressedLength = 0;
		var compressedData:haxe.io.Bytes = null;
		if (replayVersion > 5) {
			this.customId = data.getInt32(3 + nameLength + missionLength);
			uncompressedLength = data.getInt32(7 + nameLength + missionLength);
			compressedData = data.sub(11 + nameLength + missionLength, data.length - 11 - nameLength - missionLength);
		} else {
			uncompressedLength = data.getInt32(3 + nameLength + missionLength);
			compressedData = data.sub(7 + nameLength + missionLength, data.length - 7 - nameLength - missionLength);
		}

		#if hl
		var uncompressed = haxe.zip.Uncompress.run(compressedData, uncompressedLength);
		#end
		#if js
		var uncompressed = haxe.zip.InflateImpl.run(new BytesInput(compressedData), uncompressedLength);
		#end
		var br = new BytesReader(uncompressed);
		this.initialState.read(br, replayVersion);
		if (replayVersion > 8) {
			var modeLen = br.readInt32();
			this.modeData = modeLen > 0 ? @:privateAccess br.bytes.sub(br.tell(), modeLen) : null;
			br.seek(br.tell() + modeLen);
		} else {
			this.modeData = null;
		}
		var count = br.readInt32();
		this.frameData = [];
		this.powerupPickups = new Map();
		for (i in 0...count) {
			frameData.push(br.readFloat()); // time
			frameData.push(br.readFloat()); // clockTime
			frameData.push(br.readFloat()); // bonusTime
			frameData.push(br.readFloat()); // pos.x
			frameData.push(br.readFloat()); // pos.y
			frameData.push(br.readFloat()); // pos.z
			frameData.push(br.readFloat()); // vel.x
			frameData.push(br.readFloat()); // vel.y
			frameData.push(br.readFloat()); // vel.z
			frameData.push(br.readFloat()); // orient.x
			frameData.push(br.readFloat()); // orient.y
			frameData.push(br.readFloat()); // orient.z
			frameData.push(br.readFloat()); // orient.w
			frameData.push(br.readFloat()); // angvel.x
			frameData.push(br.readFloat()); // angvel.y
			frameData.push(br.readFloat()); // angvel.z
			frameData.push(br.readByte()); // stateFlags
			frameData.push(br.readFloat()); // cameraPitch
			frameData.push(br.readFloat()); // cameraYaw
			frameData.push(br.readFloat()); // marbleX
			frameData.push(br.readFloat()); // marbleY
			// Added in version 7 - older replay files simply never had cannon/bubble hold-input recorded.
			frameData.push(replayVersion > 6 ? br.readByte() : 0); // powerupHeld
			if (br.readByte() == 1) {
				frameData.push(br.readFloat()); // gravity.x
				frameData.push(br.readFloat()); // gravity.y
				frameData.push(br.readFloat()); // gravity.z
				frameData.push(br.readByte()); // gravityInstant
				frameData.push(1); // gravityChange
			} else {
				frameData.push(0);
				frameData.push(0);
				frameData.push(0);
				frameData.push(0);
				frameData.push(0);
			}
			if (br.readByte() == 1) {
				powerupPickups.set(i, br.readStr());
			}
		}
		this.frameCount = count;
		return true;
	}

	public function readHeader(data:Bytes, fe:FileEntry) {
		this.readFullEntry = fe;
		Console.log("Loading replay");
		var replayVersion = data.get(0);
		if (replayVersion > version) {
			Console.log("Replay loading failed: unknown version");
			return false;
		}
		if (replayVersion < 5) { // first version with headers
			Console.log('Replay loading failed: version ${replayVersion} does not have a header');
			return false;
		}
		var nameLength = data.get(1);
		this.name = data.getString(2, nameLength);
		var missionLength = data.get(2 + nameLength);
		this.mission = data.getString(3 + nameLength, missionLength);
		if (replayVersion > 5) {
			this.customId = data.getInt32(3 + nameLength + missionLength);
		}
		return true;
	}

	public function readFull() {
		if (readFullEntry != null)
			return read(readFullEntry.getBytes());
		return false;
	}
}
