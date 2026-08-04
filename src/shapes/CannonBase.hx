package shapes;

import mis.MissionElement.MissionElementStaticShape;
import src.DtsObject;

class CannonBase extends DtsObject {
	public var cannon:Cannon;

	public function new(?element:MissionElementStaticShape) {
		super();
		this.dtsPath = "data/shapes_pq/gameplay/cannon/base.dts";
		this.identifier = "CannonBase";
		this.isCollideable = true;
	}

	public override function onMarbleContact(marble:src.Marble, timeState:src.TimeState, ?contact:collision.CollisionInfo) {
		super.onMarbleContact(marble, timeState, contact);
		if (this.cannon != null)
			marble.enterCannon(this.cannon, timeState);
	}
}
