package triggers;

import src.TimeState;
import src.Marble;
import mis.MisParser;
import h3d.Vector;
import net.NetPacket.MarbleNetFlags;
import mis.MissionElement.MissionElementTrigger;
import src.MarbleWorld;

class GravityWellTrigger extends Trigger {
	var restoreUp:Map<Marble, Vector> = [];
	var wasWithinRadius:Map<Marble, Bool> = [];

	var useRadius:Bool;
	var radius:Float;
	var axis:String;
	var invert:Bool;
	var restoreGravity:Bool;
	var restoreGravityQuat:h3d.Quat;
	var customPoint:Vector;

	override public function new(element:MissionElementTrigger, level:MarbleWorld) {
		super(element, level);

		var useRadiusField = this.element.fields.get("useradius");
		useRadius = useRadiusField != null && MisParser.parseBoolean(useRadiusField[0]);

		var radiusField = this.element.fields.get("radiussize");
		radius = radiusField != null ? MisParser.parseNumber(radiusField[0]) : 0;

		var axisField = this.element.fields.get("axis");
		axis = axisField != null ? axisField[0] : "x";
		var invertField = this.element.fields.get("invert");
		invert = invertField != null && MisParser.parseBoolean(invertField[0]);

		var pointField = this.element.fields.get("custompoint");
		if (pointField != null && pointField[0] != null && StringTools.trim(pointField[0]) != "") {
			customPoint = MisParser.parseVector3(pointField[0]);
			customPoint.x *= -1;
		}

		var restoreField = this.element.fields.get("restoregravity");
		restoreGravity = restoreField[0] == "1";
		if (!restoreGravity) {
			restoreGravityQuat = MisParser.parseRotation(restoreField[0]);
			restoreGravityQuat.x = -restoreGravityQuat.x;
			restoreGravityQuat.w = -restoreGravityQuat.w;
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

	function leaveRestoreGravity(marble:Marble, timeState:TimeState) {
		if (!restoreGravity && restoreGravityQuat == null)
			return;

		var direction:Vector;
		if (restoreGravity) {
			direction = this.restoreUp.exists(marble) ? this.restoreUp.get(marble) : new Vector(0, 0, 1);
			this.restoreUp.remove(marble);
		} else {
			direction = new Vector(0, 0, -1);
			direction.transform(restoreGravityQuat.toMatrix());
		}

		apply(marble, direction, timeState);
	}

	override function onMarbleInside(marble:Marble, timeState:TimeState) {
		var marblePos = marble.getAbsPos().getPosition();
		var within = withinRadius(marblePos, getCenter());
		if (!within) {
			if (this.wasWithinRadius.get(marble) == true)
				leaveRestoreGravity(marble, timeState);
			this.wasWithinRadius.set(marble, false);
			return;
		}
		if (this.wasWithinRadius.get(marble) != true) {
			if (restoreGravity)
				this.restoreUp.set(marble, marble.currentUp.clone());
		}
		this.wasWithinRadius.set(marble, true);
		apply(marble, getDownVector(marblePos).multiply(-1), timeState);
	}

	override function onMarbleLeave(marble:Marble, timeState:TimeState) {
		this.wasWithinRadius.remove(marble);
		leaveRestoreGravity(marble, timeState);
	}

	override function reset() {
		super.reset();
		this.wasWithinRadius = [];
		this.restoreUp = [];
	}
}
