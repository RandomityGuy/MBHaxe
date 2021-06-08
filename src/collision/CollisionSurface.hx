package collision;

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

	public function new() {}

	public function getElementType() {
		return 2;
	}

	public function generateNormals() {
		var i = 0;
		normals = [for (n in points) null];
		while (i < indices.length) {
			var p1 = points[indices[i]];
			var p2 = points[indices[i + 1]];
			var p3 = points[indices[i + 2]];
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

	public function isIntersectedByRay(rayOrigin:Vector, rayDirection:Vector, intersectionPoint:Vector):Bool {
		var intersections = [];
		var i = 0;
		while (i < indices.length) {
			var p1 = points[indices[i]];
			var p2 = points[indices[i + 1]];
			var p3 = points[indices[i + 2]];
			var n = normals[indices[i]];
			var d = -p1.dot(n);

			var t = -(rayOrigin.dot(n) + d) / (rayDirection.dot(n));
			var ip = rayOrigin.add(rayDirection.multiply(t));
			if (Collision.PointInTriangle(ip, p1, p2, p3)) {
				intersections.push(ip);
			}
			i += 3;
		}
		intersections.sort((a, b) -> cast(a.distance(rayOrigin) - b.distance(rayOrigin)));
		if (intersections.length > 0) {
			intersectionPoint.load(intersections[0]);
		}
		return intersections.length > 0;
	}
}
