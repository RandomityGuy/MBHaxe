package touch;

import hxd.res.DefaultFont;
import h2d.Text;
import gui.GuiGraphics;
import h3d.Vector;
import gui.GuiControl;
import src.MarbleGame;
import src.Settings;
import touch.TouchInput.TouchEventState;
import src.Util;

class CameraInput {
	var identifier:Int = -1;

	public var enabled = false;

	var added = false;

	var collider:GuiGraphics;

	public function new() {
		var width = MarbleGame.canvas.scene2d.width;
		var height = MarbleGame.canvas.scene2d.height;

		var g = new h2d.Graphics();
		// g.beginFill(0xFF00FF, 0.5);
		// g.drawRect(0, 0, width, height);
		// g.endFill();
		var gcollider = h2d.col.Bounds.fromValues(0, 0, width, height);
		var interactive = new h2d.Interactive(width, height, g, gcollider);

		this.collider = new GuiGraphics(g);
		this.collider.position = new Vector(0, 0);
		this.collider.extent = new Vector(width, height);
		this.collider.horizSizing = Width;
		this.collider.vertSizing = Height;

		var pressed = false;

		var prevMouse = new Vector(0, 0);
		interactive.onPush = (e) -> {
			e.propagate = true;

			if (!enabled)
				return;

			if (pressed)
				return;

			var scene2d = interactive.getScene();
			if (e.relX < scene2d.width / 2) {
				var restartG = @:privateAccess MarbleGame.instance.touchInput.pauseButton?.collider;
				if (restartG != null) {
					if (e.relY > restartG.getAbsPos().y + restartG.height) {
						if (Settings.touchSettings.dynamicJoystick) {
							// Move that joystick over our finger
							MarbleGame.instance.touchInput.movementInput.moveToFinger(e);
						}
					}
				}
				return;
			}

			pressed = true;
			this.identifier = e.touchId;
			prevMouse.x = e.relX;
			prevMouse.y = e.relY;
		}

		interactive.onMove = (e) -> {
			e.propagate = true;
			if (!enabled)
				return;

			if (this.identifier != e.touchId)
				return;

			if (pressed) {
				var curPos = new Vector(e.relX, e.relY);
				var delta = curPos.sub(prevMouse);
				var scaleFactor = 1.0;
				#if js
				scaleFactor = js.Browser.window.devicePixelRatio / Settings.zoomRatio;
				#end
				var jumpcam = MarbleGame.instance.touchInput.jumpButton.pressed
					|| MarbleGame.instance.touchInput.powerupButton.pressed
					|| MarbleGame.instance.touchInput.blastbutton.pressed;
				if (jumpcam) {
					scaleFactor /= Settings.touchSettings.buttonJoystickMultiplier;
				}

				var inpX = delta.x / scaleFactor;
				var inpY = delta.y / scaleFactor;

				if (jumpcam) {
					if (Math.abs(inpX) < 1)
						inpX = 0;
					if (Math.abs(inpY) < 1)
						inpY = 0;
				}

				MarbleGame.instance.world.marble.camera.orbit(applyNonlinearScale(inpX), applyNonlinearScale(inpY), true);
				prevMouse.x = e.relX;
				prevMouse.y = e.relY;
			}
		}

		interactive.onRelease = (e) -> {
			e.propagate = true;
			if (!enabled)
				return;

			if (this.identifier != e.touchId)
				return;

			pressed = false;
			this.identifier = -1;
		}
	}

	function applyNonlinearScale(value:Float) {
		var clamped = Util.clamp(value, -Settings.touchSettings.cameraSwipeExtent, Settings.touchSettings.cameraSwipeExtent);
		return Math.abs(clamped) < 3 ? Math.pow(Math.abs(clamped / 2), 2.7) * (clamped >= 0 ? 1 : -1) : clamped;
	}

	// public function update(touchState:TouchEventState, joycam:Bool) {
	// 	if (!enabled)
	// 		return;
	// 	if (!doing) {
	// 		// Check for touches on the right half of the screen
	// 		for (touch in touchState.changedTouches) {
	// 			if (touch.position.x >= Settings.optionsSettings.screenWidth / 2 && touch.state == Pressed) {
	// 				identifier = touch.identifier;
	// 				doing = true;
	// 			}
	// 		}
	// 	}
	// 	if (doing) {
	// 		// Get our identifier
	// 		for (touch in touchState.changedTouches) {
	// 			if (touch.identifier == this.identifier) {
	// 				switch (touch.state) {
	// 					case Release:
	// 						doing = false;
	// 						return;
	// 					case Move:
	// 						var scaleFactor = 1.0;
	// 						#if js
	// 						scaleFactor = js.Browser.window.devicePixelRatio / Settings.zoomRatio;
	// 						#end
	// 						if (joycam) {
	// 							scaleFactor /= 2.5;
	// 						}
	// 						MarbleGame.instance.world.marble.camera.orbit(touch.deltaPosition.x / scaleFactor, touch.deltaPosition.y / scaleFactor, true);
	// 						return;
	// 					case _:
	// 						return;
	// 				}
	// 			}
	// 		}
	// 		doing = false;
	// 	}
	// }

	public function dispose() {
		this.collider.dispose();
	}

	public function add(parentGui:GuiControl) {
		parentGui.addChild(this.collider);
		added = true;
	}

	public function remove(parentGui:GuiControl) {
		parentGui.removeChild(this.collider);
		added = false;
	}
}
