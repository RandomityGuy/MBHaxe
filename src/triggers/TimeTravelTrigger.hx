package triggers;

import src.TimeState;
import src.Marble;

class TimeTravelTrigger extends Trigger {
	override function onMarbleEnter(marble:Marble, timeState:TimeState) {
		var bonusField = this.element.fields.get("timebonus");
		var bonus = bonusField != null ? Std.parseFloat(bonusField[0]) : 5000;
		if (Math.isNaN(bonus))
			bonus = 5000;

		this.level.addBonusTime(bonus / 1000);

		var sign = bonus < 0 ? "-" : "+";
		this.level.displayAlert('${sign}${Math.abs(bonus / 1000)}s');
	}
}
