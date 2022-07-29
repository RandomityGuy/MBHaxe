package octree;

class PriorityQueue<T> {
	var queue:Array<PriorityQueueNode<T>>;

	public var count:Int;

	public function new() {
		count = 0;
		queue = [];
	}

	public function enqueue(val:T, priority:Float) {
		var node = new PriorityQueueNode<T>(val, priority);
		if (this.queue == null) {
			this.queue = [node];
		} else {
			if (this.queue[0].priority >= priority) {
				this.queue.insert(0, node);
			} else {
				var insertIndex = 0;
				var end = false;
				while (insertIndex < this.queue.length) {
					if (this.queue[insertIndex].priority > node.priority) {
						break;
					}
					insertIndex++;
				}
				this.queue.insert(insertIndex, node);
			}
		}

		count++;
	}

	public function dequeue() {
		var ret = this.queue[0];
		this.queue.splice(0, 1);
		count--;
		return ret.value;
	}
}
