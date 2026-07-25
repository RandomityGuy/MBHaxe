package modes;

import rewind.RewindableState;
import rewind.RewindManager;

@:publicFields
class TwoDState implements RewindableState {
	var active:Bool;
	var targetYaw:Float;
	var targetPitch:Float;
	var changesPitch:Bool;

	public function new() {}

	public function clone():RewindableState {
		var c = new TwoDState();
		c.active = active;
		c.targetYaw = targetYaw;
		c.targetPitch = targetPitch;
		c.changesPitch = changesPitch;
		return c;
	}

	public function getSize():Int {
		return 1 + 8 + 8 + 1;
	}

	public function serialize(rm:RewindManager, bw:haxe.io.BytesOutput) {
		bw.writeByte(active ? 1 : 0);
		bw.writeDouble(targetYaw);
		bw.writeDouble(targetPitch);
		bw.writeByte(changesPitch ? 1 : 0);
	}

	public function deserialize(rm:RewindManager, br:haxe.io.BytesInput) {
		active = br.readByte() != 0;
		targetYaw = br.readDouble();
		targetPitch = br.readDouble();
		changesPitch = br.readByte() != 0;
	}
}
