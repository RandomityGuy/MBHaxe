package triggers;

import src.TimeState;
import src.Marble;
import mis.MisParser;

class CancelVelocityTrigger extends Trigger {
	override function onMarbleEnter(marble:Marble, timeState:TimeState) {
		var cancelX = this.element.fields.get("cancelx") != null && MisParser.parseBoolean(this.element.fields.get("cancelx")[0]);
		var cancelY = this.element.fields.get("cancely") != null && MisParser.parseBoolean(this.element.fields.get("cancely")[0]);
		var cancelZ = this.element.fields.get("cancelz") != null && MisParser.parseBoolean(this.element.fields.get("cancelz")[0]);

		if (cancelX)
			marble.velocity.x = 0;
		if (cancelY)
			marble.velocity.y = 0;
		if (cancelZ)
			marble.velocity.z = 0;
	}
}
