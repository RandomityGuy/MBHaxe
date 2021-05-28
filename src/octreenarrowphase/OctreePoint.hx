package octreenarrowphase;

import dif.math.Point3F;

class OctreePoint<T> implements IOctreeNode<T> {
	public var point:Point3F;

	public var priority:Int;
	public var position:Int;

	public var value:T;

	public function new(point:Point3F, value:T) {
		this.point = point;
		this.value = value;
	}

	public function getNodeType() {
		return 0;
	}
}
