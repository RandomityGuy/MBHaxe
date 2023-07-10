package rewind;

import shapes.AbstractBumper;
import shapes.PowerUp;
import src.MarbleWorld;
import shapes.Trapdoor;
import src.Util;
import src.Settings;

class RewindManager {
	var frames:Array<RewindFrame> = [];
	var level:MarbleWorld;

	public var timeScale:Float = 1;

	public function new(level:MarbleWorld) {
		this.level = level;
		this.timeScale = Settings.optionsSettings.rewindTimescale;
	}

	public function recordFrame() {
		var rf = new RewindFrame();
		rf.timeState = level.timeState.clone();
		rf.marbleColliderTransform = level.marble.collider.transform.clone();
		rf.marblePrevPosition = @:privateAccess level.marble.oldPos.clone();
		rf.marbleNextPosition = @:privateAccess level.marble.newPos.clone();
		rf.marbleOrientation = @:privateAccess level.marble.prevRot.clone();
		rf.marblePhysicsAccmulator = @:privateAccess level.marble.physicsAccumulator;
		rf.marbleVelocity = level.marble.velocity.clone();
		rf.marbleAngularVelocity = level.marble.omega.clone();
		rf.marblePowerup = level.marble.heldPowerup;
		rf.bonusTime = level.bonusTime;
		rf.gemCount = level.gemCount;
		rf.gemStates = level.gems.map(x -> x.pickedUp);
		rf.activePowerupStates = [@:privateAccess level.marble.helicopterEnableTime, @:privateAccess level.marble.megaMarbleEnableTime];
		rf.currentUp = level.currentUp.clone();
		rf.lastContactNormal = level.marble.lastContactNormal.clone();
		rf.mpStates = level.pathedInteriors.map(x -> {
			return {
				curState: {
					currentTime: x.currentTime,
					targetTime: x.targetTime,
					velocity: x.velocity.clone(),
				},
				stopped: @:privateAccess x.stopped,
				position: @:privateAccess x.position.clone(),
				prevPosition: @:privateAccess x.prevPosition.clone(),
				stoppedPosition: @:privateAccess x.stoppedPosition != null ? @:privateAccess x.stoppedPosition.clone() : null,
			}
		});
		rf.powerupStates = [];
		rf.landMineStates = [];
		rf.trapdoorStates = [];
		for (dts in level.dtsObjects) {
			if (dts is PowerUp) {
				var pow:PowerUp = cast dts;
				rf.powerupStates.push(pow.lastPickUpTime);
			}
			if (dts is Trapdoor) {
				var td:Trapdoor = cast dts;
				rf.trapdoorStates.push({
					lastCompletion: td.lastCompletion,
					lastDirection: td.lastDirection,
					lastContactTime: td.lastContactTime
				});
			}
			if (dts is AbstractBumper) {
				var ab:AbstractBumper = cast dts;
				rf.powerupStates.push(ab.lastContactTime);
			}
		}
		rf.blastAmt = level.blastAmount;
		rf.oobState = {
			oob: level.outOfBounds,
			timeState: level.outOfBoundsTime != null ? level.outOfBoundsTime.clone() : null
		};
		rf.checkpointState = {
			currentCheckpoint: @:privateAccess level.currentCheckpoint,
			currentCheckpointTrigger: @:privateAccess level.currentCheckpointTrigger,
			checkpointBlast: @:privateAccess level.cheeckpointBlast,
			checkpointCollectedGems: @:privateAccess level.checkpointCollectedGems.copy(),
			checkpointHeldPowerup: @:privateAccess level.checkpointHeldPowerup,
		};
		rf.modeState = level.gameMode.getRewindState();
		frames.push(rf);
	}

	public function applyFrame(rf:RewindFrame) {
		level.timeState = rf.timeState.clone();
		@:privateAccess level.marble.oldPos.load(rf.marblePrevPosition);
		@:privateAccess level.marble.newPos.load(rf.marbleNextPosition);
		@:privateAccess level.marble.collider.transform.load(rf.marbleColliderTransform);
		@:privateAccess level.marble.physicsAccumulator = rf.marblePhysicsAccmulator;
		@:privateAccess level.marble.prevRot.load(rf.marbleOrientation);
		// level.marble.setMarblePosition(rf.marblePosition.x, rf.marblePosition.y, rf.marblePosition.z);
		// level.marble.setRotationQuat(rf.marbleOrientation.clone());
		level.marble.velocity.load(rf.marbleVelocity);
		level.marble.omega.load(rf.marbleAngularVelocity);

		if (level.marble.heldPowerup == null) {
			if (rf.marblePowerup != null) {
				level.pickUpPowerUp(rf.marblePowerup);
			}
		} else {
			if (rf.marblePowerup == null) {
				level.deselectPowerUp();
			} else {
				level.pickUpPowerUp(rf.marblePowerup);
			}
		}

		level.bonusTime = rf.bonusTime;
		level.gemCount = rf.gemCount;
		@:privateAccess level.playGui.formatGemCounter(level.gemCount, level.totalGems);
		for (i in 0...rf.gemStates.length) {
			level.gems[i].setHide(rf.gemStates[i]);
		}
		@:privateAccess level.marble.helicopterEnableTime = rf.activePowerupStates[0];
		@:privateAccess level.marble.megaMarbleEnableTime = rf.activePowerupStates[1];

		if (level.currentUp.x != rf.currentUp.x || level.currentUp.y != rf.currentUp.y || level.currentUp.z != rf.currentUp.z) {
			level.setUp(rf.currentUp, level.timeState);
			// Hacky things
			@:privateAccess level.orientationChangeTime = level.timeState.currentAttemptTime - 300;
			var oldorient = level.newOrientationQuat;
			level.newOrientationQuat = @:privateAccess level.oldOrientationQuat;
			@:privateAccess level.oldOrientationQuat = oldorient;
		}

		var gravitycompletion = Util.clamp((level.timeState.currentAttemptTime - @:privateAccess level.orientationChangeTime) / 300, 0, 1);
		if (gravitycompletion == 0) {
			level.newOrientationQuat = @:privateAccess level.oldOrientationQuat;
			@:privateAccess level.orientationChangeTime = -1e8;
		}

		level.currentUp.load(rf.currentUp);
		level.marble.lastContactNormal.load(rf.lastContactNormal);
		for (i in 0...rf.mpStates.length) {
			level.pathedInteriors[i].currentTime = rf.mpStates[i].curState.currentTime;
			level.pathedInteriors[i].targetTime = rf.mpStates[i].curState.targetTime;
			level.pathedInteriors[i].velocity.load(rf.mpStates[i].curState.velocity);
			@:privateAccess level.pathedInteriors[i].stopped = rf.mpStates[i].stopped;
			@:privateAccess level.pathedInteriors[i].position.load(rf.mpStates[i].position);
			@:privateAccess level.pathedInteriors[i].prevPosition.load(rf.mpStates[i].prevPosition);
			@:privateAccess level.pathedInteriors[i].stoppedPosition = rf.mpStates[i].stoppedPosition;
			// level.pathedInteriors[i].setTransform(level.pathedInteriors[i].getTransform());
		}
		var pstates = rf.powerupStates.copy();
		var lmstates = rf.landMineStates.copy();
		var tstates = rf.trapdoorStates.copy();
		for (dts in level.dtsObjects) {
			if (dts is PowerUp) {
				var pow:PowerUp = cast dts;
				pow.lastPickUpTime = pstates.shift();
			}
			if (dts is Trapdoor) {
				var td:Trapdoor = cast dts;
				var tdState = tstates.shift();
				td.lastCompletion = tdState.lastCompletion;
				td.lastDirection = tdState.lastDirection;
				td.lastContactTime = tdState.lastContactTime;
			}
			if (dts is AbstractBumper) {
				var ab:AbstractBumper = cast dts;
				ab.lastContactTime = pstates.shift();
			}
		}

		if (!rf.oobState.oob) {
			@:privateAccess level.cancel(level.oobSchedule);
			@:privateAccess level.cancel(level.oobSchedule2);
		} else {
			level.goOutOfBounds();
		}

		level.outOfBounds = rf.oobState.oob;
		if (level.outOfBounds)
			@:privateAccess level.playGui.setCenterText('Out of Bounds');
		else
			@:privateAccess level.playGui.setCenterText('');
		level.marble.camera.oob = rf.oobState.oob;
		level.outOfBoundsTime = rf.oobState.timeState != null ? rf.oobState.timeState.clone() : null;
		level.blastAmount = rf.blastAmt;
		@:privateAccess level.checkpointCollectedGems = rf.checkpointState.checkpointCollectedGems;
		@:privateAccess level.cheeckpointBlast = rf.checkpointState.checkpointBlast;
		@:privateAccess level.checkpointHeldPowerup = rf.checkpointState.checkpointHeldPowerup;
		@:privateAccess level.currentCheckpoint = rf.checkpointState.currentCheckpoint;
		@:privateAccess level.currentCheckpointTrigger = rf.checkpointState.currentCheckpointTrigger;
		if (rf.modeState != null)
			rf.modeState.apply(level);
	}

	public function getNextRewindFrame(absTime:Float):RewindFrame {
		if (frames.length == 0)
			return null;

		var topFrame = frames[frames.length - 1];
		while (topFrame.timeState.currentAttemptTime > absTime) {
			if (frames.length == 1) {
				return frames[0];
			}
			frames.pop();
			if (frames.length == 0)
				return null;
			topFrame = frames[frames.length - 1];
		}
		return topFrame;
	}

	public function clear() {
		frames = [];
	}
}
