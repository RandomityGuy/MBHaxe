package net;

import net.NetPacket.ExplodableUpdatePacket;
import src.TimeState;
import net.NetPacket.PowerupPickupPacket;

class ExplodablePredictionStore {
	var predictions:Array<Int>;

	public inline function new() {
		predictions = [];
	}

	public inline function alloc() {
		predictions.push(-100000);
	}

	public inline function getState(netIndex:Int) {
		return predictions[netIndex];
	}

	public inline function acknowledgeExplodableUpdate(packet:ExplodableUpdatePacket) {
		predictions[packet.explodableId] = packet.serverTicks;
	}
}
