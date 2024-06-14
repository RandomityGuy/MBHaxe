package src;

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

	public var CameraDistance = 2.5;
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

	var _ignoreCursor:Bool = false;

	public function new(marble:Marble) {
		super();
		this.marble = marble;
	}

	public function init(level:MarbleWorld) {
		this.level = level;
		// level.scene.addEventListener(onEvent);
		// Sdl.setRelativeMouseMode(true);
		level.scene.camera.setFovX(Settings.optionsSettings.fovX, Settings.optionsSettings.screenWidth / Settings.optionsSettings.screenHeight);
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
		Window.getInstance().lockPointer((x, y) -> orbit(x, y));
		#if hl
		Cursor.show(false);
		#end
	}

	public function unlockCursor() {
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

		if (deltaposX != 0 || deltaposY != 0) {
			var absX = Math.abs(deltaposX);
			var absY = Math.abs(deltaposY);
			var len = Math.sqrt(deltaposX * deltaposX + deltaposY * deltaposY);
			var max = Math.max(absX, absY);
			if (max > 0.01) {
				deltaposX *= len / max;
				deltaposY *= len / max;
			}
		}
		if (!Settings.controlsSettings.alwaysFreeLook && !Key.isDown(Settings.controlsSettings.freelook)) {
			deltaposY = 0;
		}

		var factor = isTouch ? Util.lerp(1 / 25, 1 / 15,
			Settings.controlsSettings.cameraSensitivity) : Util.lerp(1 / 2500, 1 / 100, Settings.controlsSettings.cameraSensitivity);

		// CameraPitch += deltaposY * factor;
		// CameraYaw += deltaposX * factor;

		nextCameraPitch += deltaposY * factor;
		nextCameraYaw += deltaposX * factor;

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

	public function update(currentTime:Float, dt:Float) {
		// camera.position.set(marblePosition.x, marblePosition.y, marblePosition.z).sub(directionVector.clone().multiplyScalar(2.5));
		// this.level.scene.camera.target = marblePosition.add(cameraVerticalTranslation);
		// camera.position.add(cameraVerticalTranslation);
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

		CameraYaw = Util.lerp(CameraYaw, nextCameraYaw, lerpt);
		CameraPitch = Util.lerp(CameraPitch, nextCameraPitch, lerpt);

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
