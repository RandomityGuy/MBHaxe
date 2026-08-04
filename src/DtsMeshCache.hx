package src;

import collision.CollisionSurface;
import src.Polygon;

@:publicFields
class DtsMeshCacheEntry {
	var polygons:Array<Polygon>; // length: graphNodes.length
	var polygonMaterials:Array<Array<Int>>;
	var surfaces:Array<{node:Int, surfaces:Array<CollisionSurface>}>;

	public function new() {}

	public function dispose() {
		for (poly in polygons) {
			if (poly != null)
				poly.dispose();
		}
	}
}

class DtsMeshCache {
	var cacheMap:Map<String, DtsMeshCacheEntry>;

	public function new() {
		cacheMap = [];
	}

	public inline function has(dtsPath:String) {
		return cacheMap.exists(dtsPath);
	}

	public inline function get(dtsPath:String) {
		return cacheMap.get(dtsPath);
	}

	public function createEntry(dtsPath:String) {
		var entry = new DtsMeshCacheEntry();
		cacheMap.set(dtsPath, entry);
		return entry;
	}

	public function dispose() {
		for (entryPath => entry in cacheMap) {
			entry.dispose();
		}
	}
}
