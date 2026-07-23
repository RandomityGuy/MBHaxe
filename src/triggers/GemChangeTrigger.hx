package triggers;

import src.TimeState;
import src.Marble;

class GemChangeTrigger extends Trigger {
	override function onMarbleEnter(marble:Marble, timeState:TimeState) {
		var bonusField = this.element.fields.get("gembonus");
		var bonus = bonusField != null ? Std.parseInt(bonusField[0]) : -1;
		if (bonus == null || Math.isNaN(bonus))
			bonus = -1;

		if (bonus < 0 && this.level.gemCount < Math.abs(bonus)) {
			this.level.gemCount = 0;
		} else {
			this.level.gemCount += bonus;
		}
		@:privateAccess this.level.playGui.formatGemCounter(this.level.gemCount, this.level.totalGems);

		var sign = bonus > 0 ? "+" : "";
		this.level.displayAlert('${sign}${bonus} gem${Math.abs(bonus) == 1 ? "" : "s"}');
	}
}
