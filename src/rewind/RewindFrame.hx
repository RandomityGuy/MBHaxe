package rewind;

import haxe.io.BytesOutput;
import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import dif.io.BytesWriter;
import mis.MissionElement.MissionElementBase;
import triggers.CheckpointTrigger;
import src.PathedInterior.PIState;
import src.GameObjectPathFollower.PathFollowerSaveState;
import shapes.PowerUp;
import h3d.Vector;
import h3d.Quat;
import src.TimeState;
import src.DtsObject;
import shapes.Gem;

@:publicFields
class RewindMPState {
	var currentTime:Float;
	var targetTime:Float;
	var stoppedPosition:Vector;
	var prevPosition:Vector;
	var position:Vector;
	var velocity:Vector;

	public function new() {
		prevPosition = new Vector();
		position = new Vector();
		velocity = new Vector();
	}
}

/** Reusable mutable snapshot of a `Trapdoor`'s progress - was an anonymous struct, reallocated
	fresh per object per tick; now a plain class so `RewindManager.recordFrame`/`RewindFrame.
	deserialize` can pool and mutate instances in place instead (see
	[No Anonymous Structs](feedback_no_anonymous_structs.md), and
	[PQ Port Status](pq-port-status.md)'s rewind-optimization entry). */
@:publicFields
class TrapdoorSaveState {
	var lastContactTime:Float;
	var lastDirection:Int;
	var lastCompletion:Float;

	public function new() {}
}

/** Same idea as `TrapdoorSaveState`, for `FadePlatform`. */
@:publicFields
class FadePlatformSaveState {
	var lastContactTime:Float;
	var fadingState:Int;
	var lastFadingContactTime:Float;

	public function new() {}
}

/** Same idea as `TrapdoorSaveState`, for `MegaManPlatform`. */
@:publicFields
class MegaManPlatformSaveState {
	var showTime:Float;
	var hasCollided:Bool;
	var respondToCollision:Bool;
	var queuedNext:Bool;

	public function new() {}
}

/** Same idea as `TrapdoorSaveState`, for `RepetitiveTriggerGotoTarget`'s `triggered`/`enterCount`
	"triggered-once gate" state - the same bug class `PathTrigger.triggered` had (see its doc
	comment), fixed the same way. */
@:publicFields
class RepetitiveTriggerSaveState {
	var triggered:Bool;
	var enterCount:Int;

	public function new() {}
}

/** `CountdownStartTrigger.activated` has the same "triggered-once gate" bug class as
	`RepetitiveTriggerGotoTarget`/`PathTrigger`; `pendingStartTime`/`pendingTime`/`pendingIcon` are
	the (also genuinely per-tick, not self-healing) state backing its `startDelay` countdown, which
	used to be a `level.schedule()` callback - converting that to a plain per-tick check
	(`CountdownStartTrigger.update`) means this state now needs the same explicit rewind snapshot
	any other mutable-per-tick field gets. */
@:publicFields
class CountdownTriggerSaveState {
	var activated:Bool;
	var pendingStartTime:Float;
	var pendingTime:Float;
	var pendingIcon:String;

	public function new() {
		pendingIcon = "";
	}
}

@:publicFields
class RewindFrame {
	var timeState:TimeState;
	var marblePosition:Vector;
	var marbleOrientation:Quat;
	var marbleVelocity:Vector;
	var marbleAngularVelocity:Vector;
	var marblePowerup:PowerUp;
	var bonusTime:Float;
	var collectedBonusTime:Float;
	var mpStates:Array<RewindMPState>;
	var gemCount:Int;
	var gemStates:Array<Bool>;
	var powerupStates:Array<Float>;
	var landMineStates:Array<Float>;
	var activePowerupStates:Array<Float>;
	var currentUp:Vector;
	var trapdoorStates:Array<TrapdoorSaveState>;
	var fadePlatformStates:Array<FadePlatformSaveState>;
	var megaManPlatformStates:Array<MegaManPlatformSaveState>;
	var lastContactNormal:Vector;
	var blastAmt:Float;
	var marbleRadius:Float;
	var movementTriggerCount:Int;
	var toggleButtonStates:Array<Bool>;
	var teleporterArmed:Bool;
	var teleporterSavedPosition:Vector;
	var teleporterSavedYaw:Float;
	var teleporterSavedPitch:Float;
	var teleporterSavedGravity:Vector;
	var teleporterKeepVelocity:Bool;
	var teleporterTeleTime:Float;
	var teleporterFiring:Bool;
	var teleporterFireStartTime:Float;
	var isFrozen:Bool;
	var lastFreezeTime:Float;
	var powerupLockCount:Int;
	var timeStopTriggerCount:Int;

	/** Water/Bubble state - `waterTriggers`/`isInWater` can't just self-heal from the collision
		system on the next tick after a rewind (unlike e.g. `onOutOfBounds`-triggered flows), since
		`WaterPhysicsTrigger.onMarbleEnter`/`onMarbleLeave` only fire on a fresh overlap transition,
		not every tick the marble happens to already be inside one - a rewind can restore a frame
		where the marble is mid-submersion without ever re-triggering that enter event. Whether the
		"water"/"bubble" physics layers are currently pushed isn't snapshotted directly - it's
		re-derived from `isInWater`/`bubbleActive` on `applyFrame` (the override values themselves
		are fixed constants, not marble-instance data, so there's nothing instance-specific to lose
		by re-pushing a fresh layer instead of restoring the exact old array reference). */
	var isInWater:Bool;

	var waterTriggers:Array<triggers.WaterPhysicsTrigger>;
	var bubbleTime:Float;
	var bubbleTotalTime:Float;
	var bubbleInfinite:Bool;
	var bubbleActive:Bool;

	/** Fireball PowerUp state - mirrors the Bubble fields above. `fireball` can't self-heal on
		rewind either (there's no per-tick "am I still on fire" re-derivation, unlike a trigger-set
		flag), so it's snapshotted directly like `bubbleActive`. */
	var fireball:Bool;

	var fireballTime:Float;
	var fireballTotalTime:Float;
	var fireballLastBlastTime:Float;

	/** Cannon containment state (`src.shapes.Cannon`) - `cannonFrozenLayer`/`cannonControlLockLayer`
		themselves aren't snapshotted (same reasoning as `waterPhysicsLayer`/`bubblePhysicsLayer`
		above - re-derived fresh from these plain fields on apply, since the override values are
		fixed constants). */
	var activeCannon:shapes.Cannon;

	var cannonCharge:Float;
	var lastCannon:shapes.Cannon;
	var cannonReenableTime:Float;
	var cannonControlLockUntil:Float;
	var cannonCameraLockUntil:Float;
	var instantCannonFireTime:Float;

	/** Index-aligned with `level.iceShards`, mirrors `gemStates`. */
	var iceShardStates:Array<Bool>;

	/** Also index-aligned with `level.iceShards` - see `IceShard.gotoTargetTriggered`'s doc comment. */
	var iceShardGotoTargetStates:Array<Bool>;

	/** Index-aligned with `level.respawningTimeTravels`, mirrors `iceShardStates` - see
		`shapes.TimeTravel.respawnCount`'s doc comment. */
	var respawningTimeTravelStates:Array<Int>;

	/** HUD countdown timer state (`MarbleWorld.startCountdown`/`stopCountdown`,
		`CountdownStartTrigger`/`CountdownStopTrigger`) - unlike most HUD-driving state elsewhere in
		this file, `countdownRemaining` is a genuine per-tick accumulator (decremented by `dt` each
		frame in `updateTimer`, not re-derived from a fixed start timestamp), so it can't self-heal
		after a rewind and must be snapshotted directly like any other mutable scalar. */
	var countdownActive:Bool;

	var countdownRemaining:Float;
	var countdownIcon:String;

	/** Index-aligned with `level.triggers.filter(x -> x is triggers.PathTrigger)` - mirrors
		`gemStates`/`iceShardStates`. See `triggers.PathTrigger.triggered`'s doc comment. */
	var pathTriggerStates:Array<Bool>;

	/** Index-aligned with iterating `level.pathedInteriors` then each one's own nested
		`triggers` array, filtered to `RepetitiveTriggerGotoTarget` instances - these live nested
		inside their owning `PathedInterior.triggers`, not `level.triggers`, but that nesting is
		built once at load and never mutated afterward, so (unlike `PathTrigger`'s `movingObjects`)
		no pre-scan/stable-registration step is needed for this to stay positionally aligned. */
	var repetitiveTriggerStates:Array<RepetitiveTriggerSaveState>;

	/** Index-aligned with `level.triggers.filter(x -> x is triggers.CountdownStartTrigger)`. */
	var countdownTriggerStates:Array<CountdownTriggerSaveState>;

	/** Ported from the `mbu-port` branch's design - whichever `GameMode` (or `CompositeMode` of
		several) is active supplies one of these via `getRewindState()`/`constructRewindState()`,
		rather than `RewindFrame` growing a flat field per mode regardless of which mode is active. */
	var modeState:RewindableState;

	/** Path-follower progress, index-aligned with `level.movingObjects` filtered to non-
		`PathedInterior` entries (i.e. path-following `GameObject`s) - see
		`RewindManager.recordFrame`/`applyFrame`. Parent-followers need no rewind state at all,
		they're a pure function of their parent's current transform every tick. */
	var pathFollowerStates:Array<PathFollowerSaveState>;

	var oobState:{
		oob:Bool,
		timeState:TimeState
	};

	var checkpointState:{
		currentCheckpoint:{obj:DtsObject, elem:MissionElementBase},
		currentCheckpointTrigger:CheckpointTrigger,
		checkpointCollectedGems:Map<Gem, Bool>,
		checkpointHeldPowerup:PowerUp,
		checkpointUp:Vector,
		checkpointBlast:Float
	};

	/** Every container field is allocated exactly once here, then mutated/refilled in place for the
		rest of this instance's life - `RewindManager` keeps exactly one persistent `RewindFrame` for
		recording and one for reading/applying (rather than `new RewindFrame()` every tick), so this
		constructor's allocations only happen twice total per `RewindManager`, not once per frame.
		`clone()` no longer exists - nothing ever kept a live `RewindFrame` around long enough to need
		copying one (recording immediately serializes and discards; reading immediately applies and
		discards - see `RewindManager.recordFrame`/`getFrameAtIndex`), so it was dead code. */
	public function new() {
		timeState = new TimeState();
		marblePosition = new Vector();
		marbleOrientation = new Quat();
		marbleVelocity = new Vector();
		marbleAngularVelocity = new Vector();
		currentUp = new Vector();
		lastContactNormal = new Vector();
		teleporterSavedPosition = new Vector();
		teleporterSavedGravity = new Vector();
		gemStates = [];
		powerupStates = [];
		landMineStates = [];
		activePowerupStates = [0.0, 0.0, 0.0, 0.0];
		mpStates = [];
		trapdoorStates = [];
		fadePlatformStates = [];
		megaManPlatformStates = [];
		toggleButtonStates = [];
		waterTriggers = [];
		iceShardStates = [];
		iceShardGotoTargetStates = [];
		respawningTimeTravelStates = [];
		countdownIcon = "";
		pathTriggerStates = [];
		repetitiveTriggerStates = [];
		countdownTriggerStates = [];
		pathFollowerStates = [];
		oobState = {oob: false, timeState: null};
		checkpointState = {
			currentCheckpoint: null,
			currentCheckpointTrigger: null,
			checkpointCollectedGems: new Map<Gem, Bool>(),
			checkpointHeldPowerup: null,
			checkpointUp: null,
			checkpointBlast: 0.0
		};
	}

	/** Grows `arr` to `n` elements (appending freshly-`make()`d instances) or shrinks it down to
		`n` - called every frame against a persistent array, so it only actually allocates the first
		time a given count is reached, never again after (the count of trapdoors/buttons/path
		followers/etc. in a level is fixed once loaded). */
	public static function syncLength<T>(arr:Array<T>, n:Int, make:Void->T) {
		while (arr.length < n)
			arr.push(make());
		if (arr.length > n)
			arr.resize(n);
	}

	public inline function serialize(rm:RewindManager) {
		var bb = new BytesOutput();
		var framesize = 0;
		framesize += 32; // timeState
		framesize += 24; // marblePosition
		framesize += 32; // marbleOrientation
		framesize += 24; // marbleVelocity
		framesize += 24; // marbleAngularVelocity
		framesize += 2; // marblePowerup
		framesize += 8; // bonusTime
		framesize += 8; // collectedBonusTime
		framesize += 2; // gemCount
		framesize += 2 + gemStates.length * 1; // gemStates
		framesize += 2 + powerupStates.length * 8; // powerupStates
		framesize += 2 + landMineStates.length * 8; // landMineStates
		framesize += 32; // activePowerupStates
		framesize += 24; // currentUp
		framesize += 24; // lastContactNormal
		framesize += 2; // mpStates.length
		for (s in mpStates) {
			framesize += 8; // s.currentTime
			framesize += 8; // s.targetTime
			framesize += 1; // Null<s.stoppedPosition>
			if (s.stoppedPosition != null)
				framesize += 24; // s.stoppedPosition
			framesize += 24; // s.prevPosition
			framesize += 24; // s.position
			framesize += 24; // s.velocity
		}
		framesize += 2; // trapdoorStates.length
		for (s in trapdoorStates) {
			framesize += 8; // s.lastContactTime
			framesize += 1; // s.lastDirection
			framesize += 8; // s.lastCompletion
		}
		framesize += 2; // fadePlatformStates.length
		for (s in fadePlatformStates) {
			framesize += 8; // s.lastContactTime
			framesize += 2; // s.fadingState
			framesize += 8; // s.lastFadingContactTime
		}
		framesize += 2; // megaManPlatformStates.length
		for (s in megaManPlatformStates) {
			framesize += 8; // s.showTime
			framesize += 1; // s.hasCollided
			framesize += 1; // s.respondToCollision
			framesize += 1; // s.queuedNext
		}
		framesize += 8; // blastAmt
		framesize += 8; // marbleRadius
		framesize += 2; // movementTriggerCount
		framesize += 2 + toggleButtonStates.length * 1; // toggleButtonStates
		framesize += 1; // teleporterArmed
		framesize += 24; // teleporterSavedPosition
		framesize += 8; // teleporterSavedYaw
		framesize += 8; // teleporterSavedPitch
		framesize += 24; // teleporterSavedGravity
		framesize += 1; // teleporterKeepVelocity
		framesize += 8; // teleporterTeleTime
		framesize += 1; // teleporterFiring
		framesize += 8; // teleporterFireStartTime
		framesize += 1; // isFrozen
		framesize += 8; // lastFreezeTime
		framesize += 2; // powerupLockCount
		framesize += 2; // timeStopTriggerCount
		framesize += 1; // isInWater
		framesize += 2 + waterTriggers.length * 2; // waterTriggers
		framesize += 8; // bubbleTime
		framesize += 8; // bubbleTotalTime
		framesize += 1; // bubbleInfinite
		framesize += 1; // bubbleActive
		framesize += 1; // fireball
		framesize += 8; // fireballTime
		framesize += 8; // fireballTotalTime
		framesize += 8; // fireballLastBlastTime
		framesize += 2; // activeCannon
		framesize += 8; // cannonCharge
		framesize += 2; // lastCannon
		framesize += 8; // cannonReenableTime
		framesize += 8; // cannonControlLockUntil
		framesize += 8; // cannonCameraLockUntil
		framesize += 8; // instantCannonFireTime
		framesize += 2 + iceShardStates.length * 1; // iceShardStates
		framesize += 2 + iceShardGotoTargetStates.length * 1; // iceShardGotoTargetStates
		framesize += 2 + respawningTimeTravelStates.length * 1; // respawningTimeTravelStates
		framesize += 1; // countdownActive
		framesize += 8; // countdownRemaining
		framesize += 2 + countdownIcon.length; // countdownIcon
		framesize += 2 + pathTriggerStates.length * 1; // pathTriggerStates
		framesize += 2; // repetitiveTriggerStates.length
		for (s in repetitiveTriggerStates) {
			framesize += 1; // s.triggered
			framesize += 2; // s.enterCount
		}
		framesize += 2; // countdownTriggerStates.length
		for (s in countdownTriggerStates) {
			framesize += 1; // s.activated
			framesize += 8; // s.pendingStartTime
			framesize += 8; // s.pendingTime
			framesize += 2 + s.pendingIcon.length; // s.pendingIcon
		}
		framesize += 1; // Null<modeState>
		if (modeState != null)
			framesize += modeState.getSize();
		framesize += 2; // pathFollowerStates.length
		for (s in pathFollowerStates) {
			framesize += 1; // s.active
			if (s.active) {
				framesize += 8; // s.pathPosition
				framesize += 2 + s.currentNode.length; // s.currentNode
				framesize += 2 + s.prevNode.length; // s.prevNode
				framesize += 2; // s.rngCursor
			}
		}
		if (oobState.oob)
			framesize += 1; // oobState.oob
		framesize += 32; // oobState.timeState
		framesize += 1; // Null<checkpointState>
		if (checkpointState != null) {
			framesize += 4; // checkpointState.currentCheckpoint
		}
		framesize += 2; // checkpointState.currentCheckpointTrigger
		framesize += 2; // checkpointState.checkpointCollectedGems.length
		for (gem in checkpointState.checkpointCollectedGems.keys()) {
			framesize += 2; // gem
			framesize += 1; // checkpointState.checkpointCollectedGems[gem]
		}
		framesize += 2; // checkpointState.checkpointHeldPowerup
		framesize += 1; // Null<checkpointState.checkpointUp>
		if (checkpointState.checkpointUp != null)
			framesize += 24; // checkpointState.checkpointUp
		framesize += 8; // checkpointState.checkpointBlast
		bb.prepare(framesize);
		// Now actually write
		bb.writeDouble(timeState.currentAttemptTime);
		bb.writeDouble(timeState.timeSinceLoad);
		bb.writeDouble(timeState.gameplayClock);
		bb.writeDouble(timeState.dt);
		bb.writeDouble(marblePosition.x);
		bb.writeDouble(marblePosition.y);
		bb.writeDouble(marblePosition.z);
		bb.writeDouble(marbleOrientation.x);
		bb.writeDouble(marbleOrientation.y);
		bb.writeDouble(marbleOrientation.z);
		bb.writeDouble(marbleOrientation.w);
		bb.writeDouble(marbleVelocity.x);
		bb.writeDouble(marbleVelocity.y);
		bb.writeDouble(marbleVelocity.z);
		bb.writeDouble(marbleAngularVelocity.x);
		bb.writeDouble(marbleAngularVelocity.y);
		bb.writeDouble(marbleAngularVelocity.z);
		bb.writeInt16(rm.allocGO(marblePowerup));
		bb.writeDouble(bonusTime);
		bb.writeDouble(collectedBonusTime);
		bb.writeInt16(gemCount);
		bb.writeInt16(gemStates.length);
		for (s in gemStates) {
			bb.writeByte(s ? 1 : 0);
		}
		bb.writeInt16(powerupStates.length);
		for (s in powerupStates) {
			bb.writeDouble(s);
		}
		bb.writeInt16(landMineStates.length);
		for (s in landMineStates) {
			bb.writeDouble(s);
		}
		bb.writeDouble(activePowerupStates[0]);
		bb.writeDouble(activePowerupStates[1]);
		bb.writeDouble(activePowerupStates[2]);
		bb.writeDouble(activePowerupStates[3]);
		bb.writeDouble(currentUp.x);
		bb.writeDouble(currentUp.y);
		bb.writeDouble(currentUp.z);
		bb.writeDouble(lastContactNormal.x);
		bb.writeDouble(lastContactNormal.y);
		bb.writeDouble(lastContactNormal.z);
		bb.writeInt16(mpStates.length);
		for (s in mpStates) {
			bb.writeDouble(s.currentTime);
			bb.writeDouble(s.targetTime);
			bb.writeByte(s.stoppedPosition == null ? 0 : 1);
			if (s.stoppedPosition != null) {
				bb.writeDouble(s.stoppedPosition.x);
				bb.writeDouble(s.stoppedPosition.y);
				bb.writeDouble(s.stoppedPosition.z);
			}
			bb.writeDouble(s.prevPosition.x);
			bb.writeDouble(s.prevPosition.y);
			bb.writeDouble(s.prevPosition.z);
			bb.writeDouble(s.position.x);
			bb.writeDouble(s.position.y);
			bb.writeDouble(s.position.z);
			bb.writeDouble(s.velocity.x);
			bb.writeDouble(s.velocity.y);
			bb.writeDouble(s.velocity.z);
		}
		bb.writeInt16(trapdoorStates.length);
		for (s in trapdoorStates) {
			bb.writeDouble(s.lastContactTime);
			bb.writeByte(s.lastDirection);
			bb.writeDouble(s.lastCompletion);
		}
		bb.writeInt16(fadePlatformStates.length);
		for (s in fadePlatformStates) {
			bb.writeDouble(s.lastContactTime);
			bb.writeInt16(s.fadingState);
			bb.writeDouble(s.lastFadingContactTime);
		}
		bb.writeInt16(megaManPlatformStates.length);
		for (s in megaManPlatformStates) {
			bb.writeDouble(s.showTime);
			bb.writeByte(s.hasCollided ? 1 : 0);
			bb.writeByte(s.respondToCollision ? 1 : 0);
			bb.writeByte(s.queuedNext ? 1 : 0);
		}
		bb.writeDouble(blastAmt);
		bb.writeDouble(marbleRadius);
		bb.writeInt16(movementTriggerCount);
		bb.writeInt16(toggleButtonStates.length);
		for (s in toggleButtonStates) {
			bb.writeByte(s ? 1 : 0);
		}
		bb.writeByte(teleporterArmed ? 1 : 0);
		bb.writeDouble(teleporterSavedPosition.x);
		bb.writeDouble(teleporterSavedPosition.y);
		bb.writeDouble(teleporterSavedPosition.z);
		bb.writeDouble(teleporterSavedYaw);
		bb.writeDouble(teleporterSavedPitch);
		bb.writeDouble(teleporterSavedGravity.x);
		bb.writeDouble(teleporterSavedGravity.y);
		bb.writeDouble(teleporterSavedGravity.z);
		bb.writeByte(teleporterKeepVelocity ? 1 : 0);
		bb.writeDouble(teleporterTeleTime);
		bb.writeByte(teleporterFiring ? 1 : 0);
		bb.writeDouble(teleporterFireStartTime);
		bb.writeByte(isFrozen ? 1 : 0);
		bb.writeDouble(lastFreezeTime);
		bb.writeInt16(powerupLockCount);
		bb.writeInt16(timeStopTriggerCount);
		bb.writeByte(isInWater ? 1 : 0);
		bb.writeInt16(waterTriggers.length);
		for (t in waterTriggers)
			bb.writeInt16(rm.allocGO(t));
		bb.writeDouble(bubbleTime);
		bb.writeDouble(bubbleTotalTime);
		bb.writeByte(bubbleInfinite ? 1 : 0);
		bb.writeByte(bubbleActive ? 1 : 0);
		bb.writeByte(fireball ? 1 : 0);
		bb.writeDouble(fireballTime);
		bb.writeDouble(fireballTotalTime);
		bb.writeDouble(fireballLastBlastTime);
		bb.writeInt16(rm.allocGO(activeCannon));
		bb.writeDouble(cannonCharge);
		bb.writeInt16(rm.allocGO(lastCannon));
		bb.writeDouble(cannonReenableTime);
		bb.writeDouble(cannonControlLockUntil);
		bb.writeDouble(cannonCameraLockUntil);
		bb.writeDouble(instantCannonFireTime);
		bb.writeInt16(iceShardStates.length);
		for (s in iceShardStates)
			bb.writeByte(s ? 1 : 0);
		bb.writeInt16(iceShardGotoTargetStates.length);
		for (s in iceShardGotoTargetStates)
			bb.writeByte(s ? 1 : 0);
		bb.writeInt16(respawningTimeTravelStates.length);
		for (s in respawningTimeTravelStates)
			bb.writeByte(s);
		bb.writeByte(countdownActive ? 1 : 0);
		bb.writeDouble(countdownRemaining);
		bb.writeInt16(countdownIcon.length);
		bb.writeString(countdownIcon);
		bb.writeInt16(pathTriggerStates.length);
		for (s in pathTriggerStates)
			bb.writeByte(s ? 1 : 0);
		bb.writeInt16(repetitiveTriggerStates.length);
		for (s in repetitiveTriggerStates) {
			bb.writeByte(s.triggered ? 1 : 0);
			bb.writeInt16(s.enterCount);
		}
		bb.writeInt16(countdownTriggerStates.length);
		for (s in countdownTriggerStates) {
			bb.writeByte(s.activated ? 1 : 0);
			bb.writeDouble(s.pendingStartTime);
			bb.writeDouble(s.pendingTime);
			bb.writeInt16(s.pendingIcon.length);
			bb.writeString(s.pendingIcon);
		}
		bb.writeByte(modeState == null ? 0 : 1);
		if (modeState != null)
			modeState.serialize(rm, bb);
		bb.writeInt16(pathFollowerStates.length);
		for (s in pathFollowerStates) {
			bb.writeByte(s.active ? 1 : 0);
			if (s.active) {
				bb.writeDouble(s.pathPosition);
				bb.writeInt16(s.currentNode.length);
				bb.writeString(s.currentNode);
				bb.writeInt16(s.prevNode.length);
				bb.writeString(s.prevNode);
				bb.writeInt16(s.rngCursor);
			}
		}
		bb.writeByte(oobState.oob ? 1 : 0);
		if (oobState.oob) {
			bb.writeDouble(oobState.timeState.currentAttemptTime);
			bb.writeDouble(oobState.timeState.timeSinceLoad);
			bb.writeDouble(oobState.timeState.gameplayClock);
			bb.writeDouble(oobState.timeState.dt);
		}
		bb.writeByte(checkpointState.currentCheckpoint == null ? 0 : 1);
		if (checkpointState.currentCheckpoint != null) {
			bb.writeInt16(rm.allocGO(checkpointState.currentCheckpoint.obj));
			bb.writeInt16(rm.allocME(checkpointState.currentCheckpoint.elem));
		}
		bb.writeInt16(rm.allocGO(checkpointState.currentCheckpointTrigger));
		var chkgemcount = 0;
		for (g in checkpointState.checkpointCollectedGems) {
			chkgemcount++;
		}
		bb.writeInt16(chkgemcount);
		for (gem in checkpointState.checkpointCollectedGems.keys()) {
			bb.writeInt16(rm.allocGO(gem));
			bb.writeByte(checkpointState.checkpointCollectedGems[gem] ? 1 : 0);
		}
		bb.writeInt16(rm.allocGO(checkpointState.checkpointHeldPowerup));
		bb.writeByte(checkpointState.checkpointUp == null ? 0 : 1);
		if (checkpointState.checkpointUp != null) {
			bb.writeDouble(checkpointState.checkpointUp.x);
			bb.writeDouble(checkpointState.checkpointUp.y);
			bb.writeDouble(checkpointState.checkpointUp.z);
		}
		bb.writeDouble(checkpointState.checkpointBlast);
		return bb.getBytes();
	}

	/** Reuses every already-allocated container from `new()` (or a previous `deserialize` call on
		this same instance) in place instead of reallocating it - safe for every field EXCEPT the
		handful `RewindManager.applyFrame` hands off *by reference* into long-lived `MarbleWorld`/
		`Marble` state instead of copying out of (`mpStates[i].stoppedPosition`, `checkpointState.
		checkpointUp`/`checkpointCollectedGems`/`currentCheckpoint`) - those are deliberately still
		allocated fresh every call, since aliasing a reused scratch object into state that outlives
		this call would silently corrupt it the next time this same instance gets deserialized for a
	 	 	 *different* frame. See [PQ Port Status](pq-port-status.md)'s rewind-optimization entry. */
	public inline function deserialize(rm:RewindManager, br:haxe.io.BytesInput) {
		timeState.currentAttemptTime = br.readDouble();
		timeState.timeSinceLoad = br.readDouble();
		timeState.gameplayClock = br.readDouble();
		timeState.dt = br.readDouble();
		marblePosition.x = br.readDouble();
		marblePosition.y = br.readDouble();
		marblePosition.z = br.readDouble();
		marbleOrientation.x = br.readDouble();
		marbleOrientation.y = br.readDouble();
		marbleOrientation.z = br.readDouble();
		marbleOrientation.w = br.readDouble();
		marbleVelocity.x = br.readDouble();
		marbleVelocity.y = br.readDouble();
		marbleVelocity.z = br.readDouble();
		marbleAngularVelocity.x = br.readDouble();
		marbleAngularVelocity.y = br.readDouble();
		marbleAngularVelocity.z = br.readDouble();
		marblePowerup = cast rm.getGO(br.readInt16());
		bonusTime = br.readDouble();
		collectedBonusTime = br.readDouble();
		gemCount = br.readInt16();
		gemStates.resize(0);
		var gemStates_len = br.readInt16();
		for (i in 0...gemStates_len) {
			gemStates.push(br.readByte() != 0);
		}
		powerupStates.resize(0);
		var powerupStates_len = br.readInt16();
		for (i in 0...powerupStates_len) {
			powerupStates.push(br.readDouble());
		}
		landMineStates.resize(0);
		var landMineStates_len = br.readInt16();
		for (i in 0...landMineStates_len) {
			landMineStates.push(br.readDouble());
		}
		activePowerupStates[0] = br.readDouble();
		activePowerupStates[1] = br.readDouble();
		activePowerupStates[2] = br.readDouble();
		activePowerupStates[3] = br.readDouble();
		currentUp.x = br.readDouble();
		currentUp.y = br.readDouble();
		currentUp.z = br.readDouble();
		lastContactNormal.x = br.readDouble();
		lastContactNormal.y = br.readDouble();
		lastContactNormal.z = br.readDouble();
		var mpStates_len = br.readInt16();
		syncLength(mpStates, mpStates_len, () -> new RewindMPState());
		for (i in 0...mpStates_len) {
			var mpStates_item = mpStates[i];
			mpStates_item.currentTime = br.readDouble();
			mpStates_item.targetTime = br.readDouble();
			// `stoppedPosition` deliberately allocated fresh (or left null) every time - see this
			// function's doc comment.
			if (br.readByte() != 0) {
				mpStates_item.stoppedPosition = new Vector();
				mpStates_item.stoppedPosition.x = br.readDouble();
				mpStates_item.stoppedPosition.y = br.readDouble();
				mpStates_item.stoppedPosition.z = br.readDouble();
			} else {
				mpStates_item.stoppedPosition = null;
			}
			mpStates_item.prevPosition.x = br.readDouble();
			mpStates_item.prevPosition.y = br.readDouble();
			mpStates_item.prevPosition.z = br.readDouble();
			mpStates_item.position.x = br.readDouble();
			mpStates_item.position.y = br.readDouble();
			mpStates_item.position.z = br.readDouble();
			mpStates_item.velocity.x = br.readDouble();
			mpStates_item.velocity.y = br.readDouble();
			mpStates_item.velocity.z = br.readDouble();
		}
		var trapdoorStates_len = br.readInt16();
		syncLength(trapdoorStates, trapdoorStates_len, () -> new TrapdoorSaveState());
		for (i in 0...trapdoorStates_len) {
			var trapdoorStates_item = trapdoorStates[i];
			trapdoorStates_item.lastContactTime = br.readDouble();
			trapdoorStates_item.lastDirection = br.readByte();
			trapdoorStates_item.lastCompletion = br.readDouble();
		}
		var fadePlatformStates_len = br.readInt16();
		syncLength(fadePlatformStates, fadePlatformStates_len, () -> new FadePlatformSaveState());
		for (i in 0...fadePlatformStates_len) {
			var fadePlatformStates_item = fadePlatformStates[i];
			fadePlatformStates_item.lastContactTime = br.readDouble();
			fadePlatformStates_item.fadingState = br.readInt16();
			fadePlatformStates_item.lastFadingContactTime = br.readDouble();
		}
		var megaManPlatformStates_len = br.readInt16();
		syncLength(megaManPlatformStates, megaManPlatformStates_len, () -> new MegaManPlatformSaveState());
		for (i in 0...megaManPlatformStates_len) {
			var megaManPlatformStates_item = megaManPlatformStates[i];
			megaManPlatformStates_item.showTime = br.readDouble();
			megaManPlatformStates_item.hasCollided = br.readByte() != 0;
			megaManPlatformStates_item.respondToCollision = br.readByte() != 0;
			megaManPlatformStates_item.queuedNext = br.readByte() != 0;
		}
		blastAmt = br.readDouble();
		marbleRadius = br.readDouble();
		movementTriggerCount = br.readInt16();
		toggleButtonStates.resize(0);
		var toggleButtonStates_len = br.readInt16();
		for (i in 0...toggleButtonStates_len) {
			toggleButtonStates.push(br.readByte() != 0);
		}
		teleporterArmed = br.readByte() != 0;
		teleporterSavedPosition.x = br.readDouble();
		teleporterSavedPosition.y = br.readDouble();
		teleporterSavedPosition.z = br.readDouble();
		teleporterSavedYaw = br.readDouble();
		teleporterSavedPitch = br.readDouble();
		teleporterSavedGravity.x = br.readDouble();
		teleporterSavedGravity.y = br.readDouble();
		teleporterSavedGravity.z = br.readDouble();
		teleporterKeepVelocity = br.readByte() != 0;
		teleporterTeleTime = br.readDouble();
		teleporterFiring = br.readByte() != 0;
		teleporterFireStartTime = br.readDouble();
		isFrozen = br.readByte() != 0;
		lastFreezeTime = br.readDouble();
		powerupLockCount = br.readInt16();
		timeStopTriggerCount = br.readInt16();
		isInWater = br.readByte() != 0;
		waterTriggers.resize(0);
		var waterTriggers_len = br.readInt16();
		for (i in 0...waterTriggers_len)
			waterTriggers.push(cast rm.getGO(br.readInt16()));
		bubbleTime = br.readDouble();
		bubbleTotalTime = br.readDouble();
		bubbleInfinite = br.readByte() != 0;
		bubbleActive = br.readByte() != 0;
		fireball = br.readByte() != 0;
		fireballTime = br.readDouble();
		fireballTotalTime = br.readDouble();
		fireballLastBlastTime = br.readDouble();
		activeCannon = cast rm.getGO(br.readInt16());
		cannonCharge = br.readDouble();
		lastCannon = cast rm.getGO(br.readInt16());
		cannonReenableTime = br.readDouble();
		cannonControlLockUntil = br.readDouble();
		cannonCameraLockUntil = br.readDouble();
		instantCannonFireTime = br.readDouble();
		iceShardStates.resize(0);
		var iceShardStates_len = br.readInt16();
		for (i in 0...iceShardStates_len)
			iceShardStates.push(br.readByte() != 0);
		iceShardGotoTargetStates.resize(0);
		var iceShardGotoTargetStates_len = br.readInt16();
		for (i in 0...iceShardGotoTargetStates_len)
			iceShardGotoTargetStates.push(br.readByte() != 0);
		respawningTimeTravelStates.resize(0);
		var respawningTimeTravelStates_len = br.readInt16();
		for (i in 0...respawningTimeTravelStates_len)
			respawningTimeTravelStates.push(br.readByte());
		countdownActive = br.readByte() != 0;
		countdownRemaining = br.readDouble();
		var countdownIcon_len = br.readInt16();
		countdownIcon = br.readString(countdownIcon_len);
		pathTriggerStates.resize(0);
		var pathTriggerStates_len = br.readInt16();
		for (i in 0...pathTriggerStates_len)
			pathTriggerStates.push(br.readByte() != 0);
		var repetitiveTriggerStates_len = br.readInt16();
		syncLength(repetitiveTriggerStates, repetitiveTriggerStates_len, () -> new RepetitiveTriggerSaveState());
		for (i in 0...repetitiveTriggerStates_len) {
			var s = repetitiveTriggerStates[i];
			s.triggered = br.readByte() != 0;
			s.enterCount = br.readInt16();
		}
		var countdownTriggerStates_len = br.readInt16();
		syncLength(countdownTriggerStates, countdownTriggerStates_len, () -> new CountdownTriggerSaveState());
		for (i in 0...countdownTriggerStates_len) {
			var s = countdownTriggerStates[i];
			s.activated = br.readByte() != 0;
			s.pendingStartTime = br.readDouble();
			s.pendingTime = br.readDouble();
			var pendingIcon_len = br.readInt16();
			s.pendingIcon = br.readString(pendingIcon_len);
		}
		var hasModeState = br.readByte() != 0;
		if (hasModeState) {
			modeState = rm.level.gameMode.constructRewindState();
			modeState.deserialize(rm, br);
		} else {
			modeState = null;
		}
		var pathFollowerStates_len = br.readInt16();
		syncLength(pathFollowerStates, pathFollowerStates_len, () -> new PathFollowerSaveState());
		for (i in 0...pathFollowerStates_len) {
			var s = pathFollowerStates[i];
			s.active = br.readByte() != 0;
			if (!s.active)
				continue;
			s.pathPosition = br.readDouble();
			var currentNodeLen = br.readInt16();
			s.currentNode = br.readString(currentNodeLen);
			var prevNodeLen = br.readInt16();
			s.prevNode = br.readString(prevNodeLen);
			s.rngCursor = br.readInt16();
		}
		oobState = {
			oob: br.readByte() != 0,
			timeState: null
		};
		if (oobState.oob) {
			oobState.timeState = new TimeState();
			oobState.timeState.currentAttemptTime = br.readDouble();
			oobState.timeState.timeSinceLoad = br.readDouble();
			oobState.timeState.gameplayClock = br.readDouble();
			oobState.timeState.dt = br.readDouble();
		}
		var hasCheckpoint = br.readByte() != 0;
		checkpointState = {
			currentCheckpoint: null,
			currentCheckpointTrigger: null,
			checkpointCollectedGems: new Map<Gem, Bool>(),
			checkpointHeldPowerup: null,
			checkpointUp: null,
			checkpointBlast: 0.0,
		};
		if (hasCheckpoint) {
			var co = rm.getGO(br.readInt16());
			var ce = rm.getME(br.readInt16());
			checkpointState.currentCheckpoint = {obj: cast co, elem: ce};
		}
		checkpointState.currentCheckpointTrigger = cast rm.getGO(br.readInt16());
		var checkpointState_checkpointCollectedGems_len = br.readInt16();
		for (i in 0...checkpointState_checkpointCollectedGems_len) {
			var gem = cast rm.getGO(br.readInt16());
			var c = br.readByte() != 0;
			checkpointState.checkpointCollectedGems.set(cast gem, c);
		}
		checkpointState.checkpointHeldPowerup = cast rm.getGO(br.readInt16());
		var checkpointState_checkpointUp_has = br.readByte() != 0;
		if (checkpointState_checkpointUp_has) {
			checkpointState.checkpointUp = new Vector();
			checkpointState.checkpointUp.x = br.readDouble();
			checkpointState.checkpointUp.y = br.readDouble();
			checkpointState.checkpointUp.z = br.readDouble();
		}
		checkpointState.checkpointBlast = br.readDouble();
	}
}
