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

	public function new(texture:Tile, exts:{
		tl:Vector,
		tr:Vector,
		bl:Vector,
		br:Vector,
		top:Vector,
		left:Vector,
		right:Vector,
		bottom:Vector,
		fill:Vector,
		separation:Float
	} = null) {
		super();
		texture.getTexture().filter = Nearest;
		texture.getTexture().mipMap = None;
		if (exts == null) {
			exts = {
				tl: new Vector(0, 1, 13, 13),
				tr: new Vector(35, 1, 13, 13),
				bl: new Vector(0, 23, 13, 13),
				br: new Vector(35, 23, 13, 13),
				top: new Vector(14, 1, 20, 13),
				left: new Vector(0, 15, 13, 7),
				right: new Vector(35, 15, 13, 7),
				bottom: new Vector(14, 23, 20, 13),
				fill: new Vector(14, 15, 20, 7),
				separation: 36
			}
		}

		var tilesubs = [];

		for (i in 0...4) {
			var tl = texture.sub(exts.tl.x, exts.tl.y + i * exts.separation, exts.tl.z, exts.tl.w);
			var tr = texture.sub(exts.tr.x, exts.tr.y + i * exts.separation, exts.tr.z, exts.tr.w);
			var bl = texture.sub(exts.bl.x, exts.bl.y + i * exts.separation, exts.bl.z, exts.bl.w);
			var br = texture.sub(exts.br.x, exts.br.y + i * exts.separation, exts.br.z, exts.br.w);
			var top = texture.sub(exts.top.x, exts.top.y + i * exts.separation, exts.top.z, exts.top.w);
			var left = texture.sub(exts.left.x, exts.left.y + i * exts.separation, exts.left.z, exts.left.w);
			var right = texture.sub(exts.right.x, exts.right.y + i * exts.separation, exts.right.z, exts.right.w);
			var bottom = texture.sub(exts.bottom.x, exts.bottom.y + i * exts.separation, exts.bottom.z, exts.bottom.w);
			var fill = texture.sub(exts.fill.x, exts.fill.y + i * exts.separation, exts.fill.z, exts.fill.w);
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

	public override function render(scene2d:Scene) {
		if (scene2d.contains(container))
			scene2d.removeChild(container);

		scene2d.addChild(container);

		var renderRect = this.getRenderRectangle();

		container.setPosition(Math.floor(renderRect.position.x), Math.floor(renderRect.position.y));

		var tl = bmps[0];
		var tr = bmps[1];
		var bl = bmps[2];
		var br = bmps[3];
		var top = bmps[4];
		var left = bmps[5];
		var right = bmps[6];
		var bottom = bmps[7];

		tl.setPosition(0, 0);

		tr.setPosition(Math.floor(renderRect.extent.x - tr.tile.width), 0);

		bl.setPosition(0, Math.floor(renderRect.extent.y - bl.tile.height));

		br.setPosition(Math.floor(renderRect.extent.x - tr.tile.width), Math.floor(renderRect.extent.y - bl.tile.height));

		// now for the sides

		top.setPosition(tl.tile.width, 0);
		top.width = Math.floor(renderRect.extent.x - tl.tile.width - tr.tile.width);
		top.height = top.tile.height;

		left.setPosition(0, tl.tile.height);
		left.height = Math.floor(renderRect.extent.y - tl.tile.height - bl.tile.height);
		left.width = left.tile.width;

		right.setPosition(Math.floor(renderRect.extent.x - tr.tile.width), tl.tile.height);
		right.height = Math.floor(renderRect.extent.y - tl.tile.height - bl.tile.height);
		right.width = right.tile.width;

		bottom.setPosition(bl.tile.width, Math.floor(renderRect.extent.y - bl.tile.height));
		bottom.width = Math.floor(renderRect.extent.x - bl.tile.width - br.tile.width);
		bottom.height = bottom.tile.height;

		// // the fill
		var fill = bmps[8];
		fill.setPosition(tl.tile.width, tl.tile.height);
		fill.width = Math.floor(renderRect.extent.x - tl.tile.width - tr.tile.width);
		fill.height = Math.floor(renderRect.extent.y - tr.tile.height - bl.tile.height);

		super.render(scene2d);
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
