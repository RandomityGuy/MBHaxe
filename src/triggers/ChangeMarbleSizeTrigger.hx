package triggers;

import src.TimeState;
import src.Marble;
import src.DtsObject;
import mis.MisParser;

class ChangeMarbleSizeTrigger extends Trigger {
	override function onMarbleEnter(marble:Marble, timeState:TimeState) {
		var sizeField = this.element.fields.get("mbsize");
		var newRadius = sizeField != null ? Std.parseFloat(sizeField[0]) : 0.2;
		if (Math.isNaN(newRadius))
			newRadius = 0.2;

		var oldRadius = marble._radius;
		if (newRadius == oldRadius)
			return;

		var marbleDts = cast(marble.getChildAt(0), DtsObject);
		marbleDts.scale(newRadius / oldRadius);
		marble._radius = newRadius;
		marble.collider.radius = newRadius;

		var indicatorField = this.element.fields.get("indicator");
		var suppressIndicator = indicatorField != null && MisParser.parseBoolean(indicatorField[0]);
		if (!suppressIndicator && marble == this.level.marble) {
			if (newRadius == 0.2)
				this.level.displayAlert("Your marble has returned to normal.");
			else if (newRadius < oldRadius)
				this.level.displayAlert("Oh dear, your marble has shrunk...");
			else
				this.level.displayAlert("Oh my, your marble has grown!");
		}
	}
}
