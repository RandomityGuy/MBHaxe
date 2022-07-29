package octree;

class PriorityQueueNode<T> {
	public var value:T;
	public var priority:Float;

	public function new(value:T, priority:Float) {
		this.value = value;
		this.priority = priority;
	}
}
