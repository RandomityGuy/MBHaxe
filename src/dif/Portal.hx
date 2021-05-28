package dif;

import dif.io.BytesWriter;
import dif.io.BytesReader;

@:expose
class Portal {
	public var planeIndex:Int;
	public var triFanCount:Int;
	public var triFanStart:Int;
	public var zoneFront:Int;
	public var zoneBack:Int;

	public function new(planeIndex, triFanCount, triFanStart, zoneFront, zoneBack) {
		this.planeIndex = planeIndex;
		this.triFanCount = triFanCount;
		this.triFanStart = triFanStart;
		this.zoneFront = zoneFront;
		this.zoneBack = zoneBack;
	}

	public static function read(io:BytesReader) {
		return new Portal(io.readUInt16(), io.readUInt16(), io.readInt32(), io.readUInt16(), io.readUInt16());
	}

	public function write(io:BytesWriter) {
		io.writeUInt16(this.planeIndex);
		io.writeUInt16(this.triFanCount);
		io.writeInt32(this.triFanStart);
		io.writeUInt16(this.zoneFront);
		io.writeUInt16(this.zoneBack);
	}
}
