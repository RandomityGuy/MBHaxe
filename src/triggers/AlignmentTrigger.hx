package triggers;

import src.TimeState;
import src.Marble;
import mis.MisParser;

class AlignmentTrigger extends Trigger {
	function align(marble:Marble, timeState:TimeState) {
		if (marble != this.level.marble)
			return;

		var pos = marble.getAbsPos().getPosition().clone();
		var center = this.collider.boundingBox.getCenter().toVector();

		var xField = this.element.fields.get("x");
		var xVal = xField != null ? xField[0] : "none";
		if (xVal != "none") {
			pos.x = xVal == "trigger" ? center.x : -MisParser.parseNumber(xVal);
			marble.velocity.x = 0;
			marble.omega.y = 0;
		}

		var yField = this.element.fields.get("y");
		var yVal = yField != null ? yField[0] : "none";
		if (yVal != "none") {
			pos.y = yVal == "trigger" ? center.y : MisParser.parseNumber(yVal);
			marble.velocity.y = 0;
			marble.omega.x = 0;
		}

		var zField = this.element.fields.get("z");
		var zVal = zField != null ? zField[0] : "none";
		if (zVal != "none") {
			pos.z = zVal == "trigger" ? center.z : MisParser.parseNumber(zVal);
			marble.velocity.z = 0;
		}

		marble.prevPos.load(pos);
		marble.setPosition(pos.x, pos.y, pos.z);
		var ct = marble.collider.transform.clone();
		ct.setPosition(pos);
		marble.collider.setTransform(ct);
	}

	override function onMarbleEnter(marble:Marble, timeState:TimeState) {
		align(marble, timeState);
	}

	override function onMarbleInside(marble:Marble, timeState:TimeState) {
		var alwaysOnField = this.element.fields.get("alwayson");
		var alwaysOn = alwaysOnField != null && MisParser.parseBoolean(alwaysOnField[0]);
		if (alwaysOn)
			align(marble, timeState);
	}
}
