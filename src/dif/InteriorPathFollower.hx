package dif;

import dif.io.BytesWriter;
import dif.io.BytesReader;
import haxe.xml.Access;
import haxe.ds.StringMap;
import dif.math.Point3F;

using dif.ReaderExtensions;
using dif.WriterExtensions;

@:expose
class InteriorPathFollower {
	public var name:String;
	public var datablock:String;
	public var interiorResIndex:Int;
	public var offset:Point3F;
	public var properties:StringMap<String>;
	public var triggerId:Array<Int>;
	public var wayPoint:Array<WayPoint>;
	public var totalMS:Int;

	public function new() {
		this.name = "";
		this.datablock = "";
		this.interiorResIndex = 0;
		this.offset = new Point3F();
		this.properties = new StringMap<String>();
		this.triggerId = new Array<Int>();
		this.wayPoint = new Array<WayPoint>();
		this.totalMS = 0;
	}

	public static function read(io:BytesReader) {
		var ret = new InteriorPathFollower();
		ret.name = io.readStr();
		ret.datablock = io.readStr();
		ret.interiorResIndex = io.readInt32();
		ret.offset = Point3F.read(io);
		ret.properties = io.readDictionary();
		ret.triggerId = io.readArray(io -> io.readInt32());
		ret.wayPoint = io.readArray(WayPoint.read);
		ret.totalMS = io.readInt32();
		return ret;
	}

	public function write(io:BytesWriter) {
		io.writeStr(this.name);
		io.writeStr(this.datablock);
		io.writeInt32(this.interiorResIndex);
		this.offset.write(io);
		io.writeDictionary(this.properties);
		io.writeArray(this.triggerId, (io, p) -> io.writeInt32(p));
		io.writeArray(this.wayPoint, (io, p) -> p.write(io));
		io.writeInt32(this.totalMS);
	}
}
