package triggers;

import src.TimeState;
import src.Marble;
import mis.MisParser;
import h3d.Vector;
import net.NetPacket.MarbleNetFlags;

class GravityPointTrigger extends Trigger {
	// Ported from `gravity.cs`'s `Gravity::update()`/`GravityPointTrigger_getDistance()` -
	// real PQ's radius check happens independently of the trigger's actual AABB volume (which just
	// controls whether the marble is a candidate at all): a marble can be well inside the AABB but
	// outside `RadiusSize`, at which point this trigger reports itself out of range and effectively
	// "leaves" (its `onPlayerLeave`-equivalent, `UpDownLeave`, fires) even though it never actually
	// exited the trigger volume. Tracks per-marble since multiple marbles can be inside/outside the
	// radius independently of each other.
	var wasWithinRadius:Map<Marble, Bool> = [];

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
		var radius = radiusField != null ? MisParser.parseNumber(radiusField[0]) : 20;
		return marblePos.sub(center).length() <= radius;
	}

	function getDownVector(marblePos:Vector):Vector {
		var invertField = this.element.fields.get("invert");
		var invert = invertField != null && MisParser.parseBoolean(invertField[0]);

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
		var upDownLeaveField = this.element.fields.get("updownleave");
		var upDownLeave = upDownLeaveField != null && MisParser.parseBoolean(upDownLeaveField[0]);
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
			// Radius-exit while still inside the AABB - real source's `getDistance` reports this
			// trigger out of range the instant this happens, not just on real AABB exit.
			if (this.wasWithinRadius.get(marble) == true)
				leaveUpDown(marble, timeState);
			this.wasWithinRadius.set(marble, false);
			return;
		}
		this.wasWithinRadius.set(marble, true);
		apply(marble, getDownVector(marblePos).multiply(-1), timeState);
	}

	override function onMarbleLeave(marble:Marble, timeState:TimeState) {
		this.wasWithinRadius.remove(marble);
		leaveUpDown(marble, timeState);
	}

	override function reset() {
		super.reset();
		this.wasWithinRadius = [];
	}
}
