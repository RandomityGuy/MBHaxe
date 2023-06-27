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

class GuiXboxListButton extends GuiControl {
	var button:GuiAnim;
	var buttonIcon:GuiAnim;
	var buttonText:GuiText;

	public var pressedAction:GuiEvent->Void = null;

	public var disabled:Bool = false;

	public var pressed:Bool = false;

	public var buttonSounds:Bool = true;

	public var accelerator:Int = 0;
	public var gamepadAccelerator:Array<String> = [];
	public var acceleratorWasPressed = false;

	public function new(icon:Int, text:String) {
		super();

		var buttonImage = ResourceLoader.getResource("data/ui/xbox/cursorArray.png", ResourceLoader.getImage, this.imageResources).toTile();
		var buttonDefault = buttonImage.sub(0, 2, 502, 94);
		var buttonHover = buttonImage.sub(0, 98, 502, 94);
		var buttonIconImg = buttonImage.sub(74 * icon, 219, 36, 36);
		var buttonIconPressed = buttonImage.sub(74 * icon + 37, 219, 36, 36);

		var cmat = Matrix.I();
		cmat.colorGain(0x7F7F7F, 1);
		// cmat._44 = 1;
		var shadeFilter = new h2d.filter.ColorMatrix(cmat);
		shadeFilter.enable = false;

		button = new GuiAnim([buttonDefault, buttonHover]);
		button.position = new Vector(0, 0);
		button.extent = new Vector(502, 94);
		button.anim.filter = shadeFilter;
		this.addChild(button);

		buttonIcon = new GuiAnim([buttonIconImg, buttonIconPressed]);
		buttonIcon.position = new Vector(42, 30);
		buttonIcon.extent = new Vector(36, 36);
		this.addChild(buttonIcon);

		var arial14fontdata = ResourceLoader.getFileEntry("data/font/Arial Bold.fnt");
		var arial14b = new BitmapFont(arial14fontdata.entry);
		@:privateAccess arial14b.loader = ResourceLoader.loader;
		var arial14 = arial14b.toSdfFont(cast 26 * Settings.uiScale, h2d.Font.SDFChannel.MultiChannel);

		buttonText = new GuiText(arial14);
		buttonText.position = new Vector(92, 36);
		buttonText.extent = new Vector(92, 35);
		buttonText.vertSizing = Top;
		buttonText.text.text = text;
		buttonText.text.textColor = 0x787878;
		this.addChild(buttonText);
	}

	public override function update(dt:Float, mouseState:MouseState) {
		var renderRect = getHitTestRect();
		renderRect.position = renderRect.position.add(new Vector(24, 20)); // Offset
		renderRect.extent.set(439, 53);
		if (renderRect.inRect(mouseState.position) && !disabled) {
			if (buttonSounds && Key.isPressed(Key.MOUSE_LEFT)) {
				AudioManager.playSound(ResourceLoader.getResource("data/sound/buttonpress.wav", ResourceLoader.getAudio, this.soundResources));
			}
		}
		if (renderRect.inRect(mouseState.position) && !disabled) {
			if (Key.isDown(Key.MOUSE_LEFT)) {
				this.button.anim.currentFrame = 1;
				this.buttonIcon.anim.currentFrame = 1;
				buttonText.text.textColor = 0x101010;
				button.anim.filter.enable = true;
				pressed = true;
			} else {
				this.button.anim.currentFrame = 1;
				this.buttonIcon.anim.currentFrame = 1;
				buttonText.text.textColor = 0x101010;
				button.anim.filter.enable = false;
				pressed = false;
			}
		} else {
			this.button.anim.currentFrame = disabled ? 3 : 0;
			this.buttonIcon.anim.currentFrame = 0;
			this.buttonText.text.textColor = 0x787878;
			button.anim.filter.enable = false;
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
		var renderRect = getHitTestRect();
		renderRect.position = renderRect.position.add(new Vector(24, 20)); // Offset
		renderRect.extent.set(439, 53);
		if (!renderRect.inRect(mouseState.position))
			return;

		super.onMouseRelease(mouseState);
		if (this.pressedAction != null && !disabled) {
			this.pressedAction(new GuiEvent(this));
		}
	}

	public override function onMouseEnter(mouseState:MouseState) {
		var renderRect = getHitTestRect();
		renderRect.position = renderRect.position.add(new Vector(24, 20)); // Offset
		renderRect.extent.set(439, 53);
		if (!renderRect.inRect(mouseState.position))
			return;

		super.onMouseEnter(mouseState);

		if (buttonSounds && !disabled) {
			AudioManager.playSound(ResourceLoader.getResource("data/sound/buttonover.wav", ResourceLoader.getAudio, this.soundResources));
		}
	}
}
