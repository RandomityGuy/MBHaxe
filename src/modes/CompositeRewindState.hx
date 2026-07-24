package modes;

import rewind.RewindableState;
import rewind.RewindManager;

/** `RewindableState` counterpart to `CompositeMode` - one slot per child mode (`null` where that
	child has no state of its own), so a multi-mode mission (e.g. `"Quota Haste"`) rewinds every
	active mode's state, not just one. */
@:publicFields
class CompositeRewindState implements RewindableState {
	var states:Array<RewindableState>;

	public function new(states:Array<RewindableState>) {
		this.states = states;
	}

	public function clone():RewindableState {
		return new CompositeRewindState(states.map(s -> s != null ? s.clone() : null));
	}

	public function getSize():Int {
		var size = 2; // states.length
		for (s in states) {
			size += 1; // has-state byte
			if (s != null)
				size += s.getSize();
		}
		return size;
	}

	public function serialize(rm:RewindManager, bw:haxe.io.BytesOutput) {
		bw.writeInt16(states.length);
		for (s in states) {
			bw.writeByte(s == null ? 0 : 1);
			if (s != null)
				s.serialize(rm, bw);
		}
	}

	public function deserialize(rm:RewindManager, br:haxe.io.BytesInput) {
		var len = br.readInt16();
		for (i in 0...len) {
			var hasState = br.readByte() != 0;
			if (hasState && states[i] != null)
				states[i].deserialize(rm, br);
		}
	}
}
