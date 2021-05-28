package dif;

import dif.io.BytesWriter;
import dif.io.BytesReader;
import dif.math.QuatF;
import dif.math.Point3F;

@:expose
class WayPoint {
	public var position:Point3F;
	public var rotation:QuatF;
	public var msToNext:Int;
	public var smoothingType:Int;

	public function new(position, rotation, msToNext, smoothingType) {
		this.position = position;
		this.rotation = rotation;
		this.msToNext = msToNext;
		this.smoothingType = smoothingType;
	}

	public static function read(io:BytesReader) {
		return new WayPoint(Point3F.read(io), QuatF.read(io), io.readInt32(), io.readInt32());
	};

	public function write(io:BytesWriter) {
		this.position.write(io);
		this.rotation.write(io);
		io.writeInt32(this.msToNext);
		io.writeInt32(this.smoothingType);
	}
}
