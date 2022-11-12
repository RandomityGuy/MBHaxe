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

	public var grid:Grid;

	public var surfaces:Array<CollisionSurface>;

	public var priority:Int;
	public var position:Int;
	public var velocity:Vector = new Vector();

	public var transform:Matrix;

	var invTransform:Matrix;

	public var go:GameObject;

	public var userData:Int;

	public var difEdgeMap:Map<Int, dif.Edge>;

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

	// Generates the grid
	public function finalize() {
		this.generateBoundingBox();
		this.grid = new Grid(this.boundingBox);
		for (surface in this.surfaces) {
			this.grid.insert(surface);
		}
	}

	public function setTransform(transform:Matrix) {
		if (this.transform.equal(transform))
			return;
		this.transform.load(transform);
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
		if (grid == null) {
			var intersections = octree.raycast(rStart, rDir);
			var iData:Array<RayIntersectionData> = [];
			for (i in intersections) {
				i.point.transform(transform);
				i.normal.transform3x3(transform);
				i.normal.normalize();
				iData.push({point: i.point, normal: i.normal, object: i.object});
			}
			return iData;
		} else {
			var intersections = this.grid.rayCast(rStart, rDir);
			for (i in intersections) {
				i.point.transform(transform);
				i.normal.transform3x3(transform);
				i.normal.normalize();
			}

			return intersections;
		}
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
		var surfaces = grid == null ? octree.boundingSearch(sphereBounds).map(x -> cast x) : grid.boundingSearch(sphereBounds);

		var tform = transform.clone();
		// tform.setPosition(tform.getPosition().add(this.velocity.multiply(timeState.dt)));

		function toDifPoint(pt:Vector) {
			return new Point3F(pt.x, pt.y, pt.z);
		}

		function fromDifPoint(pt:Point3F) {
			return new Vector(pt.x, pt.y, pt.z);
		}

		function hashEdge(i1:Int, i2:Int) {
			return i1 >= i2 ? i1 * i1 + i1 + i2 : i1 + i2 * i2;
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

				// var e1e2 = hashEdge(surface.originalIndices[i], surface.originalIndices[i + 1]);
				// var e2e3 = hashEdge(surface.originalIndices[i + 1], surface.originalIndices[i + 2]);
				// var e1e3 = hashEdge(surface.originalIndices[i], surface.originalIndices[i + 3]);

				// var edgeData = 0;
				// if (this.difEdgeMap.exists(e1e2)) {
				// 	edgeData |= 1;
				// }
				// if (this.difEdgeMap.exists(e2e3)) {
				// 	edgeData |= 2;
				// }
				// if (this.difEdgeMap.exists(e1e3)) {
				// 	edgeData |= 4;
				// }

				var edgeData = surface.edgeData[Math.floor(i / 3)];

				var edgeDots = surface.edgeDots.slice(Math.floor(i / 3), Math.floor(i / 3) + 3);

				var surfacenormal = surface.normals[surface.indices[i]].transformed3x3(transform).normalized();

				var res = Collision.IntersectTriangleSphere(v0, v, v2, surfacenormal, position, radius, edgeData, edgeDots);
				var closest = res.point;
				// var closest = Collision.ClosestPtPointTriangle(position, radius, v0, v, v2, surfacenormal);
				if (closest != null) {
					var contactDist = closest.distanceSq(position);
					if (contactDist <= radius * radius) {
						var normal = res.normal;

						if (position.sub(closest).dot(surfacenormal) > 0) {
							normal.normalize();

							// We find the normal that is closest to the surface normal, sort of fixes weird edge cases of when colliding with
							// var testDot = normal.dot(surfacenormal);
							// if (testDot > bestDot) {
							// 	bestDot = testDot;

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
							contacts.push(cinfo);
							// surfaceBestContact = cinfo;
							// }
						}
					}
				}

				i += 3;
			}

			// if (surfaceBestContact != null)
			// contacts.push(surfaceBestContact);
		}

		return contacts;
	}
}
