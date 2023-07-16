package rewind;

import h3d.Matrix;
import mis.MissionElement.MissionElementBase;
import triggers.CheckpointTrigger;
import src.PathedInterior.PIState;
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

	public function new() {}

	public function clone() {
		var c = new RewindMPState();
		c.currentTime = currentTime;
		c.targetTime = targetTime;
		c.stoppedPosition = stoppedPosition != null ? stoppedPosition.clone() : null;
		c.prevPosition = prevPosition.clone();
		c.position = position.clone();
		c.velocity = velocity.clone();
		return c;
	}
}

@:publicFields
class RewindFrame {
	var timeState:TimeState;
	var rewindAccumulator:Float;
	var marbleColliderTransform:Matrix;
	var marblePrevPosition:Vector;
	var marbleNextPosition:Vector;
	var marblePhysicsAccmulator:Float;
	var marbleOrientation:Quat;
	var marblePrevOrientation:Quat;
	var marbleVelocity:Vector;
	var marbleAngularVelocity:Vector;
	var marblePowerup:PowerUp;
	var bonusTime:Float;
	var mpStates:Array<RewindMPState>;
	var gemCount:Int;
	var gemStates:Array<Bool>;
	var powerupStates:Array<Float>;
	var landMineStates:Array<Float>;
	var activePowerupStates:Array<Float>;
	var currentUp:Vector;
	var trapdoorStates:Array<{lastContactTime:Float, lastDirection:Int, lastCompletion:Float}>;
	var lastContactNormal:Vector;
	var blastAmt:Float;
	var oobState:{
		oob:Bool,
		timeState:TimeState
	};

	var checkpointState:{
		currentCheckpoint:DtsObject,
		currentCheckpointTrigger:CheckpointTrigger,
		checkpointCollectedGems:Map<Gem, Bool>,
		checkpointHeldPowerup:PowerUp,
		checkpointBlast:Float
	};
	var modeState:RewindableState;

	public function new() {}

	public function clone() {
		var c = new RewindFrame();
		c.timeState = timeState.clone();
		c.rewindAccumulator = rewindAccumulator;
		c.marbleColliderTransform = marbleColliderTransform.clone();
		c.marblePrevPosition = marblePrevPosition.clone();
		c.marbleNextPosition = marbleNextPosition.clone();
		c.marblePhysicsAccmulator = marblePhysicsAccmulator;
		c.marbleOrientation = marbleOrientation.clone();
		c.marblePrevOrientation = marblePrevOrientation.clone();
		c.marbleVelocity = marbleVelocity.clone();
		c.marbleAngularVelocity = marbleAngularVelocity.clone();
		c.marblePowerup = marblePowerup;
		c.bonusTime = bonusTime;
		c.gemCount = gemCount;
		c.gemStates = gemStates.copy();
		c.powerupStates = powerupStates.copy();
		c.landMineStates = landMineStates.copy();
		c.activePowerupStates = activePowerupStates.copy();
		c.currentUp = currentUp.clone();
		c.lastContactNormal = lastContactNormal.clone();
		c.mpStates = mpStates.copy();
		c.trapdoorStates = [];
		for (s in trapdoorStates) {
			c.trapdoorStates.push({
				lastContactTime: s.lastContactTime,
				lastDirection: s.lastDirection,
				lastCompletion: s.lastCompletion,
			});
		}
		c.blastAmt = blastAmt;
		c.oobState = {
			oob: oobState.oob,
			timeState: oobState.timeState != null ? oobState.timeState.clone() : null
		};
		c.checkpointState = {
			currentCheckpoint: checkpointState.currentCheckpoint,
			currentCheckpointTrigger: checkpointState.currentCheckpointTrigger,
			checkpointCollectedGems: checkpointState.checkpointCollectedGems.copy(),
			checkpointHeldPowerup: checkpointState.checkpointHeldPowerup,
			checkpointBlast: checkpointState.checkpointBlast,
		};
		c.modeState = modeState != null ? modeState.clone() : null;
		return c;
	}
}
