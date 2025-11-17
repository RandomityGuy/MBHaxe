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
		var arr = ensureHistory(marble);
		truncateFromTick(arr, tick);
		arr.push(new MarblePrediction(marble, tick));
	}

	public function retrieveState(marble:Marble, tick:Int) {
		var arr = predictions.get(marble);
		if (arr == null)
			return null;

		dropBeforeTick(arr, tick);
		return (arr.length != 0 && arr[0].tick == tick) ? arr[0] : null;
	}

	public function clearStatesAfterTick(marble:Marble, tick:Int) {
		var arr = predictions.get(marble);
		if (arr != null)
			truncateFromTick(arr, tick);
	}

	public function removeMarbleFromPrediction(marble:Marble) {
		this.predictions.remove(marble);
	}

	inline function ensureHistory(marble:Marble) {
		var arr = predictions.get(marble);
		if (arr == null) {
			arr = [];
			predictions.set(marble, arr);
		}
		return arr;
	}

	inline function dropBeforeTick(arr:Array<MarblePrediction>, tick:Int) {
		var idx = lowerBound(arr, tick);
		if (idx > 0)
			arr.splice(0, idx);
	}

	inline function truncateFromTick(arr:Array<MarblePrediction>, tick:Int) {
		var idx = lowerBound(arr, tick);
		if (idx < arr.length)
			arr.splice(idx, arr.length - idx);
	}

	static inline function lowerBound(arr:Array<MarblePrediction>, tick:Int) {
		var lo = 0;
		var hi = arr.length;
		while (lo < hi) {
			var mid = (lo + hi) >> 1;
			if (arr[mid].tick < tick)
				lo = mid + 1;
			else
				hi = mid;
		}
		return lo;
	}
}
