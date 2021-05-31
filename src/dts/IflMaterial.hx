package dts;

import dif.io.BytesReader;

class IflMaterial {
	var name:Int;
	var slot:Int;
	var firstFrame:Int;
	var time:Int;
	var numFrames:Int;

	public function new() {}

	public static function read(reader:DtsAlloc) {
		var ifl = new IflMaterial();
		ifl.name = reader.readU32();
		ifl.slot = reader.readU32();
		ifl.firstFrame = reader.readU32();
		ifl.time = reader.readU32();
		ifl.numFrames = reader.readU32();
		return ifl;
	}
}
