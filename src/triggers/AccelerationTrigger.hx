package triggers;

import src.TimeState;
import src.Marble;

class AccelerationTrigger extends Trigger {
	override function onMarbleInside(marble:Marble, timeState:TimeState) {
		var xforceField = this.element.fields.get("xforce");
		var yforceField = this.element.fields.get("yforce");
		var zforceField = this.element.fields.get("zforce");
		var xforce = xforceField != null ? Std.parseFloat(xforceField[0]) : 0;
		var yforce = yforceField != null ? Std.parseFloat(yforceField[0]) : 0;
		var zforce = zforceField != null ? Std.parseFloat(zforceField[0]) : 0;

		marble.velocity.x += -xforce * timeState.dt;
		marble.velocity.y += yforce * timeState.dt;
		marble.velocity.z += zforce * timeState.dt;
	}
}
