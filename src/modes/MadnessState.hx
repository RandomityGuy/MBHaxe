package modes;

import rewind.RewindableState;
import rewind.RewindManager;

@:publicFields
class MadnessState implements RewindableState {
	var gotAllGems:Bool;
	var score:Int;

	public function new() {}

	public function clone():RewindableState {
		var c = new MadnessState();
		c.gotAllGems = gotAllGems;
		c.score = score;
		return c;
	}

	public function getSize():Int {
		return 1 + 2; // gotAllGems + score
	}

	public function serialize(rm:RewindManager, bw:haxe.io.BytesOutput) {
		bw.writeByte(gotAllGems ? 1 : 0);
		bw.writeInt16(score);
	}

	public function deserialize(rm:RewindManager, br:haxe.io.BytesInput) {
		gotAllGems = br.readByte() != 0;
		score = br.readInt16();
	}
}
