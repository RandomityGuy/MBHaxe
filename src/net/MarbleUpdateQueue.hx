package net;

import net.NetPacket.MarbleNetFlags;
import net.NetPacket.MarbleUpdatePacket;
import net.Net;

@:publicFields
class OtherMarbleUpdate {
	var packets:Array<MarbleUpdatePacket> = [];
	var lastBlastTick:Int;
	var lastHeliTick:Int;
	var lastMegaTick:Int;
	var lastPowerUpId:Int;

	public function new() {}
}

@:publicFields
class MarbleUpdateQueue {
	var otherMarbleUpdates:Map<Int, OtherMarbleUpdate> = [];
	var myMarbleUpdate:MarbleUpdatePacket;
	var ourMoveApplied:Bool = false;

	public function new() {}

	public function enqueue(update:MarbleUpdatePacket) {
		var cc = update.clientId;
		if (cc != Net.clientId) {
			if (myMarbleUpdate != null && update.serverTicks > myMarbleUpdate.serverTicks)
				ourMoveApplied = true;
			if (otherMarbleUpdates.exists(cc)) {
				var otherUpdate = otherMarbleUpdates[cc];
				var ourList = otherUpdate.packets;
				// Copy the netflagg'd fields
				if (update.netFlags & MarbleNetFlags.DoBlast == 0)
					update.blastTick = otherUpdate.lastBlastTick;
				else
					otherUpdate.lastBlastTick = update.blastTick;
				if (update.netFlags & MarbleNetFlags.DoHelicopter == 0)
					update.heliTick = otherUpdate.lastHeliTick;
				else
					otherUpdate.lastHeliTick = update.heliTick;
				if (update.netFlags & MarbleNetFlags.DoMega == 0)
					update.megaTick = otherUpdate.lastMegaTick;
				else
					otherUpdate.lastMegaTick = update.megaTick;
				if (update.netFlags & MarbleNetFlags.PickupPowerup == 0)
					update.powerUpId = otherUpdate.lastPowerUpId;
				else
					otherUpdate.lastPowerUpId = update.powerUpId;
				ourList.push(update);
			} else {
				var otherUpdate = new OtherMarbleUpdate();
				otherUpdate.packets.push(update);
				// Copy the netflagg'd fields
				if (update.netFlags & MarbleNetFlags.DoBlast != 0)
					otherUpdate.lastBlastTick = update.blastTick;
				if (update.netFlags & MarbleNetFlags.DoHelicopter != 0)
					otherUpdate.lastHeliTick = update.heliTick;
				if (update.netFlags & MarbleNetFlags.DoMega != 0)
					otherUpdate.lastMegaTick = update.megaTick;
				if (update.netFlags & MarbleNetFlags.PickupPowerup != 0)
					otherUpdate.lastPowerUpId = update.powerUpId;
				otherMarbleUpdates[cc] = otherUpdate;
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
