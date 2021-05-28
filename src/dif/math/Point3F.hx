package dif.math;

import dif.io.BytesWriter;
import dif.io.BytesReader;

@:expose
class Point3F {
	public var x:Float;
	public var y:Float;
	public var z:Float;

	public function new(x = 0.0, y = 0.0, z = 0.0) {
		this.x = x;
		this.y = y;
		this.z = z;
	}

	@:op([]) public function get(dim:Int) {
		if (dim == 0)
			return this.x;
		if (dim == 1)
			return this.y;
		if (dim == 2)
			return this.z;
		return -1;
	}

	public function set(dim:Int, value:Float) {
		if (dim == 0)
			this.x = value;
		if (dim == 1)
			this.y = value;
		if (dim == 2)
			this.z = value;
	}

	@:op(A + B) public function add(rhs:Point3F) {
		return new Point3F(this.x + rhs.x, this.y + rhs.y, this.z + rhs.z);
	}

	@:op(A - B) public function sub(rhs:Point3F) {
		return new Point3F(this.x - rhs.x, this.y - rhs.y, this.z - rhs.z);
	}

	@:op(A * B) public function scalar(rhs:Float) {
		return new Point3F(this.x * rhs, this.y * rhs, this.z * rhs);
	}

	@:op(A / B) public function scalarDiv(rhs:Float) {
		return new Point3F(this.x / rhs, this.y / rhs, this.z / rhs);
	}

	public function dot(rhs:Point3F) {
		return this.x * rhs.x + this.y * rhs.y + this.z * rhs.z;
	}

	public function cross(rhs:Point3F) {
		return new Point3F(this.y * rhs.z - this.z * rhs.y, this.z * rhs.x - this.x * rhs.z, this.x * rhs.y - this.y * rhs.x);
	}

	public function length() {
		return Math.sqrt(this.x * this.x + this.y * this.y + this.z * this.z);
	}

	public function lengthSq() {
		return this.x * this.x + this.y * this.y + this.z * this.z;
	}

	public function normalized() {
		return this.length() != 0 ? this.scalarDiv(this.length()) : this;
	}

	public function equal(other:Point3F) {
		return this.x == other.x && this.y == other.y && this.z == other.z;
	}

	public static function read(io:BytesReader) {
		var ret = new Point3F();
		ret.x = io.readFloat();
		ret.y = io.readFloat();
		ret.z = io.readFloat();
		return ret;
	}

	public function write(io:BytesWriter) {
		io.writeFloat(this.x);
		io.writeFloat(this.y);
		io.writeFloat(this.z);
	}

	public function copy() {
		return new Point3F(this.x, this.y, this.z);
	}
}
