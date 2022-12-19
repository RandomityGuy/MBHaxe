package gui;

import src.AudioManager;
import hxd.Key;
import gui.GuiControl.MouseState;
import hxd.Window;
import h2d.Tile;
import src.ResourceLoader;

enum ButtonType {
	Normal;
	Toggle;
	Radio;
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

	public var buttonSounds:Bool = true;

	public var accelerator:Int = 0;

	public function new(anim:Array<Tile>) {
		super(anim);
	}

	public override function update(dt:Float, mouseState:MouseState) {
		var renderRect = getRenderRectangle();
		if (renderRect.inRect(mouseState.position) && !disabled) {
			if (buttonSounds && Key.isPressed(Key.MOUSE_LEFT)) {
				AudioManager.playSound(ResourceLoader.getResource("data/sound/buttonpress.wav", ResourceLoader.getAudio, this.soundResources));
			}
		}
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
		if (buttonType == Toggle || buttonType == Radio) {
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
		if (!disabled && accelerator != 0 && hxd.Key.isReleased(accelerator)) {
			if (this.pressedAction != null) {
				this.pressedAction(this);
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
		if (buttonType == Radio) {
			pressed = true;
		}
	}

	public override function onMouseEnter(mouseState:MouseState) {
		super.onMouseEnter(mouseState);

		if (buttonSounds && !disabled) {
			AudioManager.playSound(ResourceLoader.getResource("data/sound/buttonover.wav", ResourceLoader.getAudio, this.soundResources));
		}
	}
}
