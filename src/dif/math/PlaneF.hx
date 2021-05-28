package dif.math;

import dif.io.BytesWriter;
import dif.io.BytesReader;

@:expose
class PlaneF {
	public var x:Float;
	public var y:Float;
	public var z:Float;
	public var d:Float;

	public function new(x = 0.0, y = 0.0, z = 0.0, d = 0.0) {
		this.x = x;
		this.y = y;
		this.z = z;
		this.d = d;
	}

	public function distance(p:Point3F) {
		return this.x * p.x + this.y * p.y + this.z * p.z + this.d;
	}

	public function project(p:Point3F) {
		var d = distance(p);
		return new Point3F(p.x - d * this.x, p.y - d * this.y, p.z - d * this.z);
	}

	public function getNormal() {
		return new Point3F(this.x, this.y, this.z);
	}

	public static function ThreePoints(a:Point3F, b:Point3F, c:Point3F) {
		var v1 = a.sub(b);
		var v2 = c.sub(b);
		var res = v1.cross(v2);

		var ret = new PlaneF();

		var normal = res.normalized();
		ret.x = normal.x;
		ret.y = normal.y;
		ret.z = normal.z;
		ret.d = -b.dot(normal);
		return ret;
	}

	public static function NormalD(normal:Point3F, d:Float) {
		var ret = new PlaneF();

		ret.x = normal.x;
		ret.y = normal.y;
		ret.z = normal.z;
		ret.d = d;
		return ret;
	}

	public static function PointNormal(pt:Point3F, n:Point3F) {
		var ret = new PlaneF();

		var normal = n.normalized();
		ret.x = normal.x;
		ret.y = normal.y;
		ret.z = normal.z;
		ret.d = -pt.dot(normal);
		return ret;
	}

	public static function read(io:BytesReader) {
		var ret = new PlaneF();
		ret.x = io.readFloat();
		ret.y = io.readFloat();
		ret.z = io.readFloat();
		ret.d = io.readFloat();
		return ret;
	}

	public function write(io:BytesWriter) {
		io.writeFloat(this.x);
		io.writeFloat(this.y);
		io.writeFloat(this.z);
		io.writeFloat(this.d);
	}
}
