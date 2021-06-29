package src;

import h3d.col.Plane;
import h3d.mat.Material;
import h3d.prim.Cube;
import h3d.scene.Mesh;
import src.Settings;
import hxd.Key;
import src.Util;
import h3d.Quat;
#if hl
import sdl.Cursor;
import sdl.Sdl;
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

enum CameraMode {
	FreeOrbit;
	FixedOrbit;
}

class CameraController extends Object {
	var marble:Marble;
	var level:MarbleWorld;

	var view:Matrix;
	var projection:Matrix;

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

	public var phi:Float;
	public var theta:Float;

	var screenHeight:Int;
	var screenWidth:Int;

	var lastCamPos:Vector;

	public var oob:Bool = false;
	public var finish:Bool = false;

	public function new(marble:Marble) {
		super();
		this.marble = marble;
	}

	public function init(level:MarbleWorld) {
		this.level = level;
		Window.getInstance().addEventTarget(onEvent);
		// level.scene.addEventListener(onEvent);
		// Sdl.setRelativeMouseMode(true);
		#if hl
		this.screenHeight = Sdl.getScreenHeight();
		this.screenWidth = Sdl.getScreenWidth();
		#end
		level.scene.camera.fovY = 60;
		#if hl
		Cursor.show(false);
		#end
	}

	function onEvent(e:Event) {
		switch (e.kind) {
			case EMove:
				if (this.level.cursorLock) {
					orbit(e.relX, e.relY);
					lockCursor();
				}
			default:
		}
	}

	public function lockCursor() {
		#if hl
		Sdl.warpMouseGlobal(cast this.screenWidth / 2, cast this.screenHeight / 2);
		#end
	}

	function orbit(mouseX:Float, mouseY:Float) {
		var window = Window.getInstance();
		var deltaposX = (window.width / 2) - mouseX;
		var deltaposY = (window.height / 2) - mouseY * (Settings.controlsSettings.invertYAxis ? -1 : 1);
		if (!Settings.controlsSettings.alwaysFreeLook && !Key.isDown(Settings.controlsSettings.freelook)) {
			deltaposY = 0;
		}
		var rotX = deltaposX * 0.001 * Settings.controlsSettings.cameraSensitivity * Math.PI * 2;
		var rotY = deltaposY * 0.001 * Settings.controlsSettings.cameraSensitivity * Math.PI * 2;
		CameraYaw -= rotX;
		CameraPitch -= rotY;
		// CameraYaw = Math.PI / 2;
		// CameraPitch = Math.PI / 4;

		if (CameraPitch > Math.PI / 2)
			CameraPitch = Math.PI / 2 - 0.001;
		if (CameraPitch < -Math.PI / 2)
			CameraPitch = -Math.PI / 2 + 0.001;
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

		if (Key.isDown(Settings.controlsSettings.camForward)) {
			CameraPitch += 0.75 * 5 * dt;
		}
		if (Key.isDown(Settings.controlsSettings.camBackward)) {
			CameraPitch -= 0.75 * 5 * dt;
		}
		if (Key.isDown(Settings.controlsSettings.camLeft)) {
			CameraYaw -= 0.75 * 5 * dt;
		}
		if (Key.isDown(Settings.controlsSettings.camRight)) {
			CameraYaw += 0.75 * 5 * dt;
		}

		CameraPitch = Util.clamp(CameraPitch, -Math.PI / 12, Math.PI / 2);

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
		var rayCastOrigin = marblePosition.add(level.currentUp.multiply(marble._radius));
		var rayCastDirection = camera.pos.sub(rayCastOrigin).normalized();
		var results = level.collisionWorld.rayCast(rayCastOrigin, rayCastDirection);
		var rayCastEnd = rayCastOrigin.add(rayCastDirection.multiply(CameraDistance));

		var firstHit = null;
		var minD = 1e8;

		for (result in results) {
			if (result.distance < CameraDistance) {
				var t1 = (result.point.x - rayCastOrigin.x) / (rayCastEnd.x - rayCastOrigin.x);
				if (t1 < 0 || t1 > 1)
					continue;
				var t2 = (result.point.y - rayCastOrigin.y) / (rayCastEnd.y - rayCastOrigin.y);
				if (t2 < 0 || t2 > 1)
					continue;
				var t3 = (result.point.z - rayCastOrigin.z) / (rayCastEnd.z - rayCastOrigin.z);
				if (t3 < 0 || t3 > 1)
					continue;
				if (result.distance < minD) {
					minD = result.distance;
					firstHit = result;
				}
			}
		}

		if (firstHit != null) {
			if (firstHit.distance < CameraDistance) {
				// camera.pos = marblePosition.sub(directionVector.multiply(firstHit.distance * 0.7));
				var plane = new Plane(firstHit.normal.x, firstHit.normal.y, firstHit.normal.z, firstHit.point.dot(firstHit.normal));
				var normal = firstHit.normal.multiply(-1);
				// var position = firstHit.point;

				var projected = plane.project(camera.pos.toPoint());
				var dist = plane.distance(camera.pos.toPoint());
				if (dist < closeness) {
					camera.pos = projected.toVector().add(normal.multiply(-closeness));
				}
			}
		}

		if (oob) {
			camera.pos = lastCamPos;
			camera.target = marblePosition.add(cameraVerticalTranslation);
		}

		if (!oob)
			lastCamPos = camera.pos;
		// camera.target = null;
		// camera.target = targetpos.add(cameraVerticalTranslation);
		// this.x = targetpos.x + directionVec.x;

		// this.y = targetpos.y + directionVec.y;
		// this.z = targetpos.z + directionVec.z;
		// this.level.scene.camera.follow = {pos: this, target: this.marble};
	}
}
