package src;

import src.TimeState;
import collision.CollisionInfo;
import h3d.scene.Object;

class GameObject extends Object {
	public var identifier:String;
	public var currentOpacity:Float = 1;
	public var isCollideable:Bool = false;
	public var isBoundingBoxCollideable:Bool = true;

	public function onMarbleContact(time:TimeState, ?contact:CollisionInfo) {}

	public function onMarbleInside(time:TimeState) {}

	public function onMarbleEnter(time:TimeState) {}

	public function onMarbleLeave(time:TimeState) {}

	public function onLevelStart() {}

	public function reset() {}
}
