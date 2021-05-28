import h3d.Vector;
import hxsl.Types.Matrix;
import h3d.scene.Scene;

enum CameraMode {
	FreeOrbit;
	FixedOrbit;
}

class CameraController {
	var scene:Scene;

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

	public var CameraDistance = 5;
	public var CameraMinDistance = 1;
	public var CameraMaxDistance = 25;
	public var CameraPitch:Float;
	public var CameraYaw:Float;

	public function new(scene:Scene) {
		this.scene = scene;
	}

	function createLookAt() {
		this.view = Matrix.lookAtX(LookAtPoint.sub(Position), Up);
	}
}
