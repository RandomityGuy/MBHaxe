package octreenarrowphase;

import polygonal.ds.PriorityQueue;
import dif.math.Box3F;
import dif.math.Point3F;

class Octree<T> {
	var root:OctreeNode<T>;

	public function new(pts:Array<OctreePoint<T>>, binPoints:Int = 8) {
		var pos = pts;

		var min = new Point3F();
		var max = new Point3F();

		// Generate the bounding box
		for (index => op in pos) {
			var p = op.point;
			if (p.x < min.x)
				min.x = p.x;
			if (p.y < min.y)
				min.y = p.y;
			if (p.z < min.z)
				min.z = p.z;

			if (p.x > max.x)
				max.x = p.x;
			if (p.y > max.y)
				max.y = p.y;
			if (p.z > max.z)
				max.z = p.z;
		}

		root = new OctreeNode();
		root.box = new Box3F(min.x, min.y, min.z, max.x, max.y, max.z);

		// We use the insert method because its much faster doing this way
		for (index => pt in pts)
			root.insert(pt.point, pt.value);
	}

	public function find(pt:Point3F)
		return root.find(pt);

	public function remove(pt:Point3F)
		return root.remove(pt);

	public function insert(pt:Point3F, value:T)
		return root.insert(pt, value);

	public function knn(point:Point3F, number:Int) {
		var queue = new PriorityQueue<IOctreeNode<T>>();
		root.priority = cast(-root.box.getClosestPoint(point).sub(point).lengthSq());
		queue.enqueue(root);

		var l = new Array<OctreePoint<T>>();

		while (l.length < number && queue.size > 0) {
			var node = queue.dequeue();

			switch (node.getNodeType()) {
				case 1:
					var leaf:OctreeNode<T> = cast node;
					for (index => pt in leaf.points) {
						pt.priority = cast(-pt.point.sub(point).lengthSq());
						queue.enqueue(pt);
					}

				case 0:
					var pt:OctreePoint<T> = cast node;
					l.push(pt);

				case 2:
					var n:OctreeNode<T> = cast node;
					for (subnode in n.nodes) {
						subnode.priority = cast(-subnode.box.getClosestPoint(point).sub(point).lengthSq());
						queue.enqueue(subnode);
					}
			}
		}

		return l;
	}
}
