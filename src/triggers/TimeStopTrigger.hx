package triggers;

import src.TimeState;
import src.Marble;

/** Ported from PQ's `TimeStopTrigger` datablock (`server/scripts/triggers.cs`) - freezes the
	scoring clock (`level.timeStopTriggerCount`, checked in `MarbleWorld.updateTimer`) for as long
	as the marble is inside, using the same overlap-safe counter pattern as `LockPowerupTrigger`/
	`Marble.powerupLockCount` so multiple overlapping volumes don't unfreeze each other early.
	Matches PQ's `Time::stop()`/`Time::start()`: only the scoring clock pauses, not the marble's
	movement or physics. */
class TimeStopTrigger extends Trigger {
	override function onMarbleEnter(marble:Marble, timeState:TimeState) {
		this.level.timeStopTriggerCount++;
	}

	override function onMarbleLeave(marble:Marble, timeState:TimeState) {
		this.level.timeStopTriggerCount--;
		if (this.level.timeStopTriggerCount < 0)
			this.level.timeStopTriggerCount = 0;
	}
}
