package collision;

import h3d.Matrix;
import h3d.col.Bounds;
import octree.IOctreeObject;
import h3d.Vector;
import collision.BVHTree.IBVHObject;

@:publicFields
class TransformedCollisionTriangle {
	var v1x:Float;
	var v1y:Float;
	var v1z:Float;
	var v2x:Float;
	var v2y:Float;
	var v2z:Float;
	var v3x:Float;
	var v3y:Float;
	var v3z:Float;
	var nx:Float;
	var ny:Float;
	var nz:Float;

	inline public function new(v1:Vector, v2:Vector, v3:Vector, n:Vector) {
		v1x = v1.x;
		v1y = v1.y;
		v1z = v1.z;
		v2x = v2.x;
		v2y = v2.y;
		v2z = v2.z;
		v3x = v3.x;
		v3y = v3.y;
		v3z = v3.z;
		nx = n.x;
		ny = n.y;
		nz = n.z;
	}
}

class CollisionSurface implements IOctreeObject implements IBVHObject {
	public var priority:Int;
	public var position:Int;
	public var boundingBox:Bounds;
	public var points:Array<Float>;
	public var normals:Array<Float>;
	public var indices:Array<Int>;
	public var friction:Float = 1;
	public var restitution:Float = 1;
	public var force:Float = 0;
	public var originalIndices:Array<Int>;
	public var originalSurfaceIndex:Int;
	public var transformKeys:Array<Int>;
	public var key:Int = 0;

	var _transformedPoints:Array<Float>;
	var _transformedNormals:Array<Float>;

	public function new() {}

	public function getElementType() {
		return 2;
	}

	public function generateNormals() {
		var i = 0;
		normals = [for (n in points) 0.0];
		while (i < indices.length) {
			var p1 = getPoint(indices[i]);
			var p2 = getPoint(indices[i + 1]);
			var p3 = getPoint(indices[i + 2]);
			var n = p2.sub(p1).cross(p3.sub(p1)).normalized().multiply(-1);
			normals[indices[i] * 3] = n.x;
			normals[indices[i] * 3 + 1] = n.y;
			normals[indices[i] * 3 + 2] = n.z;
			normals[indices[i + 1] * 3] = n.x;
			normals[indices[i + 1] * 3 + 1] = n.y;
			normals[indices[i + 1] * 3 + 2] = n.z;
			normals[indices[i + 2] * 3] = n.x;
			normals[indices[i + 2] * 3 + 1] = n.y;
			normals[indices[i + 2] * 3 + 2] = n.z;
			i += 3;
		}
	}

	public function generateBoundingBox() {
		var boundingBox = new Bounds();
		boundingBox.xMin = 10e8;
		boundingBox.yMin = 10e8;
		boundingBox.zMin = 10e8;
		boundingBox.xMax = -10e8;
		boundingBox.yMax = -10e8;
		boundingBox.zMax = -10e8;

		for (i in 0...Std.int(points.length / 3)) {
			var point = getPoint(i);
			if (point.x > boundingBox.xMax) {
				boundingBox.xMax = point.x;
			}
			if (point.x < boundingBox.xMin) {
				boundingBox.xMin = point.x;
			}
			if (point.y > boundingBox.yMax) {
				boundingBox.yMax = point.y;
			}
			if (point.y < boundingBox.yMin) {
				boundingBox.yMin = point.y;
			}
			if (point.z > boundingBox.zMax) {
				boundingBox.zMax = point.z;
			}
			if (point.z < boundingBox.zMin) {
				boundingBox.zMin = point.z;
			}
		}
		this.boundingBox = boundingBox;
	}

	public function setPriority(priority:Int) {
		this.priority = priority;
	}

	inline public function getPoint(idx:Int) {
		return new Vector(points[idx * 3], points[idx * 3 + 1], points[idx * 3 + 2]);
	}

	inline public function getNormal(idx:Int) {
		return new Vector(normals[idx * 3], normals[idx * 3 + 1], normals[idx * 3 + 2]);
	}

	inline public function addPoint(x:Float, y:Float, z:Float) {
		points.push(x);
		points.push(y);
		points.push(z);
	}

	inline public function addNormal(x:Float, y:Float, z:Float) {
		normals.push(x);
		normals.push(y);
		normals.push(z);
	}

	public function rayCast(rayOrigin:Vector, rayDirection:Vector, intersections:Array<RayIntersectionData>) {
		var i = 0;
		while (i < indices.length) {
			var p1 = getPoint(indices[i]);
			var p2 = getPoint(indices[i + 1]);
			var p3 = getPoint(indices[i + 2]);
			var n = getNormal(indices[i]);
			var d = -p1.dot(n);

			var t = -(rayOrigin.dot(n) + d) / (rayDirection.dot(n));
			var ip = rayOrigin.add(rayDirection.multiply(t));
			ip.w = 1;
			if (t >= 0 && Collision.PointInTriangle(ip, p1, p2, p3)) {
				intersections.push({point: ip, normal: n, object: cast this});
			}
			i += 3;
		}
	}

	public function support(direction:Vector, transform:Matrix) {
		var furthestDistance:Float = Math.NEGATIVE_INFINITY;
		var furthestVertex:Vector = new Vector();

		for (i in 0...Std.int(points.length / 3)) {
			var v = getPoint(i);
			var v2 = v.transformed(transform);
			var distance:Float = v2.dot(direction);
			if (distance > furthestDistance) {
				furthestDistance = distance;
				furthestVertex.x = v2.x;
				furthestVertex.y = v2.y;
				furthestVertex.z = v2.z;
			}
		}

		return furthestVertex;
	}

	public inline function transformTriangle(idx:Int, tform:Matrix, invtform:Matrix, key:Int) {
		if (_transformedPoints == null) {
			_transformedPoints = points.copy();
		}
		if (_transformedNormals == null) {
			_transformedNormals = normals.copy();
		}
		var p1 = indices[idx];
		var p2 = indices[idx + 1];
		var p3 = indices[idx + 2];
		if (transformKeys[p1] != key) {
			var pt = getPoint(p1).transformed(tform);
			_transformedPoints[p1 * 3] = pt.x;
			_transformedPoints[p1 * 3 + 1] = pt.y;
			_transformedPoints[p1 * 3 + 2] = pt.z;
			var pn = getNormal(p1).transformed3x3(invtform).normalized();
			_transformedNormals[p1 * 3] = pn.x;
			_transformedNormals[p1 * 3 + 1] = pn.y;
			_transformedNormals[p1 * 3 + 2] = pn.z;
			transformKeys[p1] = key;
		}
		if (transformKeys[p2] != key) {
			var pt = getPoint(p2).transformed(tform);
			_transformedPoints[p2 * 3] = pt.x;
			_transformedPoints[p2 * 3 + 1] = pt.y;
			_transformedPoints[p2 * 3 + 2] = pt.z;
			transformKeys[p2] = key;
		}
		if (transformKeys[p3] != key) {
			var pt = getPoint(p3).transformed(tform);
			_transformedPoints[p3 * 3] = pt.x;
			_transformedPoints[p3 * 3 + 1] = pt.y;
			_transformedPoints[p3 * 3 + 2] = pt.z;
			transformKeys[p3] = key;
		}
		return new TransformedCollisionTriangle(new Vector(_transformedPoints[p1 * 3], _transformedPoints[p1 * 3 + 1], _transformedPoints[p1 * 3 + 2]),
			new Vector(_transformedPoints[p2 * 3], _transformedPoints[p2 * 3 + 1], _transformedPoints[p2 * 3 + 2]),
			new Vector(_transformedPoints[p3 * 3], _transformedPoints[p3 * 3 + 1], _transformedPoints[p3 * 3 + 2]),
			new Vector(_transformedNormals[p1 * 3], _transformedNormals[p1 * 3 + 1], _transformedNormals[p1 * 3 + 2]));
	}

	public inline function getTriangle(idx:Int) {
		var p1 = indices[idx];
		var p2 = indices[idx + 1];
		var p3 = indices[idx + 2];

		return new TransformedCollisionTriangle(getPoint(p1), getPoint(p2), getPoint(p3), getNormal(p1));
	}

	public function getTransformed(m:Matrix, invtform:Matrix) {
		var tformed = new CollisionSurface();
		tformed.points = this.points.copy();
		tformed.normals = this.normals.copy();
		tformed.indices = this.indices.copy();
		tformed.friction = this.friction;
		tformed.force = this.force;
		tformed.restitution = this.restitution;
		tformed.transformKeys = this.transformKeys.copy();

		for (i in 0...Std.int(points.length / 3)) {
			var v = getPoint(i);
			var v2 = v.transformed(m);
			tformed.points[i * 3] = v2.x;
			tformed.points[i * 3 + 1] = v2.y;
			tformed.points[i * 3 + 2] = v2.z;

			var n = getNormal(i);
			var n2 = n.transformed3x3(invtform).normalized();
			tformed.normals[i * 3] = n2.x;
			tformed.normals[i * 3 + 1] = n2.y;
			tformed.normals[i * 3 + 2] = n2.z;
		}
		tformed.generateBoundingBox();

		return tformed;
	}

	public function dispose() {
		points = null;
		normals = null;
		indices = null;
		_transformedPoints = null;
		_transformedNormals = null;
		originalIndices = null;
	}
}
