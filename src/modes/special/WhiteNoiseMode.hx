package modes.special;

import modes.TwoDMode.TwoDState;
import src.InteriorObject;
import src.Marble;
import collision.CollisionInfo;
import rewind.RewindableState;
import rewind.RewindManager;

@:publicFields
class WhiteNoiseState extends TwoDState {
	var smbImpulse:Float;
	var smbUpwards:Float;
	var smbBlockUntil:Float;

	public function new() {
		super();
	}

	public override function clone():RewindableState {
		var c = new WhiteNoiseState();
		c.smbImpulse = smbImpulse;
		c.smbUpwards = smbUpwards;
		c.smbBlockUntil = smbBlockUntil;
		c.active = active;
		c.changesPitch = changesPitch;
		c.lastPressedLR = lastPressedLR;
		c.targetPitch = targetPitch;
		c.targetYaw = targetYaw;
		return c;
	}

	public override function getSize():Int {
		return super.getSize() + 8 + 8 + 8;
	}

	public override function serialize(rm:RewindManager, bw:haxe.io.BytesOutput) {
		super.serialize(rm, bw);
		bw.writeDouble(smbImpulse);
		bw.writeDouble(smbUpwards);
		bw.writeDouble(smbBlockUntil);
	}

	public override function deserialize(rm:RewindManager, br:haxe.io.BytesInput) {
		super.deserialize(rm, br);
		smbImpulse = br.readDouble();
		smbUpwards = br.readDouble();
		smbBlockUntil = br.readDouble();
	}
}

class WhiteNoiseMode extends TwoDMode {
	var buzzsawd = false;

	var smbImpulse:Float = 0;
	var smbUpwards:Float = 0;
	var smbBlockUntil:Float = -1e8;

	public function smbTriggerEnter(impulse:Float, upwards:Float, currentTime:Float) {
		this.smbImpulse = impulse;
		this.smbUpwards = upwards;
		this.smbBlockUntil = currentTime + 0.3;
	}

	public function smbTriggerLeave(currentTime:Float) {
		if (currentTime < this.smbBlockUntil)
			return;
		this.smbImpulse = 0;
		this.smbUpwards = 0;
	}

	var pendingSmbJump:Bool = false;

	public override function onJump(marble:Marble) {
		if (this.smbImpulse != 0 || this.smbUpwards != 0)
			this.pendingSmbJump = true;
	}

	public override function processMaterialContact(marble:src.Marble, contact:CollisionInfo) {
		if (contact.otherObject is InteriorObject) {
			var igo = cast(contact.otherObject, InteriorObject);
			if (igo.interiorFile.indexOf("buzzsaw") != -1) {
				// teleport the marble back to start
				buzzsawd = true;
			}
		}
	}

	public override function update(t:src.TimeState) {
		super.update(t);
		if (this.pendingSmbJump) {
			this.pendingSmbJump = false;
			if (this.smbImpulse != 0)
				this.level.marble.velocity.load(this.level.marble.velocity.add(new h3d.Vector(0, 0, this.smbImpulse)));
			if (this.smbUpwards != 0)
				this.level.marble.velocity.z = Math.max(this.level.marble.velocity.z, this.smbUpwards);
		}
		if (buzzsawd) {
			buzzsawd = false;

			var startPos = this.getSpawnTransform();
			this.level.marble.setMarblePosition(startPos.position.x, startPos.position.y, startPos.position.z);
			this.level.marble.velocity.set(0, 0, 0);
			this.level.marble.omega.set(0, 0, 0);
			this.level.timeState.gameplayClock = 0;
		}
	}

	public override function getRewindState():RewindableState {
		var s = new WhiteNoiseState();
		s.smbImpulse = this.smbImpulse;
		s.smbUpwards = this.smbUpwards;
		s.smbBlockUntil = this.smbBlockUntil;
		return s;
	}

	public override function applyRewindState(state:RewindableState) {
		var s:WhiteNoiseState = cast state;
		this.smbImpulse = s.smbImpulse;
		this.smbUpwards = s.smbUpwards;
		this.smbBlockUntil = s.smbBlockUntil;
	}

	public override function constructRewindState():RewindableState {
		return new WhiteNoiseState();
	}
}
