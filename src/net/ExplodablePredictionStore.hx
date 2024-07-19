package net;

import src.MarbleWorld;
import net.NetPacket.ExplodableUpdatePacket;
import src.TimeState;
import net.NetPacket.PowerupPickupPacket;

class ExplodablePredictionStore {
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

	public inline function acknowledgeExplodableUpdate(packet:ExplodableUpdatePacket) {
		predictions[packet.explodableId] = packet.serverTicks;
		if (!world.explodablesToTick.contains(packet.explodableId))
			world.explodablesToTick.push(packet.explodableId);
		world.explodables[packet.explodableId].playExplosion();
	}

	public inline function reset() {
		for (i in 0...predictions.length) {
			predictions[i] = -100000;
		}
	}
}
