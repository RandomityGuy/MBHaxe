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

	public function new() {}

	public function getElementType() {
		return 2;
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
		// TEMP cause bruh
		return true;
	}
}
