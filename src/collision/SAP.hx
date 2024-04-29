package collision;

@:structInit
@:publicFields
class SAPProxy {
	var object:CollisionEntity;
	var flags:Int;
	var intersections:Array<CollisionEntity>;
	var positions:Array<Int>;
}

class SAP {
	var dimXEdges:Array<Float> = [];
	var dimXEdgeLefts:Array<Bool> = [];
	var dimXEdgeOwner:Array<Int> = [];
	var dimYEdges:Array<Float> = [];
	var dimYEdgeLefts:Array<Bool> = [];
	var dimYEdgeOwner:Array<Int> = [];
	var dimZEdges:Array<Float> = [];
	var dimZEdgeLefts:Array<Bool> = [];
	var dimZEdgeOwner:Array<Int> = [];

	var objects:Array<SAPProxy> = [];
	var objToProxy:Map<CollisionEntity, SAPProxy> = [];
	var needsSort = true;

	public function new() {}

	public function addEntity(obj:CollisionEntity) {
		needsSort = true;
		var edgeLen = dimXEdges.length;
		var proxy:SAPProxy = {
			object: obj,
			intersections: [],
			flags: 0,
			positions: [edgeLen, edgeLen + 1, edgeLen, edgeLen + 1, edgeLen, edgeLen + 1]
		};
		var idx = objects.length;
		objects.push(proxy);
		dimXEdges.push(obj.boundingBox.xMin);
		dimXEdges.push(obj.boundingBox.xMax);
		dimYEdges.push(obj.boundingBox.yMin);
		dimYEdges.push(obj.boundingBox.yMax);
		dimZEdges.push(obj.boundingBox.zMin);
		dimZEdges.push(obj.boundingBox.zMax);
		dimXEdgeLefts.push(true);
		dimXEdgeLefts.push(false);
		dimYEdgeLefts.push(true);
		dimYEdgeLefts.push(false);
		dimZEdgeLefts.push(true);
		dimZEdgeLefts.push(false);
		dimXEdgeOwner.push(idx);
		dimXEdgeOwner.push(idx);
		dimYEdgeOwner.push(idx);
		dimYEdgeOwner.push(idx);
		dimZEdgeOwner.push(idx);
		dimZEdgeOwner.push(idx);

		objToProxy.set(obj, proxy);
	}

	public function update(obj:CollisionEntity) {
		if (!objToProxy.exists(obj))
			addEntity(obj);
		needsSort = true;
		var proxy = objToProxy.get(obj);
		proxy.object = obj;
		proxy.intersections = [];
		proxy.flags = 0;
		dimXEdges[proxy.positions[0]] = obj.boundingBox.xMin;
		dimXEdges[proxy.positions[1]] = obj.boundingBox.xMax;
		dimYEdges[proxy.positions[2]] = obj.boundingBox.yMin;
		dimYEdges[proxy.positions[3]] = obj.boundingBox.yMax;
		dimZEdges[proxy.positions[4]] = obj.boundingBox.zMin;
		dimZEdges[proxy.positions[5]] = obj.boundingBox.zMax;
	}

	public function sort(dim:Int) {
		var edges;
		var edgeLefts;
		var edgeOwner;
		if (dim == 0) {
			edges = dimXEdges;
			edgeLefts = this.dimXEdgeLefts;
			edgeOwner = this.dimXEdgeOwner;
		} else if (dim == 1) {
			edges = dimYEdges;
			edgeLefts = this.dimYEdgeLefts;
			edgeOwner = this.dimYEdgeOwner;
		} else {
			edges = dimZEdges;
			edgeLefts = this.dimZEdgeLefts;
			edgeOwner = this.dimZEdgeOwner;
		}

		for (i in 0...edges.length) {
			var j = i - 1;
			while (j >= 0) {
				if (edges[j] < edges[j + 1])
					break;

				// Swap

				var edge1Owner = objects[edgeOwner[j]];
				var edge2Owner = objects[edgeOwner[j + 1]];
				var edge1Left = edgeLefts[j];
				var edge2Left = edgeLefts[j + 1];

				edge1Owner.positions[2 * dim + (edge1Left ? 1 : 0)] = j + 1;
				edge2Owner.positions[2 * dim + (edge2Left ? 1 : 0)] = j;

				var tmp = edges[j];
				edges[j] = edges[j + 1];
				edges[j + 1] = tmp;

				var tmp2 = edgeLefts[j];
				edgeLefts[j] = edgeLefts[j + 1];
				edgeLefts[j + 1] = tmp2;

				var tmp3 = edgeOwner[j];
				edgeOwner[j] = edgeOwner[j + 1];
				edgeOwner[j + 1] = tmp3;

				// Sweep
				var edge1 = j;
				var edge2 = j + 1;
				if (edgeLefts[edge1] && !edgeLefts[edge2]) {
					var obj1 = edgeOwner[edge1];
					var obj2 = edgeOwner[edge2];
					objects[obj1].flags |= (1 << dim);
					objects[obj2].flags |= (1 << dim);

					if (objects[obj1].flags == 7 && objects[obj2].flags == 7) {
						objects[obj1].intersections.push(objects[obj2].object);
						objects[obj2].intersections.push(objects[obj1].object);
					}
				} else if (!edgeLefts[edge1] && edgeLefts[edge2]) {
					var obj1 = edgeOwner[edge2];
					var obj2 = edgeOwner[edge1];
					if (objects[obj1].flags == 7) {
						objects[obj1].intersections.remove(objects[obj2].object);
					}
					if (objects[obj2].flags == 7) {
						objects[obj2].intersections.remove(objects[obj1].object);
					}

					objects[obj1].flags &= ~(1 << dim);
					objects[obj2].flags &= ~(1 << dim);
				}

				j--;
			}
		}
	}

	public function recompute() {
		if (needsSort) {
			this.sort(0);
			this.sort(1);
			this.sort(2);
			needsSort = false;
		}
	}

	public function getIntersections(obj:CollisionEntity):Array<CollisionEntity> {
		return objToProxy[obj].intersections;
	}
}
