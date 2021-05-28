package octree;

class PriorityQueue<T> {
	var first:PriorityQueueNode<T>;

	public var count:Int;

	public function new() {
		count = 0;
		first = null;
	}

	public function enqueue(val:T, priority:Float) {
		var node = new PriorityQueueNode<T>(val, priority);
		if (this.first == null) {
			this.first = node;
		} else {
			if (this.first.priority >= priority) {
				node.next = this.first;
				this.first.prev = node;
				this.first = node;
			} else {
				var n = this.first;
				var end = false;
				while (n.priority < node.priority) {
					if (n.next == null) {
						end = true;
						break;
					}
					n = n.next;
				}
				if (!end) {
					if (n.prev != null) {
						n.prev.next = node;
						node.prev = n.prev;
					}
					n.prev = node;
					node.next = n;
				} else {
					n.next = node;
					node.prev = n;
				}
			}
		}

		count++;
	}

	public function dequeue() {
		var ret = this.first;
		this.first = this.first.next;
		if (this.first != null)
			this.first.prev = null;
		count--;
		return ret.value;
	}
}
