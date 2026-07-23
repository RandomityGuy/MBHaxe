package triggers;

import src.TimeState;
import src.Marble;
import mis.MisParser;

class CameraTrigger extends Trigger {
	override function onMarbleEnter(marble:Marble, timeState:TimeState) {
		if (marble != this.level.marble)
			return;

		var useRadians = this.element.fields.get("useradians") == null || MisParser.parseBoolean(this.element.fields.get("useradians")[0]);

		var pitchField = this.element.fields.get("pitch");
		if (pitchField != null && pitchField[0] != "NoChange") {
			var pitch = Std.parseFloat(pitchField[0]);
			if (!useRadians)
				pitch = pitch * Math.PI / 180;
			marble.camera.CameraPitch = pitch;
			marble.camera.nextCameraPitch = pitch;
		}

		var yawField = this.element.fields.get("yaw");
		if (yawField != null && yawField[0] != "NoChange") {
			var yaw = Std.parseFloat(yawField[0]);
			if (!useRadians)
				yaw = yaw * Math.PI / 180;
			yaw = -yaw;
			marble.camera.CameraYaw = yaw;
			marble.camera.nextCameraYaw = yaw;
		}
	}
}
