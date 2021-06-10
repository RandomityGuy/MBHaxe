package collision;

import src.GameObject;
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

	public var octree:Octree;

	public var surfaces:Array<CollisionSurface>;

	public var priority:Int;
	public var position:Int;
	public var velocity:Vector = new Vector();

	public var transform:Matrix;
	public var go:GameObject;

	public var userData:Int;

	public function new(go:GameObject) {
		this.go = go;
		this.octree = new Octree();
		this.surfaces = [];
		this.transform = Matrix.I();
	}

	public function addSurface(surface:CollisionSurface) {
		if (surface.points.length > 0) {
			this.octree.insert(surface);
			this.surfaces.push(surface);
		}
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
		var invMatrix = transform.clone();
		invMatrix.invert();
		var rStart = rayOrigin.transformed(invMatrix);
		var rDir = rayDirection.transformed(invMatrix);
		var intersections = octree.raycast(rStart, rDir);
		for (i in intersections) {
			i.point.transform(transform);
		}
		if (intersections.length > 0) {
			intersectionPoint.load(intersections[0].point);
		}
		return intersections.length > 0;
	}

	public function getElementType() {
		return 2;
	}

	public function setPriority(priority:Int) {
		this.priority = priority;
	}

	public function sphereIntersection(collisionEntity:SphereCollisionEntity, dt:Float) {
		var position = collisionEntity.transform.getPosition();
		var velocity = collisionEntity.velocity;
		var radius = collisionEntity.radius;

		var invMatrix = transform.clone();
		invMatrix.invert();
		var localpos = position.clone();
		localpos.transform(invMatrix);
		var surfaces = octree.radiusSearch(localpos, radius * 1.1);

		var tform = transform.clone();
		tform.setPosition(tform.getPosition().add(this.velocity.multiply(dt)));

		function toDifPoint(pt:Vector) {
			return new Point3F(pt.x, pt.y, pt.z);
		}

		function fromDifPoint(pt:Point3F) {
			return new Vector(pt.x, pt.y, pt.z);
		}

		var contacts = [];

		for (obj in surfaces) {
			var surface:CollisionSurface = cast obj;

			var i = 0;
			while (i < surface.indices.length) {
				var v0 = surface.points[surface.indices[i]].transformed(tform);
				var v = surface.points[surface.indices[i + 1]].transformed(tform);
				var v2 = surface.points[surface.indices[i + 2]].transformed(tform);

				var surfacenormal = surface.normals[surface.indices[i]].transformed3x3(transform);

				var res = Collision.IntersectTriangleSphere(v0, v, v2, surfacenormal, position, radius);
				var closest = res.point;
				// closest = Collision.ClosestPtPointTriangle(position, radius, v0, v, v2, surface.normals[surface.indices[i]]);
				if (closest != null) {
					if (position.sub(closest).lengthSq() < radius * radius) {
						var normal = res.normal;

						if (position.sub(closest).dot(surfacenormal) > 0) {
							normal.normalize();

							var cinfo = new CollisionInfo();
							cinfo.normal = normal; // surface.normals[surface.indices[i]];
							cinfo.point = closest;
							// cinfo.collider = this;
							cinfo.velocity = this.velocity;
							cinfo.contactDistance = closest.distance(position);
							cinfo.otherObject = this.go;
							// cinfo.penetration = radius - (position.sub(closest).dot(normal));
							cinfo.restitution = surface.restitution;
							cinfo.force = surface.force;
							cinfo.friction = surface.friction;
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
