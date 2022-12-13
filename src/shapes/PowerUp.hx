package shapes;

import src.AudioManager;
import hxd.res.Sound;
import mis.MissionElement.MissionElementItem;
import src.TimeState;
import src.Util;
import h3d.Vector;
import src.DtsObject;

class PowerupParams {
	public var duration:Float = 5;
	public var airAccel = 1.0;
	public var activateTime:Float = 0;
	public var bounce = -1.0;
	public var sizeScale = 1.0;
	public var massScale = 1.0;
	public var gravityMod = 1.0;
	public var repulseDist = 0.0;
	public var repulseMax = 0.0;
	public var boostDir = new Vector();
	public var timeFreeze:Float = 0;
	public var boostAmount = 0.0;
	public var boostMassless = 0.0;

	public function new() {};
}

abstract class PowerUp extends DtsObject {
	public var lastPickUpTime:Float = -1;
	public var cooldownDuration:Float = 7;
	public var autoUse:Bool = false;
	public var powerupParams:PowerupParams = new PowerupParams();
	public var pickUpName:String;
	public var element:MissionElementItem;
	public var pickupSound:Sound;

	public function new(element:MissionElementItem) {
		super();
		this.isBoundingBoxCollideable = true;
		this.isCollideable = false;
		this.ambientRotate = true;
		this.element = element;
	}

	public override function onMarbleInside(timeState:TimeState) {
		var pickupable = this.lastPickUpTime == -1 || (timeState.currentAttemptTime - this.lastPickUpTime) >= this.cooldownDuration;
		if (!pickupable)
			return;

		if (this.pickUp()) {
			// this.level.replay.recordMarbleInside(this);

			this.lastPickUpTime = timeState.currentAttemptTime;
			if (this.autoUse)
				this.use(timeState);

			this.level.displayAlert('You picked up a ${this.pickUpName}!');
			if (this.element.showhelponpickup == "1" && !this.autoUse)
				this.level.displayHelp('Press <func:bind mousefire> to use the ${this.pickUpName}!');

			if (pickupSound != null) {
				AudioManager.playSound(pickupSound);
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

	public abstract function pickUp():Bool;

	public abstract function use(timeState:TimeState):Void;

	public override function reset() {
		this.lastPickUpTime = Math.NEGATIVE_INFINITY;
	}
}
