package octree;

class PriorityQueueNode<T> {
	public var value:T;
	public var priority:Float;
	public var next:PriorityQueueNode<T>;
	public var prev:PriorityQueueNode<T>;

	public function new(value:T, priority:Float) {
		this.value = value;
		this.priority = priority;
	}
}
