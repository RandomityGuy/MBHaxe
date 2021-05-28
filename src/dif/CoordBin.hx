package dif;

import haxe.Int32;
import dif.io.BytesWriter;
import dif.io.BytesReader;

@:expose
class CoordBin {
	public var binStart:Int32;
	public var binCount:Int32;

	public function new() {
		this.binStart = 0;
		this.binCount = 0;
	}

	public static function read(io:BytesReader) {
		var ret = new CoordBin();
		ret.binStart = io.readInt32();
		ret.binCount = io.readInt32();
		return ret;
	}

	public function write(io:BytesWriter) {
		io.writeInt32(this.binStart);
		io.writeInt32(this.binCount);
	}
}
