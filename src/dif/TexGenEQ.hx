package dif;

import dif.io.BytesWriter;
import dif.io.BytesReader;
import dif.math.PlaneF;

@:expose
class TexGenEQ {
	public var planeX:PlaneF;
	public var planeY:PlaneF;

	public function new() {
		planeX = new PlaneF();
		planeY = new PlaneF();
	}

	public static function read(io:BytesReader) {
		var ret = new TexGenEQ();
		ret.planeX = PlaneF.read(io);
		ret.planeY = PlaneF.read(io);
		return ret;
	}

	public function write(io:BytesWriter) {
		this.planeX.write(io);
		this.planeY.write(io);
	}
}
