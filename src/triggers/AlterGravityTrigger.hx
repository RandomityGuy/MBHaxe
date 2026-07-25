package triggers;

import src.TimeState;
import src.Marble;
import mis.MisParser;
import h3d.Vector;
import src.Util;
import net.NetPacket.MarbleNetFlags;

class AlterGravityTrigger extends Trigger {
	function axisIndex(name:String):Int {
		return switch (name) {
			case "y": 1;
			case "z": 2;
			default: 0;
		}
	}

	function getDownVector(marblePos:Vector):Vector {
		var measureAxisField = this.element.fields.get("measureaxis");
		var measureAxis = axisIndex(measureAxisField != null ? measureAxisField[0] : "x");
		var gravityAxisField = this.element.fields.get("gravityaxis");
		var gravityAxis = axisIndex(gravityAxisField != null ? gravityAxisField[0] : "y");
		var flipField = this.element.fields.get("flipmeasure");
		var flip = flipField != null && MisParser.parseBoolean(flipField[0]);
		var startField = this.element.fields.get("startinggravityrot");
		var startRot = startField != null ? MisParser.parseNumber(startField[0]) : 0;
		var endField = this.element.fields.get("endinggravityrot");
		var endRot = endField != null ? MisParser.parseNumber(endField[0]) : 720;

		var box = this.collider.boundingBox;
		var lo = [box.xMin, box.yMin, box.zMin][measureAxis];
		var hi = [box.xMax, box.yMax, box.zMax][measureAxis];
		var m = [marblePos.x, marblePos.y, marblePos.z][measureAxis];

		var t = hi > lo ? (m - lo) / (hi - lo) : 0;
		if (flip)
			t = 1 - t;
		t = Util.clamp(t, 0, 1);

		var rot = startRot + (endRot - startRot) * t;

		var rotationStr = '${gravityAxis == 0 ? 1 : 0} ${gravityAxis == 1 ? 1 : 0} ${gravityAxis == 2 ? 1 : 0} $rot';
		var quat = MisParser.parseRotation(rotationStr);
		quat.x = -quat.x;
		quat.w = -quat.w;
		var direction = new Vector(0, 0, -1);
		direction.transform(quat.toMatrix());
		return direction.multiply(-1);
	}

	function apply(marble:Marble, timeState:TimeState) {
		var direction = getDownVector(marble.getAbsPos().getPosition());
		if (marble == this.level.marble)
			this.level.setUp(marble, direction, timeState, true);
		else {
			@:privateAccess marble.netFlags |= MarbleNetFlags.GravityChange;
			marble.currentUp.load(direction);
		}
	}

	override function onMarbleInside(marble:Marble, timeState:TimeState) {
		apply(marble, timeState);
	}
}
