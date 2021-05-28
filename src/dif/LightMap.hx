package dif;

import haxe.io.Bytes;
import dif.io.BytesWriter;
import dif.io.BytesReader;
import haxe.Int32;

using dif.ReaderExtensions;
using dif.WriterExtensions;

@:expose
class LightMap {
	public var lightmap:Array<Int>;
	public var lightdirmap:Array<Int>;
	public var keepLightMap:Int;

	public function new() {
		this.lightmap = new Array<Int>();
		this.lightdirmap = new Array<Int>();
		this.keepLightMap = 0;
	}

	public static function read(io:BytesReader, version:Version) {
		var ret = new LightMap();
		ret.lightmap = io.readPNG();

		if (version.interiorType != "mbg" && version.interiorType != "tge") {
			ret.lightdirmap = io.readPNG();
		}
		ret.keepLightMap = io.readByte();
		return ret;
	}

	public function writeLightMap(io:BytesWriter, version:Version) {
		io.writePNG(this.lightmap);
		if (version.interiorType != "mbg" && version.interiorType != "tge") {
			io.writePNG(this.lightdirmap);
		}
		io.writeByte(this.keepLightMap);
	}
}
