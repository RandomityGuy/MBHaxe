package net;

import net.NetPacket.MarbleUpdatePacket;
import net.NetPacket.MarbleMovePacket;
import src.TimeState;
import src.Marble;
import h3d.Vector;

@:publicFields
class MarblePrediction {
	var tick:Int;
	var position:Vector;
	var velocity:Vector;
	var omega:Vector;
	var isControl:Bool;
	var blastAmount:Int;

	public function new(marble:Marble, tick:Int) {
		this.tick = tick;
		position = @:privateAccess marble.newPos.clone();
		velocity = @:privateAccess marble.velocity.clone();
		omega = @:privateAccess marble.omega.clone();
		blastAmount = @:privateAccess marble.blastTicks;
		isControl = @:privateAccess marble.controllable;
	}

	public inline function getError(p:MarbleUpdatePacket) {
		// Just doing position errors is enough to make it work
		var subs = position.sub(p.position).lengthSq(); // + velocity.sub(p.velocity).lengthSq() + omega.sub(p.omega).lengthSq();
		if (p.netFlags != 0)
			subs += 1;
		// if (p.powerUpId != powerupItemId)
		// if (tick % 10 == 0)
		//	subs += 1; // temp
		// if (isControl)
		// 	subs += Math.abs(blastAmount - p.blastAmount);
		return subs;
	}
}

class MarblePredictionStore {
	var predictions:Map<Marble, Array<MarblePrediction>>;

	public function new() {
		predictions = [];
	}

	public function storeState(marble:Marble, tick:Int) {
		var state = new MarblePrediction(marble, tick);
		if (predictions.exists(marble)) {
			var arr = predictions[marble];
			while (arr.length != 0 && arr[0].tick >= tick)
				arr.shift();
			arr.push(state);
		} else {
			predictions.set(marble, [state]);
		}
	}

	public function retrieveState(marble:Marble, tick:Int) {
		if (predictions.exists(marble)) {
			var arr = predictions[marble];
			while (arr.length != 0 && arr[0].tick < tick)
				arr.shift();
			if (arr.length == 0)
				return null;
			var p = arr[0];
			if (p.tick == tick)
				return p;
			return null;
		}
		return null;
	}

	public function clearStatesAfterTick(marble:Marble, tick:Int) {
		if (predictions.exists(marble)) {
			var arr = predictions[marble];
			while (arr.length != 0 && arr[arr.length - 1].tick >= tick)
				arr.pop();
		}
	}

	public function removeMarbleFromPrediction(marble:Marble) {
		this.predictions.remove(marble);
	}
}
