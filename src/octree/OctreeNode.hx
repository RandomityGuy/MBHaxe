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
	public var bounds:Bounds;

	/** The size of the bounding box on all three axes. This forces the bounding box to be a cube. */
	public var octants:Array<OctreeNode> = null;

	/** A list of objects contained in this node. Note that the node doesn't need to be a leaf node for this set to be non-empty; since this is an octree of bounding boxes, some volumes cannot fit into an octant and therefore need to be stored in the node itself. */
	public var objects = new Array<IOctreeObject>();

	/** The total number of objects in the subtree with this node as its root. */
	public var count = 0;

	public var depth:Int;

	public function new(octree:Octree, depth:Int) {
		this.octree = octree;
		this.depth = depth;
	}

	public function insert(object:IOctreeObject) {
		this.count++;
		if (this.octants != null) {
			for (i in 0...8) {
				var octant = this.octants[i];
				if (octant.largerThan(object) && octant.containsCenter(object)) {
					octant.insert(object);
					return;
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
			for (j in 0...8) {
				var octant = this.octants[j];
				if (octant.largerThan(object) && octant.containsCenter(object)) {
					octant.insert(object);
					this.objects.remove(object);
					break;
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
			var newNode = new OctreeNode(this.octree, this.depth + 1);
			newNode.parent = this;
			var newSize = this.bounds.getSize().multiply(1 / 2);
			newNode.bounds = this.bounds.clone();
			newNode.bounds.setMin(new Point(this.bounds.xMin
				+ newSize.x * ((i & 1) >> 0), this.bounds.yMin
				+ newSize.y * ((i & 2) >> 1),
				this.bounds.zMin
				+ newSize.z * ((i & 4) >> 2)));
			newNode.bounds.xSize = newSize.x;
			newNode.bounds.ySize = newSize.y;
			newNode.bounds.zSize = newSize.z;
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

	public function merge() {
		if (this.count > 8 || (this.octants == null))
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

	public function largerThan(object:IOctreeObject) {
		return this.bounds.containsBounds(object.boundingBox);
		// return this.size > (box.xMax - box.xMin) && this.size > (box.yMax - box.yMin) && this.size > (box.zMax - box.zMin);
	}

	public function containsCenter(object:IOctreeObject) {
		return this.bounds.contains(object.boundingBox.getCenter());
	}

	public function containsPoint(point:Vector) {
		return this.bounds.contains(point.toPoint());
	}

	public function raycast(rayOrigin:Vector, rayDirection:Vector, intersections:Array<OctreeIntersection>) {
		var ray = Ray.fromValues(rayOrigin.x, rayOrigin.y, rayOrigin.z, rayDirection.x, rayDirection.y, rayDirection.z);
		// Construct the loose bounding box of this node (2x in size, with the regular bounding box in the center)

		if (this.bounds.rayIntersection(ray, true) == -1)
			return;

		for (obj in this.objects) {
			var iSec = new Vector();
			if (obj.isIntersectedByRay(rayOrigin, rayDirection, iSec)) {
				var intersectionData = new OctreeIntersection();
				intersectionData.distance = rayOrigin.distance(iSec);
				intersectionData.object = obj;
				intersectionData.point = iSec;
				intersections.push(intersectionData);
			}
		}

		if (this.octants != null) {
			for (i in 0...8) {
				var octant = this.octants[i];
				octant.raycast(rayOrigin, rayDirection, intersections);
			}
		}
	}

	public function boundingSearch(bounds:Bounds, intersections:Array<IOctreeElement>) {
		if (this.bounds.collide(bounds)) {
			for (obj in this.objects) {
				if (obj.boundingBox.collide(bounds))
					intersections.push(obj);
			}
			if (octants != null) {
				for (octant in this.octants)
					octant.boundingSearch(bounds, intersections);
			}
		}
	}

	public function getClosestPoint(point:Vector) {
		var closest = new Vector();
		if (this.bounds.xMin > point.x)
			closest.x = this.bounds.xMin;
		else if (this.bounds.xMax < point.x)
			closest.x = this.bounds.xMax;
		else
			closest.x = point.x;

		if (this.bounds.yMin > point.y)
			closest.y = this.bounds.yMin;
		else if (this.bounds.yMax < point.y)
			closest.y = this.bounds.yMax;
		else
			closest.y = point.y;

		if (this.bounds.zMin > point.z)
			closest.z = this.bounds.zMin;
		else if (this.bounds.zMax < point.z)
			closest.z = this.bounds.zMax;
		else
			closest.z = point.z;

		return closest;
	}

	public function getElementType() {
		return 1;
	}

	public function setPriority(priority:Int) {
		this.priority = priority;
	}
}
