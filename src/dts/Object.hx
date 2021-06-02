package dts;

import dif.io.BytesReader;

@:publicFields
class Object {
	var name:Int;
	var numMeshes:Int;
	var firstMesh:Int;
	var node:Int;
	var firstDecal:Int;
	var nextSibling:Int;

	public function new() {}

	public static function read(reader:DtsAlloc) {
		var obj = new Object();
		obj.name = reader.readU32();
		obj.numMeshes = reader.readU32();
		obj.firstMesh = reader.readU32();
		obj.node = reader.readU32();
		obj.nextSibling = reader.readU32();
		obj.firstDecal = reader.readU32();
		return obj;
	}
}
