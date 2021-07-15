package collision.gjk;

import h3d.Vector;

@:publicFields
class Capsule implements GJKShape {
	var p1:Vector;
	var p2:Vector;
	var radius:Float;

	public function new() {}

	public function getCenter():Vector {
		return p1.add(p2).multiply(0.5);
	}

	public function support(dir:Vector) {
		var axis = p2.sub(p1);
		var dy = dir.dot(axis);

		return ((dy < 0) ? p1 : p2).add(dir.multiply(radius));
	}
}
