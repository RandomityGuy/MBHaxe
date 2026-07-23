package triggers;

import src.TimeState;
import src.Marble;
import mis.MisParser;
import h3d.Vector;
import net.NetPacket.MarbleNetFlags;

class GravityTrigger extends Trigger {
	function getDownVector():Vector {
		var rotField = this.element.fields.get("simrotation");
		var quat = rotField != null ? MisParser.parseRotation(rotField[0]) : new h3d.Quat();
		var direction = new Vector(0, 0, -1);
		direction.transform(quat.toMatrix());
		return direction;
	}

	function apply(marble:Marble, timeState:TimeState) {
		var direction = getDownVector();
		if (marble == this.level.marble)
			this.level.setUp(marble, direction, timeState, true);
		else {
			@:privateAccess marble.netFlags |= MarbleNetFlags.GravityChange;
			marble.currentUp.load(direction);
		}
	}

	override function onMarbleEnter(marble:Marble, timeState:TimeState) {
		var onLeaveField = this.element.fields.get("onleave");
		var onLeave = onLeaveField != null && MisParser.parseBoolean(onLeaveField[0]);
		if (!onLeave)
			apply(marble, timeState);
	}

	override function onMarbleLeave(marble:Marble, timeState:TimeState) {
		var onLeaveField = this.element.fields.get("onleave");
		var onLeave = onLeaveField != null && MisParser.parseBoolean(onLeaveField[0]);
		if (onLeave)
			apply(marble, timeState);
	}
}
