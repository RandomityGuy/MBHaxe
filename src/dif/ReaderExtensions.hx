package dif;

import dif.io.BytesReader;
import haxe.ds.StringMap;

class ReaderExtensions {
	public static function readDictionary(io:BytesReader) {
		var len = io.readInt32();
		var dict = new StringMap<String>();

		for (i in 0...len) {
			var name = io.readStr();
			var value = io.readStr();
			dict.set(name, value);
		}

		return dict;
	}

	public static function readArray<V>(io:BytesReader, readMethod:BytesReader->V):Array<V> {
		var len = io.readInt32();
		var arr = new Array<V>();

		for (i in 0...len) {
			arr.push(readMethod(io));
		}

		return arr;
	}

	public static function readArrayAs<V>(io:BytesReader, test:(Bool, Int) -> Bool, failMethod:BytesReader->V, passMethod:BytesReader->V) {
		var length = io.readInt32();
		var signed = false;
		var param = 0;

		if ((length & 0x80000000) == 0x80000000) {
			length ^= 0x80000000;
			signed = true;
			param = io.readByte();
		}

		var array = new Array<V>();
		for (i in 0...length) {
			if (test(signed, param)) {
				array.push(passMethod(io));
			} else {
				array.push(failMethod(io));
			}
		}

		return array;
	}

	public static function readArrayFlags<V>(io:BytesReader, readMethod:BytesReader->V) {
		var length = io.readInt32();
		var flags = io.readInt32();
		var array = new Array<V>();
		for (i in 0...length) {
			array.push(readMethod(io));
		}
		return array;
	};

	public static function readPNG(io:BytesReader) {
		var footer = [0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82];

		// I can't parse these, so I just read em all
		var data = [];
		while (true) {
			data.push(io.readByte());

			if (data.length >= 8) {
				var match = true;
				for (i in 0...8) {
					if (data[i + (data.length - 8)] != footer[i]) {
						match = false;
						break;
					}
				}
				if (match)
					break;
			}
		}

		return data;
	};

	public static function readColorF(io:BytesReader) {
		return [io.readByte(), io.readByte(), io.readByte(), io.readByte()];
	}
}
