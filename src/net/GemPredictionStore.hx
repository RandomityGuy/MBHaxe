package net;

import net.NetPacket.GemSpawnPacket;
import net.NetPacket.GemPickupPacket;

class GemPredictionStore {
	var predictions:Array<Bool>;

	public inline function new() {
		predictions = [];
	}

	public inline function alloc() {
		predictions.push(true);
	}

	public inline function getState(netIndex:Int) {
		return predictions[netIndex];
	}

	public inline function acknowledgeGemPickup(packet:GemPickupPacket) {
		predictions[packet.gemId] = true;
	}

	public inline function acknowledgeGemSpawn(packet:GemSpawnPacket) {
		for (gemId in packet.gemIds)
			predictions[gemId] = false;
	}

	public inline function reset() {
		for (i in 0...predictions.length) {
			predictions[i] = true;
		}
	}
}
