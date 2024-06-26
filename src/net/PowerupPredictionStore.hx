package net;

import src.TimeState;
import net.NetPacket.PowerupPickupPacket;

class PowerupPredictionStore {
	var predictions:Array<Float>;

	public inline function new() {
		predictions = [];
	}

	public inline function alloc() {
		predictions.push(Math.NEGATIVE_INFINITY);
	}

	public inline function getState(netIndex:Int) {
		return predictions[netIndex];
	}

	public inline function acknowledgePowerupPickup(packet:PowerupPickupPacket, timeState:TimeState, futureTicks:Int) {
		predictions[packet.powerupItemId] = timeState.currentAttemptTime - futureTicks * 0.032; // Approximate
	}

	public inline function reset() {
		for (i in 0...predictions.length) {
			predictions[i] = Math.NEGATIVE_INFINITY;
		}
	}
}
