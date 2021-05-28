package dif.io;

import haxe.io.Bytes;

class BytesReader {
	var bytes:Bytes;
	var position:Int;

	public function new(bytes:Bytes) {
		this.bytes = bytes;
		this.position = 0;
	}

	public function readInt32() {
		var b = bytes.getInt32(position);
		position += 4;
		return b;
	}

	public function readInt16() {
		var b = bytes.getUInt16(position);
		position += 2;
		return b;
	}

	public function readUInt16() {
		var b = bytes.getUInt16(position);
		position += 2;
		return b;
	}

	public function readByte() {
		var b = bytes.get(position);
		position += 1;
		return b;
	}

	public function readStr() {
		var len = this.readByte();
		var str = "";
		for (i in 0...len) {
			str += String.fromCharCode(this.readByte());
		}
		return str;
	}

	public function readFloat() {
		var b = bytes.getFloat(position);
		position += 4;
		return b;
	}

	public function tell() {
		return position;
	}

	public function seek(pos) {
		position = pos;
	}
}
