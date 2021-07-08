package collision;

import src.TimeState;
import h3d.Matrix;
import src.GameObject;
import src.Marble;
import h3d.col.Ray;
import h3d.Vector;
import h3d.col.Sphere;
import h3d.col.Bounds;

class BoxCollisionEntity extends CollisionEntity {
	var bounds:Bounds;

	public function new(bounds:Bounds, go:GameObject) {
		super(go);
		this.bounds = bounds;
		this.generateBoundingBox();
	}

	public override function generateBoundingBox() {
		this.boundingBox = bounds.clone();
		this.boundingBox.transform(this.transform);
	}

	public override function rayCast(rayOrigin:Vector, rayDirection:Vector) {
		// TEMP cause bruh
		return [];
	}

	public override function sphereIntersection(collisionEntity:SphereCollisionEntity, timeState:TimeState) {
		return [];
	}
}
