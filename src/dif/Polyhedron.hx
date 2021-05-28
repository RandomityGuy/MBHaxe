package dif;

import dif.io.BytesWriter;
import dif.io.BytesReader;
import dif.math.PlaneF;
import dif.math.Point3F;

using dif.ReaderExtensions;
using dif.WriterExtensions;

@:expose
class Polyhedron {
	public var pointList:Array<Point3F>;
	public var planeList:Array<PlaneF>;
	public var edgeList:Array<PolyhedronEdge>;

	public function new() {
		this.pointList = new Array<Point3F>();
		this.planeList = new Array<PlaneF>();
		this.edgeList = new Array<PolyhedronEdge>();
	}

	public static function read(io:BytesReader) {
		var ret = new Polyhedron();
		ret.pointList = io.readArray(Point3F.read);
		ret.planeList = io.readArray(PlaneF.read);
		ret.edgeList = io.readArray(PolyhedronEdge.read);
		return ret;
	}

	public function write(io:BytesWriter) {
		io.writeArray(this.pointList, (io, p) -> p.write(io));
		io.writeArray(this.planeList, (io, p) -> p.write(io));
		io.writeArray(this.edgeList, (io, p) -> p.write(io));
	}
}
