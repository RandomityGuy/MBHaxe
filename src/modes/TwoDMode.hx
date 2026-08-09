package modes;

import hxd.Key;
import mis.MisParser;
import src.Marble;
import src.MarbleWorld;
import src.Settings;
import rewind.RewindableState;
import rewind.RewindManager;
import src.MarbleGame;
import net.Move;

@:publicFields
class TwoDState implements RewindableState {
	var active:Bool;
	var targetYaw:Float;
	var targetPitch:Float;
	var changesPitch:Bool;
	var lastPressedLR:Bool;

	public function new() {}

	public function clone():RewindableState {
		var c = new TwoDState();
		c.active = active;
		c.targetYaw = targetYaw;
		c.targetPitch = targetPitch;
		c.changesPitch = changesPitch;
		c.lastPressedLR = lastPressedLR;
		return c;
	}

	public function getSize():Int {
		return 1 + 8 + 8 + 1 + 1;
	}

	public function serialize(rm:RewindManager, bw:haxe.io.BytesOutput) {
		bw.writeByte(active ? 1 : 0);
		bw.writeDouble(targetYaw);
		bw.writeDouble(targetPitch);
		bw.writeByte(changesPitch ? 1 : 0);
		bw.writeByte(lastPressedLR ? 1 : 0);
	}

	public function deserialize(rm:RewindManager, br:haxe.io.BytesInput) {
		active = br.readByte() != 0;
		targetYaw = br.readDouble();
		targetPitch = br.readDouble();
		changesPitch = br.readByte() != 0;
		lastPressedLR = br.readByte() != 0;
	}
}

class TwoDMode extends NullMode {
	var hasMissionPlane:Bool = false;
	var missionYaw:Float = 0;
	var missionInverted:Bool = false;
	var missionCamDistance:Float = Math.NaN;

	var active:Bool = false;
	var targetYaw:Float = 0;

	var targetPitch:Float = 0;
	var changesPitch = false;

	public var lastPressedLR:Bool = false;

	public function new(level:MarbleWorld) {
		super(level);
	}

	public static function planeToYaw(plane:String, invert:Bool):Float {
		var yaw = switch (plane.toLowerCase()) {
			case "xz": 0.0;
			case "yz": Math.PI / 2;
			default: Std.parseFloat(plane) * Math.PI / 180;
		}
		if (invert)
			yaw += Math.PI;
		return yaw;
	}

	override function onMissionLoad() {
		var plane = level.mission.missionInfo.cameraplane;
		if (plane == null || plane == "") {
			this.hasMissionPlane = false;
			return;
		}
		this.hasMissionPlane = true;
		this.missionInverted = level.mission.missionInfo.invertcameraplane != null
			&& mis.MisParser.parseBoolean(level.mission.missionInfo.invertcameraplane);
		this.missionYaw = planeToYaw(plane, this.missionInverted);
		var distField = level.mission.missionInfo.initialcameradistance;
		this.missionCamDistance = distField != null && distField != "" ? Std.parseFloat(distField) : Math.NaN;
		this.changesPitch = level.mission.missionInfo.targetpitch != null
			&& level.mission.missionInfo.targetpitch.toLowerCase() != "nochange";
		if (this.changesPitch)
			targetPitch = hxd.Math.degToRad(MisParser.parseNumber(level.mission.missionInfo.targetpitch));
		this.activate(this.missionYaw, this.missionCamDistance, this.changesPitch, targetPitch);
	}

	override function onRespawn(marble:Marble) {
		if (this.hasMissionPlane)
			this.activate(this.missionYaw, this.missionCamDistance, this.changesPitch, targetPitch);
	}

	public function activate(yaw:Float, camDistance:Float, changesPitch:Bool, pitch:Float) {
		this.active = true;
		this.targetYaw = yaw;
		this.targetPitch = pitch;

		level.marble.camera.CameraYaw = yaw + Math.PI / 2;
		level.marble.camera.nextCameraYaw = yaw + Math.PI / 2;
		if (!Math.isNaN(camDistance))
			level.marble.camera.CameraDistance = camDistance;
		if (changesPitch) {
			var pitch = pitch;
			level.marble.camera.CameraPitch = pitch;
			level.marble.camera.nextCameraPitch = pitch;
		} else {
			this.targetPitch = level.marble.camera.CameraPitch;
		}
		level.scene.camera.setFovX(90, Settings.optionsSettings.screenWidth / Settings.optionsSettings.screenHeight);
	}

	public function deactivate() {
		if (!this.active)
			return;
		this.active = false;
		level.scene.camera.setFovX(getBaseFov(), Settings.optionsSettings.screenWidth / Settings.optionsSettings.screenHeight);
	}

	function getBaseFov():Float {
		var fovField = level.mission.missionInfo.camerafov;
		return fovField != null && fovField != "" ? MisParser.parseNumber(fovField) : Settings.optionsSettings.fovX;
	}

	override function processMove(marble:Marble, move:Move) {
		if (this.active)
			move.d.x = 0;
	}

	override function update(t:src.TimeState) {
		if (!this.active)
			return;
		level.marble.camera.CameraYaw = this.targetYaw + Math.PI / 2;
		level.marble.camera.nextCameraYaw = this.targetYaw + Math.PI / 2;
		level.marble.camera.CameraPitch = this.targetPitch;
		level.marble.camera.nextCameraPitch = this.targetPitch;

		if (Key.isDown(Settings.controlsSettings.left)) {
			lastPressedLR = false;
		}
		if (Key.isDown(Settings.controlsSettings.right)) {
			lastPressedLR = true;
		}

		if (MarbleGame.instance.touchInput.movementInput.pressed) {
			lastPressedLR = MarbleGame.instance.touchInput.movementInput.value.x > 0;
		}
	}

	override function getRewindState():RewindableState {
		var s = new TwoDState();
		s.active = this.active;
		s.targetYaw = this.targetYaw;
		s.targetPitch = this.targetPitch;
		s.changesPitch = this.changesPitch;
		s.lastPressedLR = this.lastPressedLR;
		return s;
	}

	override function applyRewindState(state:RewindableState) {
		var s:TwoDState = cast state;
		this.active = s.active;
		this.targetYaw = s.targetYaw;
		this.targetPitch = s.targetPitch;
		this.changesPitch = s.changesPitch;
		this.lastPressedLR = s.lastPressedLR;
		level.scene.camera.setFovX(this.active ? 90 : getBaseFov(), Settings.optionsSettings.screenWidth / Settings.optionsSettings.screenHeight);
	}

	override function constructRewindState():RewindableState {
		return new TwoDState();
	}
}
