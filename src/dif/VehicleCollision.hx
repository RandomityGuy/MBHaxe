package dif;

import dif.io.BytesWriter;
import dif.io.BytesReader;
import dif.math.Point3F;

using dif.ReaderExtensions;
using dif.WriterExtensions;

@:expose
class VehicleCollision {
	public var vehicleCollisionFileVersion:Int;
	public var convexHulls:Array<ConvexHull>;
	public var convexHullEmitStrings:Array<Int>;
	public var hullIndices:Array<Int>;
	public var hullPlaneIndices:Array<Int>;
	public var hullEmitStringIndices:Array<Int>;
	public var hullSurfaceIndices:Array<Int>;
	public var polyListPlanes:Array<Int>;
	public var polyListPoints:Array<Int>;
	public var polyListStrings:Array<Int>;
	public var nullSurfaces:Array<NullSurface>;
	public var points:Array<Point3F>;
	public var planes:Array<Plane>;
	public var windings:Array<Int>;
	public var windingIndices:Array<WindingIndex>;

	public function new() {}

	public static function read(io:BytesReader, version:Version) {
		var ret = new VehicleCollision();
		ret.vehicleCollisionFileVersion = io.readInt32();
		ret.convexHulls = io.readArray((io) -> ConvexHull.read(io, version));
		ret.convexHullEmitStrings = io.readArray(io -> io.readByte());
		ret.hullIndices = io.readArray(io -> io.readInt32());
		ret.hullPlaneIndices = io.readArray(io -> io.readInt16());
		ret.hullEmitStringIndices = io.readArray(io -> io.readInt32());
		ret.hullSurfaceIndices = io.readArray(io -> io.readInt32());
		ret.polyListPlanes = io.readArray(io -> io.readInt16());
		ret.polyListPoints = io.readArray(io -> io.readInt32());
		ret.polyListStrings = io.readArray(io -> io.readByte());
		ret.nullSurfaces = io.readArray(io -> NullSurface.read(io, new Version()));
		ret.points = io.readArray(Point3F.read);
		ret.planes = io.readArray(Plane.read);
		ret.windings = io.readArray(io -> io.readInt32());
		ret.windingIndices = io.readArray(WindingIndex.read);
		return ret;
	}

	public function write(io:BytesWriter, version:Version) {
		io.writeInt32(this.vehicleCollisionFileVersion);
		io.writeArray(this.convexHulls, (io, p) -> p.write(io, version));
		io.writeArray(this.convexHullEmitStrings, (io, p) -> io.writeByte(p));
		io.writeArray(this.hullIndices, (io, p) -> io.writeInt32(p));
		io.writeArray(this.hullPlaneIndices, (io, p) -> io.writeInt16(p));
		io.writeArray(this.hullEmitStringIndices, (io, p) -> io.writeInt32(p));
		io.writeArray(this.hullSurfaceIndices, (io, p) -> io.writeInt32(p));
		io.writeArray(this.polyListPlanes, (io, p) -> io.writeInt16(p));
		io.writeArray(this.polyListPoints, (io, p) -> io.writeInt32(p));
		io.writeArray(this.polyListStrings, (io, p) -> io.writeByte(p));
		io.writeArray(this.nullSurfaces, (io, p) -> p.write(io, new Version()));
		io.writeArray(this.points, (io, p) -> p.write(io));
		io.writeArray(this.planes, (io, p) -> p.write(io));
		io.writeArray(this.windings, (io, p) -> io.writeInt32(p));
		io.writeArray(this.windingIndices, (io, p) -> p.write(io));
	}
}
