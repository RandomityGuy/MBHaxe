package net;

import h3d.Vector;
import net.NetPacket.MarbleNetFlags;
import net.NetPacket.MarbleUpdatePacket;
import net.Net;

@:publicFields
class OtherMarbleUpdate {
	var packets:Array<MarbleUpdatePacket> = [];
	var lastBlastTick:Int;
	var lastHeliTick:Int;
	var lastMegaTick:Int;
	var lastPowerUpId:Int = 0x1FF;
	var lastGravityUp:Vector;
	var lastTrapdoorUpdates:Map<Int, Int> = [];

	public function new() {}
}

@:publicFields
class MarbleUpdateQueue {
	var otherMarbleUpdates:Map<Int, OtherMarbleUpdate> = [];
	var myMarbleUpdate:MarbleUpdatePacket;
	var ourMoveApplied:Bool = false;

	public function new() {}

	inline function applyFlagged<T>(flag:Int, updateHas:Bool, updateValue:T, lastValue:T, setter:(T) -> Void, updater:(T) -> Void) {
		if (updateHas)
			updater(updateValue);
		else
			setter(lastValue);
	}

	public function enqueue(update:MarbleUpdatePacket) {
		var cc = update.clientId;
		var flags = update.netFlags;

		if (cc != Net.clientId) {
			var otherUpdate = otherMarbleUpdates.get(cc);
			if (otherUpdate == null) {
				otherUpdate = new OtherMarbleUpdate();
				otherMarbleUpdates[cc] = otherUpdate;
			}
			if (otherUpdate.packets.length == 0) {
				if (flags & MarbleNetFlags.DoBlast != 0)
					otherUpdate.lastBlastTick = update.blastTick;
				if (flags & MarbleNetFlags.DoHelicopter != 0)
					otherUpdate.lastHeliTick = update.heliTick;
				if (flags & MarbleNetFlags.DoMega != 0) {
					otherUpdate.lastMegaTick = update.megaTick;
				}
				if (flags & MarbleNetFlags.PickupPowerup != 0)
					otherUpdate.lastPowerUpId = update.powerUpId;
				if (flags & MarbleNetFlags.GravityChange != 0)
					otherUpdate.lastGravityUp = update.gravityDirection;
				if (flags & MarbleNetFlags.UpdateTrapdoor != 0)
					otherUpdate.lastTrapdoorUpdates = update.trapdoorUpdates;
			}

			applyFlagged(MarbleNetFlags.DoBlast, (flags & MarbleNetFlags.DoBlast) != 0, update.blastTick, otherUpdate.lastBlastTick,
				v -> update.blastTick = v, v -> otherUpdate.lastBlastTick = v);
			applyFlagged(MarbleNetFlags.DoHelicopter, (flags & MarbleNetFlags.DoHelicopter) != 0, update.heliTick, otherUpdate.lastHeliTick,
				v -> update.heliTick = v, v -> otherUpdate.lastHeliTick = v);
			applyFlagged(MarbleNetFlags.DoMega, (flags & MarbleNetFlags.DoMega) != 0, update.megaTick, otherUpdate.lastMegaTick, v -> update.megaTick = v,
				v -> otherUpdate.lastMegaTick = v);
			applyFlagged(MarbleNetFlags.PickupPowerup, (flags & MarbleNetFlags.PickupPowerup) != 0, update.powerUpId, otherUpdate.lastPowerUpId,
				v -> update.powerUpId = v, v -> otherUpdate.lastPowerUpId = v);
			applyFlagged(MarbleNetFlags.GravityChange, (flags & MarbleNetFlags.GravityChange) != 0, update.gravityDirection, otherUpdate.lastGravityUp,
				v -> update.gravityDirection = v, v -> otherUpdate.lastGravityUp = v);
			applyFlagged(MarbleNetFlags.UpdateTrapdoor, (flags & MarbleNetFlags.UpdateTrapdoor) != 0, update.trapdoorUpdates, otherUpdate.lastTrapdoorUpdates,
				v -> update.trapdoorUpdates = v, v -> otherUpdate.lastTrapdoorUpdates = v);
			otherUpdate.packets.push(update);
		} else if (myMarbleUpdate == null || update.serverTicks > myMarbleUpdate.serverTicks) {
			if (myMarbleUpdate != null) {
				if ((flags & MarbleNetFlags.DoBlast) == 0)
					update.blastTick = myMarbleUpdate.blastTick;
				if ((flags & MarbleNetFlags.DoHelicopter) == 0)
					update.heliTick = myMarbleUpdate.heliTick;
				if ((flags & MarbleNetFlags.DoMega) == 0)
					update.megaTick = myMarbleUpdate.megaTick;
				if ((flags & MarbleNetFlags.PickupPowerup) == 0)
					update.powerUpId = myMarbleUpdate.powerUpId;
				if ((flags & MarbleNetFlags.GravityChange) == 0)
					update.gravityDirection = myMarbleUpdate.gravityDirection;
				if ((flags & MarbleNetFlags.UpdateTrapdoor) == 0)
					update.trapdoorUpdates = myMarbleUpdate.trapdoorUpdates;
			}
			myMarbleUpdate = update;
			ourMoveApplied = false;
		}
	}
}
