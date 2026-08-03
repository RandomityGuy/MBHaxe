package modes.special;

import src.Marble;
import src.PathedInterior;
import src.TimeState;
import shapes.Gem;
import triggers.PhysModTrigger;

/** Ported from `TakeTheGold.mcs`'s `package TTG` block - `GameConnection::onFoundGem` advances the
	`MustChange` `PathedInterior` to its final position and enables the `FinishGravity`
	`PhysModTrigger` once every gem is collected. `FinishGravity.disabled` is derived fresh every
	tick from `level.gemCount == level.totalGems` (both already part of the core rewind snapshot),
	rather than tracked as separate mode state, so a rewind restores it for free the same way
	`FadePlatform` re-derives its visuals from a restored timestamp every frame.

	Real PQ's `GameConnection::respawnPlayer` unconditionally re-disables `FinishGravity` on every
	respawn - since gems never uncollect, that would permanently lock the trigger back off the first
	time the player respawns after already having every gem (nothing ever calls `onFoundGem` again
	to re-enable it). Deliberately not reproduced: deriving straight from gem count means
	`FinishGravity` simply stays enabled once all gems are in, which is what makes the level
	completable at all. */
class TakeTheGoldMode extends TwoDMode {
	public override function onGemPickup(marble:Marble, gem:Gem):Bool {
		var result = super.onGemPickup(marble, gem);
		if (this.level.gemCount == this.level.totalGems) {
			var mustChange = this.level.namedGameObjects.get("mustchange");
			if (mustChange != null)
				cast(mustChange, PathedInterior).setTargetTime(this.level.timeState, 4001 / 1000);
		}
		return result;
	}

	public override function update(t:TimeState) {
		super.update(t);
		var trigger = this.level.namedGameObjects.get("finishgravity");
		if (trigger != null)
			cast(trigger, PhysModTrigger).disabled = this.level.gemCount != this.level.totalGems;
	}
}
