package touch;

import src.MarbleGame;
import src.Settings;
import touch.TouchInput.TouchEventState;

class CameraInput {
	var identifier:Int = -1;

	var doing = false;

	public function new() {}

	public function update(touchState:TouchEventState) {
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
							MarbleGame.instance.world.marble.camera.orbit(touch.deltaPosition.x, touch.deltaPosition.y);
							return;

						case _:
							return;
					}
				}
			}
		}
	}
}
