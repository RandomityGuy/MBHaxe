package rewind;

import src.PathedInterior.PIState;
import shapes.PowerUp;
import h3d.Vector;
import h3d.Quat;
import src.TimeState;

@:publicFields
class RewindFrame {
	var timeState:TimeState;
	var marblePosition:Vector;
	var marbleOrientation:Quat;
	var marbleVelocity:Vector;
	var marbleAngularVelocity:Vector;
	var marblePowerup:PowerUp;
	var bonusTime:Float;
	var mpStates:Array<{
		curState:PIState,
		prevState:PIState,
		stopped:Bool,
		stopTime:Float
	}>;
	var gemCount:Int;
	var gemStates:Array<Bool>;
	var powerupStates:Array<Float>;
	var landMineStates:Array<Float>;
	var activePowerupStates:Array<Float>;
	var currentUp:Vector;
	var trapdoorStates:Array<{lastContactTime:Float, lastDirection:Int, lastCompletion:Float}>;
	var lastContactNormal:Vector;

	public function new() {}

	public function clone() {
		var c = new RewindFrame();
		c.timeState = timeState.clone();
		c.marblePosition = marblePosition.clone();
		c.marbleOrientation = marbleOrientation.clone();
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
		c.mpStates = [];
		for (s in mpStates) {
			c.mpStates.push({
				curState: {
					currentTime: s.curState.currentTime,
					targetTime: s.curState.targetTime,
					velocity: s.curState.velocity.clone(),
					currentPosition: s.curState.currentPosition.clone(),
					prevPosition: s.curState.prevPosition.clone(),
					changeTime: s.curState.changeTime,
				},
				stopTime: s.stopTime,
				stopped: s.stopped,
				prevState: s.prevState != null ? {
					currentTime: s.prevState.currentTime,
					targetTime: s.prevState.targetTime,
					velocity: s.prevState.velocity.clone(),
					currentPosition: s.prevState.currentPosition.clone(),
					prevPosition: s.prevState.prevPosition.clone(),
					changeTime: s.prevState.changeTime,
				} : null,
			});
		}
		c.trapdoorStates = [];
		for (s in trapdoorStates) {
			c.trapdoorStates.push({
				lastContactTime: s.lastContactTime,
				lastDirection: s.lastDirection,
				lastCompletion: s.lastCompletion,
			});
		}
	}
}
