package collision;

@:structInit
@:publicFields
class SAPProxy {
	var object:CollisionEntity;
	var index:Int;
	var value:Float;
	var left:Bool;
}

@:structInit
@:publicFields
class SAPProxyHolder {
	var isec:Int;
	var xMinProxy:SAPProxy;
	var yMinProxy:SAPProxy;
	var zMinProxy:SAPProxy;
	var xMaxProxy:SAPProxy;
	var yMaxProxy:SAPProxy;
	var zMaxProxy:SAPProxy;
}

class SAP {
	var dimX:Array<SAPProxy> = [];
	var dimY:Array<SAPProxy> = [];
	var dimZ:Array<SAPProxy> = [];

	var objects:Array<CollisionEntity> = [];
	var flags:Array<Int> = [];
	var intersections:Array<Array<CollisionEntity>> = [];
	var objToProxy:Map<CollisionEntity, SAPProxyHolder> = [];
	var needsSort = true;
	var anyFlagSet = false;

	public function new() {}

	public function addEntity(obj:CollisionEntity) {
		var idx = objects.length;
		var xMinProxy:SAPProxy = {
			object: obj,
			left: false,
			value: obj.boundingBox.xMin,
			index: idx
		};
		dimX.push(xMinProxy);
		var xMaxProxy:SAPProxy = {
			object: obj,
			left: true,
			value: obj.boundingBox.xMax,
			index: idx
		};
		dimX.push(xMaxProxy);

		var yMinProxy:SAPProxy = {
			object: obj,
			left: false,
			value: obj.boundingBox.yMin,
			index: idx
		};
		dimY.push(yMinProxy);
		var yMaxProxy:SAPProxy = {
			object: obj,
			left: true,
			value: obj.boundingBox.yMax,
			index: idx
		};
		dimY.push(yMaxProxy);

		var zMinProxy:SAPProxy = {
			object: obj,
			left: false,
			value: obj.boundingBox.zMin,
			index: idx
		};
		dimZ.push(zMinProxy);
		var zMaxProxy:SAPProxy = {
			object: obj,
			left: true,
			value: obj.boundingBox.zMax,
			index: idx
		};
		dimZ.push(zMaxProxy);

		objects.push(obj);
		intersections.push([]);
		objToProxy.set(obj, {
			xMinProxy: xMinProxy,
			xMaxProxy: xMaxProxy,
			yMinProxy: yMinProxy,
			yMaxProxy: yMaxProxy,
			zMinProxy: zMinProxy,
			zMaxProxy: zMaxProxy,
			isec: idx
		});

		var oldFlags = flags;
		flags = [];
		var n = objects.length - 1;
		for (i in 0...Std.int((idx * idx + idx) / 2))
			flags.push(0);
		if (anyFlagSet) {
			for (o1 in 0...(objects.length - 1)) {
				for (o2 in (o1 + 1)...(objects.length - 2)) {
					// https://stackoverflow.com/questions/27086195/linear-index-upper-triangular-matrix
					var oldN = n - 1;
					var oldIndex = Std.int((oldN * (oldN - 1) / 2) - (oldN - o2) * ((oldN - o2) - 1) / 2 + o1 - o2 - 1);
					var newIndex = Std.int((n * (n - 1) / 2) - (n - o2) * ((n - o2) - 1) / 2 + o1 - o2 - 1);

					this.flags[newIndex] = oldFlags[oldIndex];
				}
			}
		}

		needsSort = true;
	}

	public function update(obj:CollisionEntity) {
		if (!objToProxy.exists(obj))
			addEntity(obj);

		var proxyHolder = objToProxy.get(obj);
		proxyHolder.xMinProxy.value = obj.boundingBox.xMin;
		proxyHolder.xMaxProxy.value = obj.boundingBox.xMax;
		proxyHolder.yMinProxy.value = obj.boundingBox.yMin;
		proxyHolder.yMaxProxy.value = obj.boundingBox.yMax;
		proxyHolder.zMinProxy.value = obj.boundingBox.zMin;
		proxyHolder.zMaxProxy.value = obj.boundingBox.zMax;

		needsSort = true;
	}

	public function sort(dim:Int) {
		var edges;
		if (dim == 0) {
			edges = dimX;
		} else if (dim == 1) {
			edges = dimY;
		} else {
			edges = dimZ;
		}

		for (i in 0...edges.length) {
			var j = i - 1;
			while (j >= 0) {
				if (edges[j].value < edges[j + 1].value)
					break;

				// Swap
				var tmp = edges[j];
				edges[j] = edges[j + 1];
				edges[j + 1] = tmp;

				// Sweep
				var edge1 = edges[j];
				var edge2 = edges[j + 1];

				var n = objects.length;
				var i1 = edge1.index;
				var i2 = edge2.index;
				var flagIndex = Std.int((n * (n - 1) / 2) - (n - i2) * ((n - i2) - 1) / 2 + i1 - i2 - 1);

				if (edge1.left && !edge2.left) {
					flags[flagIndex] |= (1 << dim);

					if (flags[flagIndex] == 7) {
						intersections[edge1.index].push(edge2.object);
						intersections[edge2.index].push(edge1.object);
					}
				} else if (!edge1.left && edge2.left) {
					if (flags[flagIndex] == 7) {
						intersections[edge1.index].remove(edge2.object);
						intersections[edge2.index].remove(edge1.object);
					}
					flags[flagIndex] &= ~(1 << dim);
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
		return intersections[objToProxy[obj].isec];
	}
}
