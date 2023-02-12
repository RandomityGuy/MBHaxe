package dts;

import haxe.Exception;
import dif.io.BytesReader;
import dif.math.QuatF;
import dif.math.Box3F;
import dif.math.Point3F;
import src.ResourceLoader;

@:publicFields
class DtsFile {
	var fileVersion:Int;
	var exporterVersion:Int;
	var sequences:Array<Sequence>;
	var matNames:Array<String>;
	var matFlags:Array<Int>;
	var matReflectanceMaps:Array<Int>;
	var matBumpMaps:Array<Int>;
	var matDetailMaps:Array<Int>;
	var matDetailScales:Array<Float>;
	var matReflectionAmounts:Array<Float>;
	var smallestVisibleSize:Float;
	var smallestVisibleDL:Float;

	var radius:Float;
	var radiusTube:Float;
	var center:Point3F;
	var bounds:Box3F;

	var nodes:Array<Node>;
	var objects:Array<Object>;
	var mats:Array<IflMaterial>;
	var subshapes:Array<SubShape>;

	var defaultRotations:Array<QuatF>;
	var defaultTranslations:Array<Point3F>;

	var nodeTranslations:Array<Point3F>;
	var nodeRotations:Array<QuatF>;

	var nodeUniformScales:Array<Float>;
	var nodeAlignedScales:Array<Point3F>;
	var nodeArbitraryScaleFactors:Array<Point3F>;
	var nodeArbitraryScaleRots:Array<QuatF>;

	var groundTranslations:Array<Point3F>;
	var groundRots:Array<QuatF>;

	var objectStates:Array<ObjectState>;
	var decalStates:Array<Int>;
	var triggers:Array<Trigger>;

	var detailLevels:Array<Detail>;
	var meshes:Array<Mesh>;

	var names:Array<String>;

	var alphaIn:Array<Int>;
	var alphaOut:Array<Int>;

	public function new() {}

	public function read(filepath:String) {
		var f = ResourceLoader.getFileEntry(filepath).entry;
		var bytes = f.getBytes();
		var br = new BytesReader(bytes);

		fileVersion = br.readInt16();
		exporterVersion = br.readInt16();
		fileVersion &= 0xFF;

		var memBuffer:BytesReader;
		var start32:Int;
		var start16:Int;
		var start8:Int;

		if (fileVersion > 24) {
			throw new Exception("Invalid DTS version");
		}

		if (fileVersion < 19) {
			var result = this.readOldShape(fileVersion, br);
			memBuffer = new BytesReader(result.bufferInfo.buffer);
			start32 = 0;
			start16 = result.bufferInfo.start16;
			start8 = result.bufferInfo.start8;

			sequences = result.sequences;
			// throw new Exception("Cant read this!");
		} else {
			var sizeMemBuffer = br.readInt32();
			memBuffer = br;
			start16 = br.readInt32();
			start8 = br.readInt32();
			start32 = br.tell();

			br.seek(br.tell() + sizeMemBuffer * 4);

			var numSequences = br.readInt32();
			sequences = [];
			for (i in 0...numSequences) {
				var seq = new Sequence();
				seq.read(br, fileVersion, true);
				sequences.push(seq);
			}

			parseMaterialList(br, fileVersion);
		}

		var alloc = new DtsAlloc(memBuffer, start32, start16, start8);
		this.assembleShape(alloc);
	}

	function readOldShape(version:Int, br:BytesReader) {
		var oldAlloc = new DtsOldAlloc(br, br.tell());

		oldAlloc.allocate32(15);
		oldAlloc.guard();

		oldAlloc.copyInto32(1); // Radius
		oldAlloc.copyInto32(1); // Tube radius
		oldAlloc.copyInto32(3); // Center
		oldAlloc.copyInto32(6); // Bounds

		oldAlloc.guard();

		var numNodes = oldAlloc.readS32(0);
		for (i in 0...numNodes) {
			oldAlloc.copyInto32(2);
			oldAlloc.allocate32(3);
		}

		oldAlloc.guard();

		var numObjects = oldAlloc.readS32(1);
		for (i in 0...numObjects) {
			oldAlloc.copyInto32(4);
			oldAlloc.allocate32(2);
		}

		oldAlloc.guard();

		var numDecals = oldAlloc.readS32(2);
		for (i in 0...numDecals) {
			oldAlloc.copyInto32(4);
			oldAlloc.allocate32(1);
		}

		oldAlloc.guard();

		var numIflMaterials = oldAlloc.readS32(4);
		for (i in 0...numIflMaterials) {
			oldAlloc.copyInto32(2);
			oldAlloc.allocate32(3);
		}

		oldAlloc.guard();

		var numSubShapes = oldAlloc.readS32(3);
		var subShapeFirstStart = oldAlloc.index32;
		oldAlloc.copyInto32(numSubShapes); // subShapeFirstNode
		oldAlloc.skip(4); // toss
		oldAlloc.copyInto32(numSubShapes); // subShapeFirstObject
		oldAlloc.skip(4); // toss
		oldAlloc.copyInto32(numSubShapes); // subShapeFirstDecal

		oldAlloc.guard();

		var subShapeNumStart = oldAlloc.index32;
		oldAlloc.allocate32(3 * numSubShapes);

		oldAlloc.guard();

		// compute subShapeNum* vectors
		var prev, first;
		for (i in 0...3) {
			prev = ((i == 0) ? numNodes : (i == 1 ? numObjects : numDecals));
			var j = numSubShapes - 1;
			while (j >= 0) {
				first = oldAlloc.buffer32.getInt32(subShapeFirstStart + j * 4);
				oldAlloc.buffer32.setInt32(subShapeNumStart + j * 4, prev - first);
				prev = first;
				j--;
			}

			subShapeFirstStart += numSubShapes;
			subShapeNumStart += numSubShapes;
		}

		var numNodeStates = oldAlloc.readS32(5);
		var nodeStateStart32 = oldAlloc.index32;
		var nodeStateStart16 = oldAlloc.index16;
		for (i in 0...numNodeStates) {
			oldAlloc.copyInto16(4); // read Quat16....rotation
			oldAlloc.copyInto32(3); // read Point3F...translation
		}

		oldAlloc.guard();

		var numObjectStates = oldAlloc.readS32(6);
		var objectStateStart = oldAlloc.index32;
		oldAlloc.copyInto32(numObjectStates * 3);

		oldAlloc.guard();

		var numDecalStates = oldAlloc.readS32(7);
		var decalStateStart = oldAlloc.index32;
		oldAlloc.copyInto32(numDecalStates);

		oldAlloc.guard();

		var numTriggers = oldAlloc.readS32(8);
		oldAlloc.copyInto32(numTriggers * 2);

		oldAlloc.guard();

		var numDetails = oldAlloc.readS32(9);
		for (i in 0...numDetails) {
			oldAlloc.copyInto32(4);
			oldAlloc.allocate32(3);
		}

		// There's some added detail filling-up code here, but we don't use these anyways. Screw it.

		oldAlloc.guard();

		br.seek(oldAlloc.sourceIndex);
		var numSequences = br.readInt32();
		var sequences = [];
		for (i in 0...numSequences) {
			var sequence = new Sequence();
			sequence.read(br, version, true);
			sequences.push(sequence);
		}

		oldAlloc.sourceIndex = br.tell();
		var numMeshes = oldAlloc.readS32(10);
		for (i in 0...numMeshes) {
			var meshType = oldAlloc.readS32(-1);
			this.readAllocMesh(oldAlloc, meshType);
		}

		oldAlloc.guard();

		var numNames = oldAlloc.readS32(12);
		for (i in 0...numNames) {
			var length = oldAlloc.readS32(null);
			oldAlloc.copyInto8(length);
			oldAlloc.writeU8(0); // end the string
		}

		oldAlloc.guard();

		br.seek(oldAlloc.sourceIndex);
		var gotList = br.readInt32();
		if (gotList > 0) {
			this.parseMaterialList(br, version);
		}
		oldAlloc.sourceIndex = br.tell();

		// Note: There would still be some skinned mesh or whatever code following this, but really, that's totally unnecessary. To prevent stupid "read out of range" errors when reading this buffer, we just add some extra bit to the end. Done.
		oldAlloc.allocate32(16);

		return {
			bufferInfo: oldAlloc.createBuffer(),
			sequences: sequences,
		};
	}

	function readAllocMesh(oldAlloc:DtsOldAlloc, meshType:Int) {
		if (meshType == 4)
			return;

		oldAlloc.guard();

		// numFrames, numMatFrames
		oldAlloc.copyInto32(2);

		// parentMesh
		oldAlloc.writeS32(-1);

		// allocate memory for mBounds,mCenter, and mRadius...just filler, will be computed later
		oldAlloc.allocate32(10);

		// read in verts
		var numVerts = oldAlloc.readS32(-1);
		oldAlloc.copyInto32(numVerts * 3);

		// read in tverts
		var numTverts = oldAlloc.readS32(-1);
		oldAlloc.copyInto32(numTverts * 2);

		// read in normals
		var numNormals = oldAlloc.readS32(null); // we could assume same as verts, but apparently in file.
		oldAlloc.copyInto32(numNormals * 3);

		// read in primitives
		var numPrimitives = oldAlloc.readS32(-1);
		for (i in 0...numPrimitives) {
			oldAlloc.copyInto16(2);
			oldAlloc.copyInto32(1);
		}

		// read in indices
		var numIndices = oldAlloc.readS32(-1);
		oldAlloc.copyInto16(numIndices);

		// mergeIndices...none
		oldAlloc.writeS32(0);

		// vertsPerFrame, flags
		oldAlloc.copyInto32(2);

		oldAlloc.guard();

		if (meshType == 1) {
			var numInitialVerts = oldAlloc.readS32(-1);
			oldAlloc.copyInto32(numInitialVerts * 3);

			var numInitialNorms = oldAlloc.readS32(null); // we assume same as verts
			oldAlloc.copyInto32(numInitialNorms * 3);

			var numInitialTransforms = oldAlloc.readS32(-1);
			oldAlloc.copyInto32(numInitialTransforms * 16);

			var numVertIndices = oldAlloc.readS32(-1);
			oldAlloc.copyInto32(numVertIndices);

			var numBoneIndices = oldAlloc.readS32(null);
			oldAlloc.copyInto32(numBoneIndices);

			var weightStart = oldAlloc.index32;
			oldAlloc.allocate32(numBoneIndices); // this is memory for the weights

			var numNodeIndices = oldAlloc.readS32(-1);
			oldAlloc.copyInto32(numNodeIndices);
			var returnToIndex = oldAlloc.index32;

			var numWeights = oldAlloc.readS32(null);
			oldAlloc.index32 = weightStart;
			oldAlloc.copyInto32(numWeights);
			oldAlloc.index32 = returnToIndex;

			oldAlloc.guard();
		}
	}

	function assembleShape(ar:DtsAlloc) {
		var numNodes = ar.readS32();
		var numObjects = ar.readS32();
		var numDecals = ar.readS32();
		var numSubShapes = ar.readS32();
		var numIflMaterials = ar.readS32();

		var numNodeRots:Int;
		var numNodeTrans:Int;
		var numNodeUniformScales:Int;
		var numNodeAlignedScales:Int;
		var numNodeArbitraryScales:Int;
		if (this.fileVersion < 22) {
			numNodeRots = numNodeTrans = ar.readS32() - numNodes;
			numNodeUniformScales = numNodeAlignedScales = numNodeArbitraryScales = 0;
		} else {
			numNodeRots = ar.readS32();
			numNodeTrans = ar.readS32();
			numNodeUniformScales = ar.readS32();
			numNodeAlignedScales = ar.readS32();
			numNodeArbitraryScales = ar.readS32();
		}
		var numGroundFrames = 0;
		if (this.fileVersion > 23) {
			numGroundFrames = ar.readS32();
		}
		var numObjectStates = ar.readS32();
		var numDecalStates = ar.readS32();
		var numTriggers = ar.readS32();
		var numDetails = ar.readS32();
		var numMeshes = ar.readS32();
		var numSkins = 0;
		if (this.fileVersion < 23) {
			numSkins = ar.readS32();
		}
		var numNames = ar.readS32();
		this.smallestVisibleSize = ar.readF32();
		this.smallestVisibleDL = ar.readS32();

		ar.guard();

		radius = ar.readF32();
		radiusTube = ar.readF32();
		center = ar.readPoint3F();
		bounds = ar.readBoxF();

		ar.guard();

		nodes = [];
		for (i in 0...numNodes) {
			nodes.push(Node.read(ar));
		}
		ar.guard();

		objects = [];
		for (i in 0...numObjects) {
			objects.push(Object.read(ar));
		}
		ar.guard();
		ar.guard();

		mats = [];
		for (i in 0...numIflMaterials) {
			mats.push(IflMaterial.read(ar));
		}
		ar.guard();

		subshapes = [];
		for (i in 0...numSubShapes) {
			subshapes.push(new SubShape(0, 0, 0, 0, 0, 0));
		}

		for (i in 0...numSubShapes)
			subshapes[i].firstNode = ar.readS32();
		for (i in 0...numSubShapes)
			subshapes[i].firstObject = ar.readS32();
		for (i in 0...numSubShapes)
			subshapes[i].firstDecal = ar.readS32();

		ar.guard();

		for (i in 0...numSubShapes)
			subshapes[i].numNodes = ar.readS32();
		for (i in 0...numSubShapes)
			subshapes[i].numObjects = ar.readS32();
		for (i in 0...numSubShapes)
			subshapes[i].numDecals = ar.readS32();
		ar.guard();

		if (fileVersion < 16) {
			var num = ar.readS32();
			for (i in 0...num)
				ar.readS32();
		}

		defaultRotations = [];
		defaultTranslations = [];
		for (i in 0...numNodes) {
			defaultRotations.push(ar.readQuat16());
			defaultTranslations.push(ar.readPoint3F());
		}

		nodeTranslations = [];
		for (i in 0...numNodeTrans)
			nodeTranslations.push(ar.readPoint3F());

		nodeRotations = [];
		for (i in 0...numNodeRots)
			nodeRotations.push(ar.readQuat16());

		ar.guard();

		nodeUniformScales = [];
		nodeAlignedScales = [];
		nodeArbitraryScaleFactors = [];
		nodeArbitraryScaleRots = [];

		if (fileVersion > 21) {
			for (i in 0...numNodeUniformScales)
				nodeUniformScales.push(ar.readF32());
			for (i in 0...numNodeAlignedScales)
				nodeAlignedScales.push(ar.readPoint3F());
			for (i in 0...numNodeArbitraryScales)
				nodeArbitraryScaleFactors.push(ar.readPoint3F());
			for (i in 0...numNodeArbitraryScales)
				nodeArbitraryScaleRots.push(ar.readQuat16());
			ar.guard();
		} else {
			for (i in 0...numNodeUniformScales)
				nodeUniformScales.push(1);
			for (i in 0...numNodeAlignedScales)
				nodeAlignedScales.push(new Point3F(1, 1, 1));
			for (i in 0...numNodeArbitraryScales)
				nodeArbitraryScaleFactors.push(new Point3F(1, 1, 1));
			for (i in 0...numNodeArbitraryScales)
				nodeArbitraryScaleRots.push(new QuatF());
		}

		groundTranslations = [];
		groundRots = [];
		if (fileVersion > 23) {
			for (i in 0...numGroundFrames) {
				groundTranslations.push(ar.readPoint3F());
			}
			for (i in 0...numGroundFrames) {
				groundRots.push(ar.readQuat16());
			}
			ar.guard();
		} else {
			for (i in 0...numGroundFrames) {
				groundTranslations.push(new Point3F(1, 1, 1));
			}
			for (i in 0...numGroundFrames) {
				groundRots.push(new QuatF());
			}
		}

		objectStates = [];
		for (i in 0...numObjectStates) {
			objectStates.push(ObjectState.read(ar));
		}
		ar.guard();

		decalStates = [];
		for (i in 0...numDecalStates) {
			decalStates.push(ar.readS32());
		}
		ar.guard();

		triggers = [];
		for (i in 0...numTriggers) {
			triggers.push(Trigger.read(ar));
		}
		ar.guard();

		detailLevels = [];
		for (i in 0...numDetails) {
			detailLevels.push(Detail.read(ar));
		}
		ar.guard();

		meshes = [];
		for (i in 0...numMeshes) {
			meshes.push(Mesh.read(this, ar, fileVersion));
		}
		ar.guard();

		names = [];
		for (i in 0...numNames) {
			var str = "";

			while (true) {
				var charCode = ar.readU8();
				if (charCode == 0)
					break;

				str += String.fromCharCode(charCode);
			}

			names.push(str);
		}
		ar.guard();

		alphaIn = [];
		alphaOut = [];

		if (fileVersion >= 26) {
			for (i in 0...numDetails) {
				alphaIn.push(ar.readS32());
			}
			for (i in 0...numDetails) {
				alphaOut.push(ar.readS32());
			}
		}
	}

	function parseMaterialList(br:BytesReader, version:Int) {
		var matStreamType = br.readByte();
		var numMaterials = br.readInt32();
		matNames = [];
		matFlags = [];
		matReflectanceMaps = [];
		matBumpMaps = [];
		matDetailMaps = [];
		matDetailScales = [];
		matReflectionAmounts = [];
		for (i in 0...numMaterials) {
			var mname = br.readStr();
			mname = StringTools.replace(mname, '\x00', '');
			matNames.push(mname);
		}
		for (i in 0...numMaterials) {
			matFlags.push(br.readInt32());
		}
		for (i in 0...numMaterials) {
			matReflectanceMaps.push(br.readInt32());
		}
		for (i in 0...numMaterials) {
			matBumpMaps.push(br.readInt32());
		}
		for (i in 0...numMaterials) {
			matDetailMaps.push(br.readInt32());
		}
		if (version == 25) {
			for (i in 0...numMaterials) {
				br.readInt32();
			}
		}
		for (i in 0...numMaterials) {
			matDetailScales.push(br.readFloat());
		}
		for (i in 0...numMaterials) {
			matReflectionAmounts.push(br.readFloat());
		}
	}
}
