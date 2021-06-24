package gui;

import hxd.Key;
import gui.GuiControl.MouseState;
import hxd.Window;
import h2d.Tile;

enum ButtonType {
	Normal;
	Toggle;
}

class GuiButton extends GuiAnim {
	// 0 is normal
	// 1 is hover
	// 2 is pressed
	// 3 is disabled
	public var pressedAction:GuiControl->Void = null;

	public var disabled:Bool = false;

	public var buttonType:ButtonType = Normal;
	public var pressed:Bool = false;

	public function new(anim:Array<Tile>) {
		super(anim);
	}

	public override function update(dt:Float, mouseState:MouseState) {
		var renderRect = getRenderRectangle();
		if (buttonType == Normal) {
			if (renderRect.inRect(mouseState.position) && !disabled) {
				if (Key.isDown(Key.MOUSE_LEFT)) {
					this.anim.currentFrame = 2;
					pressed = true;
				} else {
					this.anim.currentFrame = 1;
					pressed = false;
				}
			} else {
				this.anim.currentFrame = disabled ? 3 : 0;
				pressed = false;
			}
		}
		if (buttonType == Toggle) {
			if (this.pressed) {
				this.anim.currentFrame = 2;
			} else {
				if (renderRect.inRect(mouseState.position) && !disabled) {
					if (Key.isDown(Key.MOUSE_LEFT)) {
						this.anim.currentFrame = 2;
					} else if (!Key.isReleased(Key.MOUSE_LEFT)) {
						this.anim.currentFrame = 1;
					}
				} else {
					this.anim.currentFrame = disabled ? 3 : 0;
				}
			}
		}
		super.update(dt, mouseState);
	}

	public override function onMouseRelease(mouseState:MouseState) {
		super.onMouseRelease(mouseState);
		if (this.pressedAction != null && !disabled) {
			this.pressedAction(this);
		}
		if (buttonType == Toggle) {
			pressed = !pressed;
		}
	}
}
