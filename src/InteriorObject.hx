package src;

import h3d.Matrix;
import collision.CollisionEntity;
import src.GameObject;
import h3d.scene.Object;

class InteriorObject extends GameObject {
	public var collider:CollisionEntity;

	public function new() {
		super();
	}

	public override function setTransform(transform:Matrix) {
		super.setTransform(transform);
		collider.setTransform(transform);
	}
}
