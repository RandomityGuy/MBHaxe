package dif;

import dif.io.BytesWriter;
import dif.io.BytesReader;
import dif.math.Point3F;

using dif.WriterExtensions;

@:expose
class AISpecialNode {
	public var name:String;
	public var position:Point3F;

	public function new(name, position) {
		this.name = name;
		this.position = position;
	}

	public static function read(io:BytesReader) {
		return new AISpecialNode(io.readStr(), Point3F.read(io));
	}

	public function write(io:BytesWriter) {
		io.writeStr(this.name);
		this.position.write(io);
	}
}
