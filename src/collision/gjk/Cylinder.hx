package collision.gjk;

import h3d.Vector;

@:publicFields
class Cylinder implements GJKShape {
	var p1:Vector;
	var p2:Vector;
	var radius:Float;

	public function new() {}

	public function getCenter():Vector {
		return p1.add(p2).multiply(0.5);
	}

	public function support(dir:Vector) {
		var axis = p2.sub(p1);
		var v = axis.dot(dir) > 0 ? p2 : p1;
		var rejection = dir.sub(axis.multiply(dir.dot(axis) / (axis.dot(axis)))).normalized().multiply(radius);
		return v.add(rejection);
	}
}
