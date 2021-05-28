package collision;

import dif.math.Point3F;
import dif.math.PlaneF;
import h3d.col.Plane;
import octree.Octree;
import h3d.col.Ray;
import h3d.Vector;
import octree.IOctreeObject;
import h3d.Matrix;
import h3d.col.Bounds;

class CollisionEntity implements IOctreeObject {
	public var boundingBox:Bounds;

	var octree:Octree;

	public var surfaces:Array<CollisionSurface>;

	public var priority:Int;
	public var position:Int;

	public var transform:Matrix;

	public function new() {
		this.octree = new Octree();
		this.surfaces = [];
		this.transform = Matrix.I();
	}

	public function addSurface(surface:CollisionSurface) {
		this.octree.insert(surface);
		this.surfaces.push(surface);
	}

	public function setTransform(transform:Matrix) {
		this.transform = transform;
		generateBoundingBox();
	}

	public function generateBoundingBox() {
		var boundingBox = new Bounds();
		for (surface in this.surfaces) {
			var tform = surface.boundingBox.clone();
			tform.transform(transform);
			boundingBox.add(tform);
		}
		this.boundingBox = boundingBox;
	}

	public function isIntersectedByRay(rayOrigin:Vector, rayDirection:Vector, intersectionPoint:Vector):Bool {
		// TEMP cause bruh
		return boundingBox.rayIntersection(Ray.fromValues(rayOrigin.x, rayOrigin.y, rayOrigin.z, rayDirection.x, rayDirection.y, rayDirection.z), true) != -1;
	}

	public function getElementType() {
		return 2;
	}

	public function setPriority(priority:Int) {
		this.priority = priority;
	}

	public function sphereIntersection(collisionEntity:SphereCollisionEntity) {
		var position = collisionEntity.transform.getPosition();
		var velocity = collisionEntity.velocity;
		var radius = collisionEntity.radius;

		var invMatrix = transform.clone();
		invMatrix.invert();
		var localpos = position.clone();
		localpos.transform(invMatrix);
		var surfaces = octree.radiusSearch(localpos, radius * 1.1);

		var contacts = [];

		for (obj in surfaces) {
			var surface:CollisionSurface = cast obj;

			var i = 0;
			while (i < surface.indices.length) {
				var v0 = surface.points[surface.indices[i]].transformed(transform);
				var v = surface.points[surface.indices[i + 1]].transformed(transform);
				var v2 = surface.points[surface.indices[i + 2]].transformed(transform);

				var surfacenormal = surface.normals[surface.indices[i]].transformed(transform);

				var res = Collision.IntersectTriangleSphere(v0, v, v2, surfacenormal, position, radius);
				var closest = res.point;
				// Collision.ClosestPtPointTriangle(position, radius, v0, v, v2, surface.normals[surface.indices[i]]);
				if (res.result) {
					if (position.sub(closest).lengthSq() < radius * radius) {
						var normal = res.normal;

						if (position.sub(closest).dot(surfacenormal) > 0) {
							normal.normalize();

							var cinfo = new CollisionInfo();
							cinfo.normal = res.normal; // surface.normals[surface.indices[i]];
							cinfo.point = closest;
							// cinfo.collider = this;
							cinfo.velocity = new Vector();
							cinfo.penetration = radius - (position.sub(closest).dot(normal));
							cinfo.restitution = 1;
							cinfo.friction = 1;
							contacts.push(cinfo);
						}
					}
				}

				i += 3;
			}
		}

		return contacts;
	}
}
