package octree;

import h3d.Vector;
import h3d.col.Bounds;

class Octree {
	public var root:OctreeNode;

	static var DEFAULT_ROOT_NODE_SIZE = 1;
	static var MIN_DEPTH = -52; // Huge
	static var MAX_DEPTH = 8;

	/** A map of each object in the octree to the node that it's in. This accelerates removal drastically, as the lookup step can be skipped. */
	public var objectToNode:Map<IOctreeObject, OctreeNode>;

	var prevBoundSearch:Bounds;
	var boundSearchCache:Array<IOctreeElement>;

	public function new() {
		this.root = new OctreeNode(this, 0);
		this.objectToNode = new Map();
	}

	public function insert(object:IOctreeObject) {
		var node = this.objectToNode.get(object);
		if (node != null)
			return false; // Don't insert if already contained in the tree
		while (!this.root.largerThan(object) || !this.root.containsCenter(object)) {
			// The root node does not fit the object; we need to grow the tree.
			if (this.root.depth == -32) {
				return true;
			}
			this.grow(object);
		}
		var emptyBefore = this.root.count == 0;
		this.root.insert(object);
		if (emptyBefore)
			this.shrink(); // See if we can fit the octree better now that we actually have an element in it
		return true;
	}

	public function remove(object:IOctreeObject) {
		var node = this.objectToNode.get(object);
		if (node == null)
			return;
		node.remove(object);
		this.objectToNode.remove(object);
		this.shrink(); // Try shrinking the octree
	}

	/** Updates an object in the tree whose bounding box has changed. */
	public function update(object:IOctreeObject) {
		if (!this.objectToNode.exists(object)) {
			this.insert(object);
			return;
		}
		var success = this.objectToNode.get(object).update(object);
		if (!success) {
			this.objectToNode.remove(object);
			this.insert(object);
		}
	}

	/** Expand the octree towards an object that doesn't fit in it. */
	public function grow(towards:IOctreeObject) {
		// We wanna grow towards all the vertices of the object's bounding box that lie outside the octree, so we determine the average position of those vertices:
		var averagePoint = new Vector();
		var count = 0;
		for (i in 0...8) {
			var vec = new Vector();
			vec.x = (i & 1) == 1 ? towards.boundingBox.xMin : towards.boundingBox.xMax;
			vec.y = (i & 2) == 2 ? towards.boundingBox.yMin : towards.boundingBox.yMax;
			vec.z = (i & 4) == 4 ? towards.boundingBox.zMin : towards.boundingBox.zMax;
			if (!this.root.containsPoint(vec)) {
				averagePoint = averagePoint.add(vec);
				count++;
			}
		}
		averagePoint.load(averagePoint.multiply(1 / count)); // count should be greater than 0, because that's why we're growing in the first place.
		// Determine the direction from the root center to the determined point
		var rootCenter = new Vector((this.root.xMax + this.root.xMin) / 2, (this.root.yMax + this.root.yMin) / 2, (this.root.zMax + this.root.zMin) / 2);
		var direction = averagePoint.sub(rootCenter); // Determine the "direction of growth"
		// Create a new root. The current root will become a quadrant in this new root.
		var newRoot = new OctreeNode(this, this.root.depth - 1);
		newRoot.xMin = this.root.xMin;
		newRoot.yMin = this.root.yMin;
		newRoot.zMin = this.root.zMin;
		newRoot.xMax = 2 * this.root.xMax - this.root.xMin;
		newRoot.yMax = 2 * this.root.yMax - this.root.yMin;
		newRoot.zMax = 2 * this.root.zMax - this.root.zMin;
		if (direction.x < 0)
			newRoot.xMin -= this.root.xMax - this.root.xMin;
		if (direction.y < 0)
			newRoot.yMin -= this.root.yMax - this.root.yMin;
		if (direction.z < 0)
			newRoot.zMin -= this.root.zMax - this.root.zMin;
		if (this.root.count > 0) {
			var octantIndex = ((direction.x < 0) ? 1 : 0) + ((direction.y < 0) ? 2 : 0) + ((direction.z < 0) ? 4 : 0);
			newRoot.createOctants();
			newRoot.octants[octantIndex] = this.root;
			this.root.parent = newRoot;
			newRoot.count = this.root.count;
			newRoot.merge();
		}
		this.root = newRoot;
	}

	/** Tries to shrink the octree if large parts of the octree are empty. */
	public function shrink() {
		if (this.root.xMax - this.root.xMin < 1 || this.root.yMax - this.root.yMin < 1 || this.root.zMax - this.root.zMin < 1 || this.root.objects.length > 0)
			return;
		if (this.root.count == 0) {
			// Reset to default empty octree
			this.root.xMin = this.root.yMin = this.root.zMin = 0;
			this.root.xMax = this.root.yMax = this.root.zMax = 1;
			this.root.depth = 0;
			return;
		}
		if (this.root.octants == null) {
			this.root.createOctants();

			var fittingOctant:OctreeNode = null;
			for (obj in this.root.objects) {
				if (this.root.octants[0].largerThan(obj)) {
					for (i in 0...8) {
						var octant = this.root.octants[i];
						if (octant.containsCenter(obj)) {
							if (fittingOctant != null && fittingOctant != octant)
								return;
							fittingOctant = octant;
						}
					}
				} else {
					return;
				}
			}
		}
		// Find the only non-empty octant
		var nonEmptyOctant:OctreeNode = null;
		for (i in 0...8) {
			var octant = this.root.octants[i];
			if (octant.count > 0) {
				if (nonEmptyOctant != null)
					return; // There are more than two non-empty octants -> don't shrink.
				else
					nonEmptyOctant = octant;
			}
		}
		// Make the only non-empty octant the new root
		this.root = nonEmptyOctant;
		nonEmptyOctant.parent = null;
		this.shrink();
	}

	/** Returns a list of all objects that intersect with the given ray, sorted by distance. */
	public function raycast(rayOrigin:Vector, rayDirection:Vector) {
		var intersections:Array<OctreeIntersection> = [];
		this.root.raycast(rayOrigin, rayDirection, intersections);
		intersections.sort((a, b) -> (a.distance == b.distance) ? 0 : (a.distance > b.distance ? 1 : -1));
		return intersections;
	}

	public function boundingSearch(bounds:Bounds, useCache:Bool = false) {
		var intersections = [];
		if (useCache) {
			if (this.prevBoundSearch != null) {
				if (this.prevBoundSearch.containsBounds(bounds)) {
					return boundSearchCache;
				}
			}
		}
		this.root.boundingSearch(bounds, intersections);
		if (useCache) {
			prevBoundSearch = bounds;
			boundSearchCache = intersections;
		}
		return intersections;
	}

	public function radiusSearch(point:Vector, maximumDistance:Float) {
		function getClosestPoint(box:Bounds, point:Vector) {
			var closest = new Vector();
			if (box.xMin > point.x)
				closest.x = box.xMin;
			else if (box.xMax < point.x)
				closest.x = box.xMax;
			else
				closest.x = point.x;

			if (box.yMin > point.y)
				closest.y = box.yMin;
			else if (box.yMax < point.y)
				closest.y = box.yMax;
			else
				closest.y = point.y;

			if (box.zMin > point.z)
				closest.z = box.zMin;
			else if (box.zMax < point.z)
				closest.z = box.zMax;
			else
				closest.z = point.z;

			return closest;
		}

		var L = [];
		var queue = new PriorityQueue<IOctreeElement>();

		var maxDistSq = maximumDistance * maximumDistance;
		var closestPoint = this.root.getClosestPoint(point);
		var distSq = closestPoint.distanceSq(point);

		if (distSq > maximumDistance)
			return L;

		this.root.setPriority(cast(-distSq));
		queue.enqueue(root, distSq);

		while (queue.count > 0) {
			var node = queue.dequeue();

			switch (node.getElementType()) {
				case 1:
					var octant = cast(node, OctreeNode);
					if (octant.objects != null) {
						for (object in octant.objects) {
							var dist = point.distanceSq(getClosestPoint(object.boundingBox, point));
							if (dist < maxDistSq) {
								object.setPriority(cast(-dist));
								queue.enqueue(object, dist);
							}
						}
					}
					if (octant.octants != null) {
						for (suboctant in octant.octants) {
							var dist = point.distanceSq(suboctant.getClosestPoint(point));
							if (dist < maxDistSq) {
								suboctant.setPriority(cast(-dist));
								queue.enqueue(suboctant, dist);
							}
						}
					}

				case 2:
					L.push(cast(node, IOctreeObject));
			}
		}
		return L;
	}
}
