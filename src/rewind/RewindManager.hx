package rewind;

import rewind.RewindFrame.RewindMPState;
import rewind.RewindFrame.TrapdoorSaveState;
import rewind.RewindFrame.FadePlatformSaveState;
import rewind.RewindFrame.RepetitiveTriggerSaveState;
import rewind.RewindFrame.CountdownTriggerSaveState;
import haxe.io.BytesInput;
import haxe.io.BytesBuffer;
import mis.MissionElement.MissionElementBase;
import src.GameObject;
import src.GameObjectPathFollower;
import src.GameObjectPathFollower.PathFollowerSaveState;
import shapes.AbstractBumper;
import shapes.PowerUp;
import shapes.LandMine;
import src.MarbleWorld;
import src.Marble;
import gui.PlayGui;
import shapes.Trapdoor;
import shapes.FadePlatform;
import shapes.PushButton;
import shapes.ToggleButton;
import src.Util;
import shapes.Nuke;
import h3d.Vector;

class RewindManager {
	var frameData:BytesBuffer;
	var frameElapsedTimes:Array<Float> = [];
	var frameDataOffsets:Array<Int> = [];
	var frameSizes:Array<Int> = [];
	var allocObjMap:Map<GameObject, Int> = [];
	var allocObjs:Array<GameObject> = [];
	var allocMeMap:Map<MissionElementBase, Int> = [];
	var allocMes:Array<MissionElementBase> = [];

	public var level:MarbleWorld;

	var allocId = 0;
	var allocMeId = 0;

	public var timeScale:Float = 1;

	/** Recording (`recordFrame`) and reading (`getFrameAtIndex`) each reuse exactly one persistent
		`RewindFrame` instead of allocating a fresh one every tick - both are populated, immediately
		consumed (`serialize()`/`applyFrame()`), and discarded within the same function call, with no
		code anywhere keeping a `RewindFrame` reference beyond that, so a single reused scratch
		instance per direction is safe. See [PQ Port Status](pq-port-status.md)'s rewind-optimization
		entry for the full writeup, including the handful of fields that still allocate fresh on
		purpose because `applyFrame` hands them off by reference into long-lived state. */
	var recordScratch:RewindFrame = new RewindFrame();

	var readScratch:RewindFrame = new RewindFrame();

	public function new(level:MarbleWorld) {
		this.level = level;
		this.frameData = new BytesBuffer();
	}

	/** Populates the persistent `recordScratch` in place (see its doc comment) instead of building
		a fresh `RewindFrame` graph every tick just to serialize and discard it - was previously the
		single biggest GC-pressure source in this file, allocating a whole object graph (frame,
		~15 cloned Vectors/Quats, ~10 arrays, a struct per trapdoor/fadeplatform/button/mover in the
		level) every tick only to throw all of it away right after `serialize()`. None of this
		function's writes into `recordScratch` are ever read back by anyone after `serialize()`
		returns, so reference-only assignments (no `.clone()`/`.copy()`) are safe throughout - unlike
		`RewindFrame.deserialize`, which has a few fields it deliberately still allocates fresh
		because `RewindManager.applyFrame` hands *those* off by reference into long-lived state. */
	public function recordFrame() {
		var rf = recordScratch;
		rf.timeState.currentAttemptTime = level.timeState.currentAttemptTime;
		rf.timeState.timeSinceLoad = level.timeState.timeSinceLoad;
		rf.timeState.gameplayClock = level.timeState.gameplayClock;
		rf.timeState.dt = level.timeState.dt;
		rf.marblePosition.load(level.marble.collider.transform.getPosition());
		rf.marbleOrientation.load(level.marble.getRotationQuat());
		rf.marbleVelocity.load(level.marble.velocity);
		rf.marbleAngularVelocity.load(level.marble.omega);
		rf.marblePowerup = level.marble.heldPowerup;
		rf.bonusTime = level.bonusTime;
		rf.collectedBonusTime = level.collectedBonusTime;
		rf.gemCount = level.gemCount;
		rf.gemStates.resize(0);
		for (g in level.gems)
			rf.gemStates.push(g.pickedUp);
		rf.activePowerupStates[0] = @:privateAccess level.marble.superBounceEnableTime;
		rf.activePowerupStates[1] = @:privateAccess level.marble.shockAbsorberEnableTime;
		rf.activePowerupStates[2] = @:privateAccess level.marble.helicopterEnableTime;
		rf.activePowerupStates[3] = @:privateAccess level.marble.megaMarbleEnableTime;
		rf.currentUp.load(level.marble.currentUp);
		rf.lastContactNormal.load(level.marble.lastContactNormal);
		RewindFrame.syncLength(rf.mpStates, level.pathedInteriors.length, () -> new RewindMPState());
		for (i in 0...level.pathedInteriors.length) {
			var x = level.pathedInteriors[i];
			var mpstate = rf.mpStates[i];
			mpstate.currentTime = x.currentTime;
			mpstate.targetTime = x.targetTime;
			mpstate.velocity.load(x.velocity);
			// Read-only reference is fine here - `serialize()` only reads `.x/.y/.z` out of it
			// synchronously, right below, on this same call.
			mpstate.stoppedPosition = @:privateAccess x.stopped ? @:privateAccess x.stoppedPosition : null;
			mpstate.position.load(@:privateAccess x.position);
			mpstate.prevPosition.load(@:privateAccess x.prevPosition);
		}
		rf.teleporterArmed = level.marble.teleporterArmed;
		rf.teleporterSavedPosition.load(level.marble.teleporterSavedPosition);
		rf.teleporterSavedYaw = level.marble.teleporterSavedYaw;
		rf.teleporterSavedPitch = level.marble.teleporterSavedPitch;
		rf.teleporterSavedGravity.load(level.marble.teleporterSavedGravity);
		rf.teleporterKeepVelocity = level.marble.teleporterKeepVelocity;
		rf.teleporterTeleTime = level.marble.teleporterTeleTime;
		rf.teleporterFiring = level.marble.teleporterFiring;
		rf.teleporterFireStartTime = @:privateAccess level.marble.teleporterFireStartTime;
		rf.isFrozen = level.marble.isFrozen;
		rf.lastFreezeTime = level.marble.lastFreezeTime;
		rf.powerupLockCount = level.marble.powerupLockCount;
		rf.timeStopTriggerCount = level.timeStopTriggerCount;
		rf.isInWater = level.marble.isInWater;
		rf.waterTriggers.resize(0);
		for (t in level.marble.waterTriggers)
			rf.waterTriggers.push(t);
		rf.bubbleTime = level.marble.bubbleTime;
		rf.bubbleTotalTime = level.marble.bubbleTotalTime;
		rf.bubbleInfinite = level.marble.bubbleInfinite;
		rf.bubbleActive = level.marble.bubbleActive;
		rf.fireball = level.marble.fireball;
		rf.fireballTime = level.marble.fireballTime;
		rf.fireballTotalTime = level.marble.fireballTotalTime;
		rf.fireballLastBlastTime = @:privateAccess level.marble.fireballLastBlastTime;
		rf.activeCannon = level.marble.activeCannon;
		rf.cannonCharge = @:privateAccess level.marble.cannonCharge;
		rf.lastCannon = level.marble.lastCannon;
		rf.cannonReenableTime = @:privateAccess level.marble.cannonReenableTime;
		rf.cannonControlLockUntil = @:privateAccess level.marble.cannonControlLockUntil;
		rf.cannonCameraLockUntil = @:privateAccess level.marble.cannonCameraLockUntil;
		rf.instantCannonFireTime = @:privateAccess level.marble.instantCannonFireTime;
		rf.iceShardStates.resize(0);
		rf.iceShardGotoTargetStates.resize(0);
		for (s in level.iceShards) {
			rf.iceShardStates.push(s.destroyed);
			rf.iceShardGotoTargetStates.push(s.gotoTargetTriggered);
		}
		rf.respawningTimeTravelStates.resize(0);
		for (t in level.respawningTimeTravels)
			rf.respawningTimeTravelStates.push(@:privateAccess t.respawnCount);
		rf.countdownActive = @:privateAccess level.countdownActive;
		rf.countdownRemaining = @:privateAccess level.countdownRemaining;
		rf.countdownIcon = @:privateAccess level.countdownIcon;
		rf.pathTriggerStates.resize(0);
		for (t in level.triggers)
			if (t is triggers.PathTrigger)
				rf.pathTriggerStates.push((cast t : triggers.PathTrigger).triggered);
		var repetitiveTriggerIdx = 0;
		for (pi in level.pathedInteriors) {
			for (t in pi.triggers) {
				if (!(t is triggers.RepetitiveTriggerGotoTarget))
					continue;
				var rt:triggers.RepetitiveTriggerGotoTarget = cast t;
				if (repetitiveTriggerIdx >= rf.repetitiveTriggerStates.length)
					rf.repetitiveTriggerStates.push(new RepetitiveTriggerSaveState());
				var s = rf.repetitiveTriggerStates[repetitiveTriggerIdx++];
				s.triggered = rt.triggered;
				s.enterCount = rt.enterCount;
			}
		}
		rf.repetitiveTriggerStates.resize(repetitiveTriggerIdx);
		var countdownTriggerIdx = 0;
		for (t in level.triggers) {
			if (!(t is triggers.CountdownStartTrigger))
				continue;
			var ct:triggers.CountdownStartTrigger = cast t;
			if (countdownTriggerIdx >= rf.countdownTriggerStates.length)
				rf.countdownTriggerStates.push(new CountdownTriggerSaveState());
			var s = rf.countdownTriggerStates[countdownTriggerIdx++];
			s.activated = ct.activated;
			s.pendingStartTime = ct.pendingStartTime;
			s.pendingTime = ct.pendingTime;
			s.pendingIcon = ct.pendingIcon;
		}
		rf.countdownTriggerStates.resize(countdownTriggerIdx);
		rf.modeState = level.gameMode.getRewindState();

		rf.marbleRadius = level.marble._radius;
		rf.movementTriggerCount = level.marble.movementTriggerCount;
		// One slot per non-`PathedInterior` mover, unconditionally (not filtered to only currently-
		// active ones) - `active = false` for a mover that isn't path-active right now.
		// `level.movingObjects` must be stable in size/order for the whole session (see
		// `MarbleWorld.loadBegin`'s PathTrigger-target pre-scan) for this to align positionally
		// across every recorded frame; otherwise a mover that gets triggered mid-game would shift
		// every later frame's array out of alignment with earlier ones on rewind.
		var pathFollowerIdx = 0;
		for (mover in level.movingObjects) {
			if (mover is src.PathedInterior)
				continue;
			if (pathFollowerIdx >= rf.pathFollowerStates.length)
				rf.pathFollowerStates.push(new PathFollowerSaveState());
			var s = rf.pathFollowerStates[pathFollowerIdx++];
			var go:GameObject = cast mover;
			if (go.pathFollower != null)
				go.pathFollower.fillState(s);
			else
				s.active = false;
		}
		rf.pathFollowerStates.resize(pathFollowerIdx);

		rf.powerupStates.resize(0);
		rf.landMineStates.resize(0);
		rf.toggleButtonStates.resize(0);
		var trapdoorIdx = 0;
		var fadePlatformIdx = 0;
		for (dts in level.dtsObjects) {
			if (dts is PowerUp) {
				var pow:PowerUp = cast dts;
				rf.powerupStates.push(pow.lastPickUpTime);
			}
			if (dts is PushButton) {
				var pow:PushButton = cast dts;
				rf.powerupStates.push(pow.lastContactTime);
			}
			if (dts is LandMine) {
				var lm:LandMine = cast dts;
				rf.landMineStates.push(lm.disappearTime);
			}
			if (dts is Nuke) {
				var lm:Nuke = cast dts;
				rf.landMineStates.push(lm.disappearTime);
			}
			if (dts is Trapdoor) {
				var td:Trapdoor = cast dts;
				if (trapdoorIdx >= rf.trapdoorStates.length)
					rf.trapdoorStates.push(new TrapdoorSaveState());
				var ts = rf.trapdoorStates[trapdoorIdx++];
				ts.lastCompletion = td.lastCompletion;
				ts.lastDirection = td.lastDirection;
				ts.lastContactTime = td.lastContactTime;
			}
			if (dts is FadePlatform) {
				var fp:FadePlatform = cast dts;
				if (fadePlatformIdx >= rf.fadePlatformStates.length)
					rf.fadePlatformStates.push(new FadePlatformSaveState());
				var fs = rf.fadePlatformStates[fadePlatformIdx++];
				fs.lastContactTime = fp.lastContactTime;
				fs.fadingState = fp.fadingState;
				fs.lastFadingContactTime = fp.lastFadingContactTime;
			}
			if (dts is AbstractBumper) {
				var ab:AbstractBumper = cast dts;
				rf.powerupStates.push(ab.lastContactTime);
			}
			if (dts is ToggleButton) {
				var tb:ToggleButton = cast dts;
				rf.toggleButtonStates.push(tb.activated);
			}
		}
		rf.trapdoorStates.resize(trapdoorIdx);
		rf.fadePlatformStates.resize(fadePlatformIdx);
		rf.blastAmt = level.marble.blastAmount;
		rf.oobState.oob = level.marble.outOfBounds;
		// Reference-only, safe on the record side (see this function's doc comment).
		rf.oobState.timeState = level.marble.outOfBoundsTime;
		rf.checkpointState.currentCheckpoint = @:privateAccess level.currentCheckpoint;
		rf.checkpointState.currentCheckpointTrigger = @:privateAccess level.currentCheckpointTrigger;
		rf.checkpointState.checkpointBlast = @:privateAccess level.cheeckpointBlast;
		rf.checkpointState.checkpointCollectedGems = @:privateAccess level.checkpointCollectedGems;
		rf.checkpointState.checkpointHeldPowerup = @:privateAccess level.checkpointHeldPowerup;
		rf.checkpointState.checkpointUp = @:privateAccess level.checkpointUp;
		frameElapsedTimes.push(level.timeState.currentAttemptTime);
		frameDataOffsets.push(frameData.length);
		var frameDataSerialized = rf.serialize(this);
		frameSizes.push(frameDataSerialized.length);
		frameData.addBytes(frameDataSerialized, 0, frameDataSerialized.length);
	}

	public function applyFrame(rf:RewindFrame) {
		level.timeState = rf.timeState.clone();
		// `ParticleManager.currentTime` otherwise wouldn't reflect the just-restored (rewound) time
		// until this frame's later `particleManager.update()` call - any emitter created *during*
		// `applyFrame` (e.g. `Gem.setHide(false)` -> `startGemEmitter` for a gem un-picked-up by this
		// rewind) would get stamped with the stale pre-rewind time as its `creationTime`, which
		// `ParticleManager.tick`'s "remove emitters created in a future we've rewound past" check
		// would then immediately (same frame) treat as being from the future and delete on the spot.
		@:privateAccess level.particleManager.currentTime = 1000 * rf.timeState.timeSinceLoad;
		level.marble.setMarblePosition(rf.marblePosition.x, rf.marblePosition.y, rf.marblePosition.z);
		level.marble.setRotationQuat(rf.marbleOrientation.clone());
		level.marble.velocity.set(rf.marbleVelocity.x, rf.marbleVelocity.y, rf.marbleVelocity.z);
		level.marble.omega.set(rf.marbleAngularVelocity.x, rf.marbleAngularVelocity.y, rf.marbleAngularVelocity.z);

		if (level.marble.heldPowerup == null) {
			if (rf.marblePowerup != null) {
				level.pickUpPowerUp(level.marble, rf.marblePowerup);
			}
		} else {
			if (rf.marblePowerup == null) {
				level.deselectPowerUp(level.marble);
			} else {
				level.pickUpPowerUp(level.marble, rf.marblePowerup);
			}
		}

		level.bonusTime = rf.bonusTime;
		level.collectedBonusTime = rf.collectedBonusTime;
		level.gemCount = rf.gemCount;
		@:privateAccess level.playGui.formatGemCounter(level.gemCount, level.gemCounterTotal());
		for (i in 0...rf.gemStates.length) {
			level.gems[i].setHide(rf.gemStates[i]);
		}
		@:privateAccess level.marble.superBounceEnableTime = rf.activePowerupStates[0];
		@:privateAccess level.marble.shockAbsorberEnableTime = rf.activePowerupStates[1];
		@:privateAccess level.marble.helicopterEnableTime = rf.activePowerupStates[2];
		@:privateAccess level.marble.megaMarbleEnableTime = rf.activePowerupStates[3];

		if (level.marble.currentUp.x != rf.currentUp.x
			|| level.marble.currentUp.y != rf.currentUp.y
			|| level.marble.currentUp.z != rf.currentUp.z) {
			level.setUp(level.marble, rf.currentUp, level.timeState);
			// Hacky things
			@:privateAccess level.orientationChangeTime = level.timeState.currentAttemptTime - 0.3;
			var oldorient = level.newOrientationQuat;
			level.newOrientationQuat = @:privateAccess level.oldOrientationQuat;
			@:privateAccess level.oldOrientationQuat = oldorient;
		}

		var gravitycompletion = Util.clamp((level.timeState.currentAttemptTime - @:privateAccess level.orientationChangeTime) / 0.3, 0, 1);
		if (gravitycompletion == 0) {
			level.newOrientationQuat = @:privateAccess level.oldOrientationQuat;
			@:privateAccess level.orientationChangeTime = -1e8;
		}

		level.marble.currentUp.set(rf.currentUp.x, rf.currentUp.y, rf.currentUp.z);
		level.marble.lastContactNormal.set(rf.lastContactNormal.x, rf.lastContactNormal.y, rf.lastContactNormal.z);
		for (i in 0...rf.mpStates.length) {
			level.pathedInteriors[i].currentTime = rf.mpStates[i].currentTime;
			level.pathedInteriors[i].targetTime = rf.mpStates[i].targetTime;
			level.pathedInteriors[i].velocity.load(rf.mpStates[i].velocity);
			@:privateAccess level.pathedInteriors[i].stopped = rf.mpStates[i].stoppedPosition != null;
			@:privateAccess level.pathedInteriors[i].position.load(rf.mpStates[i].position);
			@:privateAccess level.pathedInteriors[i].prevPosition.load(rf.mpStates[i].prevPosition);
			@:privateAccess level.pathedInteriors[i].stoppedPosition = rf.mpStates[i].stoppedPosition;
			if (level.pathedInteriors[i].isCollideable) {
				var tform = level.pathedInteriors[i].getAbsPos().clone();
				tform.setPosition(rf.mpStates[i].position);
				@:privateAccess level.pathedInteriors[i].collider.setTransform(tform);
				level.collisionWorld.updateTransform(@:privateAccess level.pathedInteriors[i].collider);
			}
			// level.pathedInteriors[i].setTransform(level.pathedInteriors[i].getTransform());
		}
		var pstates = rf.powerupStates.copy();
		var lmstates = rf.landMineStates.copy();
		var tstates = rf.trapdoorStates.copy();
		var fpstates = rf.fadePlatformStates.copy();
		var tbstates = rf.toggleButtonStates.copy();
		level.marble._radius = rf.marbleRadius;
		level.marble.collider.radius = rf.marbleRadius;
		level.marble.movementTriggerCount = rf.movementTriggerCount;
		level.marble.teleporterArmed = rf.teleporterArmed;
		level.marble.teleporterSavedPosition = rf.teleporterSavedPosition.clone();
		level.marble.teleporterSavedYaw = rf.teleporterSavedYaw;
		level.marble.teleporterSavedPitch = rf.teleporterSavedPitch;
		level.marble.teleporterSavedGravity = rf.teleporterSavedGravity.clone();
		level.marble.teleporterKeepVelocity = rf.teleporterKeepVelocity;
		level.marble.teleporterTeleTime = rf.teleporterTeleTime;
		level.marble.teleporterFiring = rf.teleporterFiring;
		@:privateAccess level.marble.teleporterFireStartTime = rf.teleporterFireStartTime;
		level.marble.isFrozen = rf.isFrozen;
		level.marble.lastFreezeTime = rf.lastFreezeTime;
		level.marble.powerupLockCount = rf.powerupLockCount;
		// `powerupLockCount` itself was already snapshotted correctly, but the HUD icon
		// (`PlayGui.lockPowerup`) is a one-shot call fired only on the 0<->1 transition edge
		// (`Marble.lockPowerupUse`/`unlockPowerupUse`), not re-derived every frame - so without this,
		// rewinding past a freeze (or any other lock reason) left the icon showing whatever it was at
		// the moment rewind started, even though the underlying count was already correct. Fully
		// derivable from the restored count, so no extra state needs to be captured for this.
		level.playGui.lockPowerup(rf.powerupLockCount > 0);
		level.timeStopTriggerCount = rf.timeStopTriggerCount;

		level.marble.waterTriggers = rf.waterTriggers.copy();
		level.marble.isInWater = rf.isInWater;
		if (@:privateAccess level.marble.waterPhysicsLayer != null) {
			level.marble.popPhysicsLayer(@:privateAccess level.marble.waterPhysicsLayer);
			@:privateAccess level.marble.waterPhysicsLayer = null;
		}
		if (rf.isInWater)
			@:privateAccess level.marble.waterPhysicsLayer = level.marble.pushPhysicsLayer(Marble.buildWaterPhysicsLayer());

		level.marble.bubbleTime = rf.bubbleTime;
		level.marble.bubbleTotalTime = rf.bubbleTotalTime;
		level.marble.bubbleInfinite = rf.bubbleInfinite;
		level.marble.bubbleActive = rf.bubbleActive;
		if (@:privateAccess level.marble.bubblePhysicsLayer != null) {
			level.marble.popPhysicsLayer(@:privateAccess level.marble.bubblePhysicsLayer);
			@:privateAccess level.marble.bubblePhysicsLayer = null;
		}
		if (rf.bubbleActive)
			@:privateAccess level.marble.bubblePhysicsLayer = level.marble.pushPhysicsLayer(Marble.buildBubblePhysicsLayer());
		@:privateAccess level.playGui.updateBubbleBar(level.marble.bubbleTime, level.marble.bubbleTotalTime, level.marble.bubbleInfinite);

		level.marble.fireball = rf.fireball;
		level.marble.fireballTime = rf.fireballTime;
		level.marble.fireballTotalTime = rf.fireballTotalTime;
		@:privateAccess level.marble.fireballLastBlastTime = rf.fireballLastBlastTime;
		@:privateAccess level.playGui.updateFireballBar(level.marble.fireballTime, level.marble.fireballTotalTime,
			@:privateAccess level.marble.canFireballBlast());

		level.marble.activeCannon = rf.activeCannon;
		@:privateAccess level.marble.cannonCharge = rf.cannonCharge;
		level.marble.lastCannon = rf.lastCannon;
		@:privateAccess level.marble.cannonReenableTime = rf.cannonReenableTime;
		@:privateAccess level.marble.cannonControlLockUntil = rf.cannonControlLockUntil;
		@:privateAccess level.marble.cannonCameraLockUntil = rf.cannonCameraLockUntil;
		@:privateAccess level.marble.instantCannonFireTime = rf.instantCannonFireTime;
		if (@:privateAccess level.marble.cannonFrozenLayer != null) {
			level.marble.popPhysicsLayer(@:privateAccess level.marble.cannonFrozenLayer);
			@:privateAccess level.marble.cannonFrozenLayer = null;
		}
		if (rf.activeCannon != null)
			@:privateAccess level.marble.cannonFrozenLayer = level.marble.pushPhysicsLayer(Marble.buildCannonFrozenLayer());
		if (@:privateAccess level.marble.cannonControlLockLayer != null) {
			level.marble.popPhysicsLayer(@:privateAccess level.marble.cannonControlLockLayer);
			@:privateAccess level.marble.cannonControlLockLayer = null;
		}
		if (rf.cannonControlLockUntil > rf.timeState.currentAttemptTime)
			@:privateAccess level.marble.cannonControlLockLayer = level.marble.pushPhysicsLayer(Marble.buildCannonControlLockLayer());
		for (i in 0...rf.iceShardStates.length) {
			var shard = level.iceShards[i];
			if (shard.destroyed != rf.iceShardStates[i])
				shard.setDestroyed(rf.iceShardStates[i]);
			shard.gotoTargetTriggered = rf.iceShardGotoTargetStates[i];
		}
		for (i in 0...rf.respawningTimeTravelStates.length)
			@:privateAccess level.respawningTimeTravels[i].respawnCount = rf.respawningTimeTravelStates[i];

		@:privateAccess level.countdownActive = rf.countdownActive;
		@:privateAccess level.countdownRemaining = rf.countdownRemaining;
		@:privateAccess level.countdownIcon = rf.countdownIcon;
		if (rf.countdownActive) {
			level.playGui.setCountdownThIcon(rf.countdownIcon);
			var color = rf.countdownRemaining <= 0 ? PlayGui.timerStopped : PlayGui.timerNormal;
			level.playGui.formatCountdownThTimer(Math.max(0, rf.countdownRemaining), color);
		} else {
			level.playGui.formatCountdownThTimer(0);
		}

		var ptstates = rf.pathTriggerStates.copy();
		for (t in level.triggers)
			if (t is triggers.PathTrigger)
				(cast t : triggers.PathTrigger).triggered = ptstates.shift();

		var rtIdx = 0;
		for (pi in level.pathedInteriors) {
			for (t in pi.triggers) {
				if (!(t is triggers.RepetitiveTriggerGotoTarget))
					continue;
				var rt:triggers.RepetitiveTriggerGotoTarget = cast t;
				var s = rf.repetitiveTriggerStates[rtIdx++];
				rt.triggered = s.triggered;
				rt.enterCount = s.enterCount;
			}
		}

		var ctIdx = 0;
		for (t in level.triggers) {
			if (!(t is triggers.CountdownStartTrigger))
				continue;
			var ct:triggers.CountdownStartTrigger = cast t;
			var s = rf.countdownTriggerStates[ctIdx++];
			ct.activated = s.activated;
			ct.pendingStartTime = s.pendingStartTime;
			ct.pendingTime = s.pendingTime;
			ct.pendingIcon = s.pendingIcon;
		}

		if (rf.modeState != null)
			level.gameMode.applyRewindState(rf.modeState);

		if (level.marble.teleporterMarker != null) {
			if (rf.teleporterArmed) {
				level.marble.teleporterMarker.skinOverride = rf.teleporterKeepVelocity ? "yellow" : null;
				level.marble.teleporterMarker.setPosition(rf.teleporterSavedPosition.x, rf.teleporterSavedPosition.y, rf.teleporterSavedPosition.z);
			} else {
				level.marble.teleporterMarker.setPosition(1e8, 1e8, 1e8);
			}
		}
		var pfstates = rf.pathFollowerStates.copy();
		for (mover in level.movingObjects) {
			if (mover is src.PathedInterior)
				continue;
			var go:GameObject = cast mover;
			var state = pfstates.shift();
			if (!state.active) {
				// Rewound to before this object was ever put on a path (e.g. a PathTrigger/button
				// hasn't fired yet in this timeline) - un-trigger it entirely rather than leaving it
				// stuck wherever it was mid-path.
				go.deactivatePath();
			} else {
				if (go.pathFollower == null)
					go.moveOnPath(state.currentNode, level); // also (re-)registers into movingObjects, a no-op if already there
				go.pathFollower.setState(state);
			}
		}
		for (dts in level.dtsObjects) {
			if (dts is PowerUp) {
				var pow:PowerUp = cast dts;
				pow.lastPickUpTime = pstates.shift();
			}
			if (dts is PushButton) {
				var pow:PushButton = cast dts;
				pow.lastContactTime = pstates.shift();
			}
			if (dts is LandMine) {
				var lm:LandMine = cast dts;
				lm.disappearTime = lmstates.shift();
			}
			if (dts is Nuke) {
				var lm:Nuke = cast dts;
				lm.disappearTime = lmstates.shift();
			}
			if (dts is Trapdoor) {
				var td:Trapdoor = cast dts;
				var tdState = tstates.shift();
				td.lastCompletion = tdState.lastCompletion;
				td.lastDirection = tdState.lastDirection;
				td.lastContactTime = tdState.lastContactTime;
			}
			if (dts is FadePlatform) {
				var fp:FadePlatform = cast dts;
				var fpState = fpstates.shift();
				fp.lastContactTime = fpState.lastContactTime;
				fp.fadingState = fpState.fadingState;
				fp.lastFadingContactTime = fpState.lastFadingContactTime;
			}
			if (dts is AbstractBumper) {
				var ab:AbstractBumper = cast dts;
				ab.lastContactTime = pstates.shift();
			}
			if (dts is ToggleButton) {
				var tb:ToggleButton = cast dts;
				tb.activated = tbstates.shift();
			}
		}

		if (!rf.oobState.oob) {
			@:privateAccess level.cancel(level.oobSchedule);
			@:privateAccess level.cancel(level.marble.oobSchedule);
		} else {
			level.goOutOfBounds(level.marble);
		}

		level.marble.outOfBounds = rf.oobState.oob;
		level.marble.camera.oob = rf.oobState.oob;
		level.marble.outOfBoundsTime = rf.oobState.timeState != null ? rf.oobState.timeState.clone() : null;
		level.marble.blastAmount = rf.blastAmt;
		@:privateAccess level.checkpointUp = rf.checkpointState.checkpointUp;
		@:privateAccess level.checkpointCollectedGems = rf.checkpointState.checkpointCollectedGems;
		@:privateAccess level.cheeckpointBlast = rf.checkpointState.checkpointBlast;
		@:privateAccess level.checkpointHeldPowerup = rf.checkpointState.checkpointHeldPowerup;
		@:privateAccess level.currentCheckpoint = rf.checkpointState.currentCheckpoint;
		@:privateAccess level.currentCheckpointTrigger = rf.checkpointState.currentCheckpointTrigger;
	}

	public function getNextRewindFrame(absTime:Float):RewindFrame {
		if (frameElapsedTimes.length == 0)
			return null;

		var topFrame = frameElapsedTimes[frameElapsedTimes.length - 1];
		while (topFrame > absTime) {
			if (frameElapsedTimes.length == 1) {
				return getFrameAtIndex(0);
			}
			popFrame();
			if (frameElapsedTimes.length == 0)
				return null;
			topFrame = frameElapsedTimes[frameElapsedTimes.length - 1];
		}
		return getFrameAtIndex(frameElapsedTimes.length - 1);
		// return topFrame;
	}

	function getFrameAtIndex(index:Int) {
		var offset = frameDataOffsets[index];
		var size = frameSizes[index];
		#if sys
		var frameBytes = @:privateAccess frameData.b.sub(offset, size);
		var bi = new BytesInput(frameBytes.toBytes(size));
		#end
		#if js
		var frameBytes = @:privateAccess frameData.buffer.slice(offset, offset + size);
		var bi = new BytesInput(haxe.io.Bytes.ofData(frameBytes));
		#end
		readScratch.deserialize(this, bi);
		return readScratch;
	}

	function popFrame() {
		frameElapsedTimes.pop();
		var offset = frameDataOffsets[frameDataOffsets.length - 1];
		@:privateAccess frameData.pos = offset;
		frameDataOffsets.pop();
		frameSizes.pop();
	}

	public function allocGO(go:GameObject) {
		if (go == null)
			return -1;
		if (allocObjMap.exists(go))
			return allocObjMap.get(go);
		var newId = allocId++;
		allocObjMap.set(go, newId);
		allocObjs.push(go);
		return newId;
	}

	public function getGO(id:Int):GameObject {
		if (id == -1)
			return null;
		return allocObjs[id];
	}

	public function allocME(me:MissionElementBase) {
		if (me == null)
			return -1;
		if (allocMeMap.exists(me))
			return allocMeMap.get(me);
		var newId = allocMeId++;
		allocMeMap.set(me, newId);
		allocMes.push(me);
		return newId;
	}

	public function getME(id:Int):MissionElementBase {
		if (id == -1)
			return null;
		return allocMes[id];
	}

	public function clear() {
		frameData = new BytesBuffer(); // clear
		frameDataOffsets = [];
		frameElapsedTimes = [];
		frameSizes = [];
		allocObjs = [];
		allocObjMap = [];
		allocMes = [];
		allocMeMap = [];
		allocId = 0;
		allocMeId = 0;
	}
}
