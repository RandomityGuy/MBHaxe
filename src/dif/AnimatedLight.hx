package dif;

import dif.io.BytesWriter;
import dif.io.BytesReader;
import haxe.Int32;

@:expose
class AnimatedLight {
	public var nameIndex:Int32;
	public var stateIndex:Int32;
	public var stateCount:Int;
	public var flags:Int;
	public var duration:Int32;

	public function new(nameIndex:Int32, stateIndex:Int32, stateCount:Int, flags:Int, duration:Int32) {
		this.nameIndex = nameIndex;
		this.stateIndex = stateIndex;
		this.stateCount = stateCount;
		this.flags = flags;
		this.duration = duration;
	}

	public static function read(io:BytesReader) {
		return new AnimatedLight(io.readInt32(), io.readInt32(), io.readInt16(), io.readInt16(), io.readInt32());
	}

	public function write(io:BytesWriter) {
		io.writeInt32(this.nameIndex);
		io.writeInt32(this.stateIndex);
		io.writeUInt16(this.stateCount);
		io.writeUInt16(this.flags);
		io.writeInt32(this.duration);
	}
}
