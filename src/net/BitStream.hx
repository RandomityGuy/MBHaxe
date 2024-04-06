package net;

import haxe.io.FPHelper;
import haxe.io.BytesOutput;
import haxe.io.BytesInput;
import haxe.io.Bytes;

class InputBitStream {
	var data:Bytes;
	var position:Int;
	var shift:Int;

	public function new(data:Bytes) {
		this.data = data;
		this.position = 0;
		this.shift = 0;
	}

	function readBits(bits:Int = 8) {
		if (this.shift + bits >= 8) {
			var extra = (this.shift + bits) % 8;
			var remain = bits - extra;
			var first = data.get(position) >> shift;
			var result = first;
			this.position++;
			if (extra > 0) {
				var second = (data.get(position) & (0xFF >> (8 - extra))) << remain;
				result |= second;
			}
			this.shift = extra;
			return result;
		} else {
			var result = (data.get(position) >> shift) & (0xFF >> (8 - bits));
			shift += bits;

			return result;
		}
	}

	public function readInt(bits:Int = 32) {
		var value = 0;
		var shift = 0;
		while (bits > 0) {
			value |= readBits(bits < 8 ? bits : 8) << shift;
			shift += 8;
			bits -= 8;
		}
		return value;
	}

	public function readFlag() {
		return readInt(1) != 0;
	}

	public function readByte() {
		return readInt(8);
	}

	public function readUInt16() {
		return readInt(16);
	}

	public function readInt32() {
		return readInt(32);
	}

	public function readFloat() {
		return FPHelper.i32ToFloat(readInt32());
	}

	public function readString() {
		var length = readByte();
		var str = "";
		for (i in 0...length) {
			str += String.fromCharCode(readByte());
		}
		return str;
	}
}

class OutputBitStream {
	var data:BytesOutput;
	var position:Int;
	var shift:Int;
	var lastByte:Int;

	public function new(data:BytesOutput = null) {
		this.data = data;
		if (this.data == null)
			this.data = new BytesOutput();
		this.position = 0;
		this.shift = 0;
		this.lastByte = 0;
	}

	function writeBits(value:Int, bits:Int) {
		value = value & (0xFF >> (8 - bits));
		if (this.shift + bits >= 8) {
			var extra = (shift + bits) % 8;
			var remain = bits - extra;

			var first = value & (0xFF >> (8 - remain));
			lastByte |= first << shift;

			var second = (value >> remain) & (0xFF >> (8 - extra));
			this.data.writeByte(this.lastByte);
			this.lastByte = second;
			this.shift = extra;
		} else {
			lastByte |= (value << this.shift) & (0xFF >> (8 - bits - this.shift));
			this.shift += bits;
		}
	}

	public function writeInt(value:Int, bits:Int = 32) {
		while (bits > 0) {
			this.writeBits(value & 0xFF, bits < 8 ? bits : 8);
			value >>= 8;
			bits -= 8;
		}
	}

	public function writeFlag(value:Bool) {
		writeInt(value ? 1 : 0, 1);
	}

	public function writeByte(value:Int) {
		writeInt(value, 8);
	}

	public function writeUInt16(value:Int) {
		writeInt(value, 16);
	}

	public function writeInt32(value:Int) {
		writeInt(value, 32);
	}

	public function getBytes() {
		this.data.writeByte(this.lastByte);
		return this.data.getBytes();
	}

	public function writeFloat(value:Float) {
		writeInt(FPHelper.floatToI32(value), 32);
	}

	public function writeString(value:String) {
		writeByte(value.length);
		for (i in 0...value.length) {
			writeByte(StringTools.fastCodeAt(value, i));
		}
	}
}
