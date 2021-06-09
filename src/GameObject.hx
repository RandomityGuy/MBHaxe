package src;

import collision.CollisionInfo;
import h3d.scene.Object;

class GameObject extends Object {
	public var identifier:String;
	public var currentOpacity:Float = 1;

	public function onMarbleContact(time:Float, ?contact:CollisionInfo) {}

	public function onMarbleInside(time:Float) {}

	public function onMarbleEnter(time:Float) {}

	public function onMarbleLeave(time:Float) {}

	public function onLevelStart() {}

	public function reset() {}
}
