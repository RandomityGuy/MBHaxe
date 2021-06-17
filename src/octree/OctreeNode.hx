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
	public var min = new Vector();

	/** The size of the bounding box on all three axes. This forces the bounding box to be a cube. */
	public var size:Float;

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
			// First we check if the object can fit into any of the octants (they all have the same size, so checking only one suffices)
			if (this.octants[0].largerThan(object)) {
				// Try to insert the object into one of the octants...
				for (i in 0...8) {
					var octant = this.octants[i];
					if (octant.containsCenter(object)) {
						octant.insert(object);
						return;
					}
				}
			}
			// No octant fit the object, so add it to the list of objects instead
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
				for (j in 0...8) {
					var octant = this.octants[j];
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
			var newNode = new OctreeNode(this.octree, this.depth + 1);
			newNode.parent = this;
			newNode.size = this.size / 2;
			newNode.min.set(this.min.x
				+ newNode.size * ((i & 1) >> 0), // The x coordinate changes every index
				this.min.y
				+ newNode.size * ((i & 2) >> 1), // The y coordinate changes every 2 indices
				this.min.z
				+ newNode.size * ((i & 4) >> 2) // The z coordinate changes every 4 indices
			);
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
		var box = object.boundingBox;
		var bb = new Bounds();
		bb.setMin(this.min.toPoint());
		bb.xMax = bb.xMin + this.size;
		bb.yMax = bb.yMin + this.size;
		bb.zMax = bb.zMin + this.size;
		return bb.containsBounds(box);
		// return this.size > (box.xMax - box.xMin) && this.size > (box.yMax - box.yMin) && this.size > (box.zMax - box.zMin);
	}

	public function containsCenter(object:IOctreeObject) {
		var box = object.boundingBox;
		var x = box.xMin + (box.xMax - box.xMin) / 2;
		var y = box.yMin + (box.yMax - box.yMin) / 2;
		var z = box.zMin + (box.zMax - box.zMin) / 2;
		return this.min.x <= x && x < (this.min.x + this.size) && this.min.y <= y && y < (this.min.y + this.size) && this.min.z <= z
			&& z < (this.min.z + this.size);
	}

	public function containsPoint(point:Vector) {
		var x = point.x;
		var y = point.y;
		var z = point.z;
		return this.min.x <= x && x < (this.min.x + this.size) && this.min.y <= y && y < (this.min.y + this.size) && this.min.z <= z
			&& z < (this.min.z + this.size);
	}

	public function raycast(rayOrigin:Vector, rayDirection:Vector, intersections:Array<OctreeIntersection>) {
		// Construct the loose bounding box of this node (2x in size, with the regular bounding box in the center)
		var looseBoundingBox = this.octree.tempBox;
		looseBoundingBox.xMin += this.min.x + (-this.size / 2);
		looseBoundingBox.yMin += this.min.y + (-this.size / 2);
		looseBoundingBox.zMin += this.min.z + (-this.size / 2);
		looseBoundingBox.xMax += this.min.x + (this.size * 3 / 2);
		looseBoundingBox.yMax += this.min.y + (this.size * 3 / 2);
		looseBoundingBox.zMax += this.min.z + (this.size * 3 / 2);
		if (looseBoundingBox.rayIntersection(Ray.fromValues(rayOrigin.x, rayOrigin.y, rayOrigin.z, rayDirection.x, rayDirection.y, rayDirection.z),
			true) == -1)
			return; // The ray doesn't hit the node's loose bounding box; we can stop
		var vec = new Vector();
		// Test all objects for intersection
		if (this.objects.length > 0)
			for (object in this.objects) {
				if (object.isIntersectedByRay(rayOrigin, rayDirection, vec)) {
					var intersection:OctreeIntersection = new OctreeIntersection();
					intersection.object = object;
					intersection.point = vec;
					intersection.distance = rayOrigin.distance(vec);
					intersections.push(intersection);
					vec = new Vector();
				}
			}
		// Recurse into the octants
		if (this.octants != null)
			for (i in 0...8) {
				var octant = this.octants[i];
				octant.raycast(rayOrigin, rayDirection, intersections);
			}
	}

	public function boundingSearch(bounds:Bounds, intersections:Array<IOctreeElement>) {
		var thisBounds = new Bounds();
		thisBounds.setMin(this.min.toPoint());
		thisBounds.xSize = thisBounds.ySize = thisBounds.zSize = this.size;
		if (thisBounds.collide(bounds)) {
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
		if (this.min.x > point.x)
			closest.x = this.min.x;
		else if (this.min.x + this.size < point.x)
			closest.x = this.min.x + this.size;
		else
			closest.x = point.x;

		if (this.min.y > point.y)
			closest.y = this.min.y;
		else if (this.min.y + this.size < point.y)
			closest.y = this.min.y + this.size;
		else
			closest.y = point.y;

		if (this.min.z > point.z)
			closest.z = this.min.z;
		else if (this.min.z + this.size < point.z)
			closest.z = this.min.z + this.size;
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
