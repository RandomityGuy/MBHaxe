package collision;

import h3d.Vector;
import h3d.col.Bounds;

interface IBVHObject {
	var boundingBox:Bounds;
	function rayCast(rayOrigin:Vector, rayDirection:Vector):Array<octree.IOctreeObject.RayIntersectionData>;
}

@:publicFields
class BVHNode<T:IBVHObject> {
	var index:Int;
	var parent:Int = -1;
	var child1:Int = -1;
	var child2:Int = -1;
	var isLeaf:Bool;
	var bounds:Bounds;
	var object:T;

	public function new() {}
}

class BVHTree<T:IBVHObject> {
	var root:BVHNode<T>;
	var nodes:Array<BVHNode<T>> = [];

	public function new() {}

	public function allocateNode():BVHNode<T> {
		var node = new BVHNode<T>();
		var index = this.nodes.length;
		node.index = index;
		this.nodes.push(node);
		return node;
	}

	public function update() {
		var invalidNodes = [];
		this.traverse(node -> {
			if (node.isLeaf) {
				var entity = node.object;
				var tightAABB = entity.boundingBox;

				if (node.bounds.containsBounds(tightAABB)) {
					return;
				}

				invalidNodes.push(node);
			}
		});
		for (node in invalidNodes) {
			this.remove(node);
			this.add(node.object);
		}
	}

	public function add(entity:T) {
		// Enlarged AABB
		var aabb = entity.boundingBox;

		var newNode = allocateNode();
		newNode.bounds = aabb;
		newNode.object = entity;
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
		var q = [{p1: this.root.index, p2: 0.0}];

		while (q.length != 0) {
			var front = q.shift();
			var current = nodes[front.p1];
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
					if (current.child1 != -1)
						q.push({p1: current.child1, p2: inheritedCost});
					if (current.child2 != -1)
						q.push({p1: current.child2, p2: inheritedCost});
				}
			}
		}

		// Create a new parent
		var oldParent = bestSibling.parent != -1 ? nodes[bestSibling.parent] : null;
		var newParent = allocateNode();
		newParent.parent = oldParent != null ? oldParent.index : -1;
		newParent.bounds = bestSibling.bounds.clone();
		newParent.bounds.add(aabb);
		newParent.isLeaf = false;

		if (oldParent != null) {
			if (oldParent.child1 == bestSibling.index) {
				oldParent.child1 = newParent.index;
			} else {
				oldParent.child2 = newParent.index;
			}

			newParent.child1 = bestSibling.index;
			newParent.child2 = newNode.index;
			bestSibling.parent = newParent.index;
			newNode.parent = newParent.index;
		} else {
			newParent.child1 = bestSibling.index;
			newParent.child2 = newNode.index;
			bestSibling.parent = newParent.index;
			newNode.parent = newParent.index;
			this.root = newParent;
		}

		// Walk back up the tree refitting ancestors' AABB and applying rotations
		var ancestor = newNode.parent != -1 ? nodes[newNode.parent] : null;

		while (ancestor != null) {
			var child1 = ancestor.child1;
			var child2 = ancestor.child2;

			ancestor.bounds = new Bounds();
			if (child1 != -1)
				ancestor.bounds.add(nodes[child1].bounds);
			if (child2 != -1)
				ancestor.bounds.add(nodes[child2].bounds);

			this.rotate(ancestor);

			ancestor = nodes[ancestor.parent];
		}

		return newNode;
	}

	function reset() {
		this.nodes = [];
		this.root = null;
	}

	// BFS tree traversal
	function traverse(callback:(node:BVHNode<T>) -> Void) {
		var q = [this.root.index];

		while (q.length != 0) {
			var current = q.shift();
			if (current == null) {
				break;
			}
			var currentnode = nodes[current];
			callback(currentnode);

			if (!currentnode.isLeaf) {
				if (currentnode.child1 != -1)
					q.push(currentnode.child1);
				if (currentnode.child2 != -1)
					q.push(currentnode.child2);
			}
		}
	}

	public function remove(node:BVHNode<T>) {
		var parent = node.parent != -1 ? nodes[node.parent] : null;

		if (parent != null) {
			var sibling = parent.child1 == node.index ? parent.child2 : parent.child1;
			var siblingnode = nodes[sibling];

			if (parent.parent != -1) {
				siblingnode.parent = parent.parent;
				if (nodes[parent.parent].child1 == parent.index) {
					nodes[parent.parent].child1 = sibling;
				} else {
					nodes[parent.parent].child2 = sibling;
				}
			} else {
				this.root = siblingnode;
				siblingnode.parent = -1;
			}

			var ancestor = siblingnode.parent;
			while (ancestor != -1) {
				var ancestornode = nodes[ancestor];
				var child1 = nodes[ancestornode.child1];
				var child2 = nodes[ancestornode.child2];

				ancestornode.bounds = child1.bounds.clone();
				ancestornode.bounds.add(child2.bounds);
				ancestor = ancestornode.parent;
			}
		} else {
			if (this.root == node) {
				this.root = null;
			}
		}
	}

	function rotate(node:BVHNode<T>) {
		if (node.parent == -1) {
			return;
		}
		var parent = nodes[node.parent];
		var sibling = nodes[parent.child1 == node.index ? parent.child2 : parent.child1];
		var costDiffs = [];
		var nodeArea = node.bounds.xSize * node.bounds.ySize + node.bounds.zSize * node.bounds.ySize + node.bounds.xSize * node.bounds.zSize;

		var ch1 = sibling.bounds.clone();
		ch1.add(nodes[node.child1].bounds);
		costDiffs.push(ch1.xSize * ch1.ySize + ch1.zSize * ch1.ySize + ch1.xSize * ch1.zSize - nodeArea);
		var ch2 = sibling.bounds.clone();
		ch2.add(nodes[node.child2].bounds);
		costDiffs.push(ch2.xSize * ch2.ySize + ch2.zSize * ch2.ySize + ch2.xSize * ch2.zSize - nodeArea);

		if (!sibling.isLeaf) {
			var siblingArea = sibling.bounds.xSize * sibling.bounds.ySize + sibling.bounds.zSize * sibling.bounds.ySize
				+ sibling.bounds.xSize * sibling.bounds.zSize;
			if (sibling.child1 != -1) {
				var ch3 = node.bounds.clone();
				ch3.add(nodes[sibling.child1].bounds);
				costDiffs.push(ch3.xSize * ch3.ySize + ch3.zSize * ch3.ySize + ch3.xSize * ch3.zSize - siblingArea);
			}
			if (sibling.child2 != -1) {
				var ch4 = node.bounds.clone();
				ch4.add(nodes[sibling.child2].bounds);
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
					if (parent.child1 == sibling.index) {
						parent.child1 = node.child2;
					} else {
						parent.child2 = node.child2;
					}

					if (node.child2 != -1) {
						nodes[node.child2].parent = parent.index;
					}

					node.child2 = sibling.index;
					sibling.parent = node.index;
					node.bounds = sibling.bounds.clone();
					if (node.child1 != -1) {
						node.bounds.add(nodes[node.child1].bounds);
					}
				case 1:
					if (parent.child1 == sibling.index) {
						parent.child1 = node.child1;
					} else {
						parent.child2 = node.child1;
					}
					if (node.child1 != -1) {
						nodes[node.child1].parent = parent.index;
					}
					node.child1 = sibling.index;
					sibling.parent = node.index;
					node.bounds = sibling.bounds.clone();
					if (node.child2 != -1) {
						node.bounds.add(nodes[node.child2].bounds);
					}
				case 2:
					if (parent.child1 == node.index) {
						parent.child1 = sibling.child2;
					} else {
						parent.child2 = sibling.child2;
					}
					if (sibling.child2 != -1) {
						nodes[sibling.child2].parent = parent.index;
					}
					sibling.child2 = node.index;
					node.parent = sibling.index;
					sibling.bounds = node.bounds.clone();
					if (sibling.child2 != -1) {
						sibling.bounds.add(nodes[sibling.child2].bounds);
					}

				case 3:
					if (parent.child1 == node.index) {
						parent.child1 = sibling.child1;
					} else {
						parent.child2 = sibling.child1;
					}
					if (sibling.child1 != -1) {
						nodes[sibling.child1].parent = parent.index;
					}
					sibling.child1 = node.index;
					node.parent = sibling.index;
					sibling.bounds = node.bounds.clone();
					if (sibling.child1 != -1) {
						sibling.bounds.add(nodes[sibling.child1].bounds);
					}
			}
		}
	}

	public function boundingSearch(searchbox:Bounds) {
		var res = [];
		if (this.root == null)
			return res;

		var q = [this.root.index];
		var qptr = 0;

		while (qptr != q.length) {
			var current = q[qptr++];
			var currentnode = this.nodes[current];

			if (currentnode.bounds.containsBounds(searchbox) || currentnode.bounds.collide(searchbox)) {
				if (currentnode.isLeaf) {
					res.push(currentnode.object);
				} else {
					if (currentnode.child1 != -1)
						q.push(currentnode.child1);
					if (currentnode.child2 != -1)
						q.push(currentnode.child2);
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
		var q = [this.root.index];
		var qptr = 0;
		while (qptr != q.length) {
			var current = q[qptr++];
			var currentnode = this.nodes[current];
			if (ray.collide(currentnode.bounds)) {
				if (currentnode.isLeaf) {
					res = res.concat(currentnode.object.rayCast(origin, direction));
				} else {
					if (currentnode.child1 != -1)
						q.push(currentnode.child1);
					if (currentnode.child2 != -1)
						q.push(currentnode.child2);
				}
			}
		}
		return res;
	}
}
