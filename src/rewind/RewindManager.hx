package rewind;

import shapes.AbstractBumper;
import shapes.PowerUp;
import shapes.LandMine;
import src.MarbleWorld;
import shapes.Trapdoor;
import shapes.PushButton;
import src.Util;
import shapes.Nuke;

class RewindManager {
	var frames:Array<RewindFrame> = [];
	var level:MarbleWorld;

	public var timeScale:Float = 1;

	public function new(level:MarbleWorld) {
		this.level = level;
	}

	public function recordFrame() {
		var rf = new RewindFrame();
		rf.timeState = level.timeState.clone();
		rf.marblePosition = level.marble.getAbsPos().getPosition().clone();
		rf.marbleOrientation = level.marble.getRotationQuat().clone();
		rf.marbleVelocity = level.marble.velocity.clone();
		rf.marbleAngularVelocity = level.marble.omega.clone();
		rf.marblePowerup = level.marble.heldPowerup;
		rf.bonusTime = level.bonusTime;
		rf.gemCount = level.gemCount;
		rf.gemStates = level.gems.map(x -> x.pickedUp);
		rf.activePowerupStates = [@:privateAccess
			level.marble.superBounceEnableTime, @:privateAccess
			level.marble.shockAbsorberEnableTime, @:privateAccess
			level.marble.helicopterEnableTime, @:privateAccess
			level.marble.megaMarbleEnableTime
		];
		rf.currentUp = level.currentUp.clone();
		rf.lastContactNormal = level.marble.lastContactNormal.clone();
		rf.mpStates = level.pathedInteriors.map(x -> {
			return {
				curState: {
					currentTime: x.currentTime,
					targetTime: x.targetTime,
					velocity: x.velocity.clone(),
					currentPosition: x.currentPosition.clone(),
					prevPosition: x.prevPosition.clone(),
					changeTime: x.changeTime,
				},
				stopTime: @:privateAccess x.stopTime,
				stopped: @:privateAccess x.stopped,
				prevState: @:privateAccess x.previousState != null ? {
					currentTime: @:privateAccess x.previousState.currentTime,
					targetTime: @:privateAccess x.previousState.targetTime,
					velocity: @:privateAccess x.previousState.velocity.clone(),
					currentPosition: @:privateAccess x.previousState.currentPosition.clone(),
					prevPosition: @:privateAccess x.previousState.prevPosition.clone(),
					changeTime: @:privateAccess x.previousState.changeTime,
				} : null,
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
			checkpointUp: @:privateAccess level.checkpointUp != null ? @:privateAccess level.checkpointUp.clone() : null,
		};
		frames.push(rf);
	}

	public function applyFrame(rf:RewindFrame) {
		level.timeState = rf.timeState.clone();
		level.marble.setPosition(rf.marblePosition.x, rf.marblePosition.y, rf.marblePosition.z);
		level.marble.setRotationQuat(rf.marbleOrientation.clone());
		level.marble.velocity.set(rf.marbleVelocity.x, rf.marbleVelocity.y, rf.marbleVelocity.z);
		level.marble.omega.set(rf.marbleAngularVelocity.x, rf.marbleAngularVelocity.y, rf.marbleAngularVelocity.z);

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
		@:privateAccess level.marble.superBounceEnableTime = rf.activePowerupStates[0];
		@:privateAccess level.marble.shockAbsorberEnableTime = rf.activePowerupStates[1];
		@:privateAccess level.marble.helicopterEnableTime = rf.activePowerupStates[2];
		@:privateAccess level.marble.megaMarbleEnableTime = rf.activePowerupStates[3];

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

		level.currentUp.set(rf.currentUp.x, rf.currentUp.y, rf.currentUp.z);
		level.marble.lastContactNormal.set(rf.lastContactNormal.x, rf.lastContactNormal.y, rf.lastContactNormal.z);
		for (i in 0...rf.mpStates.length) {
			level.pathedInteriors[i].currentTime = rf.mpStates[i].curState.currentTime;
			level.pathedInteriors[i].targetTime = rf.mpStates[i].curState.targetTime;
			level.pathedInteriors[i].velocity.set(rf.mpStates[i].curState.velocity.x, rf.mpStates[i].curState.velocity.y, rf.mpStates[i].curState.velocity.z);
			level.pathedInteriors[i].currentPosition.set(rf.mpStates[i].curState.currentPosition.x, rf.mpStates[i].curState.currentPosition.y,
				rf.mpStates[i].curState.currentPosition.z);
			level.pathedInteriors[i].prevPosition.set(rf.mpStates[i].curState.prevPosition.x, rf.mpStates[i].curState.prevPosition.y,
				rf.mpStates[i].curState.prevPosition.z);
			level.pathedInteriors[i].changeTime = rf.mpStates[i].curState.changeTime;
			@:privateAccess level.pathedInteriors[i].stopTime = rf.mpStates[i].stopTime;
			@:privateAccess level.pathedInteriors[i].stopped = rf.mpStates[i].stopped;
			if (rf.mpStates[i].prevState != null) {
				@:privateAccess level.pathedInteriors[i].previousState.currentTime = rf.mpStates[i].prevState.currentTime;
				@:privateAccess level.pathedInteriors[i].previousState.targetTime = rf.mpStates[i].prevState.targetTime;
				@:privateAccess level.pathedInteriors[i].previousState.velocity.set(rf.mpStates[i].prevState.velocity.x, rf.mpStates[i].prevState.velocity.y,
					rf.mpStates[i].prevState.velocity.z);
				@:privateAccess level.pathedInteriors[i].previousState.currentPosition.set(rf.mpStates[i].prevState.currentPosition.x,
					rf.mpStates[i].prevState.currentPosition.y, rf.mpStates[i].prevState.currentPosition.z);
				@:privateAccess level.pathedInteriors[i].previousState.prevPosition.set(rf.mpStates[i].prevState.prevPosition.x,
					rf.mpStates[i].prevState.prevPosition.y, rf.mpStates[i].prevState.prevPosition.z);
				@:privateAccess level.pathedInteriors[i].previousState.changeTime = rf.mpStates[i].prevState.changeTime;
			} else {
				@:privateAccess level.pathedInteriors[i].previousState = null;
			}
		}
		var pstates = rf.powerupStates.copy();
		var lmstates = rf.landMineStates.copy();
		var tstates = rf.trapdoorStates.copy();
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
		level.marble.camera.oob = rf.oobState.oob;
		level.outOfBoundsTime = rf.oobState.timeState != null ? rf.oobState.timeState.clone() : null;
		level.blastAmount = rf.blastAmt;
		@:privateAccess level.checkpointUp = rf.checkpointState.checkpointUp;
		@:privateAccess level.checkpointCollectedGems = rf.checkpointState.checkpointCollectedGems;
		@:privateAccess level.cheeckpointBlast = rf.checkpointState.checkpointBlast;
		@:privateAccess level.checkpointHeldPowerup = rf.checkpointState.checkpointHeldPowerup;
		@:privateAccess level.currentCheckpoint = rf.checkpointState.currentCheckpoint;
		@:privateAccess level.currentCheckpointTrigger = rf.checkpointState.currentCheckpointTrigger;
	}

	public function getNextRewindFrame(absTime:Float):RewindFrame {
		if (frames.length == 0)
			return null;

		var topFrame = frames[frames.length - 1];
		while (topFrame.timeState.currentAttemptTime > absTime) {
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
