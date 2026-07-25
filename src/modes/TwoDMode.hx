package modes;

import mis.MisParser;
import src.Marble;
import src.MarbleWorld;
import src.Settings;
import rewind.RewindableState;

/** Ported from PQ's `modes/2d.cs` - locks the camera to a fixed yaw plane (so mouse-look can't
	rotate off it, matching the real `Physics::registerLayer("2d", "cameraSpeedMultiplier 0")`
	layer's only effect) and widens the FOV to 90 while active. A mission-wide plane comes from
	`MissionInfo.cameraplane`/`invertcameraplane`/`initialcameradistance`; `TDTrigger`/`StopTDTrigger`
	(the two 2D-owned triggers) can independently activate/deactivate a possibly-different plane
	per region regardless of whether the mission-wide mode is active.

	`camDistance`/`pitchDegrees` use `Math.NaN` as the "not set" sentinel (both are otherwise
	always-finite values - camera distance can't naturally be NaN, nor can an authored pitch in
	degrees) rather than a nullable float. */
class TwoDMode extends NullMode {
	var hasMissionPlane:Bool = false;
	var missionYaw:Float = 0;
	var missionInverted:Bool = false;
	var missionCamDistance:Float = Math.NaN;

	var active:Bool = false;
	var targetYaw:Float = 0;

	var targetPitch:Float = 0;
	var changesPitch = false;

	public function new(level:MarbleWorld) {
		super(level);
	}

	/** Ported from `Mode_2d::detectCamera` - `xz`/`yz` are fixed yaw values, anything else is a raw
		degree value; `invert` adds a half-turn on top. */
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
			targetPitch = MisParser.parseNumber(level.mission.missionInfo.targetpitch);
		this.activate(this.missionYaw, this.missionCamDistance, this.changesPitch, targetPitch);
	}

	override function onRespawn(marble:Marble) {
		if (this.hasMissionPlane)
			this.activate(this.missionYaw, this.missionCamDistance, this.changesPitch, targetPitch);
	}

	/** Ported from `GameConnection::start2D`. */
	public function activate(yaw:Float, camDistance:Float, changesPitch:Bool, pitchDegrees:Float) {
		this.active = true;
		this.targetYaw = yaw;
		this.targetPitch = pitchDegrees;

		level.marble.camera.CameraYaw = yaw + Math.PI / 2;
		level.marble.camera.nextCameraYaw = yaw + Math.PI / 2;
		if (!Math.isNaN(camDistance))
			level.marble.camera.CameraDistance = camDistance;
		if (changesPitch) {
			var pitch = pitchDegrees * Math.PI / 180;
			level.marble.camera.CameraPitch = pitch;
			level.marble.camera.nextCameraPitch = pitch;
		} else {
			this.targetPitch = level.marble.camera.CameraPitch;
		}
		level.scene.camera.setFovX(90, Settings.optionsSettings.screenWidth / Settings.optionsSettings.screenHeight);
	}

	/** Ported from `GameConnection::stop2D`. */
	public function deactivate() {
		if (!this.active)
			return;
		this.active = false;
		level.scene.camera.setFovX(getBaseFov(), Settings.optionsSettings.screenWidth / Settings.optionsSettings.screenHeight);
	}

	/** The FOV to fall back to once 2D deactivates - mirrors `CameraController.init`'s own
		`MissionInfo.cameraFov` override so leaving a `TDTrigger` doesn't silently drop back to the
		player's own FOV setting on a mission that overrides it. */
	function getBaseFov():Float {
		var fovField = level.mission.missionInfo.camerafov;
		return fovField != null && fovField != "" ? MisParser.parseNumber(fovField) : Settings.optionsSettings.fovX;
	}

	override function update(t:src.TimeState) {
		if (!this.active)
			return;
		// Re-lock every tick - counters any mouse-look yaw drift accumulated by `orbit()` between
		// ticks, matching the effect of the real `cameraSpeedMultiplier 0` layer.
		level.marble.camera.CameraYaw = this.targetYaw + Math.PI / 2;
		level.marble.camera.nextCameraYaw = this.targetYaw + Math.PI / 2;
		level.marble.camera.CameraPitch = this.targetPitch;
		level.marble.camera.nextCameraPitch = this.targetPitch;
	}

	override function getRewindState():RewindableState {
		var s = new TwoDState();
		s.active = this.active;
		s.targetYaw = this.targetYaw;
		s.targetPitch = this.targetPitch;
		s.changesPitch = this.changesPitch;
		return s;
	}

	override function applyRewindState(state:RewindableState) {
		var s:TwoDState = cast state;
		this.active = s.active;
		this.targetYaw = s.targetYaw;
		this.targetPitch = s.targetPitch;
		this.changesPitch = s.changesPitch;
		// Re-derive the FOV side effect rather than tracking it separately.
		level.scene.camera.setFovX(this.active ? 90 : getBaseFov(), Settings.optionsSettings.screenWidth / Settings.optionsSettings.screenHeight);
	}

	override function constructRewindState():RewindableState {
		return new TwoDState();
	}
}
