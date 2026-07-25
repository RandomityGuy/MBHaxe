package triggers;

import src.TimeState;
import src.Marble;
import mis.MisParser;
import h3d.Vector;
import net.NetPacket.MarbleNetFlags;

class GravityWellTrigger extends Trigger {
	var restoreUp:Map<Marble, Vector> = [];

	function getCenter():Vector {
		var pointField = this.element.fields.get("custompoint");
		if (pointField != null && pointField[0] != null && StringTools.trim(pointField[0]) != "")
			return MisParser.parseVector3(pointField[0]);
		return this.collider.boundingBox.getCenter().toVector();
	}

	function withinRadius(marblePos:Vector, center:Vector):Bool {
		var useRadiusField = this.element.fields.get("useradius");
		var useRadius = useRadiusField != null && MisParser.parseBoolean(useRadiusField[0]);
		if (!useRadius)
			return true;
		var radiusField = this.element.fields.get("radiussize");
		var radius = radiusField != null ? MisParser.parseNumber(radiusField[0]) : 0;
		return marblePos.sub(center).length() <= radius;
	}

	function getDownVector(marblePos:Vector):Vector {
		var axisField = this.element.fields.get("axis");
		var axis = axisField != null ? axisField[0] : "x";
		var invertField = this.element.fields.get("invert");
		var invert = invertField != null && MisParser.parseBoolean(invertField[0]);

		var center = getCenter();
		var off = marblePos.sub(center);
		switch (axis) {
			case "x":
				off.x = 0;
			case "y":
				off.y = 0;
			case "z":
				off.z = 0;
		}

		var direction = invert ? off.clone() : off.multiply(-1);
		direction.normalize();
		return direction;
	}

	function apply(marble:Marble, direction:Vector, timeState:TimeState) {
		if (marble == this.level.marble)
			this.level.setUp(marble, direction, timeState, true);
		else {
			@:privateAccess marble.netFlags |= MarbleNetFlags.GravityChange;
			marble.currentUp.load(direction);
		}
	}

	override function onMarbleEnter(marble:Marble, timeState:TimeState) {
		var restoreField = this.element.fields.get("restoregravity");
		if (restoreField != null && restoreField[0] == "1")
			this.restoreUp.set(marble, marble.currentUp.clone());
	}

	override function onMarbleInside(marble:Marble, timeState:TimeState) {
		var marblePos = marble.getAbsPos().getPosition();
		if (!withinRadius(marblePos, getCenter()))
			return;
		apply(marble, getDownVector(marblePos).multiply(-1), timeState);
	}

	override function onMarbleLeave(marble:Marble, timeState:TimeState) {
		var restoreField = this.element.fields.get("restoregravity");
		if (restoreField == null || restoreField[0] == "")
			return;

		var direction:Vector;
		if (restoreField[0] == "1") {
			direction = this.restoreUp.exists(marble) ? this.restoreUp.get(marble) : new Vector(0, 0, 1);
			this.restoreUp.remove(marble);
		} else {
			var quat = MisParser.parseRotation(restoreField[0]);
			quat.x = -quat.x;
			quat.w = -quat.w;
			direction = new Vector(0, 0, -1);
			direction.transform(quat.toMatrix());
		}

		apply(marble, direction, timeState);
	}
}
