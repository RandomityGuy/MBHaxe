package dif;

import dif.io.BytesWriter;
import dif.io.BytesReader;

@:expose
class BSPNode {
	public var planeIndex:Int;
	public var frontIndex:Int;
	public var backIndex:Int;

	public var isFrontLeaf:Bool;
	public var isFrontSolid:Bool;

	public var isBackLeaf:Bool;
	public var isBackSolid:Bool;

	public function new(planeIndex, frontIndex, backIndex, isFrontLeaf, isFrontSolid, isBackLeaf, isBackSolid) {
		this.planeIndex = planeIndex;
		this.frontIndex = frontIndex;
		this.backIndex = backIndex;
		this.isFrontLeaf = isFrontLeaf;
		this.isFrontSolid = isFrontSolid;
		this.isBackLeaf = isBackLeaf;
		this.isBackSolid = isBackSolid;
	}

	public static function read(io:BytesReader, version:Version) {
		var planeIndex = io.readUInt16();
		var frontIndex,
			backIndex,
			isfrontleaf = false,
			isfrontsolid = false,
			isbackleaf = false,
			isbacksolid = false;
		if (version.interiorVersion >= 14) {
			frontIndex = io.readInt32();
			backIndex = io.readInt32();
			if ((frontIndex & 0x80000) != 0) {
				frontIndex = (frontIndex & ~0x80000) | 0x8000;
				isfrontleaf = true;
			}
			if ((frontIndex & 0x40000) != 0) {
				frontIndex = (frontIndex & ~0x40000) | 0x4000;
				isfrontsolid = true;
			}
			if ((backIndex & 0x80000) != 0) {
				backIndex = (backIndex & ~0x80000) | 0x8000;
				isbackleaf = true;
			}
			if ((backIndex & 0x40000) != 0) {
				backIndex = (backIndex & ~0x40000) | 0x4000;
				isbacksolid = true;
			}
		} else {
			frontIndex = io.readUInt16();
			backIndex = io.readUInt16();
			if ((frontIndex & 0x8000) != 0) {
				isfrontleaf = true;
			}
			if ((frontIndex & 0x4000) != 0) {
				isfrontsolid = true;
			}
			if ((backIndex & 0x8000) != 0) {
				isbackleaf = true;
			}
			if ((backIndex & 0x4000) != 0) {
				isbacksolid = true;
			}
		}
		return new BSPNode(planeIndex, frontIndex, backIndex, isfrontleaf, isfrontsolid, isbackleaf, isbacksolid);
	}

	public function write(io:BytesWriter, version:Version) {
		io.writeUInt16(this.planeIndex);

		if (version.interiorVersion >= 14) {
			var frontwrite = this.frontIndex;
			var frontwrite = frontIndex;
			if (this.isFrontLeaf) {
				frontwrite &= ~0x8000;
				frontwrite |= 0x80000;
			}
			if (this.isFrontSolid) {
				frontwrite &= ~0x4000;
				frontwrite |= 0x40000;
			}

			io.writeInt32(frontwrite);

			var backwrite = backIndex;
			if (this.isBackLeaf) {
				backwrite &= ~0x8000;
				backwrite |= 0x80000;
			}
			if (this.isBackSolid) {
				backwrite &= ~0x4000;
				backwrite |= 0x40000;
			}

			io.writeInt32(backwrite);
		} else {
			io.writeInt16(this.frontIndex);
			io.writeInt16(this.backIndex);
		}
	}
}
