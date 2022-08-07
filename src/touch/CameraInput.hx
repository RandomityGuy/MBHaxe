package touch;

import src.MarbleGame;
import src.Settings;
import touch.TouchInput.TouchEventState;

class CameraInput {
	var identifier:Int = -1;

	var doing = false;

	public var enabled = false;

	public function new() {}

	public function update(touchState:TouchEventState, joycam:Bool) {
		if (!enabled)
			return;
		if (!doing) {
			// Check for touches on the right half of the screen
			for (touch in touchState.changedTouches) {
				if (touch.position.x >= Settings.optionsSettings.screenWidth / 2 && touch.state == Pressed) {
					identifier = touch.identifier;
					doing = true;
				}
			}
		}
		if (doing) {
			// Get our identifier
			for (touch in touchState.changedTouches) {
				if (touch.identifier == this.identifier) {
					switch (touch.state) {
						case Release:
							doing = false;
							return;

						case Move:
							var scaleFactor = 1.0;
							#if js
							scaleFactor = js.Browser.window.devicePixelRatio / Settings.zoomRatio;
							#end
							if (joycam) {
								scaleFactor /= 2.5;
							}
							MarbleGame.instance.world.marble.camera.orbit(touch.deltaPosition.x / scaleFactor, touch.deltaPosition.y / scaleFactor, true);
							return;

						case _:
							return;
					}
				}
			}

			doing = false;
		}
	}
}
