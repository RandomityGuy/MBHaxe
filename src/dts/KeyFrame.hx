package dts;

import dif.io.BytesReader;

@:publicFields
class KeyFrame {
	var firstNodeState:Int;
	var firstObjectState:Int;
	var firstDecalState:Int;

	public function new() {}

	public static function read(reader:BytesReader) {
		var k = new KeyFrame();
		k.firstNodeState = reader.readInt32();
		k.firstObjectState = reader.readInt32();
		k.firstDecalState = reader.readInt32();
		return k;
	}
}
