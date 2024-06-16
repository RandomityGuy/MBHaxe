package rewind;

import haxe.io.BytesInput;
import haxe.io.BytesBuffer;
import mis.MissionElement.MissionElementBase;
import src.GameObject;
import shapes.AbstractBumper;
import shapes.PowerUp;
import shapes.LandMine;
import src.MarbleWorld;
import shapes.Trapdoor;
import shapes.PushButton;
import src.Util;
import shapes.Nuke;
import src.Settings;

class RewindManager {
	var frameData:BytesBuffer;
	var frameElapsedTimes:Array<Float> = [];
	var frameDataOffsets:Array<Int> = [];
	var frameSizes:Array<Int> = [];
	var allocObjMap:Map<GameObject, Int> = [];
	var allocObjs:Array<GameObject> = [];
	var allocMeMap:Map<MissionElementBase, Int> = [];
	var allocMes:Array<MissionElementBase> = [];
	var level:MarbleWorld;
	var allocId = 0;
	var allocMeId = 0;

	public var timeScale:Float = 1;

	public function new(level:MarbleWorld) {
		this.level = level;
		this.timeScale = Settings.optionsSettings.rewindTimescale;
		this.frameData = new BytesBuffer();
	}

	public function recordFrame() {
		var rf = new RewindFrame();
		rf.timeState = level.timeState.clone();
		rf.marblePosition = level.marble.collider.transform.getPosition().clone();
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
		rf.currentUp = level.marble.currentUp.clone();
		rf.lastContactNormal = level.marble.lastContactNormal.clone();
		rf.mpStates = level.pathedInteriors.map(x -> {
			return {
				curState: {
					currentTime: x.currentTime,
					targetTime: x.targetTime,
					velocity: x.velocity.clone(),
				},
				stopped: @:privateAccess x.stopped,
				position: x.getAbsPos().getPosition().clone(),
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
		rf.blastAmt = level.marble.blastAmount;
		rf.oobState = {
			oob: level.marble.outOfBounds,
			timeState: level.marble.outOfBoundsTime != null ? level.marble.outOfBoundsTime.clone() : null
		};
		rf.checkpointState = {
			currentCheckpoint: @:privateAccess level.currentCheckpoint,
			currentCheckpointTrigger: @:privateAccess level.currentCheckpointTrigger,
			checkpointBlast: @:privateAccess level.cheeckpointBlast,
			checkpointCollectedGems: @:privateAccess level.checkpointCollectedGems.copy(),
			checkpointHeldPowerup: @:privateAccess level.checkpointHeldPowerup,
			checkpointUp: @:privateAccess level.checkpointUp != null ? @:privateAccess level.checkpointUp.clone() : null,
		};
		frameElapsedTimes.push(level.timeState.currentAttemptTime);
		frameDataOffsets.push(frameData.length);
		var frameDataSerialized = rf.serialize(this);
		frameSizes.push(frameDataSerialized.length);
		frameData.addBytes(frameDataSerialized, 0, frameDataSerialized.length);
		// frames.push(rf);
	}

	public function applyFrame(rf:RewindFrame) {
		level.timeState = rf.timeState.clone();
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
		level.gemCount = rf.gemCount;
		@:privateAccess level.playGui.formatGemCounter(level.gemCount, level.totalGems);
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

		level.marble.currentUp.set(rf.currentUp.x, rf.currentUp.y, rf.currentUp.z);
		level.marble.lastContactNormal.set(rf.lastContactNormal.x, rf.lastContactNormal.y, rf.lastContactNormal.z);
		for (i in 0...rf.mpStates.length) {
			level.pathedInteriors[i].currentTime = rf.mpStates[i].curState.currentTime;
			level.pathedInteriors[i].targetTime = rf.mpStates[i].curState.targetTime;
			level.pathedInteriors[i].velocity.set(rf.mpStates[i].curState.velocity.x, rf.mpStates[i].curState.velocity.y, rf.mpStates[i].curState.velocity.z);
			@:privateAccess level.pathedInteriors[i].stopped = rf.mpStates[i].stopped;
			level.pathedInteriors[i].setPosition(rf.mpStates[i].position.x, rf.mpStates[i].position.y, rf.mpStates[i].position.z);
			level.pathedInteriors[i].setTransform(level.pathedInteriors[i].getTransform());
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
		var fr = new RewindFrame();
		fr.deserialize(this, bi);
		return fr;
		return null;
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
