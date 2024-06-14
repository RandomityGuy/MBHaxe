package collision;

import collision.Collision.ITSResult;
import collision.BVHTree.IBVHObject;
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
import src.Util;
import src.Debug;
import src.MarbleGame;

class CollisionEntity implements IOctreeObject implements IBVHObject {
	public var boundingBox:Bounds;

	public var octree:Octree;

	public var bvh:BVHTree<CollisionSurface>;

	var grid:Grid;

	public var surfaces:Array<CollisionSurface>;
	public var priority:Int;
	public var position:Int;
	public var velocity:Vector = new Vector();

	public var transform:Matrix;

	var invTransform:Matrix;

	public var go:GameObject;
	public var correctNormals:Bool = false;

	public var userData:Int;
	public var fastTransform:Bool = false;
	public var isWorldStatic:Bool = false;

	var _transformKey:Int = 0;

	public var key:Int = 0;

	var _dbgEntity:h3d.scene.Mesh;

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

	// Generates the bvh
	public function finalize() {
		this.generateBoundingBox();
		#if hl
		this.bvh = new BVHTree();
		for (surface in this.surfaces) {
			this.bvh.add(surface);
		}
		#end
		var bbox = new Bounds();
		for (surface in this.surfaces)
			bbox.add(surface.boundingBox);
		this.grid = new Grid(bbox);
		for (surface in this.surfaces)
			this.grid.insert(surface);
		this.grid.build();
		// this.bvh.build();
	}

	public function dispose() {
		for (s in this.surfaces)
			s.dispose();
		go = null;
		surfaces = null;
		bvh = null;
		octree = null;
	}

	public function setTransform(transform:Matrix) {
		if (this.transform.equal(transform))
			return;
		// Speedup
		if (this.fastTransform && Util.mat3x3equal(this.transform, transform)) {
			var oldPos = this.transform.getPosition();
			var newPos = transform.getPosition();
			this.transform.setPosition(newPos);
			this.invTransform = this.transform.getInverse();
			if (this.boundingBox == null)
				generateBoundingBox();
			else {
				this.boundingBox.xMin += newPos.x - oldPos.x;
				this.boundingBox.xMax += newPos.x - oldPos.x;
				this.boundingBox.yMin += newPos.y - oldPos.y;
				this.boundingBox.yMax += newPos.y - oldPos.y;
				this.boundingBox.zMin += newPos.z - oldPos.z;
				this.boundingBox.zMax += newPos.z - oldPos.z;
			}
		} else {
			this.transform.load(transform);
			this.invTransform = transform.getInverse();
			generateBoundingBox();
		}
		_transformKey++;
	}

	public function generateBoundingBox() {
		var boundingBox = new Bounds();
		for (surface in this.surfaces) {
			var tform = surface.boundingBox.clone();
			tform.transform(transform);
			boundingBox.add(tform);
		}
		this.boundingBox = boundingBox;
		if (Debug.drawBounds) {
			if (_dbgEntity == null) {
				_dbgEntity = cast this.boundingBox.makeDebugObj();
				_dbgEntity.getMaterials()[0].mainPass.wireframe = true;
				MarbleGame.instance.scene.addChild(_dbgEntity);
			} else {
				_dbgEntity.remove();
				_dbgEntity = cast this.boundingBox.makeDebugObj();
				_dbgEntity.getMaterials()[0].mainPass.wireframe = true;
				MarbleGame.instance.scene.addChild(_dbgEntity);
			}
		}
	}

	public function rayCast(rayOrigin:Vector, rayDirection:Vector, results:Array<RayIntersectionData>) {
		var invMatrix = invTransform;
		var invTPos = invMatrix.clone();
		invTPos.transpose();
		var rStart = rayOrigin.clone();
		rStart.transform(invMatrix);
		var rDir = rayDirection.transformed3x3(invMatrix);
		// if (bvh == null) {
		// 	var intersections = grid.rayCast(rStart, rDir); // octree.raycast(rStart, rDir);
		// 	// var iData:Array<RayIntersectionData> = [];
		// 	for (i in intersections) {
		// 		i.point.transform(transform);
		// 		i.normal.transform3x3(invTPos);
		// 		i.normal.normalize();
		// 		// iData.push({point: i.point, normal: i.normal, object: i.object});
		// 	}
		// 	return intersections; // iData;
		// } else {
		var intersections = grid.rayCast(rStart, rDir); // this.bvh.rayCast(rStart, rDir);
		for (i in intersections) {
			i.point.transform(transform);
			i.normal.transform3x3(invTPos);
			i.normal.normalize();
			results.push(i);
		}
		// }
	}

	public function getElementType() {
		return 2;
	}

	public function setPriority(priority:Int) {
		this.priority = priority;
	}

	public function sphereIntersection(collisionEntity:SphereCollisionEntity, timeState:TimeState) {
		var position = collisionEntity.transform.getPosition();
		var radius = collisionEntity.radius + 0.001;

		var invMatrix = invTransform;
		if (this.go is PathedInterior)
			invMatrix = transform.getInverse();
		var sphereBounds = new Bounds();
		var localPos = position.clone();
		localPos.transform(invMatrix);
		// sphereBounds.addSpherePos(position.x, position.y, position.z, radius * 1.1);
		// sphereBounds.transform(invMatrix);
		var invScale = invMatrix.getScale();
		var sphereRadius = new Vector(radius * invScale.x, radius * invScale.y, radius * invScale.z);
		sphereBounds.addSpherePos(localPos.x, localPos.y, localPos.z, Math.max(Math.max(sphereRadius.x, sphereRadius.y), sphereRadius.z) * 1.1);
		var surfaces = grid.boundingSearch(sphereBounds); // bvh == null ? octree.boundingSearch(sphereBounds).map(x -> cast x) : bvh.boundingSearch(sphereBounds);
		var invtform = invMatrix.clone();
		invtform.transpose();

		var tform = transform.clone();
		// tform.setPosition(tform.getPosition().add(this.velocity.multiply(timeState.dt)));

		if (isWorldStatic) {
			tform.load(Matrix.I());
			invtform.load(Matrix.I());
		}

		var contacts = [];

		for (obj in surfaces) {
			var surface:CollisionSurface = cast obj;

			var surfaceBestContact:CollisionInfo = null;
			var bestDot:Float = Math.NEGATIVE_INFINITY;

			var i = 0;
			while (i < surface.indices.length) {
				var verts = surface.transformTriangle(i, tform, invtform, this._transformKey);
				// var v0 = surface.points[surface.indices[i]].transformed(tform);
				// var v = surface.points[surface.indices[i + 1]].transformed(tform);
				// var v2 = surface.points[surface.indices[i + 2]].transformed(tform);
				var v0 = new Vector(verts.v1x, verts.v1y, verts.v1z);
				var v = new Vector(verts.v2x, verts.v2y, verts.v2z);
				var v2 = new Vector(verts.v3x, verts.v3y, verts.v3z);

				var surfacenormal = new Vector(verts.nx, verts.ny, verts.nz); // surface.normals[surface.indices[i]].transformed3x3(transform).normalized();

				if (correctNormals) {
					var vn = v.sub(v0).cross(v2.sub(v0)).normalized().multiply(-1);
					var vdot = vn.dot(surfacenormal);
					if (vdot < 0.95) {
						v.set(verts.v3x, verts.v3y, verts.v3z);
						v2.set(verts.v2x, verts.v2y, verts.v2z);

						surfacenormal.load(vn);
					}
				}

				var closest = new Vector();
				var normal = new Vector();
				var res = Collision.TriangleSphereIntersection(v0, v, v2, surfacenormal, position, radius, closest, normal);
				// var closest = Collision.ClosestPtPointTriangle(position, radius, v0, v, v2, surfacenormal);
				if (res) {
					var contactDist = closest.distanceSq(position);
					// Debug.drawTriangle(v0, v, v2);
					if (contactDist <= radius * radius) {
						if (position.sub(closest).dot(surfacenormal) > 0) {
							normal.normalize();

							// We find the normal that is closest to the surface normal, sort of fixes weird edge cases of when colliding with
							// var testDot = normal.dot(surfacenormal);
							// if (testDot > bestDot) {
							// 	bestDot = testDot;

							var cinfo = CollisionPool.alloc();
							cinfo.normal.load(normal);
							cinfo.point.load(closest);
							cinfo.collider = null;
							// cinfo.collider = this;
							cinfo.velocity.load(this.velocity);
							cinfo.contactDistance = Math.sqrt(contactDist);
							cinfo.otherObject = this.go;
							// cinfo.penetration = radius - (position.sub(closest).dot(normal));
							cinfo.restitution = surface.restitution;
							cinfo.force = surface.force;
							cinfo.friction = surface.friction;
							contacts.push(cinfo);
							if (this.go != null)
								this.go.onMarbleContact(collisionEntity.marble, timeState, cinfo);
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
