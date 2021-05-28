package dif;

import dif.io.BytesWriter;
import dif.io.BytesReader;

@:expose
class NullSurface {
	public var windingStart:Int;
	public var planeIndex:Int;
	public var surfaceFlags:Int;
	public var windingCount:Int;

	public function new() {
		this.windingStart = 0;
		this.planeIndex = 0;
		this.surfaceFlags = 0;
		this.windingCount = 0;
	}

	public static function read(io:BytesReader, version:Version) {
		var ret = new NullSurface();
		ret.windingStart = io.readInt32();
		ret.planeIndex = io.readUInt16();
		ret.surfaceFlags = io.readByte();
		if (version.interiorVersion >= 13) {
			ret.windingCount = io.readInt32();
		} else {
			ret.windingCount = io.readByte();
		}
		return ret;
	}

	public function write(io:BytesWriter, version:Version) {
		io.writeInt32(this.windingStart);
		io.writeUInt16(this.planeIndex);
		io.writeByte(this.surfaceFlags);
		if (version.interiorVersion >= 13) {
			io.writeInt32(this.windingCount);
		} else {
			io.writeByte(this.windingCount);
		}
	}
}
