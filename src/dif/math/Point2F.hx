package dif.math;

import dif.io.BytesWriter;
import dif.io.BytesReader;

@:expose
class Point2F {
	public var x:Float;
	public var y:Float;

	public function new(x, y) {
		this.x = x;
		this.y = y;
	}
}
