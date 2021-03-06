package collision;

import src.TimeState;
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
import src.PathedInterior;

class CollisionEntity implements IOctreeObject {
	public var boundingBox:Bounds;

	public var octree:Octree;

	public var surfaces:Array<CollisionSurface>;

	public var priority:Int;
	public var position:Int;
	public var velocity:Vector = new Vector();

	public var transform:Matrix;

	var invTransform:Matrix;

	public var go:GameObject;

	public var userData:Int;

	public function new(go:GameObject) {
		this.go = go;
		this.octree = new Octree();
		this.surfaces = [];
		this.transform = Matrix.I();
		this.invTransform = Matrix.I();
	}

	public function addSurface(surface:CollisionSurface) {
		if (surface.points.length > 0) {
			this.octree.insert(surface);
			this.surfaces.push(surface);
		}
	}

	public function setTransform(transform:Matrix) {
		if (this.transform == transform)
			return;
		this.transform = transform;
		this.invTransform = transform.getInverse();
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

	public function rayCast(rayOrigin:Vector, rayDirection:Vector):Array<RayIntersectionData> {
		var invMatrix = invTransform;
		var rStart = rayOrigin.clone();
		rStart.transform(invMatrix);
		var rDir = rayDirection.transformed3x3(invMatrix);
		var intersections = octree.raycast(rStart, rDir);
		var iData:Array<RayIntersectionData> = [];
		for (i in intersections) {
			i.point.transform(transform);
			i.normal.transform3x3(transform);
			i.normal.normalize();
			iData.push({point: i.point, normal: i.normal, object: i.object});
		}
		return iData;
	}

	public function getElementType() {
		return 2;
	}

	public function setPriority(priority:Int) {
		this.priority = priority;
	}

	public function sphereIntersection(collisionEntity:SphereCollisionEntity, timeState:TimeState) {
		var position = collisionEntity.transform.getPosition();
		var velocity = collisionEntity.velocity;
		var radius = collisionEntity.radius;

		var invMatrix = invTransform;
		if (this.go is PathedInterior)
			invMatrix = transform.getInverse();
		var sphereBounds = new Bounds();
		var localPos = position.clone();
		localPos.transform(invMatrix);
		sphereBounds.addSpherePos(position.x, position.y, position.z, radius * 1.1);
		sphereBounds.transform(invMatrix);
		sphereBounds.addSpherePos(localPos.x, localPos.y, localPos.z, radius * 1.1);
		var surfaces = octree.boundingSearch(sphereBounds);

		var tform = transform.clone();
		// tform.setPosition(tform.getPosition().add(this.velocity.multiply(timeState.dt)));

		function toDifPoint(pt:Vector) {
			return new Point3F(pt.x, pt.y, pt.z);
		}

		function fromDifPoint(pt:Point3F) {
			return new Vector(pt.x, pt.y, pt.z);
		}

		var contacts = [];

		for (obj in surfaces) {
			var surface:CollisionSurface = cast obj;

			var surfaceBestContact:CollisionInfo = null;
			var bestDot:Float = Math.NEGATIVE_INFINITY;

			var i = 0;
			while (i < surface.indices.length) {
				var v0 = surface.points[surface.indices[i]].transformed(tform);
				var v = surface.points[surface.indices[i + 1]].transformed(tform);
				var v2 = surface.points[surface.indices[i + 2]].transformed(tform);

				var surfacenormal = surface.normals[surface.indices[i]].transformed3x3(transform).normalized();

				var res = Collision.IntersectTriangleSphere(v0, v, v2, surfacenormal, position, radius);
				var closest = res.point;
				// var closest = Collision.ClosestPtPointTriangle(position, radius, v0, v, v2, surfacenormal);
				if (closest != null) {
					var contactDist = closest.distanceSq(position);
					if (contactDist <= radius * radius) {
						var normal = res.normal;

						if (position.sub(closest).dot(surfacenormal) > 0) {
							normal.normalize();

							// We find the normal that is closest to the surface normal, sort of fixes weird edge cases of when colliding with
							var testDot = normal.dot(surfacenormal);
							if (testDot > bestDot) {
								bestDot = testDot;

								var cinfo = new CollisionInfo();
								cinfo.normal = normal;
								cinfo.point = closest;
								// cinfo.collider = this;
								cinfo.velocity = this.velocity.clone();
								cinfo.contactDistance = Math.sqrt(contactDist);
								cinfo.otherObject = this.go;
								// cinfo.penetration = radius - (position.sub(closest).dot(normal));
								cinfo.restitution = surface.restitution;
								cinfo.force = surface.force;
								cinfo.friction = surface.friction;
								surfaceBestContact = cinfo;
							}
						}
					}
				}

				i += 3;
			}

			if (surfaceBestContact != null)
				contacts.push(surfaceBestContact);
		}

		return contacts;
	}
}
