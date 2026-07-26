package shapes;

import mis.MissionElement.MissionElementStaticShape;
import src.DtsObject;

/** Ported from `DefaultCannonBase` (`server/scripts/cannon.cs`) - the swiveling base a `Cannon`
	body sits on. Purely driven by its owning `Cannon` (`Cannon.updateAim`/`resetCannon` call
	`setTransform` on this directly every frame while aimed) - has no independent logic of its own
	beyond delegating a direct touch to the same `Marble.enterCannon` entry point the body uses,
	matching `CannonBase::onCollision`'s `%col.client.enterCannon(getServerSyncObject(%obj._cannon))`. */
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
