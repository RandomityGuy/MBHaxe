package dif;

import dif.io.BytesWriter;
import dif.io.BytesReader;
import dif.math.Point3F;
import dif.math.SphereF.Spheref;
import dif.math.Box3F;

using dif.ReaderExtensions;
using dif.WriterExtensions;

@:expose
class ForceField {
	public var forceFieldFileVersion:Int;
	public var name:String;
	public var triggers:Array<String>;
	public var boundingBox:Box3F;
	public var boundingSphere:Spheref;
	public var normals:Array<Point3F>;
	public var planes:Array<Plane>;
	public var bspNodes:Array<BSPNode>;
	public var bspSolidLeaves:Array<BSPSolidLeaf>;
	public var windings:Array<Int>;
	public var surfaces:Array<FFSurface>;
	public var solidLeafSurfaces:Array<Int>;
	public var color:Array<Int>;

	public function new() {}

	public static function read(io:BytesReader) {
		var ret = new ForceField();
		ret.forceFieldFileVersion = io.readInt32();
		ret.name = io.readStr();
		ret.triggers = io.readArray(io -> io.readStr());
		ret.boundingBox = Box3F.read(io);
		ret.boundingSphere = Spheref.read(io);
		ret.normals = io.readArray(Point3F.read);
		ret.planes = io.readArray(Plane.read);
		ret.bspNodes = io.readArray(io -> BSPNode.read(io, new Version()));
		ret.bspSolidLeaves = io.readArray(BSPSolidLeaf.read);
		ret.windings = io.readArray(io -> io.readInt32());
		ret.surfaces = io.readArray(FFSurface.read);
		ret.solidLeafSurfaces = io.readArray(io -> io.readInt32());
		ret.color = io.readColorF();
		return ret;
	}

	public function write(io:BytesWriter) {
		io.writeInt32(this.forceFieldFileVersion);
		io.writeStr(this.name);
		io.writeArray(this.triggers, (io, p) -> io.writeStr(p));
		this.boundingBox.write(io);
		this.boundingSphere.write(io);
		io.writeArray(this.normals, (io, p) -> p.write(io));
		io.writeArray(this.planes, (io, p) -> p.write(io));
		io.writeArray(this.bspNodes, (io, p) -> p.write(io, new Version()));
		io.writeArray(this.bspSolidLeaves, (io, p) -> p.write(io));
		io.writeArray(this.windings, (io, p) -> io.writeInt32(p));
		io.writeArray(this.surfaces, (io, p) -> p.write(io));
		io.writeArray(this.solidLeafSurfaces, (io, p) -> io.writeInt32(p));
		io.writeColorF(this.color);
	}
}
