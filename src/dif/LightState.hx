package dif;

import dif.io.BytesWriter;
import dif.io.BytesReader;
import haxe.Int32;

@:expose
class LightState {
	public var red:Int;
	public var green:Int;
	public var blue:Int;
	public var activeTime:Int32;
	public var dataIndex:Int32;
	public var dataCount:Int;

	public function new(red:Int, green:Int, blue:Int, activeTime:Int32, dataIndex:Int32, dataCount:Int) {
		this.red = red;
		this.green = green;
		this.blue = blue;
		this.activeTime = activeTime;
		this.dataIndex = dataIndex;
		this.dataCount = dataCount;
	}

	public static function read(io:BytesReader) {
		return new LightState(io.readByte(), io.readByte(), io.readByte(), io.readInt32(), io.readInt32(), io.readInt16());
	}

	public function write(io:BytesWriter) {
		io.writeByte(this.red);
		io.writeByte(this.green);
		io.writeByte(this.blue);
		io.writeInt32(this.activeTime);
		io.writeInt32(this.dataIndex);
		io.writeInt16(this.dataCount);
	}
}
