package shapes;

import net.BitStream.OutputBitStream;
import net.NetPacket.PowerupPickupPacket;
import net.Net;
import src.Marble;
import src.AudioManager;
import hxd.res.Sound;
import mis.MissionElement.MissionElementItem;
import src.TimeState;
import src.Util;
import h3d.Vector;
import src.DtsObject;

abstract class PowerUp extends DtsObject {
	public var lastPickUpTime:Float = -1;
	public var cooldownDuration:Float = 7;
	public var autoUse:Bool = false;
	public var pickUpName:String;
	public var element:MissionElementItem;
	public var pickupSound:Sound;
	public var netIndex:Int;

	var customPickupMessage:String = null;

	public function new(element:MissionElementItem) {
		super();
		this.isBoundingBoxCollideable = true;
		this.isCollideable = false;
		this.ambientRotate = true;
		this.element = element;
	}

	public override function onMarbleInside(marble:Marble, timeState:TimeState) {
		var pickupable = this.lastPickUpTime == -1 || (timeState.currentAttemptTime - this.lastPickUpTime) >= this.cooldownDuration;
		if (!pickupable)
			return;

		if (this.pickUp(marble)) {
			// this.level.replay.recordMarbleInside(this);

			if (level.isMultiplayer && Net.isHost) {
				var b = new OutputBitStream();
				b.writeByte(NetPacketType.PowerupPickup);
				var pickupPacket = new PowerupPickupPacket();
				pickupPacket.clientId = @:privateAccess marble.connection != null ? @:privateAccess marble.connection.id : 0;
				pickupPacket.serverTicks = timeState.ticks;
				pickupPacket.powerupItemId = this.netIndex;
				pickupPacket.serialize(b);
				Net.sendPacketToAll(b);
			}

			this.lastPickUpTime = timeState.currentAttemptTime;
			if (this.autoUse)
				this.use(marble, timeState);

			if (level.marble == marble && @:privateAccess !marble.isNetUpdate) {
				if (customPickupMessage != null)
					this.level.displayAlert(customPickupMessage);
				else
					this.level.displayAlert('You picked up ${this.pickUpName}!');
				if (this.element.showhelponpickup == "1" && !this.autoUse)
					this.level.displayHelp('Press <func:bind mousefire> to use the ${this.pickUpName}!');

				if (pickupSound != null && !this.level.rewinding) {
					AudioManager.playSound(pickupSound);
				}
			}
		}
	}

	public override function update(timeState:TimeState) {
		super.update(timeState);
		var opacity = 1.0;
		if (this.lastPickUpTime > 0 && this.cooldownDuration > 0) {
			var availableTime = this.lastPickUpTime + this.cooldownDuration;
			opacity = Util.clamp((timeState.currentAttemptTime - availableTime), 0, 1);
		}

		this.setOpacity(opacity);
	}

	public abstract function pickUp(marble:Marble):Bool;

	public abstract function use(marble:Marble, timeState:TimeState):Void;

	public override function reset() {
		this.lastPickUpTime = Math.NEGATIVE_INFINITY;
	}
}
