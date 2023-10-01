package rewind;

import haxe.io.BytesInput;
import haxe.io.BytesBuffer;
import mis.MissionElement.MissionElementBase;
import src.GameObject;
import rewind.RewindFrame.RewindMPState;
import shapes.AbstractBumper;
import shapes.PowerUp;
import src.MarbleWorld;
import shapes.Trapdoor;
import src.Util;
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

	var timeAccumulator:Float = 0.0;
	var saveResolution:Float = 0.032;

	public function new(level:MarbleWorld) {
		this.level = level;
		this.timeScale = Settings.optionsSettings.rewindTimescale;
		this.frameData = new BytesBuffer();
	}

	public function recordFrame() {
		timeAccumulator += level.timeState.dt;
		while (timeAccumulator >= saveResolution) {
			timeAccumulator -= saveResolution;
			var rf = new RewindFrame();
			rf.timeState = level.timeState.clone();
			rf.marbleColliderTransform = level.marble.collider.transform.clone();
			rf.marblePrevPosition = @:privateAccess level.marble.oldPos.clone();
			rf.marbleNextPosition = @:privateAccess level.marble.newPos.clone();
			rf.marbleOrientation = @:privateAccess level.marble.getRotationQuat().clone();
			rf.marblePrevOrientation = @:privateAccess level.marble.prevRot.clone();
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
				var mpstate = new RewindMPState();
				mpstate.currentTime = x.currentTime;
				mpstate.targetTime = x.targetTime;
				mpstate.velocity = x.velocity.clone();
				mpstate.stoppedPosition = @:privateAccess x.stopped ? @:privateAccess x.stoppedPosition.clone() : null;
				mpstate.position = @:privateAccess x.position.clone();
				mpstate.prevPosition = @:privateAccess x.prevPosition.clone();
				return mpstate;
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
			frameElapsedTimes.push(level.timeState.currentAttemptTime);
			frameDataOffsets.push(frameData.length);
			var frameDataSerialized = rf.serialize(this);
			frameSizes.push(frameDataSerialized.length);
			frameData.addBytes(frameDataSerialized, 0, frameDataSerialized.length);
			// frames.push(rf);
		}
	}

	public function applyFrame(rf:RewindFrame) {
		timeAccumulator = rf.rewindAccumulator;
		level.timeState = rf.timeState.clone();
		@:privateAccess level.marble.oldPos.load(rf.marblePrevPosition);
		@:privateAccess level.marble.newPos.load(rf.marbleNextPosition);
		@:privateAccess level.marble.collider.transform.load(rf.marbleColliderTransform);
		@:privateAccess level.marble.physicsAccumulator = rf.marblePhysicsAccmulator;
		@:privateAccess level.marble.prevRot.load(rf.marblePrevOrientation);
		// level.marble.setMarblePosition(rf.marblePosition.x, rf.marblePosition.y, rf.marblePosition.z);
		level.marble.setRotationQuat(rf.marbleOrientation.clone());
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
		timeAccumulator = 0.0;
	}
}
