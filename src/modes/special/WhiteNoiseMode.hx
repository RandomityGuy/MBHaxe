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

/** Ported from `WhiteNoise.mcs`'s `package WhiteNoise` block. `buzzsawd` (the `Marble::onCollide`
	teleport-back-to-checkpoint half) is a same-tick, non-persistent flag - set and consumed within
	the same `update()` call, so it needs no rewind state of its own.

	The `SMBTrigger` half (`Marble::onJump`) is real persistent state though - `smbImpulse`/
	`smbUpwards` stay in effect for as long as the marble remains between trigger volumes, so a
	rewind needs to restore them or a rewound jump could apply the wrong (or no) extra impulse. */
class WhiteNoiseMode extends TwoDMode {
	var buzzsawd = false;

	var smbImpulse:Float = 0;
	var smbUpwards:Float = 0;
	// Mirrors PQ's `client.smbblock` - set true for 300ms after any `SMBTrigger` enter, matching
	// `%user.client.schedule(300, setFieldValue, smbblock, false)`. Suppresses `onLeaveTrigger`'s
	// reset-to-zero while true, so briefly crossing from one `SMBTrigger` volume directly into an
	// overlapping/adjacent one doesn't flicker the effect off in between.
	var smbBlockUntil:Float = -1e8;

	/** Called by `SMBTrigger.onMarbleEnter` - ported from `SMBTrigger::onEnterTrigger`. */
	public function smbTriggerEnter(impulse:Float, upwards:Float, currentTime:Float) {
		this.smbImpulse = impulse;
		this.smbUpwards = upwards;
		this.smbBlockUntil = currentTime + 0.3;
	}

	/** Called by `SMBTrigger.onMarbleLeave` - ported from `SMBTrigger::onLeaveTrigger`. */
	public function smbTriggerLeave(currentTime:Float) {
		if (currentTime < this.smbBlockUntil)
			return;
		this.smbImpulse = 0;
		this.smbUpwards = 0;
	}

	/** Ported from `Marble::onJump`'s `MissionInfo.whiteNoise` branch - gated implicitly by this
		mode only being active on the White Noise mission at all. `applyImpulse` with no offset
		matches the original's `applyImpulse("0 0 0", "0 0" SPC $SMBTrigger)` (through the center,
		so no torque). */
	public override function onJump(marble:Marble) {
		if (this.smbImpulse != 0)
			marble.applyImpulse(new h3d.Vector(0, 0, this.smbImpulse));
		if (this.smbUpwards != 0)
			marble.velocity.z = Math.max(marble.velocity.z, this.smbUpwards);
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
