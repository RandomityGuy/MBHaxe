package collision;

import h3d.Vector;
import h3d.col.Bounds;

@:publicFields
class BVHNode {
	var id:Int;
	var parent:BVHNode;
	var child1:BVHNode;
	var child2:BVHNode;
	var isLeaf:Bool;
	var bounds:Bounds;
	var surface:CollisionSurface;

	public function new() {}
}

class BVHTree {
	var nodeId:Int = 0;
	var root:BVHNode;

	public function new() {}

	function update() {
		var invalidNodes = [];
		this.traverse(node -> {
			if (node.isLeaf) {
				var entity = node.surface;
				var tightAABB = entity.boundingBox;

				if (node.bounds.containsBounds(tightAABB)) {
					return;
				}

				invalidNodes.push(node);
			}
		});
		for (node in invalidNodes) {
			this.remove(node);
			this.add(node.surface);
		}
	}

	public function add(entity:CollisionSurface) {
		// Enlarged AABB
		var aabb = entity.boundingBox;

		var newNode = new BVHNode();
		newNode.id = this.nodeId++;
		newNode.bounds = aabb;
		newNode.surface = entity;
		newNode.isLeaf = true;

		if (this.root == null) {
			this.root = newNode;
			return newNode;
		}

		// Find the best sibling for the new leaf
		var bestSibling = this.root;
		var bestCostBox = this.root.bounds.clone();
		bestCostBox.add(aabb);
		var bestCost = bestCostBox.xSize * bestCostBox.ySize + bestCostBox.xSize * bestCostBox.zSize + bestCostBox.ySize * bestCostBox.zSize;
		var q = [{p1: this.root, p2: 0.0}];

		while (q.length != 0) {
			var front = q.shift();
			var current = front.p1;
			var inheritedCost = front.p2;

			var combined = current.bounds.clone();
			combined.add(aabb);
			var directCost = combined.xSize * combined.ySize + combined.xSize * combined.zSize + combined.ySize * combined.zSize;

			var costForCurrent = directCost + inheritedCost;
			if (costForCurrent < bestCost) {
				bestCost = costForCurrent;
				bestSibling = current;
			}

			inheritedCost += directCost
				- (current.bounds.xSize * current.bounds.ySize + current.bounds.xSize * current.bounds.zSize + current.bounds.ySize * current.bounds.zSize);

			var aabbCost = aabb.xSize * aabb.ySize + aabb.xSize * aabb.zSize + aabb.ySize * aabb.zSize;
			var lowerBoundCost = aabbCost + inheritedCost;
			if (lowerBoundCost < bestCost) {
				if (!current.isLeaf) {
					if (current.child1 != null)
						q.push({p1: current.child1, p2: inheritedCost});
					if (current.child2 != null)
						q.push({p1: current.child2, p2: inheritedCost});
				}
			}
		}

		// Create a new parent
		var oldParent = bestSibling.parent;
		var newParent = new BVHNode();
		newParent.id = this.nodeId++;
		newParent.parent = oldParent;
		newParent.bounds = bestSibling.bounds.clone();
		newParent.bounds.add(aabb);
		newParent.isLeaf = false;

		if (oldParent != null) {
			if (oldParent.child1 == bestSibling) {
				oldParent.child1 = newParent;
			} else {
				oldParent.child2 = newParent;
			}

			newParent.child1 = bestSibling;
			newParent.child2 = newNode;
			bestSibling.parent = newParent;
			newNode.parent = newParent;
		} else {
			newParent.child1 = bestSibling;
			newParent.child2 = newNode;
			bestSibling.parent = newParent;
			newNode.parent = newParent;
			this.root = newParent;
		}

		// Walk back up the tree refitting ancestors' AABB and applying rotations
		var ancestor = newNode.parent;

		while (ancestor != null) {
			var child1 = ancestor.child1;
			var child2 = ancestor.child2;

			ancestor.bounds = new Bounds();
			if (child1 != null)
				ancestor.bounds.add(child1.bounds);
			if (child2 != null)
				ancestor.bounds.add(child2.bounds);

			this.rotate(ancestor);

			ancestor = ancestor.parent;
		}

		return newNode;
	}

	function reset() {
		this.nodeId = 0;
		this.root = null;
	}

	// BFS tree traversal
	function traverse(callback:(node:BVHNode) -> Void) {
		var q = [this.root];

		while (q.length != 0) {
			var current = q.shift();
			if (current == null) {
				break;
			}

			callback(current);

			if (!current.isLeaf) {
				if (current.child1 != null)
					q.push(current.child1);
				if (current.child2 != null)
					q.push(current.child2);
			}
		}
	}

	public function remove(node:BVHNode) {
		var parent = node.parent;

		if (parent != null) {
			var sibling = parent.child1 == node ? parent.child2 : parent.child1;

			if (parent.parent != null) {
				sibling.parent = parent.parent;
				if (parent.parent.child1 == parent) {
					parent.parent.child1 = sibling;
				} else {
					parent.parent.child2 = sibling;
				}
			} else {
				this.root = sibling;
				sibling.parent = null;
			}

			var ancestor = sibling.parent;
			while (ancestor != null) {
				var child1 = ancestor.child1;
				var child2 = ancestor.child2;

				ancestor.bounds = child1.bounds.clone();
				ancestor.bounds.add(child2.bounds);
				ancestor = ancestor.parent;
			}
		} else {
			if (this.root == node) {
				this.root = null;
			}
		}
	}

	function rotate(node:BVHNode) {
		if (node.parent == null) {
			return;
		}
		var parent = node.parent;
		var sibling = parent.child1 == node ? parent.child2 : parent.child1;
		var costDiffs = [];
		var nodeArea = node.bounds.xSize * node.bounds.ySize + node.bounds.zSize * node.bounds.ySize + node.bounds.xSize * node.bounds.zSize;

		var ch1 = sibling.bounds.clone();
		ch1.add(node.child1.bounds);
		costDiffs.push(ch1.xSize * ch1.ySize + ch1.zSize * ch1.ySize + ch1.xSize * ch1.zSize - nodeArea);
		var ch2 = sibling.bounds.clone();
		ch2.add(node.child2.bounds);
		costDiffs.push(ch2.xSize * ch2.ySize + ch2.zSize * ch2.ySize + ch2.xSize * ch2.zSize - nodeArea);

		if (!sibling.isLeaf) {
			var siblingArea = sibling.bounds.xSize * sibling.bounds.ySize + sibling.bounds.zSize * sibling.bounds.ySize
				+ sibling.bounds.xSize * sibling.bounds.zSize;
			if (sibling.child1 != null) {
				var ch3 = node.bounds.clone();
				ch3.add(sibling.child1.bounds);
				costDiffs.push(ch3.xSize * ch3.ySize + ch3.zSize * ch3.ySize + ch3.xSize * ch3.zSize - siblingArea);
			}
			if (sibling.child2 != null) {
				var ch4 = node.bounds.clone();
				ch4.add(sibling.child2.bounds);
				costDiffs.push(ch4.xSize * ch4.ySize + ch4.zSize * ch4.ySize + ch4.xSize * ch4.zSize - siblingArea);
			}
		}

		var bestDiffIndex = 0;
		for (i in 1...costDiffs.length) {
			if (costDiffs[i] < costDiffs[bestDiffIndex]) {
				bestDiffIndex = i;
			}
		}

		if (costDiffs[bestDiffIndex] < 0.0) {
			switch (bestDiffIndex) {
				case 0:
					if (parent.child1 == sibling) {
						parent.child1 = node.child2;
					} else {
						parent.child2 = node.child2;
					}

					if (node.child2 != null) {
						node.child2.parent = parent;
					}

					node.child2 = sibling;
					sibling.parent = node;
					node.bounds = sibling.bounds.clone();
					if (node.child1 != null) {
						node.bounds.add(node.child1.bounds);
					}
				case 1:
					if (parent.child1 == sibling) {
						parent.child1 = node.child1;
					} else {
						parent.child2 = node.child1;
					}
					if (node.child1 != null) {
						node.child1.parent = parent;
					}
					node.child1 = sibling;
					sibling.parent = node;
					node.bounds = sibling.bounds.clone();
					if (node.child2 != null) {
						node.bounds.add(node.child2.bounds);
					}
				case 2:
					if (parent.child1 == node) {
						parent.child1 = sibling.child2;
					} else {
						parent.child2 = sibling.child2;
					}
					if (sibling.child2 != null) {
						sibling.child2.parent = parent;
					}
					sibling.child2 = node;
					node.parent = sibling;
					sibling.bounds = node.bounds.clone();
					if (sibling.child2 != null) {
						sibling.bounds.add(sibling.child2.bounds);
					}

				case 3:
					if (parent.child1 == node) {
						parent.child1 = sibling.child1;
					} else {
						parent.child2 = sibling.child1;
					}
					if (sibling.child1 != null) {
						sibling.child1.parent = parent;
					}
					sibling.child1 = node;
					node.parent = sibling;
					sibling.bounds = node.bounds.clone();
					if (sibling.child1 != null) {
						sibling.bounds.add(sibling.child1.bounds);
					}
			}
		}
	}

	public function boundingSearch(searchbox:Bounds) {
		var res = [];
		if (this.root == null)
			return res;

		var q = [this.root];

		while (q.length != 0) {
			var current = q.shift();

			if (current.bounds.containsBounds(searchbox) || current.bounds.collide(searchbox)) {
				if (current.isLeaf) {
					res.push(current.surface);
				} else {
					if (current.child1 != null)
						q.push(current.child1);
					if (current.child2 != null)
						q.push(current.child2);
				}
			}
		}

		return res;
	}

	public function rayCast(origin:Vector, direction:Vector) {
		var res = [];
		if (this.root == null)
			return res;

		var ray = h3d.col.Ray.fromValues(origin.x, origin.y, origin.z, direction.x, direction.y, direction.z);
		var q = [this.root];
		while (q.length != 0) {
			var current = q.shift();
			if (ray.collide(current.bounds)) {
				if (current.isLeaf) {
					res = res.concat(current.surface.rayCast(origin, direction));
				} else {
					if (current.child1 != null)
						q.push(current.child1);
					if (current.child2 != null)
						q.push(current.child2);
				}
			}
		}
		return res;
	}
}
