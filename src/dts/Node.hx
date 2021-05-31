package dts;

import dif.io.BytesReader;

class Node {
	var name:Int;
	var parent:Int;
	var firstObject:Int = -1;
	var firstChild:Int = -1;
	var nextSibling:Int = -1;

	public function new() {}

	public static function read(reader:DtsAlloc) {
		var node = new Node();
		node.name = reader.readU32();
		node.parent = reader.readU32();
		node.firstObject = reader.readU32();
		node.firstChild = reader.readU32();
		node.nextSibling = reader.readU32();
		return node;
	}
}
