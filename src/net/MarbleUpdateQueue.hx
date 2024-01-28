package net;

import net.NetPacket.MarbleUpdatePacket;
import net.Net;

@:publicFields
class MarbleUpdateQueue {
	var otherMarbleUpdates:Map<Int, Array<MarbleUpdatePacket>> = [];
	var myMarbleUpdate:MarbleUpdatePacket;
	var ourMoveApplied:Bool = false;
	var collisionFrame:Int;

	public function new() {}

	public function enqueue(update:MarbleUpdatePacket) {
		var cc = update.clientId;
		if (update.serverTicks < collisionFrame)
			return;
		if (cc != Net.clientId) {
			if (otherMarbleUpdates.exists(cc)) {
				otherMarbleUpdates[cc].push(update);
			} else {
				otherMarbleUpdates[cc] = [update];
			}
		} else {
			if (myMarbleUpdate == null || update.serverTicks > myMarbleUpdate.serverTicks) {
				myMarbleUpdate = update;
				ourMoveApplied = false;
			}
		}
	}

	public function addCollisionFrame(tick:Int) {
		collisionFrame = tick + 2;
	}
}
