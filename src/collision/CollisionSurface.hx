package collision;

import h3d.Matrix;
import h3d.col.Bounds;
import octree.IOctreeObject;
import h3d.Vector;

class CollisionSurface implements IOctreeObject {
	public var priority:Int;
	public var position:Int;

	public var boundingBox:Bounds;

	public var points:Array<Vector>;
	public var normals:Array<Vector>;
	public var indices:Array<Int>;

	public var friction:Float = 1;
	public var restitution:Float = 1;
	public var force:Float = 0;

	public var edgeData:Array<Int>;

	public var edgeDots:Array<Float>;
	public var originalIndices:Array<Int>;

	public var originalSurfaceIndex:Int;

	public var key:Bool = false;

	public function new() {}

	public function getElementType() {
		return 2;
	}

	public function generateNormals() {
		var i = 0;
		normals = [for (n in points) null];
		while (i < indices.length) {
			var p1 = points[indices[i]].clone();
			var p2 = points[indices[i + 1]].clone();
			var p3 = points[indices[i + 2]].clone();
			var n = p2.sub(p1).cross(p3.sub(p1)).normalized().multiply(-1);
			normals[indices[i]] = n;
			normals[indices[i + 1]] = n;
			normals[indices[i + 2]] = n;
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

		for (point in points) {
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

	public function rayCast(rayOrigin:Vector, rayDirection:Vector):Array<RayIntersectionData> {
		var intersections = [];
		var i = 0;
		while (i < indices.length) {
			var p1 = points[indices[i]].clone();
			var p2 = points[indices[i + 1]].clone();
			var p3 = points[indices[i + 2]].clone();
			var n = normals[indices[i]].clone();
			var d = -p1.dot(n);

			var t = -(rayOrigin.dot(n) + d) / (rayDirection.dot(n));
			var ip = rayOrigin.add(rayDirection.multiply(t));
			ip.w = 1;
			if (t >= 0 && Collision.PointInTriangle(ip, p1, p2, p3)) {
				intersections.push({point: ip, normal: n, object: cast this});
			}
			i += 3;
		}
		return intersections;
	}

	public function support(direction:Vector, transform:Matrix) {
		var furthestDistance:Float = Math.NEGATIVE_INFINITY;
		var furthestVertex:Vector = new Vector();

		for (v in points) {
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
}
