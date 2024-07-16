package dts;

import dif.io.BytesReader;

@:publicFields
class Sequence {
	var nameIndex:Int;
	var numKeyFrames:Int;
	var duration:Float;
	var baseRotation:Int;
	var baseTranslation:Int;
	var baseScale:Int;
	var baseObjectState:Int;
	var baseDecalState:Int;
	var firstGroundFrame:Int;
	var numGroundFrames:Int;
	var firstTrigger:Int;
	var numTriggers:Int;
	var toolBegin:Float;

	var rotationMatters:Array<Int>;
	var translationMatters:Array<Int>;
	var scaleMatters:Array<Int>;
	var visMatters:Array<Int>;
	var frameMatters:Array<Int>;
	var matFrameMatters:Array<Int>;
	var decalMatters:Array<Int>;
	var iflMatters:Array<Int>;

	var priority:Int;
	var flags:Int;
	var dirtyFlags:Int;
	var lastSequenceKeyframe:Float;

	public function new() {}

	public function read(reader:BytesReader, fileVersion:Int, readNameIndex:Bool) {
		if (readNameIndex) {
			this.nameIndex = reader.readInt32();
		}
		this.flags = 0;

		if (fileVersion > 21) {
			this.flags = reader.readInt32();
		}
		this.numKeyFrames = reader.readInt32();
		this.duration = reader.readFloat();

		if (fileVersion < 22) {
			var tmp = reader.readByte();
			if (tmp > 0) {
				flags |= ShapeFlags.Blend;
			}
			tmp = reader.readByte();
			if (tmp > 0) {
				flags |= ShapeFlags.Cyclic;
			}
			tmp = reader.readByte();
			if (tmp > 0) {
				flags |= ShapeFlags.MakePath;
			}
		}

		this.priority = reader.readInt32();
		this.firstGroundFrame = reader.readInt32();
		this.numGroundFrames = reader.readInt32();

		if (fileVersion > 21) {
			this.baseRotation = reader.readInt32();
			this.baseTranslation = reader.readInt32();
			this.baseScale = reader.readInt32();
			this.baseObjectState = reader.readInt32();
			this.baseDecalState = reader.readInt32();
		} else {
			this.baseRotation = reader.readInt32();
			this.baseTranslation = this.baseRotation;
			this.baseObjectState = reader.readInt32();
			this.baseDecalState = reader.readInt32();
		}

		this.firstTrigger = reader.readInt32();
		this.numTriggers = reader.readInt32();
		this.toolBegin = reader.readInt32();

		rotationMatters = readBitSet(reader);
		translationMatters = readBitSet(reader);
		scaleMatters = readBitSet(reader);
		decalMatters = readBitSet(reader);
		iflMatters = readBitSet(reader);
		visMatters = readBitSet(reader);
		frameMatters = readBitSet(reader);
		matFrameMatters = readBitSet(reader);

		this.dirtyFlags = 0;
		return true;
	}

	function readBitSet(reader:BytesReader) {
		var dummy = reader.readInt32();
		var numWords = reader.readInt32();
		var ret = [];
		for (i in 0...numWords) {
			ret.push(reader.readInt32());
		}
		return ret;
	}
}
