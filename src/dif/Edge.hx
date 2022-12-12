package dif;

import dif.io.BytesWriter;
import dif.io.BytesReader;
import haxe.Int32;

@:expose
class Edge {
	public var pointIndex0:Int32;
	public var pointIndex1:Int32;
	public var surfaceIndex0:Int32;
	public var surfaceIndex1:Int32;
	public var farPoint0:Int32;
	public var farPoint1:Int32;

	public function new(pointIndex0, pointIndex1, surfaceIndex0, surfaceIndex1) {
		this.pointIndex0 = pointIndex0;
		this.pointIndex1 = pointIndex1;
		this.surfaceIndex0 = surfaceIndex0;
		this.surfaceIndex1 = surfaceIndex1;
	}

	public static function read(io:BytesReader, version:Version) {
		return new Edge(io.readInt32(), io.readInt32(), io.readInt32(), io.readInt32());
	}

	public function write(io:BytesWriter, version:Version) {
		io.writeInt32(this.pointIndex0);
		io.writeInt32(this.pointIndex1);
		io.writeInt32(this.surfaceIndex0);
		io.writeInt32(this.surfaceIndex1);
	}
}
