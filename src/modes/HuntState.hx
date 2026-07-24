package modes;

import shapes.Gem;
import rewind.RewindableState;
import rewind.RewindManager;

/** Ported from the `mbu-port` branch's `HuntState` (`src/modes/HuntMode.hx`) - covers exactly the
	state that actually needs to survive a rewind: which gem-spawn group is currently active (and
	the `Gem` instances currently spawned in from it), the running score, and the two RNG seeds
	(`rng` picks the next spawn group, `rng2` picks spawn points) so a rewind can't desync which
	gem cluster spawns next. Doesn't cover this port's extra competitive-mode-only fields
	(`expiredGems`, `competitiveTimerStartTicks`, `lastSpawn`'s distance-avoidance tracking) - out
	of scope for the same reason `mbu-port`'s `HuntState` doesn't cover them either (MP-only). */
@:publicFields
class HuntState implements RewindableState {
	var activeGemSpawnGroup:Array<Int>;
	var activeGems:Array<Gem>;
	var points:Int;
	var rngState:Int;
	var rngState2:Int;

	public function new() {}

	public function clone():RewindableState {
		var c = new HuntState();
		c.activeGemSpawnGroup = activeGemSpawnGroup.copy();
		c.activeGems = activeGems.copy();
		c.points = points;
		c.rngState = rngState;
		c.rngState2 = rngState2;
		return c;
	}

	public function getSize():Int {
		var size = 2; // points
		size += 2 + activeGemSpawnGroup.length * 2;
		size += 2 + activeGems.length * 2;
		size += 4; // rngState
		size += 4; // rngState2
		return size;
	}

	public function serialize(rm:RewindManager, bw:haxe.io.BytesOutput) {
		bw.writeUInt16(points);
		bw.writeUInt16(activeGemSpawnGroup.length);
		for (elem in activeGemSpawnGroup) {
			bw.writeUInt16(elem);
		}
		bw.writeUInt16(activeGems.length);
		for (elem in activeGems) {
			bw.writeUInt16(rm.allocGO(elem));
		}
		bw.writeInt32(rngState);
		bw.writeInt32(rngState2);
	}

	public function deserialize(rm:RewindManager, br:haxe.io.BytesInput) {
		points = br.readUInt16();
		activeGemSpawnGroup = [];
		var len = br.readUInt16();
		for (i in 0...len) {
			activeGemSpawnGroup.push(br.readUInt16());
		}
		activeGems = [];
		var len2 = br.readUInt16();
		for (i in 0...len2) {
			var uid = br.readUInt16();
			activeGems.push(cast rm.getGO(uid));
		}
		rngState = br.readInt32();
		rngState2 = br.readInt32();
	}
}
