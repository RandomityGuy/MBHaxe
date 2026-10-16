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

	var localBoundingBox:Bounds;

	public var octree:Octree;

	// public var bvh:BVHTree<CollisionSurface>;
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

	public var ignoreRayCast:Bool = false;

	static var globalTransformKey:Int = 0;

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
		// #if hl
		// this.bvh = new BVHTree();
		// for (surface in this.surfaces) {
		// 	this.bvh.add(surface);
		// }
		// #end
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
		if (this.surfaces != null) {
			for (s in this.surfaces)
				s.dispose();
		}
		go = null;
		surfaces = null;
		grid = null;
		// bvh = null;
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
			this.invTransform.prependTranslation(oldPos.x - newPos.x, oldPos.y - newPos.y, oldPos.z - newPos.z);
			if (this.boundingBox == null)
				generateBoundingBox();
			else {
				this.boundingBox.xMin += newPos.x - oldPos.x;
				this.boundingBox.xMax += newPos.x - oldPos.x;
				this.boundingBox.yMin += newPos.y - oldPos.y;
				this.boundingBox.yMax += newPos.y - oldPos.y;
				this.boundingBox.zMin += newPos.z - oldPos.z;
				this.boundingBox.zMax += newPos.z - oldPos.z;

				if (Debug.drawBounds) {
					if (_dbgEntity == null) {
						_dbgEntity = cast this.boundingBox.makeDebugObj();
						_dbgEntity.getMaterials()[0].castShadows = false;
						_dbgEntity.getMaterials()[0].mainPass.wireframe = true;
						MarbleGame.instance.scene.addChild(_dbgEntity);
					} else {
						_dbgEntity.remove();
						_dbgEntity = cast this.boundingBox.makeDebugObj();
						_dbgEntity.getMaterials()[0].castShadows = false;
						_dbgEntity.getMaterials()[0].mainPass.wireframe = true;
						MarbleGame.instance.scene.addChild(_dbgEntity);
					}
				}
			}
		} else {
			this.transform.load(transform);
			transform.getInverse(this.invTransform);
			if (this.localBoundingBox == null)
				generateBoundingBox();
			else {
				this.boundingBox.load(this.localBoundingBox);
				this.boundingBox.transform(transform);
			}
		}
		_transformKey = ++globalTransformKey;
	}

	public function generateBoundingBox() {
		this.localBoundingBox = new Bounds();
		for (surface in this.surfaces) {
			var tform = surface.boundingBox.clone();
			this.localBoundingBox.add(tform);
		}
		this.boundingBox = this.localBoundingBox.clone();
		this.boundingBox.transform(transform);
		if (Debug.drawBounds) {
			if (_dbgEntity == null) {
				_dbgEntity = cast this.boundingBox.makeDebugObj();
				_dbgEntity.getMaterials()[0].castShadows = false;
				_dbgEntity.getMaterials()[0].mainPass.wireframe = true;
				MarbleGame.instance.scene.addChild(_dbgEntity);
			} else {
				_dbgEntity.remove();
				_dbgEntity = cast this.boundingBox.makeDebugObj();
				_dbgEntity.getMaterials()[0].castShadows = false;
				_dbgEntity.getMaterials()[0].mainPass.wireframe = true;
				MarbleGame.instance.scene.addChild(_dbgEntity);
			}
		}
	}

	public function rayCast(rayOrigin:Vector, rayDirection:Vector, results:Array<RayIntersectionData>, bestT:Float) {
		if (ignoreRayCast)
			return bestT;
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
		var intersections = grid.rayCast(rStart, rDir, bestT); // this.bvh.rayCast(rStart, rDir);
		for (i in intersections) {
			i.point.transform(transform);
			i.normal.transform3x3(invTPos);
			i.normal.normalize();
			if (i.t < bestT) {
				bestT = i.t;
				results.push(i);
			}
		}
		return bestT;
		// }
	}

	public function getElementType() {
		return 2;
	}

	public function setPriority(priority:Int) {
		this.priority = priority;
	}

	static var surfaceSearchPool:Array<CollisionSurface> = [];

	public function sphereIntersection(collisionEntity:SphereCollisionEntity, timeState:TimeState, contacts:Array<CollisionInfo>) {
		var position = collisionEntity.transform.getPosition();
		var radius = collisionEntity.radius + 0.001;

		var invMatrix = invTransform;
		var sphereBounds = new Bounds();
		var localPos = position.clone();
		localPos.transform(invMatrix);
		// sphereBounds.addSpherePos(position.x, position.y, position.z, radius * 1.1);
		// sphereBounds.transform(invMatrix);
		var invScale = invMatrix.getScale();
		var sphereRadius = new Vector(radius * invScale.x, radius * invScale.y, radius * invScale.z);
		sphereBounds.addSpherePos(localPos.x, localPos.y, localPos.z, Math.max(Math.max(sphereRadius.x, sphereRadius.y), sphereRadius.z) * 1.1);
		surfaceSearchPool.resize(0);
		grid.boundingSearch(sphereBounds, surfaceSearchPool);
		var surfaces = surfaceSearchPool;
		var invtform = invMatrix.clone();
		invtform.transpose();

		var tform = transform.clone();
		// tform.setPosition(tform.getPosition().add(this.velocity.multiply(timeState.dt)));

		if (isWorldStatic) {
			tform.load(Matrix.I());
			invtform.load(Matrix.I());
		}

		for (obj in surfaces) {
			var surface:CollisionSurface = cast obj;
			var i = 0;
			for (vi in 0...surface.vertexCounts.length) {
				var vtxCount = surface.vertexCounts[vi];
				var surfaceNormal = surface.getNormal(vi).transformed3x3(invtform).normalized();
				var surfacePoint = surface.getTransformedPoint(i, tform, _transformKey);

				var distance = position.sub(surfacePoint).dot(surfaceNormal);
				var absDistance = Math.abs(distance);

				if (absDistance >= 1e-6 && absDistance <= radius + 0.0001) {
					var contactVert = position.sub(surfaceNormal.multiply(distance));
					// Check if point is completely inside the triangle
					var inside = true;
					for (j in 0...vtxCount) {
						var v1 = surface.getTransformedPoint(i + j, tform, _transformKey);
						var v2 = surface.getTransformedPoint(i + ((j + 1) % vtxCount), tform, _transformKey);

						var edgeNormal = surfaceNormal.cross(v2.sub(v1));

						if (edgeNormal.dot(contactVert.sub(v1)) < 0) {
							inside = false;
							break;
						}
					}

					var closest = new Vector();

					if (inside) {
						closest.load(contactVert);
					} else {
						var bestDistSq = Math.POSITIVE_INFINITY;
						// Find the point closest to one of the edges
						for (j in 0...vtxCount) {
							var v1 = surface.getTransformedPoint(i + j, tform, _transformKey);
							var v2 = surface.getTransformedPoint(i + ((j + 1) % vtxCount), tform, _transformKey);

							var edge = v2.sub(v1);
							var edgeLen = edge.dot(edge);

							if (edgeLen < 0.0000001)
								continue;

							var diff = contactVert.sub(v1);

							var t = edgeLen > 0.0000001 ? Util.clamp(edge.dot(diff) / edgeLen, 0, 1) : 0.0;
							var c = v1.add(edge.multiply(t));

							var distFromEdgeSq = c.distanceSq(contactVert);
							if (distFromEdgeSq < bestDistSq) {
								bestDistSq = distFromEdgeSq;
								closest.load(c);
							}
						}
					}

					var contactDist = closest.distanceSq(position);

					if (contactDist > radius * radius) {
						i += vtxCount;
						continue;
					}

					var contactNormal = surfaceNormal.clone();
					if (!inside) {
						var edgeNormal = position.sub(closest).normalized();
						if (edgeNormal.dot(surfaceNormal) > 0.988)
							contactNormal.load(surfaceNormal);
						else {
							contactNormal.load(edgeNormal);
						}
					}

					var cinfo = CollisionPool.alloc();
					cinfo.normal.load(contactNormal);
					cinfo.point.load(closest);
					cinfo.collider = null;
					cinfo.velocity.load(this.velocity);
					cinfo.contactDistance = Math.sqrt(contactDist);
					cinfo.otherObject = this.go;
					cinfo.restitution = surface.restitution;
					cinfo.force = surface.force;
					cinfo.friction = surface.friction;
					contacts.push(cinfo);
					if (this.go != null)
						this.go.onMarbleContact(collisionEntity.marble, timeState, cinfo);
				}
				i += vtxCount;
			}
		}
	}
}
