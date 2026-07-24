package modes;

import rewind.RewindableState;
import rewind.RewindManager;

@:publicFields
class ConsistencyState implements RewindableState {
	var belowSpeedSince:Float;
	var failing:Bool;
	var failed:Bool;
	var lastSpawnTime:Float;

	public function new() {}

	public function clone():RewindableState {
		var c = new ConsistencyState();
		c.belowSpeedSince = belowSpeedSince;
		c.failing = failing;
		c.failed = failed;
		c.lastSpawnTime = lastSpawnTime;
		return c;
	}

	public function getSize():Int {
		return 8 + 1 + 1 + 8;
	}

	public function serialize(rm:RewindManager, bw:haxe.io.BytesOutput) {
		bw.writeDouble(belowSpeedSince);
		bw.writeByte(failing ? 1 : 0);
		bw.writeByte(failed ? 1 : 0);
		bw.writeDouble(lastSpawnTime);
	}

	public function deserialize(rm:RewindManager, br:haxe.io.BytesInput) {
		belowSpeedSince = br.readDouble();
		failing = br.readByte() != 0;
		failed = br.readByte() != 0;
		lastSpawnTime = br.readDouble();
	}
}
