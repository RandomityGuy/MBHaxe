package dts;

import dif.io.BytesReader;

class Trigger {
	var state:Int;
	var position:Float;

	public function new() {}

	public static function read(reader:DtsAlloc) {
		var t = new Trigger();
		t.state = reader.readU32();
		t.position = reader.readU32();
		return t;
	}
}
