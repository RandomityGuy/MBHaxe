package dif;

import haxe.io.Bytes;
#if sys
import sys.io.File;
#end
import dif.io.BytesWriter;
import dif.io.BytesReader;
#if js
import js.lib.ArrayBuffer;
#end
#if python
import python.Bytearray;
#end
#if cs
import cs.NativeArray;
#end

using dif.ReaderExtensions;
using dif.WriterExtensions;

@:expose
class Dif {
	public var difVersion:Int;
	public var previewIncluded:Int;
	public var interiors:Array<Interior>;
	public var subObjects:Array<Interior>;
	public var triggers:Array<Trigger>;
	public var interiorPathfollowers:Array<InteriorPathFollower>;
	public var forceFields:Array<ForceField>;
	public var aiSpecialNodes:Array<AISpecialNode>;
	public var vehicleCollision:VehicleCollision = null;
	public var gameEntities:Array<GameEntity> = null;

	public function new() {}

	#if sys
	public static function Load(path:String) {
		var f = File.read(path);
		var bytes = f.readAll();
		var br = new BytesReader(bytes);
		return Dif.read(br);
	}

	public static function Save(dif:Dif, version:Version, path:String) {
		var f = File.write(path);
		var bw = new BytesWriter();
		dif.write(bw, version);
		f.write(bw.getBuffer());
	}
	#end

	public static function LoadFromBuffer(buffer:haxe.io.Bytes) {
		var br = new BytesReader(buffer);
		return Dif.read(br);
	}

	public static function SaveToBuffer(dif:Dif, version:Version) {
		var bw = new BytesWriter();
		dif.write(bw, version);
		return bw.getBuffer();
	}

	#if js
	public static function LoadFromArrayBuffer(buffer:ArrayBuffer) {
		var br = new BytesReader(Bytes.ofData(buffer));
		return Dif.read(br);
	}

	public static function SaveToArrayBuffer(dif:Dif, version:Version) {
		var bw = new BytesWriter();
		dif.write(bw, version);
		return bw.getBuffer().getData();
	}
	#end

	#if python
	public static function LoadFromByteArray(buffer:Bytearray) {
		var br = new BytesReader(Bytes.ofData(buffer));
		return Dif.read(br);
	}

	public static function SaveToByteArray(dif:Dif, version:Version) {
		var bw = new BytesWriter();
		dif.write(bw, version);
		return bw.getBuffer().getData();
	}
	#end

	#if cs
	public static function LoadFromArray(buffer:cs.NativeArray<cs.types.UInt8>) {
		var br = new BytesReader(Bytes.ofData(buffer));
		return Dif.read(br);
	}

	public static function SaveToArray(dif:Dif, version:Version) {
		var bw = new BytesWriter();
		dif.write(bw, version);
		return bw.getBuffer().getData();
	}
	#end

	public static function read(io:BytesReader) {
		var ret = new Dif();
		var version = new Version();
		version.difVersion = io.readInt32();
		ret.difVersion = version.difVersion;
		ret.previewIncluded = io.readByte();
		ret.interiors = io.readArray(io -> Interior.read(io, version));
		ret.subObjects = io.readArray(io -> Interior.read(io, version));
		ret.triggers = io.readArray(Trigger.read);
		ret.interiorPathfollowers = io.readArray(InteriorPathFollower.read);
		ret.forceFields = io.readArray(ForceField.read);
		ret.aiSpecialNodes = io.readArray(AISpecialNode.read);
		var readVehicleCollision = io.readInt32();
		if (readVehicleCollision == 1)
			ret.vehicleCollision = VehicleCollision.read(io, version);
		var readGameEntities = io.readInt32();
		if (readGameEntities == 2)
			ret.gameEntities = io.readArray(GameEntity.read);

		return ret;
	}

	public function write(io:BytesWriter, version:Version) {
		io.writeInt32(this.difVersion);
		io.writeByte(this.previewIncluded);

		io.writeArray(this.interiors, (io, p) -> p.write(io, version));
		io.writeArray(this.subObjects, (io, p) -> p.write(io, version));
		io.writeArray(this.triggers, (io, p) -> p.write(io));
		io.writeArray(this.interiorPathfollowers, (io, p) -> p.write(io));
		io.writeArray(this.forceFields, (io, p) -> p.write(io));
		io.writeArray(this.aiSpecialNodes, (io, p) -> p.write(io));
		if (this.vehicleCollision != null) {
			io.writeInt32(1);
			this.vehicleCollision.write(io, version);
		} else {
			io.writeInt32(0);
		}
		if (this.gameEntities != null) {
			io.writeInt32(2);
			io.writeArray(this.gameEntities, (io, p) -> p.write(io));
		} else {
			io.writeInt32(0);
		}
		io.writeInt32(0);
	}
}
