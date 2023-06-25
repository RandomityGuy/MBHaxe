package src;

@:publicFields
@:generic
class LRUCacheValue<V> {
	var value:V;
	var age:Int;

	public function new() {}
}

@:generic
class LRUCache<V> {
	var cacheMap:Map<String, LRUCacheValue<V>>;
	var size = 10;
	var curSize = 0;

	public function new(size:Int) {
		cacheMap = new Map<String, LRUCacheValue<V>>();
		this.size = size;
	}

	function tick() {
		for (k => v in cacheMap) {
			v.age >>= 1;
		}
	}

	public function get(k:String) {
		var cv = cacheMap.get(k);
		return (cv != null) ? cv.value : null;
	}

	public function exists(k:String) {
		return cacheMap.exists(k);
	}

	public function set(k:String, v:V) {
		var cv = cacheMap.get(k);
		if (cv != null) {
			cv.value = v;
			cv.age = 0xFFFF;
		} else {
			cv = new LRUCacheValue<V>();
			cv.value = v;
			cv.age = 0xFFFF;
			cacheMap[k] = cv;
			curSize += 1;
		}
		tick();
		if (curSize > size) {
			var minAge = 0xFFFF;
			var minAgeKey = null;
			for (k => v in cacheMap) {
				if (v.age < minAge) {
					minAge = v.age;
					minAgeKey = k;
				}
			}
			if (minAgeKey != null) {
				cacheMap.remove(minAgeKey);
				curSize -= 1;
			}
		}
	}
}
