package touch;

import src.MarbleWorld;
import h3d.Vector;

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
	public var cameraInput:CameraInput;

	public var currentTouchState:TouchEventState;

	public var previousTouchState:TouchEventState;

	public function new() {
		this.cameraInput = new CameraInput();
		this.currentTouchState = new TouchEventState();
		this.previousTouchState = new TouchEventState();
	}

	// Registers the callbacks to the native stuff
	public function registerTouchInput() {
		#if js
		var pointercontainer = js.Browser.document.querySelector("#pointercontainer");
		pointercontainer.addEventListener('touchstart', (e:js.html.TouchEvent) -> {
			for (touch in e.changedTouches) {
				var t = new Touch(Pressed, new Vector(touch.clientX, touch.clientY), new Vector(0, 0), touch.identifier);
				currentTouchState.changedTouches.push(t);
			}
		});
		pointercontainer.addEventListener('touchmove', (e:js.html.TouchEvent) -> {
			for (touch in e.changedTouches) {
				var prevt = previousTouchState.changedTouches.filter(x -> x.identifier == touch.identifier);
				var prevDelta = new Vector(0, 0);
				if (prevt.length != 0) {
					prevDelta = new Vector(touch.clientX, touch.clientY).sub(prevt[0].position);
				}
				var t = new Touch(Move, new Vector(touch.clientX, touch.clientY), prevDelta, touch.identifier);
				currentTouchState.changedTouches.push(t);
			}
		});
		pointercontainer.addEventListener('touchend', (e:js.html.TouchEvent) -> {
			for (touch in e.changedTouches) {
				var t = new Touch(Release, new Vector(touch.clientX, touch.clientY), new Vector(0, 0), touch.identifier);
				currentTouchState.changedTouches.push(t);
			}
		});
		#end
	}

	public function update() {
		this.cameraInput.update(currentTouchState);
		previousTouchState = currentTouchState;
		currentTouchState = new TouchEventState();
	}
}
