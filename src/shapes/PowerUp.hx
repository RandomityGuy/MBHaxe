package shapes;

import src.DtsObject;

class PowerUp extends DtsObject {
	public var lastPickupTime:Float = -1;
	public var cooldownDuration:Float = 7;
	public var autoUse:Bool = false;

	public function new() {
		super();
		this.isCollideable = false;
		this.ambientRotate = true;
	}
}
