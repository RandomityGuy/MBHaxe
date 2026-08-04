package modes.special;

import src.Marble;
import src.PathedInterior;
import src.TimeState;
import shapes.Gem;
import triggers.PhysModTrigger;

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
