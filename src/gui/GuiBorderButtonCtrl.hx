package gui;

import h3d.Vector;
import h2d.Scene;
import h2d.Flow;
import h2d.Tile;
import gui.GuiControl.MouseState;
import src.AudioManager;
import hxd.Key;
import src.Gamepad;
import gui.GuiButton.ButtonType;
import src.ResourceLoader;

class GuiBorderButtonCtrl extends GuiControl {
	var tiles:Array<h2d.Tile>;
	var bmps:Array<h2d.Bitmap>; // [tl, tr, bl, br, top, left, right, bottom, fill]
	var container:h2d.Object;

	// button
	// 0 is normal
	// 1 is hover
	// 2 is pressed
	// 3 is disabled
	public var pressedAction:GuiEvent->Void = null;

	public var disabled:Bool = false;

	public var buttonType:ButtonType = Normal;
	public var pressed:Bool = false;

	public var buttonSounds:Bool = true;

	public var accelerator:Int = 0;
	public var gamepadAccelerator:Array<String> = [];
	public var acceleratorWasPressed = false;

	public function new(texture:Tile) {
		super();

		var tilesubs = [];

		for (i in 0...4) {
			var tl = texture.sub(0, 1 + i * 36, 13, 13);
			var tr = texture.sub(35, 1 + i * 36, 13, 13);
			var bl = texture.sub(0, 23 + i * 36, 13, 13);
			var br = texture.sub(35, 23 + i * 36, 13, 13);
			var top = texture.sub(14, 1 + i * 36, 20, 13);
			var left = texture.sub(0, 15 + i * 36, 13, 7);
			var right = texture.sub(35, 15 + i * 36, 13, 7);
			var bottom = texture.sub(14, 23 + i * 36, 20, 13);
			var fill = texture.sub(14, 15 + i * 36, 20, 7);
			tilesubs = tilesubs.concat([tl, tr, bl, br, top, left, right, bottom, fill]);
		}

		this.container = new h2d.Object();
		this.bmps = [];
		for (i in 0...9) {
			var n = tilesubs[i]; // all set to normal default
			this.bmps.push(new h2d.Bitmap(n, container));
		}
		this.tiles = tilesubs;
	}

	public override function render(scene2d:Scene, ?parent:Flow) {
		if (parent.contains(container))
			parent.removeChild(container);

		parent.addChild(container);
		var props = parent.getProperties(container);
		props.isAbsolute = true;

		var renderRect = this.getRenderRectangle();
		var offset = this.getOffsetFromParent();

		container.setPosition(offset.x, offset.y);

		var tl = bmps[0];
		var tr = bmps[1];
		var bl = bmps[2];
		var br = bmps[3];
		var top = bmps[4];
		var left = bmps[5];
		var right = bmps[6];
		var bottom = bmps[7];

		tl.setPosition(0, 0);

		tr.setPosition(renderRect.extent.x - tr.tile.width, 0);

		bl.setPosition(0, renderRect.extent.y - bl.tile.height);

		br.setPosition(renderRect.extent.x - tr.tile.width, renderRect.extent.y - bl.tile.height);

		// now for the sides

		top.setPosition(tl.tile.width, 0);
		top.width = renderRect.extent.x - tl.tile.width - tr.tile.width;
		top.height = top.tile.height;

		left.setPosition(0, tl.tile.height);
		left.height = renderRect.extent.y - tl.tile.height - bl.tile.height;
		left.width = left.tile.width;

		right.setPosition(renderRect.extent.x - tr.tile.width, tl.tile.height);
		right.height = renderRect.extent.y - tl.tile.height - bl.tile.height;
		right.width = right.tile.width;

		bottom.setPosition(bl.tile.width, renderRect.extent.y - bl.tile.height);
		bottom.width = renderRect.extent.x - bl.tile.width - br.tile.width;
		bottom.height = bottom.tile.height;

		// // the fill
		var fill = bmps[8];
		fill.setPosition(tl.tile.width, tl.tile.height);
		fill.width = renderRect.extent.x - tl.tile.width - tr.tile.width;
		fill.height = renderRect.extent.y - tr.tile.height - bl.tile.height;

		super.render(scene2d, parent);
	}

	public override function onRemove() {
		super.onRemove();

		container.remove();
	}

	public override function dispose() {
		super.dispose();
		container.remove();
		for (bmp in this.bmps) {
			bmp.remove();
		}
	}

	function setButtonState(state:Int) {
		for (i in 0...9) {
			this.bmps[i].tile = this.tiles[state * 9 + i];
		}
	}

	public override function update(dt:Float, mouseState:MouseState) {
		var renderRect = getHitTestRect();
		if (renderRect.inRect(mouseState.position) && !disabled) {
			if (buttonSounds && Key.isPressed(Key.MOUSE_LEFT)) {
				AudioManager.playSound(ResourceLoader.getResource("data/sound/buttonpress.wav", ResourceLoader.getAudio, this.soundResources));
			}
		}
		if (buttonType == Normal) {
			if (renderRect.inRect(mouseState.position) && !disabled) {
				if (Key.isDown(Key.MOUSE_LEFT)) {
					setButtonState(2);
					pressed = true;
				} else {
					setButtonState(1);
					pressed = false;
				}
			} else {
				setButtonState(disabled ? 3 : 0);
				pressed = false;
			}
		}
		if (buttonType == Toggle || buttonType == Radio) {
			if (this.pressed) {
				setButtonState(2);
			} else {
				if (renderRect.inRect(mouseState.position) && !disabled) {
					if (Key.isDown(Key.MOUSE_LEFT)) {
						setButtonState(2);
					} else if (!Key.isReleased(Key.MOUSE_LEFT)) {
						setButtonState(1);
					}
				} else {
					setButtonState(disabled ? 3 : 0);
				}
			}
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
		super.onMouseRelease(mouseState);
		if (this.pressedAction != null && !disabled) {
			this.pressedAction(new GuiEvent(this));
		}
		if (buttonType == Toggle) {
			pressed = !pressed;
		}
		if (buttonType == Radio) {
			pressed = true;
			// Unpress all the other radios
			for (c in this.parent.children) {
				if (c != this && c is GuiButton) {
					var cb:GuiButton = cast c;
					if (cb.buttonType == Radio) {
						cb.pressed = false;
					}
				}
			}
		}
	}

	public override function onMouseEnter(mouseState:MouseState) {
		super.onMouseEnter(mouseState);

		if (buttonSounds && !disabled) {
			AudioManager.playSound(ResourceLoader.getResource("data/sound/buttonover.wav", ResourceLoader.getAudio, this.soundResources));
		}
	}
}
