package dts;

import dif.io.BytesReader;

@:publicFields
class Primitive {
	var firstElement:Int;
	var numElements:Int;
	var matIndex:Int;

	public function new() {}

	public static function read(reader:DtsAlloc) {
		var p = new Primitive();
		p.firstElement = reader.readU16();
		p.numElements = reader.readU16();
		p.matIndex = (reader.readU32() & 0x00ffffff);
		return p;
	}
}
