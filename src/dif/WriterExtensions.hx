package dif;

import haxe.io.Bytes;
import haxe.ds.StringMap;
import dif.io.BytesWriter;
import dif.io.BytesReader;

class WriterExtensions {
	public static function writeDictionary(io:BytesWriter, dict:StringMap<String>) {
		var len = 0;
		for (key in dict.keys())
			len++;

		for (kvp in dict.keyValueIterator()) {
			io.writeStr(kvp.key);
			io.writeStr(kvp.value);
		}
	}

	public static function writeArray<V>(io:BytesWriter, arr:Array<V>, writeMethod:(BytesWriter, V) -> Void) {
		io.writeInt32(arr.length);
		for (i in 0...arr.length) {
			writeMethod(io, arr[i]);
		}

		return arr;
	}

	public static function writeArrayFlags<V>(io:BytesWriter, arr:Array<V>, flags:Int, writeMethod:(BytesWriter, V) -> Void) {
		io.writeInt32(arr.length);
		io.writeInt32(flags);
		for (i in 0...arr.length) {
			writeMethod(io, arr[i]);
		}
	};

	public static function writePNG(io:BytesWriter, arr:Array<Int>) {
		for (i in 0...arr.length) {
			io.writeByte(arr[i]);
		}
	};

	public static function writeColorF(io:BytesWriter, color:Array<Int>) {
		io.writeByte(color[0]);
		io.writeByte(color[1]);
		io.writeByte(color[2]);
		io.writeByte(color[3]);
	}
}
