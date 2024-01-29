package net;

import net.NetPacket.MarbleUpdatePacket;
import net.Net;

@:publicFields
class MarbleUpdateQueue {
	var otherMarbleUpdates:Map<Int, Array<MarbleUpdatePacket>> = [];
	var myMarbleUpdate:MarbleUpdatePacket;
	var ourMoveApplied:Bool = false;

	public function new() {}

	public function enqueue(update:MarbleUpdatePacket) {
		var cc = update.clientId;
		if (cc != Net.clientId) {
			if (myMarbleUpdate != null && update.serverTicks > myMarbleUpdate.serverTicks)
				ourMoveApplied = true;
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
}
