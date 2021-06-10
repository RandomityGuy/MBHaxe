package shapes;

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

	public function new() {
		super();
		this.isCollideable = false;
		this.ambientRotate = true;
	}

	public override function onMarbleInside(time:Float) {
		var pickupable = this.lastPickUpTime == -1 || (time - this.lastPickUpTime) >= this.cooldownDuration;
		if (!pickupable)
			return;

		if (this.pickUp()) {
			// this.level.replay.recordMarbleInside(this);

			this.lastPickUpTime = time;
			if (this.autoUse)
				this.use(time);

			this.level.displayAlert('You picked up a ${this.pickUpName}!');
			// if (this.element.showhelponpickup === "1" && !this.autoUse) displayHelp(`Press <func:bind mousefire> to use the ${this.pickUpName}!`);
		}
	}

	public override function update(currentTime:Float, dt:Float) {
		super.update(currentTime, dt);
		var opacity = 1.0;
		if (this.lastPickUpTime > 0 && this.cooldownDuration > 0) {
			var availableTime = this.lastPickUpTime + this.cooldownDuration;
			opacity = Util.clamp((currentTime - availableTime), 0, 1);
		}

		this.setOpacity(opacity);
	}

	public abstract function pickUp():Bool;

	public abstract function use(time:Float):Void;
}