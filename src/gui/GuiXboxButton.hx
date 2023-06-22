package gui;

import h3d.Matrix;
import hxd.Key;
import gui.GuiControl.MouseState;
import hxd.res.BitmapFont;
import h3d.Vector;
import src.ResourceLoader;
import src.Settings;
import src.Gamepad;
import src.AudioManager;

class GuiXboxButton extends GuiControl {
	var left:GuiAnim;
	var fill:GuiAnim;
	var right:GuiAnim;
	var text:GuiText;

	public var pressedAction:GuiEvent->Void = null;

	public var disabled:Bool = false;

	public var pressed:Bool = false;

	public var buttonSounds:Bool = true;

	public var accelerator:Int = 0;
	public var gamepadAccelerator:Array<String> = [];
	public var acceleratorWasPressed = false;

	public function new(text:String, width:Int) {
		super();
		this.extent = new Vector(width, 94);
		var buttonImage = ResourceLoader.getResource("data/ui/xbox/cursorButtonArray.png", ResourceLoader.getImage, this.imageResources).toTile();
		var buttonLeft = buttonImage.sub(0, 2, 39, 94);
		var buttonFill = buttonImage.sub(52, 2, 396, 94);
		var buttonRight = buttonImage.sub(452, 2, 41, 94);
		var buttonLeftPressed = buttonImage.sub(0, 98, 39, 94);
		var buttonFillPressed = buttonImage.sub(52, 98, 396, 94);
		var buttonRightPressed = buttonImage.sub(452, 98, 41, 94);

		var cmat = Matrix.I();
		cmat.colorGain(0x7F7F7F, 1);
		// cmat._44 = 1;
		var shadeFilter = new h2d.filter.ColorMatrix(cmat);
		shadeFilter.enable = false;

		var fillWidth = width - 39 - 41;

		left = new GuiAnim([buttonLeft, buttonLeftPressed]);
		left.position = new Vector(0, 0);
		left.extent = new Vector(39, 94);
		left.anim.filter = shadeFilter;
		this.addChild(left);
		fill = new GuiAnim([buttonFill, buttonFillPressed]);
		fill.position = new Vector(39, 0);
		fill.extent = new Vector(fillWidth, 94);
		fill.anim.filter = shadeFilter;
		this.addChild(fill);
		right = new GuiAnim([buttonRight, buttonRightPressed]);
		right.position = new Vector(39 + fillWidth, 0);
		right.extent = new Vector(41, 94);
		right.anim.filter = shadeFilter;
		this.addChild(right);

		var arial14fontdata = ResourceLoader.getFileEntry("data/font/Arial Bold.fnt");
		var arial14b = new BitmapFont(arial14fontdata.entry);
		@:privateAccess arial14b.loader = ResourceLoader.loader;
		var arial14 = arial14b.toSdfFont(cast 20 * Settings.uiScale, h2d.Font.SDFChannel.MultiChannel);

		this.text = new GuiText(arial14);
		this.text.position = new Vector(39, 37);
		this.text.extent = new Vector(fillWidth, 35);
		this.text.justify = Center;
		this.text.vertSizing = Top;
		this.text.text.text = text;
		this.text.text.textColor = 0x787878;
		this.addChild(this.text);
	}

	public override function update(dt:Float, mouseState:MouseState) {
		var renderRect = getHitTestRect();
		if (renderRect.inRect(mouseState.position) && !disabled) {
			if (buttonSounds && Key.isPressed(Key.MOUSE_LEFT)) {
				AudioManager.playSound(ResourceLoader.getResource("data/sound/buttonpress.wav", ResourceLoader.getAudio, this.soundResources));
			}
		}
		if (renderRect.inRect(mouseState.position) && !disabled) {
			if (Key.isDown(Key.MOUSE_LEFT)) {
				left.anim.currentFrame = 1;
				fill.anim.currentFrame = 1;
				right.anim.currentFrame = 1;
				left.anim.filter.enable = true;
				fill.anim.filter.enable = true;
				right.anim.filter.enable = true;
				text.text.textColor = 0x101010;
				pressed = true;
			} else {
				left.anim.currentFrame = 1;
				fill.anim.currentFrame = 1;
				right.anim.currentFrame = 1;
				left.anim.filter.enable = false;
				fill.anim.filter.enable = false;
				right.anim.filter.enable = false;
				text.text.textColor = 0x101010;
				pressed = false;
			}
		} else {
			left.anim.currentFrame = 0;
			fill.anim.currentFrame = 0;
			right.anim.currentFrame = 0;
			left.anim.filter.enable = false;
			fill.anim.filter.enable = false;
			right.anim.filter.enable = false;
			this.text.text.textColor = 0x787878;
			pressed = false;
		}
		if (!disabled) {
			if (acceleratorWasPressed && (accelerator != 0 && hxd.Key.isReleased(accelerator)) || Gamepad.isReleased(gamepadAccelerator)) {
				if (this.pressedAction != null) {
					this.pressedAction(new GuiEvent(this));
				}
			} else if ((accelerator != 0 && hxd.Key.isPressed(accelerator)) || Gamepad.isPressed(gamepadAccelerator)) {
				acceleratorWasPressed = true;
			}
		}
		if (acceleratorWasPressed) {
			if ((accelerator != 0 && hxd.Key.isReleased(accelerator)) || Gamepad.isReleased(gamepadAccelerator))
				acceleratorWasPressed = false;
		}
		super.update(dt, mouseState);
	}

	public override function onMouseRelease(mouseState:MouseState) {
		if (mouseState.handled)
			return;
		mouseState.handled = true;
		super.onMouseRelease(mouseState);
		if (this.pressedAction != null && !disabled) {
			this.pressedAction(new GuiEvent(this));
		}
	}

	public override function onMouseEnter(mouseState:MouseState) {
		if (mouseState.handled)
			return;
		mouseState.handled = true;
		super.onMouseEnter(mouseState);

		if (buttonSounds && !disabled) {
			AudioManager.playSound(ResourceLoader.getResource("data/sound/buttonover.wav", ResourceLoader.getAudio, this.soundResources));
		}
	}
}
