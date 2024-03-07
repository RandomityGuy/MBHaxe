package collision;

import src.GameObject;
import h3d.Vector;

class CollisionInfo {
	public var point:Vector;
	public var normal:Vector;
	public var velocity:Vector;
	public var collider:CollisionEntity;
	public var otherObject:GameObject;
	public var friction:Float;
	public var normalForce:Float;
	public var restitution:Float;
	public var contactDistance:Float;
	public var force:Float;

	public function new() {}
}
