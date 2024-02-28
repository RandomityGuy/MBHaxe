package net;

import net.NetPacket.GemSpawnPacket;
import net.NetPacket.GemPickupPacket;

class GemPredictionStore {
	var predictions:Array<Bool>;

	public function new() {
		predictions = [];
	}

	public function alloc() {
		predictions.push(true);
	}

	public inline function getState(netIndex:Int) {
		return predictions[netIndex];
	}

	public function acknowledgeGemPickup(packet:GemPickupPacket) {
		predictions[packet.gemId] = true;
	}

	public function acknowledgeGemSpawn(packet:GemSpawnPacket) {
		for (gemId in packet.gemIds)
			predictions[gemId] = false;
	}
}
