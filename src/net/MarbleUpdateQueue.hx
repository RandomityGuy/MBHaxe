package net;

import net.NetPacket.MarbleNetFlags;
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
				var ourList = otherMarbleUpdates[cc];
				if (ourList.length != 0) {
					var lastOne = ourList[ourList.length - 1];

					// Copy the netflagg'd fields
					if (update.netFlags & MarbleNetFlags.DoBlast == 0)
						update.blastTick = lastOne.blastTick;
					if (update.netFlags & MarbleNetFlags.DoHelicopter == 0)
						update.heliTick = lastOne.heliTick;
					if (update.netFlags & MarbleNetFlags.DoMega == 0)
						update.megaTick = lastOne.megaTick;
					if (update.netFlags & MarbleNetFlags.PickupPowerup == 0)
						update.powerUpId = lastOne.powerUpId;
				}
				ourList.push(update);
			} else {
				otherMarbleUpdates[cc] = [update];
			}
		} else {
			if (myMarbleUpdate == null || update.serverTicks > myMarbleUpdate.serverTicks) {
				if (myMarbleUpdate != null) {
					// Copy the netflagg'd fields
					if (update.netFlags & MarbleNetFlags.DoBlast == 0)
						update.blastTick = myMarbleUpdate.blastTick;
					if (update.netFlags & MarbleNetFlags.DoHelicopter == 0)
						update.heliTick = myMarbleUpdate.heliTick;
					if (update.netFlags & MarbleNetFlags.DoMega == 0)
						update.megaTick = myMarbleUpdate.megaTick;
					if (update.netFlags & MarbleNetFlags.PickupPowerup == 0)
						update.powerUpId = myMarbleUpdate.powerUpId;
				}
				myMarbleUpdate = update;
				ourMoveApplied = false;
			}
		}
	}
}
