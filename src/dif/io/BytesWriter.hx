package dif.io;

import haxe.io.BytesData;
import haxe.Int32;
import haxe.io.BytesBuffer;
import haxe.io.Bytes;

class BytesWriter {
	var bytes:BytesBuffer;

	public function new() {
		this.bytes = new BytesBuffer();
	}

	public function writeInt32(int:Int) {
		this.bytes.addInt32(int);
	}

	public function writeUInt16(int:Int) {
		var h = int >> 8;
		var l = int & 0xFF;
		this.bytes.addByte(l);
		this.bytes.addByte(h);
	}

	public function writeInt16(int:Int) {
		var h = int >> 8;
		var l = int & 0xFF;
		this.bytes.addByte(l);
		this.bytes.addByte(h);
	}

	public function writeByte(int:Int) {
		this.bytes.addByte(int);
	}

	public function writeStr(str:String) {
		this.bytes.addByte(str.length);
		for (c in 0...str.length)
			this.bytes.addByte(str.charCodeAt(c));
	}

	public function writeFloat(f:Float) {
		this.bytes.addFloat(f);
	}

	public function getBuffer() {
		return bytes.getBytes();
	}
}
