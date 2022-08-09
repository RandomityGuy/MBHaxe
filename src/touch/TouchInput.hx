package touch;

import gui.GuiControl;
import src.MarbleWorld;
import h3d.Vector;
import src.Settings;

enum TouchState {
	Pressed;
	Move;
	Release;
}

class Touch {
	public var state:TouchState;
	public var position:Vector;
	public var deltaPosition:Vector;
	public var identifier:Int;

	public function new(state:TouchState, position:Vector, deltaPos:Vector, id:Int) {
		this.state = state;
		this.position = position;
		this.deltaPosition = deltaPos;
		this.identifier = id;
	}
}

class TouchEventState {
	public var changedTouches:Array<Touch>;

	public function new() {
		this.changedTouches = [];
	}
}

class TouchInput {
	var cameraInput:CameraInput;

	public var movementInput:MovementInput;

	public var jumpButton:JumpButton;

	public var powerupButton:PowerupButton;

	public var pauseButton:PauseButton;

	public var currentTouchState:TouchEventState;

	public var previousTouchState:TouchEventState;

	var touches:Map<Int, Touch> = [];

	public function new() {
		this.cameraInput = new CameraInput();
		this.movementInput = new MovementInput();
		this.jumpButton = new JumpButton();
		this.powerupButton = new PowerupButton();
		this.pauseButton = new PauseButton();
		this.currentTouchState = new TouchEventState();
		this.previousTouchState = new TouchEventState();
	}

	// Registers the callbacks to the native stuff
	public function registerTouchInput() {
		#if js
		var pointercontainer = js.Browser.document.querySelector("#webgl");
		pointercontainer.addEventListener('touchstart', (e:js.html.TouchEvent) -> {
			for (touch in e.changedTouches) {
				var t = new Touch(Pressed, new Vector(touch.clientX, touch.clientY), new Vector(0, 0), touch.identifier);
				currentTouchState.changedTouches.push(t);
				touches.set(touch.identifier, t);
				// trace("Touch Start");
			}
		});
		pointercontainer.addEventListener('touchmove', (e:js.html.TouchEvent) -> {
			for (touch in e.changedTouches) {
				var prevt = touches.get(touch.identifier); // previousTouchState.changedTouches.filter(x -> x.identifier == touch.identifier);
				var prevDelta = new Vector(0, 0);
				if (prevt != null) {
					prevDelta = new Vector(touch.clientX, touch.clientY).sub(prevt.position);
				}
				var t = new Touch(Move, new Vector(touch.clientX, touch.clientY), prevDelta, touch.identifier);
				currentTouchState.changedTouches.push(t);
				touches.set(touch.identifier, t);
				// trace("Touch Move");
			}
		});
		pointercontainer.addEventListener('touchend', (e:js.html.TouchEvent) -> {
			for (touch in e.changedTouches) {
				var t = new Touch(Release, new Vector(touch.clientX, touch.clientY), new Vector(0, 0), touch.identifier);
				currentTouchState.changedTouches.push(t);
				touches.remove(touch.identifier);
				// trace("Touch End");
			}
		});
		#end
	}

	public function update() {
		previousTouchState = currentTouchState;
		currentTouchState = new TouchEventState();
	}

	public function showControls(parentGui:GuiControl) {
		jumpButton.dispose();
		powerupButton.dispose();
		movementInput.dispose();
		pauseButton.dispose();
		cameraInput.dispose();
		this.cameraInput = new CameraInput();
		this.movementInput = new MovementInput();
		this.jumpButton = new JumpButton();
		this.powerupButton = new PowerupButton();
		this.pauseButton = new PauseButton();
		pauseButton.add(parentGui);
		jumpButton.add(parentGui);
		powerupButton.add(parentGui);
		movementInput.add(parentGui);
		cameraInput.add(parentGui);
		cameraInput.enabled = true;
	}

	public function setControlsEnabled(enabled:Bool) {
		this.jumpButton.setVisible(enabled);
		this.powerupButton.setVisible(enabled);
		this.movementInput.setVisible(enabled);
		this.pauseButton.setVisible(enabled);
		this.cameraInput.enabled = enabled;
	}

	public function hideControls(parentGui:GuiControl) {
		jumpButton.remove(parentGui);
		powerupButton.remove(parentGui);
		movementInput.remove(parentGui);
		pauseButton.remove(parentGui);
		cameraInput.remove(parentGui);
		jumpButton.dispose();
		powerupButton.dispose();
		movementInput.dispose();
		pauseButton.dispose();
		cameraInput.dispose();
	}
}
