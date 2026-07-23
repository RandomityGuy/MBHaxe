package triggers;

import src.TimeState;
import src.Marble;
import mis.MisParser;

class SetVelocityTrigger extends Trigger {
	override function onMarbleEnter(marble:Marble, timeState:TimeState) {
		var velocityField = this.element.fields.get("velocity");
		var velocity = velocityField != null ? MisParser.parseVector3(velocityField[0]) : new h3d.Vector();

		var ignoreX = this.element.fields.get("ignorex") != null && MisParser.parseBoolean(this.element.fields.get("ignorex")[0]);
		var ignoreY = this.element.fields.get("ignorey") != null && MisParser.parseBoolean(this.element.fields.get("ignorey")[0]);
		var ignoreZ = this.element.fields.get("ignorez") != null && MisParser.parseBoolean(this.element.fields.get("ignorez")[0]);

		if (!ignoreX)
			marble.velocity.x = -velocity.x;
		if (!ignoreY)
			marble.velocity.y = velocity.y;
		if (!ignoreZ)
			marble.velocity.z = velocity.z;
	}
}
