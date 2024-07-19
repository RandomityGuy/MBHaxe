package net;

import src.MarbleWorld;
import net.NetPacket.ExplodableUpdatePacket;
import src.TimeState;
import net.NetPacket.PowerupPickupPacket;

class TrapdoorPredictionStore {
	var world:MarbleWorld;
	var predictions:Array<Int>;

	public inline function new(world:MarbleWorld) {
		predictions = [];
		this.world = world;
	}

	public inline function alloc() {
		predictions.push(-100000);
	}

	public inline function getState(netIndex:Int) {
		return predictions[netIndex];
	}

	public inline function acknowledgeTrapdoorUpdate(id:Int, ticks:Int) {
		predictions[id] = ticks;
		if (!world.trapdoorsToTick.contains(id))
			world.trapdoorsToTick.push(id);
	}

	public inline function reset() {
		for (i in 0...predictions.length) {
			predictions[i] = -100000;
		}
	}
}
