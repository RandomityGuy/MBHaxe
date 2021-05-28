package dif;

import dif.io.BytesWriter;
import dif.io.BytesReader;

@:expose
class WindingIndex {
	public var windingStart:Int;
	public var windingCount:Int;

	public function new(windingStart, windingCount) {
		this.windingStart = windingStart;
		this.windingCount = windingCount;
	}

	public static function read(io:BytesReader) {
		return new WindingIndex(io.readInt32(), io.readInt32());
	}

	public function write(io:BytesWriter) {
		io.writeInt32(this.windingStart);
		io.writeInt32(this.windingCount);
	}
}
