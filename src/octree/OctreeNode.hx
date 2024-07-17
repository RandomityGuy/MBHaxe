package octree;

import h3d.col.Ray;
import h3d.col.Bounds;
import h3d.col.Point;
import h3d.Vector;

class OctreeNode implements IOctreeElement {
	public var octree:Octree;
	public var parent:OctreeNode = null;

	public var priority:Int;
	public var position:Int;

	/** The min corner of the bounding box. */
	public var xMin:Float;

	public var yMin:Float;
	public var zMin:Float;
	public var xMax:Float;
	public var yMax:Float;
	public var zMax:Float;

	/** The size of the bounding box on all three axes. This forces the bounding box to be a cube. */
	public var octants:Array<OctreeNode> = null;

	/** A list of objects contained in this node. Note that the node doesn't need to be a leaf node for this set to be non-empty; since this is an octree of bounding boxes, some volumes cannot fit into an octant and therefore need to be stored in the node itself. */
	public var objects = new Array<IOctreeObject>();

	/** The total number of objects in the subtree with this node as its root. */
	public var count = 0;

	public var depth:Int;

	var disableMerge:Bool;

	public function new(octree:Octree, depth:Int, disableMerge:Bool = false) {
		this.octree = octree;
		this.depth = depth;
		this.xMin = 0;
		this.yMin = 0;
		this.zMin = 0;
		this.xMax = 1;
		this.yMax = 1;
		this.zMax = 1;
		this.disableMerge = disableMerge;
	}

	public function insert(object:IOctreeObject) {
		this.count++;
		if (this.octants != null) {
			if (this.octants[0].largerThan(object)) {
				for (i in 0...8) {
					var octant = this.octants[i];
					if (octant.containsCenter(object)) {
						octant.insert(object);
						return;
					}
				}
			}
			this.objects.push(object);
			this.octree.objectToNode.set(object, this);
		} else {
			this.objects.push(object);
			this.octree.objectToNode.set(object, this);
			this.split(); // Try splitting this node
		}
	}

	public function split() {
		if (this.objects.length <= 8 || this.depth == 8)
			return;
		this.createOctants();
		// Put the objects into the correct octants. Note that all objects that couldn't fit into any octant will remain in the set.

		for (object in this.objects) {
			if (this.octants[0].largerThan(object)) {
				for (i in 0...8) {
					var octant = this.octants[i];
					if (octant.containsCenter(object)) {
						octant.insert(object);
						this.objects.remove(object);
					}
				}
			}
		}
		// Try recursively splitting each octant
		for (i in 0...8) {
			this.octants[i].split();
		}
	}

	public function createOctants() {
		this.octants = [];
		for (i in 0...8) {
			var newNode = new OctreeNode(this.octree, this.depth + 1, disableMerge);
			newNode.parent = this;
			var newSize = new Vector(xMax - xMin, yMax - yMin, zMax - zMin);
			newNode.xMin = this.xMin + newSize.x * ((i & 1) >> 0);
			newNode.yMin = this.yMin + newSize.y * ((i & 2) >> 1);
			newNode.zMin = this.zMin + newSize.z * ((i & 4) >> 2);
			newNode.xMax = newNode.xMin + newSize.x;
			newNode.yMax = newNode.yMin + newSize.y;
			newNode.zMax = newNode.zMin + newSize.z;
			this.octants.push(newNode);
		}
	}

	// Note: The requirement for this method to be called is that `object` is contained directly in this node.
	public function remove(object:IOctreeObject) {
		this.objects.remove(object);
		this.count--;
		this.merge();
		// Clean up all ancestors
		var node = this.parent;
		while (node != null) {
			node.count--; // Reduce the count for all ancestor nodes up until the root
			node.merge();
			node = node.parent;
		}
	}

	public function update(object:IOctreeObject) {
		this.objects.remove(object);

		var node = this;
		while (node != null) {
			node.count--;
			node.merge();

			if (node.largerThan(object) && node.containsCenter(object)) {
				node.insert(object);
				return true;
			}

			node = node.parent;
		}

		return false;
	}

	public function merge() {
		if (this.count > 8 || (this.octants == null) || disableMerge)
			return;
		// Add all objects in the octants back to this node
		for (i in 0...8) {
			var octant = this.octants[i];
			for (object in octant.objects) {
				this.objects.push(object);
				this.octree.objectToNode.set(object, this);
			}
		}
		this.octants = null; // ...then devare the octants
	}

	public inline function largerThan(object:IOctreeObject) {
		return xMin <= object.boundingBox.xMin && yMin <= object.boundingBox.yMin && zMin <= object.boundingBox.zMin && xMax >= object.boundingBox.xMax
			&& yMax >= object.boundingBox.yMax && zMax >= object.boundingBox.zMax;
		// return this.size > (box.xMax - box.xMin) && this.size > (box.yMax - box.yMin) && this.size > (box.zMax - box.zMin);
	}

	public inline function containsCenter(object:IOctreeObject) {
		return this.containsPoint2(object.boundingBox.getCenter());
	}

	public inline function containsPoint(p:Vector) {
		return p.x >= xMin && p.x < xMax && p.y >= yMin && p.y < yMax && p.z >= zMin && p.z < zMax;
	}

	public inline function containsPoint2(p:h3d.col.Point) {
		return p.x >= xMin && p.x < xMax && p.y >= yMin && p.y < yMax && p.z >= zMin && p.z < zMax;
	}

	inline function rayIntersection(r:Ray, bestMatch:Bool):Float {
		var minTx = (xMin - r.px) / r.lx;
		var minTy = (yMin - r.py) / r.ly;
		var minTz = (zMin - r.pz) / r.lz;
		var maxTx = (xMax - r.px) / r.lx;
		var maxTy = (yMax - r.py) / r.ly;
		var maxTz = (zMax - r.pz) / r.lz;

		var realMinTx = Math.min(minTx, maxTx);
		var realMinTy = Math.min(minTy, maxTy);
		var realMinTz = Math.min(minTz, maxTz);
		var realMaxTx = Math.max(minTx, maxTx);
		var realMaxTy = Math.max(minTy, maxTy);
		var realMaxTz = Math.max(minTz, maxTz);

		var minmax = Math.min(Math.min(realMaxTx, realMaxTy), realMaxTz);
		var maxmin = Math.max(Math.max(realMinTx, realMinTy), realMinTz);

		if (minmax < maxmin)
			return -1;

		return maxmin;
	}

	public function raycast(rayOrigin:Vector, rayDirection:Vector, intersections:Array<OctreeIntersection>, bestT:Float) {
		var ray = Ray.fromValues(rayOrigin.x, rayOrigin.y, rayOrigin.z, rayDirection.x, rayDirection.y, rayDirection.z);
		// Construct the loose bounding box of this node (2x in size, with the regular bounding box in the center)

		if (rayIntersection(ray, true) == -1)
			return;

		for (obj in this.objects) {
			var iSecs = [];
			obj.rayCast(rayOrigin, rayDirection, iSecs, bestT);
			for (intersection in iSecs) {
				var intersectionData = new OctreeIntersection();
				intersectionData.distance = rayOrigin.distance(intersection.point);
				intersectionData.object = intersection.object;
				intersectionData.point = intersection.point;
				intersectionData.normal = intersection.normal;
				intersections.push(intersectionData);
			}
		}

		if (this.octants != null) {
			for (i in 0...8) {
				var octant = this.octants[i];
				octant.raycast(rayOrigin, rayDirection, intersections, bestT);
			}
		}
	}

	public function boundingSearch(b:Bounds, intersections:Array<IOctreeElement>) {
		if (!(xMin > b.xMax || yMin > b.yMax || zMin > b.zMax || xMax < b.xMin || yMax < b.yMin || zMax < b.zMin)) {
			for (obj in this.objects) {
				if (obj.boundingBox.collide(b))
					intersections.push(obj);
			}
			if (octants != null) {
				for (octant in this.octants)
					octant.boundingSearch(b, intersections);
			}
		}
	}

	public inline function getClosestPoint(point:Vector) {
		var closest = new Vector(Math.min(Math.max(this.xMin, point.x), this.xMax), Math.min(Math.max(this.yMin, point.y), this.yMax),
			Math.min(Math.max(this.zMin, point.z), this.zMax));
		return closest;
	}

	public function getElementType() {
		return 1;
	}

	public function setPriority(priority:Int) {
		this.priority = priority;
	}
}
