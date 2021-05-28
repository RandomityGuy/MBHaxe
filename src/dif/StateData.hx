package dif;

import haxe.Int32;
import dif.io.BytesWriter;
import dif.io.BytesReader;

@:expose
class StateData {
	public var surfaceIndex:Int32;
	public var mapIndex:Int32;
	public var lightStateIndex:Int32;

	public function new(surfaceIndex:Int32, mapIndex:Int32, lightStateIndex:Int32) {
		this.surfaceIndex = surfaceIndex;
		this.mapIndex = mapIndex;
		this.lightStateIndex = lightStateIndex;
	}

	public static function read(io:BytesReader) {
		return new StateData(io.readInt32(), io.readInt32(), io.readInt32());
	}

	public function write(io:BytesWriter) {
		io.writeInt32(this.surfaceIndex);
		io.writeInt32(this.mapIndex);
		io.writeInt32(this.lightStateIndex);
	}
}
