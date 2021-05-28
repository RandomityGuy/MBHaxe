package octreenarrowphase;

import dif.math.Box3F;
import dif.math.Point3F;

class OctreeNode<T> implements IOctreeNode<T> {
	public var nodes:Array<OctreeNode<T>>;

	public var priority:Int;
	public var position:Int;

	var isLeaf:Bool;

	public var points:Array<OctreePoint<T>>;

	var center:Point3F;

	public var box:Box3F;

	public function new() {
		this.isLeaf = true;
		this.points = new Array<OctreePoint<T>>();
	}

	public function getCount() {
		if (this.isLeaf) {
			return this.points.length;
		} else {
			var res = 0;
			for (index => value in nodes) {
				res += value.getCount();
			}
			return res;
		}
	}

	function getIsEmpty() {
		if (this.isLeaf)
			return this.getCount() == 0;
		else {
			for (index => value in nodes) {
				if (!value.getIsEmpty())
					return false;
			}
			return true;
		}
	}

	public function find(pt:Point3F) {
		if (this.isLeaf) {
			for (index => value in this.points) {
				if (value.point.equal(pt))
					return true;
			}
			return true;
		} else {
			var msk = 0;
			msk |= (pt.x - center.x) < 0 ? 1 : 0;
			msk |= (pt.y - center.y) < 0 ? 2 : 0;
			msk |= (pt.z - center.z) < 0 ? 4 : 0;

			return nodes[msk].find(pt);
		}
	}

	public function remove(pt:Point3F) {
		if (this.isLeaf) {
			var found = false;
			var idx = -1;
			for (index => value in this.points) {
				if (value.point.equal(pt)) {
					found = true;
					idx = index;
					break;
				}
			}
			if (found) {
				return this.points.remove(this.points[idx]);
			} else
				return false;
		} else {
			var msk = 0;
			msk |= (pt.x - center.x) < 0 ? 1 : 0;
			msk |= (pt.y - center.y) < 0 ? 2 : 0;
			msk |= (pt.z - center.z) < 0 ? 4 : 0;

			var ret = nodes[msk].remove(pt);
			this.merge();
			return ret;
		}
	}

	public function insert(pt:Point3F, value:T) {
		if (this.isLeaf) {
			this.points.push(new OctreePoint(pt, value));
			subdivide();
		} else {
			var msk = 0;
			msk |= (pt.x - center.x) < 0 ? 1 : 0;
			msk |= (pt.y - center.y) < 0 ? 2 : 0;
			msk |= (pt.z - center.z) < 0 ? 4 : 0;
			nodes[msk].insert(pt, value);
		}
	}

	function subdivide(binPoints:Int = 8) {
		var min = new Point3F(box.minX, box.minY, box.minZ);
		var max = new Point3F(box.maxX, box.maxY, box.maxZ);
		center = min.add(max).scalarDiv(2);

		if (points.length > binPoints) {
			isLeaf = false;

			var size = max.sub(min);

			nodes = new Array<OctreeNode<T>>();
			for (i in 0...8) {
				nodes.push(new OctreeNode<T>());
			}

			nodes[0].box = new Box3F(center.x, center.y, center.z, max.x, max.y, max.z);
			nodes[1].box = new Box3F(center.x - (size.x / 2), center.y, center.z, max.x - (size.x / 2), max.y, max.z);
			nodes[2].box = new Box3F(center.x, center.y - (size.y / 2), center.z, max.x, max.y - (size.y / 2), max.z);
			nodes[3].box = new Box3F(center.x - (size.x / 2), center.y - (size.y / 2), center.z, max.x - (size.x / 2), max.y - (size.y / 2), max.z);
			nodes[4].box = new Box3F(center.x, center.y, center.z - (size.z / 2), max.x, max.y, max.z - (size.z / 2));
			nodes[5].box = new Box3F(center.x - (size.x / 2), center.y, center.z - (size.z / 2), max.x - (size.x / 2), max.y, max.z - (size.z / 2));
			nodes[6].box = new Box3F(center.x, center.y - (size.y / 2), center.z - (size.z / 2), max.x, max.y - (size.y / 2), max.z - (size.z / 2));
			nodes[7].box = new Box3F(min.x, min.y, min.z, max.x, max.y, max.z);

			for (index => pt in points) {
				var msk = 0;
				msk |= (pt.point.x - center.x) < 0 ? 1 : 0;
				msk |= (pt.point.y - center.y) < 0 ? 2 : 0;
				msk |= (pt.point.z - center.z) < 0 ? 4 : 0;

				if (!nodes[msk].find(pt.point))
					nodes[msk].points.push(new OctreePoint(pt.point, pt.value));
			}

			points = null;

			for (index => value in nodes) {
				value.subdivide(binPoints);
			}
		} else {
			isLeaf = true;
		}
	}

	function merge() {
		if (this.isLeaf) {
			return;
		} else {
			if (this.getIsEmpty()) {
				this.isLeaf = true;
				this.nodes = null;
				this.points = new Array<OctreePoint<T>>();
			}
		}
	}

	public function getNodeType() {
		if (this.isLeaf)
			return 1;
		else
			return 2;
	}
}
