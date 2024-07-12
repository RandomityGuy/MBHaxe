package rewind;

import haxe.io.BytesOutput;
import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import dif.io.BytesWriter;
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
	var marblePosition:Vector;
	var marbleOrientation:Quat;
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
		currentCheckpoint:{obj:DtsObject, elem:MissionElementBase},
		currentCheckpointTrigger:CheckpointTrigger,
		checkpointCollectedGems:Map<Gem, Bool>,
		checkpointHeldPowerup:PowerUp,
		checkpointUp:Vector,
		checkpointBlast:Float
	};

	inline public function new() {}

	public inline function clone() {
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
			currentCheckpoint: checkpointState.currentCheckpoint != null ? {
				obj: checkpointState.currentCheckpoint.obj,
				elem: checkpointState.currentCheckpoint.elem,
			} : null,
			currentCheckpointTrigger: checkpointState.currentCheckpointTrigger,
			checkpointCollectedGems: checkpointState.checkpointCollectedGems.copy(),
			checkpointHeldPowerup: checkpointState.checkpointHeldPowerup,
			checkpointUp: checkpointState.checkpointUp != null ? checkpointState.checkpointUp.clone() : null,
			checkpointBlast: checkpointState.checkpointBlast,
		};
		return c;
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
		framesize += 8; // blastAmt
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
		bb.writeDouble(blastAmt);
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

	public inline function deserialize(rm:RewindManager, br:haxe.io.BytesInput) {
		marblePosition = new Vector();
		marbleOrientation = new Quat();
		marbleVelocity = new Vector();
		marbleAngularVelocity = new Vector();
		currentUp = new Vector();
		lastContactNormal = new Vector();
		timeState = new TimeState();
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
		gemCount = br.readInt16();
		gemStates = [];
		var gemStates_len = br.readInt16();
		for (i in 0...gemStates_len) {
			gemStates.push(br.readByte() != 0);
		}
		powerupStates = [];
		var powerupStates_len = br.readInt16();
		for (i in 0...powerupStates_len) {
			powerupStates.push(br.readDouble());
		}
		landMineStates = [];
		var landMineStates_len = br.readInt16();
		for (i in 0...landMineStates_len) {
			landMineStates.push(br.readDouble());
		}
		activePowerupStates = [];
		activePowerupStates.push(br.readDouble());
		activePowerupStates.push(br.readDouble());
		activePowerupStates.push(br.readDouble());
		activePowerupStates.push(br.readDouble());
		currentUp.x = br.readDouble();
		currentUp.y = br.readDouble();
		currentUp.z = br.readDouble();
		lastContactNormal.x = br.readDouble();
		lastContactNormal.y = br.readDouble();
		mpStates = [];
		var mpStates_len = br.readInt16();
		for (i in 0...mpStates_len) {
			var mpStates_item = new RewindMPState();
			mpStates_item.currentTime = br.readDouble();
			mpStates_item.targetTime = br.readDouble();
			mpStates_item.stoppedPosition = new Vector();
			mpStates_item.prevPosition = new Vector();
			mpStates_item.position = new Vector();
			mpStates_item.velocity = new Vector();
			if (br.readByte() != 0) {
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
			mpStates.push(mpStates_item);
		}
		trapdoorStates = [];
		var trapdoorStates_len = br.readInt16();
		for (i in 0...trapdoorStates_len) {
			var trapdoorStates_item = {
				lastContactTime: 0.0,
				lastDirection: 0,
				lastCompletion: 0.0
			};
			trapdoorStates_item.lastContactTime = br.readDouble();
			trapdoorStates_item.lastDirection = br.readByte();
			trapdoorStates_item.lastCompletion = br.readDouble();
			trapdoorStates.push(trapdoorStates_item);
		}
		blastAmt = br.readDouble();
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
