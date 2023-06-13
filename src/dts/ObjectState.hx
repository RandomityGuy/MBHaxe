package dts;

import dif.io.BytesReader;

@:publicFields
class ObjectState {
	var vis:Float;
	var frame:Int;
	var matFrame:Int;

	public function new() {}

	public static function read(reader:DtsAlloc) {
		var os = new ObjectState();
		os.vis = reader.readF32();
		os.frame = reader.readU32();
		os.matFrame = reader.readU32();
		return os;
	}
}
