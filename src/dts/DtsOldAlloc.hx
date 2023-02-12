package dts;

import haxe.io.BytesBuffer;
import haxe.Exception;
import h3d.Matrix;
import dif.math.QuatF;
import dif.math.Box3F;
import dif.math.Point3F;
import dif.math.Point2F;
import dif.io.BytesReader;
import haxe.io.Bytes;

class DtsOldAlloc {
	public var buf:BytesReader;

	public var index32:Int;

	public var index16:Int;

	public var index8:Int;
	public var sourceIndex:Int;

	public var buffer32:haxe.io.Bytes;
	public var buffer16:haxe.io.Bytes;
	public var buffer8:haxe.io.Bytes;

	public var nextGuard:Int = 0;

	public function new(buf:BytesReader, sourceIndex:Int) {
		this.buf = buf;
		this.index32 = 0;
		this.index16 = 0;
		this.index8 = 0;
		this.sourceIndex = sourceIndex;

		this.buffer8 = haxe.io.Bytes.alloc(25000);
		this.buffer16 = haxe.io.Bytes.alloc(25000);
		this.buffer32 = haxe.io.Bytes.alloc(25000);
	}

	public function skip(bytes:Int) {
		this.sourceIndex += bytes;
	}

	public function allocate32(words:Int) {
		this.index32 += words * 4;
	}

	public function allocate16(words:Int) {
		this.index16 += words * 2;
	}

	public function allocate8(words:Int) {
		this.index8 += words * 1;
	}

	public function copyInto32(count:Int) {
		for (i in 0...count) {
			buf.seek(this.sourceIndex + i * 4);
			this.buffer32.setInt32(this.index32 + i * 4, buf.readInt32());
		}

		this.sourceIndex += count * 4;
		this.index32 += count * 4;
	}

	public function copyInto16(count:Int) {
		for (i in 0...count) {
			buf.seek(this.sourceIndex + i * 2);
			this.buffer16.setUInt16(this.index16 + i * 2, buf.readInt16());
		}

		this.sourceIndex += count * 2;
		this.index16 += count * 2;
	}

	public function copyInto8(count:Int) {
		for (i in 0...count) {
			buf.seek(this.sourceIndex + i * 1);
			this.buffer8.set(this.index8 + i * 1, buf.readByte());
		}

		this.sourceIndex += count * 1;
		this.index8 += count * 1;
	}

	public function readS32(storeIndex:Null<Int>) {
		if (storeIndex == -1)
			storeIndex = cast(this.index32 / 4);
		this.buf.seek(this.sourceIndex);
		var val = this.buf.readInt32();
		this.sourceIndex += 4;
		if (storeIndex != null) {
			this.buffer32.setInt32(storeIndex * 4, val);
			if (storeIndex * 4 == this.index32)
				this.index32 += 4;
		}
		return val;
	}

	public function writeS32(value:Int) {
		this.buffer32.setInt32(this.index32, value);
		this.index32 += 4;
	}

	public function writeU8(value:Int) {
		this.buffer8.set(this.index8, value);
		this.index8 += 1;
	}

	public function guard() {
		this.buffer32.setInt32(this.index32, this.nextGuard);
		this.buffer16.setUInt16(this.index16, this.nextGuard);
		this.buffer8.set(this.index8, this.nextGuard);

		this.nextGuard++;
		this.index32 += 4;
		this.index16 += 2;
		this.index8 += 1;
	}

	public function createBuffer() {
		// Make sure they're all a multiple of 4 long
		this.index16 = Math.ceil(this.index16 / 4) * 4;
		this.index8 = Math.ceil(this.index8 / 4) * 4;

		var buffer = haxe.io.Bytes.alloc(this.index32 + this.index16 + this.index8);
		var index = 0;

		for (i in 0...this.index32) {
			buffer.set(index++, this.buffer32.get(i));
		}
		for (i in 0...this.index16) {
			buffer.set(index++, this.buffer16.get(i));
		}
		for (i in 0...this.index8) {
			buffer.set(index++, this.buffer8.get(i));
		}

		return {
			buffer: buffer,
			start16: Std.int(this.index32 / 4),
			start8: Std.int((this.index32 + this.index16) / 4)
		};
	}
}
