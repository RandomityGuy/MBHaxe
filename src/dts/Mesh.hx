package dts;

import haxe.Exception;
import dif.math.Point2F;
import dif.math.Point3F;
import dif.math.Box3F;

class Mesh {
	var meshType:Int;
	var numFrames:Int;
	var numMatFrames:Int;
	var parent:Int;
	var bounds:Box3F;
	var center:Point3F;
	var radius:Float;
	var vertices:Array<Point3F>;
	var uv:Array<Point2F>;
	var normals:Array<Point3F>;
	var enormals:Array<Int>;
	var primitives:Array<Primitive>;
	var indices:Array<Int>;
	var mindices:Array<Int>;
	var vertsPerFrame:Int;
	var type:Int;
	var shape:DtsFile;

	public function new() {}

	function readStandard(reader:DtsAlloc) {
		reader.guard();

		numFrames = reader.readU32();
		numMatFrames = reader.readU32();
		parent = reader.readS32();
		bounds = reader.readBoxF();
		center = reader.readPoint3F();
		radius = reader.readF32();

		var numVerts = reader.readU32();
		vertices = [];
		if (this.parent < 0) {
			for (i in 0...numVerts) {
				vertices.push(reader.readPoint3F());
			}
		} else {
			vertices = shape.meshes[this.parent].vertices;
		}

		var tVerts = reader.readU32();
		uv = [];
		if (this.parent < 0) {
			for (i in 0...tVerts) {
				uv.push(reader.readPoint2F());
			}
		} else {
			uv = shape.meshes[this.parent].uv;
		}

		var numNormals = reader.readU32();
		normals = [];
		if (this.parent < 0) {
			for (i in 0...numNormals) {
				normals.push(reader.readPoint3F());
			}
		} else {
			normals = shape.meshes[this.parent].normals;
		}

		enormals = [];
		if (this.parent < 0) {
			for (i in 0...numVerts) {
				enormals.push(reader.readU8());
			}
		}

		primitives = [];
		var numPrimitives = reader.readU32();
		for (i in 0...numPrimitives) {
			primitives.push(Primitive.read(reader));
		}

		indices = [];
		var numIndices = reader.readU32();
		for (i in 0...numIndices) {
			indices.push(reader.readS16());
		}

		mindices = [];
		var numMIndices = reader.readU32();
		for (i in 0...numMIndices) {
			mindices.push(reader.readS16());
		}

		vertsPerFrame = reader.readS32();
		type = reader.readS32();

		reader.guard();
	}

	function readSkinned(reader:DtsAlloc) {
		readStandard(reader);

		var sz = reader.readS32();
		for (i in 0...sz) {
			reader.readPoint3F();
		}
		for (i in 0...sz) {
			reader.readPoint3F();
		}
		for (i in 0...sz) {
			reader.readU8();
		}

		sz = reader.readS32();
		for (i in 0...sz) {
			for (j in 0...16) {
				reader.readF32();
			}
		}

		sz = reader.readS32();
		for (i in 0...sz) {
			reader.readS32();
		}
		for (i in 0...sz) {
			reader.readS32();
		}
		for (i in 0...sz) {
			reader.readF32();
		}

		sz = reader.readS32();
		for (i in 0...sz) {
			reader.readS32();
		}

		reader.guard();
	}

	public static function read(shape:DtsFile, reader:DtsAlloc) {
		var mesh = new Mesh();
		mesh.shape = shape;
		mesh.meshType = reader.readS32() & 7;

		if (mesh.meshType == 0)
			mesh.readStandard(reader);
		else if (mesh.meshType == 1)
			mesh.readSkinned(reader);
		else if (mesh.meshType == 4)
			return null;
		else
			throw new Exception("idk how to read this");

		return mesh;
	}
}
