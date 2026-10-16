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

	public function new() {
		position = new Vector();
		velocity = new Vector();
		omega = new Vector();
	}

	public inline function set(marble:Marble, tick:Int) {
		this.tick = tick;
		position.load(@:privateAccess marble.newPos);
		velocity.load(@:privateAccess marble.velocity);
		omega.load(@:privateAccess marble.omega);
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
	// Free list of recycled prediction states. Rollback truncates/drops history every
	// tick, so reusing these shells avoids churning MarblePrediction + 3 Vector allocations.
	var pool:Array<MarblePrediction>;

	public function new() {
		predictions = [];
		pool = [];
	}

	public function storeState(marble:Marble, tick:Int) {
		var arr = ensureHistory(marble);
		truncateFromTick(arr, tick);
		arr.push(obtain(marble, tick));
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
		var arr = predictions.get(marble);
		if (arr != null) {
			for (p in arr)
				pool.push(p);
			this.predictions.remove(marble);
		}
	}

	inline function obtain(marble:Marble, tick:Int) {
		var p = pool.length > 0 ? pool.pop() : new MarblePrediction();
		p.set(marble, tick);
		return p;
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
		if (idx > 0) {
			for (i in 0...idx)
				pool.push(arr[i]);
			arr.splice(0, idx);
		}
	}

	inline function truncateFromTick(arr:Array<MarblePrediction>, tick:Int) {
		var idx = lowerBound(arr, tick);
		if (idx < arr.length) {
			for (i in idx...arr.length)
				pool.push(arr[i]);
			arr.splice(idx, arr.length - idx);
		}
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
