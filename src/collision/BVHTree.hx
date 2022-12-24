package collision;

import h3d.col.Bounds;

interface IBVHObject {
	var boundingBox:Bounds;
	function rayCast(rayOrigin:Vector, rayDirection:Vector):Array<octree.IOctreeObject.RayIntersectionData>;
}

@:publicFields
class BVHNode<T:IBVHObject> {
	var id:Int;
	var parent:BVHNode<T>;
	var child1:BVHNode<T>;
	var child2:BVHNode<T>;
	var isLeaf:Bool;
	var bounds:Bounds;
	var object:T;

	public function new(bounds:Bounds) {
		this.bounds = bounds.clone();
		surfaceArea = this.bounds.xSize * this.bounds.ySize + this.bounds.xSize * this.bounds.zSize + this.bounds.ySize * this.bounds.zSize;
	}

	class BVHTree<T:IBVHObject> {
		var nodeId:Int = 0;
		var root:BVHNode<T>;

		public function new() {}

		function update() {
			var invalidNodes = [];
			this.traverse(node -> {
				if (node.isLeaf) {
					var entity = node.object;
					var tightAABB = entity.boundingBox;

					if (node.bounds.containsBounds(tightAABB)) {
						return;
					}

					public function split() {
						// Splitting first time
						// Calculate the centroids of all objects
						var objs = objects.map(x -> {
							x.generateBoundingBox();
							return {obj: x, centroid: x.boundingBox.getCenter()};
						});
						for (node in invalidNodes) {
							this.remove(node);
							this.add(node.object);
						}

						public function add(entity:T) {
							// Enlarged AABB
							var aabb = entity.boundingBox;

							var newNode = new BVHNode();
							newNode.id = this.nodeId++;
							newNode.bounds = aabb;
							newNode.object = entity;
							newNode.isLeaf = true;

							if (this.root == null) {
								this.root = newNode;
								return newNode;
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

						function reset() {
							this.nodeId = 0;
							this.root = null;
						}

						// BFS tree traversal
						function traverse(callback:(node:BVHNode<T>) -> Void) {
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

						public function remove(node:BVHNode<T>) {
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
								}
								return intersects;
							} else {
								return [];
							}
						}

						function rotate(node:BVHNode<T>) {
							if (node.parent == null) {
								return;
							}
							var parent = node.parent;
							var sibling = parent.child1 == node ? parent.child2 : parent.child1;
							var costDiffs = [];
							var nodeArea = node.bounds.xSize * node.bounds.ySize + node.bounds.zSize * node.bounds.ySize
								+ node.bounds.xSize * node.bounds.zSize;

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
									var res = [];
									if (this.root == null)
										return res;

									var q = [this.root];

									while (q.length != 0) {
										var current = q.shift();

										if (current.bounds.containsBounds(searchbox) || current.bounds.collide(searchbox)) {
											if (current.isLeaf) {
												res.push(current.object);
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
												res = res.concat(current.object.rayCast(origin, direction));
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
