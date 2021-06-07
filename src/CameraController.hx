package src;

import h3d.Quat;
import sdl.Cursor;
import sdl.Sdl;
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

	public function new(marble:Marble) {
		super();
		this.marble = marble;
	}

	public function init(level:MarbleWorld) {
		this.level = level;
		Window.getInstance().addEventTarget(onEvent);
		// level.scene.addEventListener(onEvent);
		// Sdl.setRelativeMouseMode(true);
		this.screenHeight = Sdl.getScreenHeight();
		this.screenWidth = Sdl.getScreenWidth();
		level.scene.camera.fovY = 60;
		Cursor.show(false);
	}

	function onEvent(e:Event) {
		switch (e.kind) {
			case EMove:
				orbit(e.relX, e.relY);
				Sdl.warpMouseGlobal(cast this.screenWidth / 2, cast this.screenHeight / 2);
			default:
		}
	}

	function orbit(mouseX:Float, mouseY:Float) {
		var window = Window.getInstance();
		var deltaposX = (window.width / 2) - mouseX;
		var deltaposY = (window.height / 2) - mouseY;
		var rotX = deltaposX * 0.001 * CameraSensitivity * Math.PI * 2;
		var rotY = deltaposY * 0.001 * CameraSensitivity * Math.PI * 2;
		CameraYaw -= rotX;
		CameraPitch += rotY;
		// CameraYaw = Math.PI / 2;
		// CameraPitch = Math.PI / 4;

		if (CameraPitch > Math.PI)
			CameraPitch = 3.141;
		if (CameraPitch < 0)
			CameraPitch = 0.001;
	}

	public function update(currentTime:Float, dt:Float) {
		// camera.position.set(marblePosition.x, marblePosition.y, marblePosition.z).sub(directionVector.clone().multiplyScalar(2.5));
		// this.level.scene.camera.target = marblePosition.add(cameraVerticalTranslation);
		// camera.position.add(cameraVerticalTranslation);
		var camera = level.scene.camera;

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

		var up = new Vector(0, 0, 1);
		up.transform(orientationQuat.toMatrix());
		camera.up = up;
		var upVec = new Vector(0, 0, 1);
		var quat = getRotQuat(upVec, up);

		var x = CameraDistance * Math.sin(CameraPitch) * Math.cos(CameraYaw);
		var y = CameraDistance * Math.sin(CameraPitch) * Math.sin(CameraYaw);
		var z = CameraDistance * Math.cos(CameraPitch);

		var directionVec = new Vector(x, y, z);
		directionVec.transform(orientationQuat.toMatrix());

		var targetpos = this.marble.getAbsPos().getPosition();
		this.x = targetpos.x + directionVec.x;
		this.y = targetpos.y + directionVec.y;
		this.z = targetpos.z + directionVec.z;
		this.level.scene.camera.follow = {pos: this, target: this.marble};
	}
}
