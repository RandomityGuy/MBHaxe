package src;

import h3d.Matrix;
import collision.CollisionEntity;
import headbutt.threed.Headbutt;
import headbutt.threed.shapes.Sphere;
import glm.Vec3;
import dif.math.Point3F;
import h3d.scene.Mesh;
import h3d.col.Bounds;
import h3d.scene.RenderContext;
import h3d.prim.Polygon;
import h3d.scene.Object;

class InteriorGeometry extends Object {
	public var collider:CollisionEntity;

	public function new() {
		super();
	}

	public override function setTransform(transform:Matrix) {
		super.setTransform(transform);
		collider.setTransform(transform);
	}
}
