package src;

import net.Net;
import mis.MisParser;
import h3d.col.Bounds;
import h3d.col.Plane;
import h3d.mat.Material;
import h3d.prim.Cube;
import h3d.scene.Mesh;
import src.Settings;
import hxd.Key;
import src.Util;
import h3d.Quat;
#if hlsdl
import sdl.Cursor;
import sdl.Sdl;
#end
#if hldx
import dx.Cursor;
import dx.Window;
#end
import hxd.Window;
import hxd.Event;
import src.MarbleWorld;
import h3d.scene.Object;
import src.Marble;
import h3d.Camera;
import h3d.Vector;
import hxsl.Types.Matrix;
import h3d.scene.Scene;
import src.Gamepad;
import src.MarbleGame;

enum CameraMode {
	FreeOrbit;
	FixedOrbit;
}

class CameraController extends Object {
	var marble:Marble;
	var level:MarbleWorld;

	public var Position:Vector;
	public var Direction:Vector;
	public var Up:Vector;
	public var LookAtPoint:Vector;
	public var Mode = CameraMode.FixedOrbit;
	public var CameraSensitivity = 0.6;
	public var CameraPanSensitivity = 0.05;
	public var CameraZoomSensitivity = 0.7;
	public var CameraZoomSpeed = 15.0;
	public var CameraZoomDeceleration = 250.0;
	public var CameraSpeed = 15.0;

	var camZoomSpeed:Float;

	public var CameraDistance:Float;
	public var CameraMinDistance = 1;
	public var CameraMaxDistance = 25;
	public var CameraPitch:Float;
	public var CameraYaw:Float;

	public var nextCameraYaw:Float;
	public var nextCameraPitch:Float;

	public var phi:Float;
	public var theta:Float;

	var lastCamPos:Vector;
	var lastVertTranslation:Vector;

	public var oob:Bool = false;
	public var finish:Bool = false;
	public var overview:Bool = false;

	var spectate:Bool = false;
	var spectateMarbleIndex:Int = -1;

	var overviewCenter:Vector;
	var overviewWidth:Vector;
	var overviewHeight:Float;

	var _ignoreCursor:Bool = false;

	public function new(marble:Marble) {
		super();
		this.marble = marble;
	}

	public function init(level:MarbleWorld) {
		this.level = level;
		this.CameraDistance = Settings.optionsSettings.cameraDistance;
		if (this.CameraDistance <= 1 #if js || this.CameraDistance == null #end) {
			this.CameraDistance = 2.5;
			Settings.optionsSettings.cameraDistance = 2.5;
		}
		// level.scene.addEventListener(onEvent);
		// Sdl.setRelativeMouseMode(true);
		level.scene.camera.setFovX(Settings.optionsSettings.fovX, Settings.optionsSettings.screenWidth / Settings.optionsSettings.screenHeight);
		if (!Net.isMP)
			lockCursor();
	}

	public function lockCursor() {
		#if js
		var jsCanvas = @:privateAccess Window.getInstance().canvas;
		jsCanvas.focus();
		var pointercontainer = js.Browser.document.querySelector("#pointercontainer");
		pointercontainer.hidden = true;
		#end
		_ignoreCursor = true;
		if (!Util.isTouchDevice())
			Window.getInstance().lockPointer((x, y) -> orbit(x, y));
		#if hl
		Cursor.show(false);
		#end
	}

	public function unlockCursor() {
		if (!Util.isTouchDevice())
			Window.getInstance().unlockPointer();
		#if hl
		Cursor.show(true);
		#end
		#if js
		var jsCanvas = @:privateAccess Window.getInstance().canvas;
		@:privateAccess Window.getInstance().lockCallback = null; // Fix cursorlock position shit
		var pointercontainer = js.Browser.document.querySelector("#pointercontainer");
		pointercontainer.hidden = false;
		#end
	}

	public function enableSpectate() {
		spectate = true;
		if (@:privateAccess this.level.playGui.setSpectateMenu(true)) {
			if (Util.isTouchDevice()) {
				MarbleGame.instance.touchInput.setSpectatorControls(true);
				MarbleGame.instance.touchInput.setSpectatorControlsVisibility(false);
			}
		}
	}

	public function stopSpectate() {
		spectate = false;
		@:privateAccess this.level.playGui.setSpectateMenu(false);
		if (Util.isTouchDevice()) {
			MarbleGame.instance.touchInput.setSpectatorControls(false);
		}
	}

	public function orbit(mouseX:Float, mouseY:Float, isTouch:Bool = false) {
		if (_ignoreCursor) {
			_ignoreCursor = false;
			return;
		}
		var scaleFactor = 1.0 / Window.getInstance().windowToPixelRatio;
		#if js
		scaleFactor = 1 / js.Browser.window.devicePixelRatio;
		#end

		var deltaposX = mouseX * scaleFactor;
		var deltaposY = mouseY * (Settings.controlsSettings.invertYAxis ? -1 : 1) * scaleFactor;
		if (!Settings.controlsSettings.alwaysFreeLook && !Key.isDown(Settings.controlsSettings.freelook)) {
			deltaposY = 0;
		}

		var factor = isTouch ? Util.lerp(1 / 25, 1 / 15,
			Settings.controlsSettings.cameraSensitivity) : Util.lerp(1 / 1000, 1 / 200, Settings.controlsSettings.cameraSensitivity);

		// CameraPitch += deltaposY * factor;
		// CameraYaw += deltaposX * factor;

		nextCameraPitch = CameraPitch + deltaposY * factor;
		nextCameraYaw = CameraYaw + deltaposX * factor;

		// var rotX = deltaposX * 0.001 * Settings.controlsSettings.cameraSensitivity * Math.PI * 2;
		// var rotY = deltaposY * 0.001 * Settings.controlsSettings.cameraSensitivity * Math.PI * 2;
		// CameraYaw -= rotX;
		// CameraPitch -= rotY;
		// // CameraYaw = Math.PI / 2;
		// // CameraPitch = Math.PI / 4;

		// if (CameraPitch > Math.PI / 2)
		// 	CameraPitch = Math.PI / 2 - 0.001;
		// if (CameraPitch < -Math.PI / 2)
		// 	CameraPitch = -Math.PI / 2 + 0.001;
		// if (CameraPitch > Math.PI)
		// 	CameraPitch = 3.141;
		// if (CameraPitch < 0)
		// 	CameraPitch = 0.001;
	}

	public function startOverview() {
		var worldBounds = new Bounds();
		var center = new Vector(0, 0, 0);
		for (itr in level.interiors) {
			var itrBounds = itr.getBounds();
			worldBounds.add(itrBounds);
			center.load(center.add(itrBounds.getCenter().toVector()));
		}
		if (level.interiors.length == 0) {
			worldBounds.xMin = -1;
			worldBounds.xMax = 1;
			worldBounds.yMin = -1;
			worldBounds.yMax = 1;
			worldBounds.zMin = -1;
			worldBounds.zMax = 1;
		} else
			center.scale(1 / level.interiors.length);

		overviewWidth = new Vector(worldBounds.xMax - worldBounds.xMin, worldBounds.yMax - worldBounds.yMin, worldBounds.zMax - worldBounds.zMin);
		if (level.mission.missionInfo.overviewwidth != null) {
			var parseTest = MisParser.parseVector3(level.mission.missionInfo.overviewwidth);
			if (parseTest != null) {
				overviewWidth = parseTest;
			}
		}
		overviewHeight = level.mission.missionInfo.overviewheight != null ? Std.parseFloat(level.mission.missionInfo.overviewheight) : 0.0;
		overviewCenter = center;

		overview = true;
	}

	public function stopOverview() {
		overview = false;
	}

	function doOverviewCamera(currentTime:Float, dt:Float) {
		var angle = Util.adjustedMod(2 * currentTime * Math.PI / 100.0, 2 * Math.PI);
		var distance = overviewWidth.multiply(2.0 / 3.0);
		var offset = new Vector(Math.sin(angle) * distance.x, Math.cos(angle) * distance.y);
		var position = overviewCenter.add(offset);

		var top = overviewCenter.z + (overviewWidth.z / 2) + overviewHeight;
		position.z = top;

		var posDist = Math.sqrt((position.x - overviewCenter.x) * (position.x - overviewCenter.x)
			+ (position.y - overviewCenter.y) * (position.y - overviewCenter.y));
		var upOffset = Math.tan(0.5) * posDist / 2;
		// position.load(position.add(new Vector(0, 0, upOffset)));

		var camera = level.scene.camera;
		camera.pos.load(position);
		camera.target.load(overviewCenter);
		camera.up.x = 0;
		camera.up.y = 0;
		camera.up.z = 1;
	}

	function doSpectateCamera(currentTime:Float, dt:Float) {
		var camera = level.scene.camera;

		var lerpt = Math.pow(0.5, dt / 0.032); // Math.min(1, 1 - Math.pow(0.6, dt / 0.032)); // hxd.Math.min(1, 1 - Math.pow(0.6, dt * 600));

		var cameraPitchDelta = (Key.isDown(Settings.controlsSettings.camBackward) ? 1 : 0)
			- (Key.isDown(Settings.controlsSettings.camForward) ? 1 : 0)
			+ Gamepad.getAxis(Settings.gamepadSettings.cameraYAxis);
		if (Settings.gamepadSettings.invertYAxis)
			cameraPitchDelta = -cameraPitchDelta;
		nextCameraPitch += 0.75 * 5 * cameraPitchDelta * dt * Settings.gamepadSettings.cameraSensitivity;
		var cameraYawDelta = (Key.isDown(Settings.controlsSettings.camRight) ? 1 : 0) - (Key.isDown(Settings.controlsSettings.camLeft) ? 1 : 0)
			+ Gamepad.getAxis(Settings.gamepadSettings.cameraXAxis);
		if (Settings.gamepadSettings.invertXAxis)
			cameraYawDelta = -cameraYawDelta;
		nextCameraYaw += 0.75 * 5 * cameraYawDelta * dt * Settings.gamepadSettings.cameraSensitivity;

		nextCameraPitch = Math.max(-Math.PI / 2 + Math.PI / 4, Math.min(Math.PI / 2 - 0.0001, nextCameraPitch));

		CameraYaw = nextCameraYaw; // Util.lerp(CameraYaw, nextCameraYaw, lerpt);
		CameraPitch = nextCameraPitch; // Util.lerp(CameraPitch, nextCameraPitch, lerpt);

		CameraPitch = Math.max(-Math.PI / 2 + Math.PI / 4, Math.min(Math.PI / 2 - 0.0001, CameraPitch)); // Util.clamp(CameraPitch, -Math.PI / 12, Math.PI / 2);

		function getRotQuat(v1:Vector, v2:Vector) {
			function orthogonal(v:Vector) {
				var x = Math.abs(v.x);
				var y = Math.abs(v.y);
				var z = Math.abs(v.z);
				var other = x < y ? (x < z ? new Vector(1, 0, 0) : new Vector(0, 0, 1)) : (y < z ? new Vector(0, 1, 0) : new Vector(0, 0, 1));
				return v.cross(other);
			}

			var u = v1.normalized();
			var v = v2.normalized();
			if (u.multiply(-1).equals(v)) {
				var q = new Quat();
				var o = orthogonal(u).normalized();
				q.x = o.x;
				q.y = o.y;
				q.z = o.z;
				q.w = 0;
				return q;
			}
			var half = u.add(v).normalized();
			var q = new Quat();
			q.w = u.dot(half);
			var vr = u.cross(half);
			q.x = vr.x;
			q.y = vr.y;
			q.z = vr.z;
			return q;
		}
		var orientationQuat = level.getOrientationQuat(currentTime);

		if (spectateMarbleIndex == -1) {
			@:privateAccess level.playGui.setSpectateMenuText(0);
			var up = new Vector(0, 0, 1);
			up.transform(orientationQuat.toMatrix());
			var directionVector = new Vector(1, 0, 0);

			var q1 = new Quat();
			q1.initRotateAxis(0, 1, 0, CameraPitch);
			directionVector.transform(q1.toMatrix());
			q1.initRotateAxis(0, 0, 1, CameraYaw);
			directionVector.transform(q1.toMatrix());
			directionVector.transform(orientationQuat.toMatrix());

			var dy = Gamepad.getAxis(Settings.gamepadSettings.moveYAxis) * CameraSpeed * dt;
			var dx = -Gamepad.getAxis(Settings.gamepadSettings.moveXAxis) * CameraSpeed * dt;

			if (Key.isDown(Settings.controlsSettings.forward)) {
				dy += CameraSpeed * dt;
			}
			if (Key.isDown(Settings.controlsSettings.backward)) {
				dy -= CameraSpeed * dt;
			}
			if (Key.isDown(Settings.controlsSettings.left)) {
				dx += CameraSpeed * dt;
			}
			if (Key.isDown(Settings.controlsSettings.right)) {
				dx -= CameraSpeed * dt;
			}

			if (MarbleGame.instance.touchInput.movementInput.pressed) {
				dx = -MarbleGame.instance.touchInput.movementInput.value.x * CameraSpeed * dt;
				dy = -MarbleGame.instance.touchInput.movementInput.value.y * CameraSpeed * dt;
			}

			if ((!Util.isTouchDevice() && Key.isDown(Settings.controlsSettings.powerup))
				|| (Util.isTouchDevice() && MarbleGame.instance.touchInput.powerupButton.pressed)
				|| Gamepad.isDown(Settings.gamepadSettings.powerup)) {
				dx *= 2;
				dy *= 2;
			}

			if (Key.isPressed(Settings.controlsSettings.blast)
				|| (MarbleGame.instance.touchInput.blastbutton.pressed && MarbleGame.instance.touchInput.blastbutton.didPressIt)
				|| Gamepad.isPressed(Settings.gamepadSettings.blast)) {
				var freeMarbleIndex = -1;

				MarbleGame.instance.touchInput.blastbutton.didPressIt = false;

				for (i in 0...level.marbles.length) {
					var marble = level.marbles[i];
					@:privateAccess if ((marble.connection != null && !marble.connection.spectator)) {
						freeMarbleIndex = i;
						break;
					}
				}
				spectateMarbleIndex = freeMarbleIndex;
				MarbleGame.instance.touchInput.setSpectatorControlsVisibility(true);
				return;
			}

			var sideDir = directionVector.cross(up);

			var moveDir = directionVector.multiply(dy).add(sideDir.multiply(dx));
			camera.pos.load(camera.pos.add(moveDir));

			camera.up = up;
			camera.target = camera.pos.add(directionVector);
		} else {
			@:privateAccess level.playGui.setSpectateMenuText(1);
			if (Key.isPressed(Settings.controlsSettings.left)
				|| (MarbleGame.instance.touchInput.leftButton.pressed && MarbleGame.instance.touchInput.leftButton.didPressIt)) {
				MarbleGame.instance.touchInput.leftButton.didPressIt = false;
				spectateMarbleIndex = (spectateMarbleIndex - 1 + level.marbles.length) % level.marbles.length;
				@:privateAccess while (level.marbles[spectateMarbleIndex].connection == null
					|| level.marbles[spectateMarbleIndex].connection.spectator) {
					spectateMarbleIndex = (spectateMarbleIndex - 1 + level.marbles.length) % level.marbles.length;
				}
			}

			if (Key.isPressed(Settings.controlsSettings.right)
				|| (MarbleGame.instance.touchInput.rightButton.pressed && MarbleGame.instance.touchInput.rightButton.didPressIt)) {
				MarbleGame.instance.touchInput.rightButton.didPressIt = false;
				spectateMarbleIndex = (spectateMarbleIndex + 1 + level.marbles.length) % level.marbles.length;
				@:privateAccess while (level.marbles[spectateMarbleIndex].connection == null
					|| level.marbles[spectateMarbleIndex].connection.spectator) {
					spectateMarbleIndex = (spectateMarbleIndex + 1 + level.marbles.length) % level.marbles.length;
				}
			}

			if (Key.isPressed(Settings.controlsSettings.blast)
				|| (MarbleGame.instance.touchInput.blastbutton.pressed && MarbleGame.instance.touchInput.blastbutton.didPressIt)
				|| Gamepad.isPressed(Settings.gamepadSettings.blast)) {
				MarbleGame.instance.touchInput.blastbutton.didPressIt = false;
				spectateMarbleIndex = -1;
				MarbleGame.instance.touchInput.setSpectatorControlsVisibility(false);
				return;
			}
			if (@:privateAccess level.marbles.length <= spectateMarbleIndex) {
				spectateMarbleIndex = -1;
				MarbleGame.instance.touchInput.setSpectatorControlsVisibility(false);
				return;
			}

			var marblePosition = @:privateAccess level.marbles[spectateMarbleIndex].lastRenderPos;
			var up = new Vector(0, 0, 1);
			up.transform(orientationQuat.toMatrix());
			var directionVector = new Vector(1, 0, 0);
			var cameraVerticalTranslation = new Vector(0, 0, 0.3);

			var q1 = new Quat();
			q1.initRotateAxis(0, 1, 0, CameraPitch);
			directionVector.transform(q1.toMatrix());
			cameraVerticalTranslation.transform(q1.toMatrix());
			q1.initRotateAxis(0, 0, 1, CameraYaw);
			directionVector.transform(q1.toMatrix());
			cameraVerticalTranslation.transform(q1.toMatrix());
			directionVector.transform(orientationQuat.toMatrix());
			cameraVerticalTranslation.transform(orientationQuat.toMatrix());
			camera.up = up;
			camera.pos = marblePosition.sub(directionVector.multiply(CameraDistance));
			camera.target = marblePosition.add(cameraVerticalTranslation);

			var closeness = 0.1;
			var rayCastOrigin = marblePosition.add(level.marbles[spectateMarbleIndex].currentUp.multiply(marble._radius));

			var processedShapes = [];
			for (i in 0...3) {
				var rayCastDirection = camera.pos.sub(rayCastOrigin);
				rayCastDirection = rayCastDirection.add(rayCastDirection.normalized().multiply(2));

				var rayCastLen = rayCastDirection.length();

				var results = level.collisionWorld.rayCast(rayCastOrigin, rayCastDirection.normalized(), rayCastLen);

				var firstHit:octree.IOctreeObject.RayIntersectionData = null;
				var firstHitDistance = 1e8;
				for (result in results) {
					if (!processedShapes.contains(result.object)
						&& (firstHit == null || (rayCastOrigin.distance(result.point) < firstHitDistance))) {
						firstHit = result;
						firstHitDistance = rayCastOrigin.distance(result.point);
						processedShapes.push(result.object);
					}
				}

				if (firstHit != null) {
					if (firstHitDistance < CameraDistance) {
						// camera.pos = marblePosition.sub(directionVector.multiply(firstHit.distance * 0.7));
						var plane = new Plane(firstHit.normal.x, firstHit.normal.y, firstHit.normal.z, firstHit.point.dot(firstHit.normal));
						var normal = firstHit.normal.multiply(-1);
						// var position = firstHit.point;

						var projected = plane.project(camera.pos.toPoint());
						var dist = plane.distance(camera.pos.toPoint());

						if (dist >= closeness)
							break;

						camera.pos = projected.toVector().add(normal.multiply(-closeness));

						var forwardVec = marblePosition.sub(camera.pos).normalized();
						var rightVec = camera.up.cross(forwardVec).normalized();
						var upVec = forwardVec.cross(rightVec);

						camera.target = marblePosition.add(upVec.multiply(0.3));
						camera.up = upVec;
						continue;
					}
				}
				break;
			}
		}

		this.setPosition(camera.pos.x, camera.pos.y, camera.pos.z);
	}

	public function update(currentTime:Float, dt:Float) {
		// camera.position.set(marblePosition.x, marblePosition.y, marblePosition.z).sub(directionVector.clone().multiplyScalar(2.5));
		// this.level.scene.camera.target = marblePosition.add(cameraVerticalTranslation);
		// camera.position.add(cameraVerticalTranslation);

		if (overview) {
			doOverviewCamera(currentTime, dt);
			return;
		}

		if (spectate) {
			doSpectateCamera(currentTime, dt);
			return;
		}

		var camera = level.scene.camera;

		var lerpt = hxd.Math.min(1,
			1 - Math.pow(0.6, dt * 600)); // Math.min(1, 1 - Math.pow(0.6, dt / 0.032)); // hxd.Math.min(1, 1 - Math.pow(0.6, dt * 600));

		var cameraPitchDelta = (Key.isDown(Settings.controlsSettings.camBackward) ? 1 : 0)
			- (Key.isDown(Settings.controlsSettings.camForward) ? 1 : 0)
			+ Gamepad.getAxis(Settings.gamepadSettings.cameraYAxis);
		if (Settings.gamepadSettings.invertYAxis)
			cameraPitchDelta = -cameraPitchDelta;
		nextCameraPitch += 0.75 * 5 * cameraPitchDelta * dt * Settings.gamepadSettings.cameraSensitivity;
		var cameraYawDelta = (Key.isDown(Settings.controlsSettings.camRight) ? 1 : 0) - (Key.isDown(Settings.controlsSettings.camLeft) ? 1 : 0)
			+ Gamepad.getAxis(Settings.gamepadSettings.cameraXAxis);
		if (Settings.gamepadSettings.invertXAxis)
			cameraYawDelta = -cameraYawDelta;
		nextCameraYaw += 0.75 * 5 * cameraYawDelta * dt * Settings.gamepadSettings.cameraSensitivity;

		nextCameraPitch = Math.max(-Math.PI / 2 + Math.PI / 4, Math.min(Math.PI / 2 - 0.0001, nextCameraPitch));

		CameraYaw = nextCameraYaw; // Util.lerp(CameraYaw, nextCameraYaw, lerpt);
		CameraPitch = nextCameraPitch; // Util.lerp(CameraPitch, nextCameraPitch, lerpt);

		CameraPitch = Math.max(-Math.PI / 2 + Math.PI / 4, Math.min(Math.PI / 2 - 0.0001, CameraPitch)); // Util.clamp(CameraPitch, -Math.PI / 12, Math.PI / 2);

		function getRotQuat(v1:Vector, v2:Vector) {
			function orthogonal(v:Vector) {
				var x = Math.abs(v.x);
				var y = Math.abs(v.y);
				var z = Math.abs(v.z);
				var other = x < y ? (x < z ? new Vector(1, 0, 0) : new Vector(0, 0, 1)) : (y < z ? new Vector(0, 1, 0) : new Vector(0, 0, 1));
				return v.cross(other);
			}

			var u = v1.normalized();
			var v = v2.normalized();
			if (u.multiply(-1).equals(v)) {
				var q = new Quat();
				var o = orthogonal(u).normalized();
				q.x = o.x;
				q.y = o.y;
				q.z = o.z;
				q.w = 0;
				return q;
			}
			var half = u.add(v).normalized();
			var q = new Quat();
			q.w = u.dot(half);
			var vr = u.cross(half);
			q.x = vr.x;
			q.y = vr.y;
			q.z = vr.z;
			return q;
		}
		var orientationQuat = level.getOrientationQuat(currentTime);

		if (this.finish) {
			// Make the camera spin around slowly
			CameraPitch = Util.lerp(this.level.finishPitch, 0.45,
				Util.clamp((this.level.timeState.currentAttemptTime - this.level.finishTime.currentAttemptTime) / 0.3, 0, 1));
			CameraYaw = this.level.finishYaw - (this.level.timeState.currentAttemptTime - this.level.finishTime.currentAttemptTime) / -1.2;
		}

		if (!this.level.isWatching) {
			if (this.level.isRecording) {
				this.level.replay.recordCameraState(CameraPitch, CameraYaw);
			}
		} else {
			CameraPitch = this.level.replay.currentPlaybackFrame.cameraPitch;
			CameraYaw = this.level.replay.currentPlaybackFrame.cameraYaw;
		}

		var marblePosition = level.marble.getAbsPos().getPosition();
		var up = new Vector(0, 0, 1);
		up.transform(orientationQuat.toMatrix());
		var directionVector = new Vector(1, 0, 0);
		var cameraVerticalTranslation = new Vector(0, 0, 0.3);

		var q1 = new Quat();
		q1.initRotateAxis(0, 1, 0, CameraPitch);
		directionVector.transform(q1.toMatrix());
		cameraVerticalTranslation.transform(q1.toMatrix());
		q1.initRotateAxis(0, 0, 1, CameraYaw);
		directionVector.transform(q1.toMatrix());
		cameraVerticalTranslation.transform(q1.toMatrix());
		directionVector.transform(orientationQuat.toMatrix());
		cameraVerticalTranslation.transform(orientationQuat.toMatrix());
		camera.up = up;
		camera.pos = marblePosition.sub(directionVector.multiply(CameraDistance));
		camera.target = marblePosition.add(cameraVerticalTranslation);

		var closeness = 0.1;
		var rayCastOrigin = marblePosition.add(level.marble.currentUp.multiply(marble._radius));

		var processedShapes = [];
		for (i in 0...3) {
			var rayCastDirection = camera.pos.sub(rayCastOrigin);
			rayCastDirection = rayCastDirection.add(rayCastDirection.normalized().multiply(2));

			var rayCastLen = rayCastDirection.length();

			var results = level.collisionWorld.rayCast(rayCastOrigin, rayCastDirection.normalized(), rayCastLen);

			var firstHit:octree.IOctreeObject.RayIntersectionData = null;
			var firstHitDistance = 1e8;
			for (result in results) {
				if (!processedShapes.contains(result.object)
					&& (firstHit == null || (rayCastOrigin.distance(result.point) < firstHitDistance))) {
					firstHit = result;
					firstHitDistance = rayCastOrigin.distance(result.point);
					processedShapes.push(result.object);
				}
			}

			if (firstHit != null) {
				if (firstHitDistance < CameraDistance) {
					// camera.pos = marblePosition.sub(directionVector.multiply(firstHit.distance * 0.7));
					var plane = new Plane(firstHit.normal.x, firstHit.normal.y, firstHit.normal.z, firstHit.point.dot(firstHit.normal));
					var normal = firstHit.normal.multiply(-1);
					// var position = firstHit.point;

					var projected = plane.project(camera.pos.toPoint());
					var dist = plane.distance(camera.pos.toPoint());

					if (dist >= closeness)
						break;

					camera.pos = projected.toVector().add(normal.multiply(-closeness));

					var forwardVec = marblePosition.sub(camera.pos).normalized();
					var rightVec = camera.up.cross(forwardVec).normalized();
					var upVec = forwardVec.cross(rightVec);

					camera.target = marblePosition.add(upVec.multiply(0.3));
					camera.up = upVec;
					continue;
				}
			}
			break;
		}

		if (oob) {
			camera.pos = lastCamPos;
			camera.target = marblePosition.add(lastVertTranslation);
		}

		if (!oob) {
			lastCamPos = camera.pos;
			lastVertTranslation = cameraVerticalTranslation;
		}

		this.setPosition(camera.pos.x, camera.pos.y, camera.pos.z);
		// camera.target = null;
		// camera.target = targetpos.add(cameraVerticalTranslation);
		// this.x = targetpos.x + directionVec.x;

		// this.y = targetpos.y + directionVec.y;
		// this.z = targetpos.z + directionVec.z;
		// this.level.scene.camera.follow = {pos: this, target: this.marble};
	}
}
