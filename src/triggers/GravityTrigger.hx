package triggers;

import src.TimeState;
import src.Marble;
import mis.MisParser;
import h3d.Vector;
import net.NetPacket.MarbleNetFlags;
import mis.MissionElement.MissionElementTrigger;
import src.MarbleWorld;

class GravityTrigger extends Trigger {
	var onLeave:Bool;
	var quat:h3d.Quat;

	override public function new(element:MissionElementTrigger, level:MarbleWorld) {
		super(element, level);

		var onLeaveField = this.element.fields.get("onleave");
		onLeave = onLeaveField != null && MisParser.parseBoolean(onLeaveField[0]);

		var rotField = this.element.fields.get("simrotation");
		quat = rotField != null ? MisParser.parseRotation(rotField[0]) : new h3d.Quat();
		if (rotField != null) {
			quat.x = -quat.x;
			quat.w = -quat.w;
		}
	}

	function getDownVector():Vector {
		var direction = new Vector(0, 0, -1);
		direction.transform(quat.toMatrix());
		return direction;
	}

	override function onMarbleInside(marble:Marble, timeState:TimeState) {
		apply(marble, timeState);
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
		if (!onLeave)
			apply(marble, timeState);
	}

	override function onMarbleLeave(marble:Marble, timeState:TimeState) {
		if (onLeave)
			apply(marble, timeState);
	}
}
