package collision;

import h3d.Vector;
import h3d.col.Bounds;

interface IBVHObject {
	var boundingBox:Bounds;
	var key:Int;
	function rayCast(rayOrigin:Vector, rayDirection:Vector, results:Array<octree.IOctreeObject.RayIntersectionData>):Void;
}

@:generic
@:publicFields
class BVHNode<T:IBVHObject> {
	var index:Int;
	var parent:Int = -1;
	var child1:Int = -1;
	var child2:Int = -1;
	var isLeaf:Bool;
	var object:T;
	var xMin:Float = 0;
	var yMin:Float = 0;
	var zMin:Float = 0;
	var xMax:Float = 0;
	var yMax:Float = 0;
	var zMax:Float = 0;

	public function new() {}

	public inline function containsBounds(b:Bounds) {
		return xMin <= b.xMin && yMin <= b.yMin && zMin <= b.zMin && xMax >= b.xMax && yMax >= b.yMax && zMax >= b.zMax;
	}

	public inline function setBounds(b:Bounds) {
		xMin = b.xMin;
		yMin = b.yMin;
		zMin = b.zMin;
		xMax = b.xMax;
		yMax = b.yMax;
		zMax = b.zMax;
	}

	public inline function setBoundsFromNode(b:BVHNode<T>) {
		xMin = b.xMin;
		yMin = b.yMin;
		zMin = b.zMin;
		xMax = b.xMax;
		yMax = b.yMax;
		zMax = b.zMax;
	}

	public inline function getBounds() {
		return Bounds.fromValues(xMin, yMin, zMin, xMax - xMin, yMax - yMin, zMax - zMin);
	}

	public inline function add(b:Bounds) {
		if (b.xMin < xMin)
			xMin = b.xMin;
		if (b.xMax > xMax)
			xMax = b.xMax;
		if (b.yMin < yMin)
			yMin = b.yMin;
		if (b.yMax > yMax)
			yMax = b.yMax;
		if (b.zMin < zMin)
			zMin = b.zMin;
		if (b.zMax > zMax)
			zMax = b.zMax;
	}

	public inline function addNodeBounds(b:BVHNode<T>) {
		if (b.xMin < xMin)
			xMin = b.xMin;
		if (b.xMax > xMax)
			xMax = b.xMax;
		if (b.yMin < yMin)
			yMin = b.yMin;
		if (b.yMax > yMax)
			yMax = b.yMax;
		if (b.zMin < zMin)
			zMin = b.zMin;
		if (b.zMax > zMax)
			zMax = b.zMax;
	}

	public inline function collide(b:Bounds) {
		return !(xMin > b.xMax || yMin > b.yMax || zMin > b.zMax || xMax < b.xMin || yMax < b.yMin || zMax < b.zMin);
	}

	public inline function getExpansionCost(b:BVHNode<T>) {
		var xm = xMin;
		var ym = yMin;
		var zm = zMin;
		var xp = xMax;
		var yp = yMax;
		var zp = zMax;
		if (b.xMin < xm)
			xm = b.xMin;
		if (b.xMax > xp)
			xp = b.xMax;
		if (b.yMin < ym)
			ym = b.yMin;
		if (b.yMax > yp)
			yp = b.yMax;
		if (b.zMin < zm)
			zm = b.zMin;
		if (b.zMax > zp)
			zp = b.zMax;
		var xs = xp - xm;
		var ys = yp - ym;
		var zs = zp - zm;
		return xs * ys + ys * zs + xs * zs;
	}

	public inline function collideRay(r:h3d.col.Ray):Bool {
		var dx = 1 / r.lx;
		var dy = 1 / r.ly;
		var dz = 1 / r.lz;
		var t1 = (xMin - r.px) * dx;
		var t2 = (xMax - r.px) * dx;
		var t3 = (yMin - r.py) * dy;
		var t4 = (yMax - r.py) * dy;
		var t5 = (zMin - r.pz) * dz;
		var t6 = (zMax - r.pz) * dz;
		var tmin = Math.max(Math.max(Math.min(t1, t2), Math.min(t3, t4)), Math.min(t5, t6));
		var tmax = Math.min(Math.min(Math.max(t1, t2), Math.max(t3, t4)), Math.max(t5, t6));
		if (tmax < 0) {
			// t = tmax;
			return false;
		} else if (tmin > tmax) {
			// t = tmax;
			return false;
		} else {
			// t = tmin;
			return true;
		}
	}
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

				if (node.containsBounds(entity.boundingBox)) {
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
		newNode.setBounds(aabb);
		newNode.object = entity;
		newNode.isLeaf = true;

		if (this.root == null) {
			this.root = newNode;
			return newNode;
		}

		// Find the best sibling for the new leaf
		var bestSibling = this.root;
		var bestCostBox = this.root.getBounds();
		bestCostBox.add(aabb);
		var bestCost = bestCostBox.xSize * bestCostBox.ySize + bestCostBox.xSize * bestCostBox.zSize + bestCostBox.ySize * bestCostBox.zSize;
		var q = [{p1: this.root.index, p2: 0.0}];

		while (q.length != 0) {
			var front = q.shift();
			var current = nodes[front.p1];
			var inheritedCost = front.p2;

			var combined = current.getBounds();
			combined.add(aabb);
			var directCost = combined.xSize * combined.ySize + combined.xSize * combined.zSize + combined.ySize * combined.zSize;

			var costForCurrent = directCost + inheritedCost;
			if (costForCurrent < bestCost) {
				bestCost = costForCurrent;
				bestSibling = current;
			}
			var xs = (current.xMax - current.xMin);
			var ys = (current.yMax - current.yMin);
			var zs = (current.zMax - current.zMin);

			inheritedCost += directCost - (xs * ys + xs * zs + ys * zs);

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
		newParent.setBoundsFromNode(bestSibling);
		newParent.add(aabb);
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

			if (child1 != -1)
				ancestor.addNodeBounds(nodes[child1]);
			if (child2 != -1)
				ancestor.addNodeBounds(nodes[child2]);

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

				ancestornode.setBoundsFromNode(child1);
				ancestornode.addNodeBounds(child2);
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
		var nxs = node.xMax - node.xMin;
		var nys = node.yMax - node.yMin;
		var nzs = node.zMax - node.zMin;
		var nodeArea = nxs * nys + nzs * nys + nxs * nzs;

		costDiffs.push(sibling.getExpansionCost(nodes[node.child1]) - nodeArea);
		costDiffs.push(sibling.getExpansionCost(nodes[node.child2]) - nodeArea);

		if (!sibling.isLeaf) {
			var sxs = sibling.xMax - sibling.xMin;
			var sys = sibling.yMax - sibling.yMin;
			var szs = sibling.zMax - sibling.zMin;
			var siblingArea = sxs * sys + sys * szs + sxs * szs;
			if (sibling.child1 != -1) {
				costDiffs.push(node.getExpansionCost(nodes[sibling.child1]) - siblingArea);
			}
			if (sibling.child2 != -1) {
				costDiffs.push(node.getExpansionCost(nodes[sibling.child2]) - siblingArea);
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
					node.setBoundsFromNode(sibling);
					if (node.child1 != -1) {
						node.addNodeBounds(nodes[node.child1]);
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
					node.setBoundsFromNode(sibling);
					if (node.child2 != -1) {
						node.addNodeBounds(nodes[node.child2]);
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
					sibling.setBoundsFromNode(node);
					if (sibling.child2 != -1) {
						sibling.addNodeBounds(nodes[sibling.child2]);
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
					sibling.setBoundsFromNode(node);
					if (sibling.child1 != -1) {
						sibling.addNodeBounds(nodes[sibling.child1]);
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

			if (currentnode.containsBounds(searchbox) || currentnode.collide(searchbox)) {
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
			if (currentnode.collideRay(ray)) {
				if (currentnode.isLeaf) {
					currentnode.object.rayCast(origin, direction, res);
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
