package collision;

class CollisionPool {
	static var pool:Array<CollisionInfo> = [];
	static var currentPtr = 0;

	public static function alloc() {
		if (pool.length <= currentPtr) {
			pool.push(new CollisionInfo());
		}
		return pool[currentPtr++];
	}

	public static function clear() {
		currentPtr = 0;
	}

	public static function freeMemory() {
		pool = [];
	}
}
