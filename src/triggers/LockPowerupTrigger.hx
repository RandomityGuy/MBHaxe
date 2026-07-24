package triggers;

import src.TimeState;
import src.Marble;

/** Ported from PQ's `LockPowerupTrigger` datablock (`server/scripts/triggers.cs`) - locks powerup
	use for as long as the marble is inside, via the same count-based `lockPowerupUse`/
	`unlockPowerupUse` mechanism `Marble`'s ice-freeze handling already uses (so overlapping lock
	reasons don't unlock each other early), and swaps the HUD's powerup icon to the "locked"
	graphic. */
class LockPowerupTrigger extends Trigger {
	override function onMarbleEnter(marble:Marble, timeState:TimeState) {
		marble.lockPowerupUse();
	}

	override function onMarbleLeave(marble:Marble, timeState:TimeState) {
		marble.unlockPowerupUse();
	}
}
