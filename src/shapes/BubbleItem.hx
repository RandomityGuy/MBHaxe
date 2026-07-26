package shapes;

import mis.MissionElement.MissionElementItem;
import src.TimeState;
import src.Marble;
import src.MarbleWorld;
import mis.MisParser;

/** Ported from PQ's `BubbleItem` (`server/scripts/powerups.cs`) - unlike every other `PowerUp`,
	picking one up doesn't occupy the single `heldPowerup` inventory slot at all; it just banks
	time directly onto the marble (`Marble.setBubbleTime`, mirroring `client.setBubbleTime`), so the
	slot stays free for another one-shot powerup even while bubble time is banked. `use()` is
	consequently never actually invoked through the normal `heldPowerup.use()` path - the marble's
	own `updateBubble` (hold-to-use, gated on `Move.powerupHeld`) drives activation instead. */
class BubbleItem extends PowerUp {
	var time:Float;
	var infinite:Bool;

	public function new(element:MissionElementItem) {
		super(element);
		this.dtsPath = "data/shapes_pq/gameplay/powerups/bubble.dts";
		this.identifier = "BubbleItem";
		this.pickUpName = "Bubble PowerUp";
		this.radarIndex = 14;

		var timeField = element.fields.get("time");
		this.time = timeField != null && timeField[0] != "" ? MisParser.parseNumber(timeField[0]) / 1000 : 5;
		var infiniteField = element.fields.get("infinite");
		this.infinite = infiniteField != null && MisParser.parseBoolean(infiniteField[0]);
	}

	public function pickUp(marble:Marble):Bool {
		// Matches `BubbleItem::onPickup`'s guard - no sense picking up another one while already
		// infinite.
		if (marble.bubbleInfinite)
			return false;
		// "Can't bubble with fireball" - one-directional (Fireball pickup cancels Bubble, but not
		// vice versa; see `Marble.activateFireball`).
		if (marble.fireball)
			return false;
		marble.setBubbleTime(this.time, this.infinite);
		return true;
	}

	public function use(marble:Marble, timeState:TimeState):Bool {
		return true;
	}
}
