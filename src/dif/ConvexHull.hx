package dif;

import haxe.Int32;
import dif.io.BytesWriter;
import dif.io.BytesReader;

@:expose
class ConvexHull {
	public var hullStart:Int32;
	public var hullCount:Int32;
	public var minX:Float;
	public var minY:Float;
	public var minZ:Float;
	public var maxX:Float;
	public var maxY:Float;
	public var maxZ:Float;
	public var surfaceStart:Int32;
	public var surfaceCount:Int32;
	public var planeStart:Int32;
	public var polyListPlaneStart:Int32;
	public var polyListPointStart:Int32;
	public var polyListStringStart:Int32;
	public var staticMesh:Bool;

	public function new() {
		this.hullStart = 0;
		this.hullCount = 0;
		this.minX = 0;
		this.minY = 0;
		this.minZ = 0;
		this.maxX = 0;
		this.maxY = 0;
		this.maxZ = 0;
		this.surfaceStart = 0;
		this.surfaceCount = 0;
		this.planeStart = 0;
		this.polyListPlaneStart = 0;
		this.polyListPointStart = 0;
		this.polyListStringStart = 0;
		this.staticMesh = false;
	}

	public static function read(io:BytesReader, version:Version) {
		var ret = new ConvexHull();
		ret.hullStart = io.readInt32();
		ret.hullCount = io.readUInt16();
		ret.minX = io.readFloat();
		ret.minY = io.readFloat();
		ret.minZ = io.readFloat();
		ret.maxX = io.readFloat();
		ret.maxY = io.readFloat();
		ret.maxZ = io.readFloat();
		ret.surfaceStart = io.readInt32();
		ret.surfaceCount = io.readUInt16();
		ret.planeStart = io.readInt32();
		ret.polyListPlaneStart = io.readInt32();
		ret.polyListPointStart = io.readInt32();
		ret.polyListStringStart = io.readInt32();

		if (version.interiorVersion >= 12) {
			ret.staticMesh = io.readByte() > 0;
		}
		return ret;
	}

	public function write(io:BytesWriter, version:Version) {
		io.writeInt32(this.hullStart);
		io.writeUInt16(this.hullCount);
		io.writeFloat(this.minX);
		io.writeFloat(this.minY);
		io.writeFloat(this.minZ);
		io.writeFloat(this.maxX);
		io.writeFloat(this.maxY);
		io.writeFloat(this.maxZ);
		io.writeInt32(this.surfaceStart);
		io.writeUInt16(this.surfaceCount);
		io.writeInt32(this.planeStart);
		io.writeInt32(this.polyListPlaneStart);
		io.writeInt32(this.polyListPointStart);
		io.writeInt32(this.polyListStringStart);

		if (version.interiorVersion >= 12) {
			io.writeByte(this.staticMesh ? 1 : 0);
		}
	}
}
