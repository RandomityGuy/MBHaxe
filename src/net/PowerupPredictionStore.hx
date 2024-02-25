package net;

import src.TimeState;
import net.NetPacket.PowerupPickupPacket;

class PowerupPredictionStore {
	var predictions:Array<Float>;

	public function new() {
		predictions = [];
	}

	public function alloc() {
		predictions.push(Math.NEGATIVE_INFINITY);
	}

	public inline function getState(netIndex:Int) {
		return predictions[netIndex];
	}

	public function acknowledgePowerupPickup(packet:PowerupPickupPacket, timeState:TimeState, futureTicks:Int) {
		predictions[packet.powerupItemId] = timeState.currentAttemptTime - futureTicks * 0.032; // Approximate
	}
}
