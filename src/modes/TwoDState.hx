package modes;

import rewind.RewindableState;
import rewind.RewindManager;

@:publicFields
class TwoDState implements RewindableState {
	var active:Bool;
	var targetYaw:Float;

	public function new() {}

	public function clone():RewindableState {
		var c = new TwoDState();
		c.active = active;
		c.targetYaw = targetYaw;
		return c;
	}

	public function getSize():Int {
		return 1 + 8;
	}

	public function serialize(rm:RewindManager, bw:haxe.io.BytesOutput) {
		bw.writeByte(active ? 1 : 0);
		bw.writeDouble(targetYaw);
	}

	public function deserialize(rm:RewindManager, br:haxe.io.BytesInput) {
		active = br.readByte() != 0;
		targetYaw = br.readDouble();
	}
}
