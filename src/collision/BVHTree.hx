package collision;

import h3d.col.Bounds;
import h3d.Vector;

// https://github.com/Sopiro/DynamicBVH/blob/master/src/aabbtree.ts

@:publicFields
class BVHNode {
	var bounds:Bounds;
	var objects:Array<CollisionSurface>;
	var objectBounds:Bounds; // total bounds for objects stored in THIS node
	var left:BVHNode;
	var right:BVHNode;
	var surfaceArea:Float;

	public function new(bounds:Bounds) {
		this.bounds = bounds.clone();
		surfaceArea = this.bounds.xSize * this.bounds.ySize + this.bounds.xSize * this.bounds.zSize + this.bounds.ySize * this.bounds.zSize;
	}

	function getSplitCost(objs:Array<{obj:CollisionSurface, centroid:h3d.col.Point}>, axis:Int) {
		// Pick best axis to split
		switch (axis) {
			case 0:
				objs.sort((x, y) -> x.centroid.x > y.centroid.x ? 1 : -1);
			case 1:
				objs.sort((x, y) -> x.centroid.y > y.centroid.y ? 1 : -1);
			case 2:
				objs.sort((x, y) -> x.centroid.z > y.centroid.z ? 1 : -1);
		};

		var leftObjects = objs.slice(0, Math.ceil(objs.length / 2));
		var rightObjects = objs.slice(Math.ceil(objs.length / 2));
		var leftAABB = new Bounds();
		var rightAABB = new Bounds();
		for (o in leftObjects)
			leftAABB.add(o.obj.boundingBox);
		for (o in rightObjects)
			rightAABB.add(o.obj.boundingBox);
		var leftSA = leftAABB.xSize * leftAABB.ySize + leftAABB.xSize * leftAABB.zSize + leftAABB.ySize * leftAABB.zSize;
		var rightSA = rightAABB.xSize * rightAABB.ySize + rightAABB.xSize * rightAABB.zSize + rightAABB.ySize * rightAABB.zSize;
		var splitCost = leftSA + rightSA;
		var bestSplit = {
			cost: splitCost,
			left: leftObjects,
			right: rightObjects,
			leftBounds: leftAABB,
			rightBounds: rightAABB,
			axis: axis
		};
		return bestSplit;
	}

	public function split() {
		// Splitting first time
		// Calculate the centroids of all objects
		var objs = objects.map(x -> {
			x.generateBoundingBox();
			return {obj: x, centroid: x.boundingBox.getCenter()};
		});

		// Find the best split cost
		var costs = [getSplitCost(objs, 0), getSplitCost(objs, 1), getSplitCost(objs, 2)];
		costs.sort((x, y) -> x.cost > y.cost ? 1 : -1);
		var bestSplit = costs[0];

		// Sort the objects according to where they should go
		var leftObjs = [];
		var rightObjs = [];
		var intersectObjs = [];
		for (o in bestSplit.left.concat(bestSplit.right)) {
			var inleft = bestSplit.leftBounds.containsBounds(o.obj.boundingBox);
			var inright = bestSplit.rightBounds.containsBounds(o.obj.boundingBox);
			if (inleft && inright) {
				intersectObjs.push(o.obj);
			} else if (inleft) {
				leftObjs.push(o.obj);
			} else if (inright) {
				rightObjs.push(o.obj);
			}
		}

		// Only one side has objects, egh
		if (leftObjs.length == 0 || rightObjs.length == 0) {
			var thisobjs = leftObjs.concat(rightObjs).concat(intersectObjs);
			this.objects = thisobjs;
			this.objectBounds = new Bounds();
			for (o in thisobjs)
				this.objectBounds.add(o.boundingBox);
			return;
		}

		// Make the child nodes
		var leftBounds = new Bounds();
		var rightBounds = new Bounds();
		for (o in leftObjs)
			leftBounds.add(o.boundingBox);
		for (o in rightObjs)
			rightBounds.add(o.boundingBox);
		left = new BVHNode(leftBounds);
		right = new BVHNode(rightBounds);
		left.objects = leftObjs;
		right.objects = rightObjs;
		this.objects = intersectObjs;
		this.objectBounds = new Bounds();
		for (o in intersectObjs)
			this.objectBounds.add(o.boundingBox);

		left.split();
		right.split();
	}

	public function boundingSearch(searchbox:Bounds) {
		if (this.bounds.containsBounds(searchbox) || this.bounds.collide(searchbox)) {
			var intersects = [];
			if (this.left != null && this.right != null) {
				intersects = intersects.concat(this.left.boundingSearch(searchbox));
				intersects = intersects.concat(this.right.boundingSearch(searchbox));
			}
			if (this.objectBounds.collide(searchbox) || this.objectBounds.containsBounds(searchbox)) {
				for (o in this.objects) {
					if (o.boundingBox.containsBounds(searchbox) || o.boundingBox.collide(searchbox))
						intersects.push(o);
				}
			}
			return intersects;
		} else {
			return [];
		}
	}

	public function rayCast(origin:Vector, direction:Vector) {
		var ray = h3d.col.Ray.fromValues(origin.x, origin.y, origin.z, direction.x, direction.y, direction.z);
		if (ray.collide(this.bounds)) {
			var intersects = [];
			if (this.left != null && this.right != null) {
				intersects = intersects.concat(this.left.rayCast(origin, direction));
				intersects = intersects.concat(this.right.rayCast(origin, direction));
			}
			if (ray.collide(this.objectBounds)) {
				for (o in this.objects) {
					if (ray.collide(o.boundingBox))
						intersects = intersects.concat(o.rayCast(origin, direction));
				}
			}
			return intersects;
		} else {
			return [];
		}
	}
}

class BVHTree {
	public var bounds:Bounds;

	var surfaces:Array<CollisionSurface> = [];

	var root:BVHNode;

	public function new(bounds:Bounds) {
		this.bounds = bounds.clone();
	}

	public function insert(surf:CollisionSurface) {
		surfaces.push(surf);
	}

	public function build() {
		root = new BVHNode(bounds);
		// Add all children
		root.objects = this.surfaces;
		root.split();
	}

	public function boundingSearch(searchbox:Bounds) {
		return this.root.boundingSearch(searchbox);
	}

	public function rayCast(origin:Vector, direction:Vector) {
		return this.root.rayCast(origin, direction);
	}
}
