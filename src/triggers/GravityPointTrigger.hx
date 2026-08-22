package triggers;

import src.TimeState;
import src.Marble;
import mis.MisParser;
import h3d.Vector;
import net.NetPacket.MarbleNetFlags;
import mis.MissionElement.MissionElementTrigger;
import src.MarbleWorld;

class GravityPointTrigger extends Trigger {
	var wasWithinRadius:Map<Marble, Bool> = [];

	var useRadius:Bool;
	var radius:Float;
	var invert:Bool;
	var upDownLeave:Bool;
	var customPoint:Vector = null;

	override public function new(element:MissionElementTrigger, level:MarbleWorld) {
		super(element, level);

		var useRadiusField = this.element.fields.get("useradius");
		useRadius = useRadiusField != null && MisParser.parseBoolean(useRadiusField[0]);

		var radiusField = this.element.fields.get("radiussize");
		radius = radiusField != null ? MisParser.parseNumber(radiusField[0]) : 20;

		var invertField = this.element.fields.get("invert");
		invert = invertField != null && MisParser.parseBoolean(invertField[0]);

		var upDownLeaveField = this.element.fields.get("updownleave");
		upDownLeave = upDownLeaveField != null && MisParser.parseBoolean(upDownLeaveField[0]);

		var pointField = this.element.fields.get("custompoint");
		if (pointField != null && pointField[0] != null && StringTools.trim(pointField[0]) != "") {
			customPoint = MisParser.parseVector3(pointField[0]);
			customPoint.x *= -1;
		}
	}

	function getCenter():Vector {
		if (customPoint != null)
			return customPoint;
		return this.collider.boundingBox.getCenter().toVector();
	}

	function withinRadius(marblePos:Vector, center:Vector):Bool {
		if (!useRadius)
			return true;

		return marblePos.sub(center).length() <= radius;
	}

	function getDownVector(marblePos:Vector):Vector {
		var center = getCenter();
		var direction = invert ? marblePos.sub(center) : center.sub(marblePos);
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

	function leaveUpDown(marble:Marble, timeState:TimeState) {
		if (!upDownLeave)
			return;

		var marblePos = marble.getAbsPos().getPosition();
		var center = getCenter();
		var direction = (marblePos.z - center.z) > 0 ? new Vector(0, 0, 1) : new Vector(0, 0, -1);
		apply(marble, direction, timeState);
	}

	override function onMarbleInside(marble:Marble, timeState:TimeState) {
		var marblePos = marble.getAbsPos().getPosition();
		var within = withinRadius(marblePos, getCenter());
		if (!within) {
			if (this.wasWithinRadius.get(marble))
				leaveUpDown(marble, timeState);
			this.wasWithinRadius.set(marble, false);
			return;
		}
		this.wasWithinRadius.set(marble, true);
		apply(marble, getDownVector(marblePos).multiply(-1), timeState);
	}

	override function onMarbleLeave(marble:Marble, timeState:TimeState) {
		if (wasWithinRadius.get(marble)) {
			this.wasWithinRadius.remove(marble);
			leaveUpDown(marble, timeState);
		}
	}

	override function reset() {
		super.reset();
		this.wasWithinRadius = [];
	}
}
