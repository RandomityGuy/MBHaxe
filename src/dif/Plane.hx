package dif;

import dif.io.BytesWriter;
import dif.io.BytesReader;

@:expose
class Plane {
	public var normalIndex:Int;
	public var planeDistance:Float;

	public function new(normalIndex, planeDistance) {
		this.normalIndex = normalIndex;
		this.planeDistance = planeDistance;
	}

	public static function read(io:BytesReader) {
		return new Plane(io.readInt16(), io.readFloat());
	}

	public function write(io:BytesWriter) {
		io.writeInt16(this.normalIndex);
		io.writeFloat(this.planeDistance);
	}
}
