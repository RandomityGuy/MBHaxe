package touch;

import src.Settings;
import gui.GuiControl;
import gui.GuiGraphics;
import touch.TouchInput.Touch;
import touch.TouchInput.TouchEventState;
import h3d.Vector;
import hxd.res.Image;
import src.MarbleGame;

class TouchButton {
	public var img:Image;

	public var guiElement:GuiGraphics;

	public var position:Vector;

	public var radius:Float;

	var doing = false;

	var added = false;

	public var pressed = false;

	public var enabled = true;

	var identifier:Int = -1;

	var collider:h2d.Interactive;

	public function new(img:Image, position:Vector, radius:Float) {
		var imgTile = img.toTile();

		var iconScale = 1.5;

		var g = new h2d.Graphics();
		g.beginFill(0xffffff);
		g.drawCircle(0, 0, radius);
		g.beginTileFill(-(imgTile.width * iconScale * radius / imgTile.width) / 2, -(imgTile.height * iconScale * radius / imgTile.width) / 2,
			iconScale * radius / imgTile.width, iconScale * radius / imgTile.height, imgTile);
		g.drawRect(-(imgTile.width * iconScale * radius / imgTile.width) / 2, -(imgTile.height * iconScale * radius / imgTile.width / 2),
			(imgTile.width * iconScale * radius / imgTile.width), (imgTile.height * iconScale * radius / imgTile.width));
		g.endFill();
		// g.setPosition(position.x, position.y);
		this.guiElement = new GuiGraphics(g);
		this.guiElement.position = position;
		this.guiElement.extent = new Vector(2 * radius, 2 * radius);
		this.guiElement.horizSizing = Left;
		this.guiElement.vertSizing = Top;
		this.radius = radius;

		this.collider = new h2d.Interactive(2 * radius, 2 * radius, this.guiElement.graphics, new h2d.col.Circle(0, 0, radius));
		this.collider.onPush = (e) -> {
			onClick();
			if (this.enabled) {
				g.alpha = 0.9;
			} else {
				g.alpha = 0.5;
			}
			this.identifier = e.touchId;
		}
		this.collider.onRelease = (e) -> {
			if (e.touchId != this.identifier)
				return;

			this.identifier = -1;
			onRelease();

			if (this.enabled) {
				g.alpha = 0.4;
			} else {
				g.alpha = 0.2;
			}
		}

		if (this.enabled) {
			g.alpha = 0.4;
		} else {
			g.alpha = 0.2;
		}
	}

	public function add(parentGui:GuiControl) {
		parentGui.addChild(this.guiElement);
		added = true;
	}

	public function remove(parentGui:GuiControl) {
		parentGui.removeChild(this.guiElement);
		added = false;
	}

	public function setEnabled(enabled:Bool) {
		this.enabled = enabled;
		if (this.enabled) {
			this.guiElement.graphics.alpha = 0.4;
		} else {
			this.guiElement.graphics.alpha = 0.2;
		}
		if (this.pressed) {
			if (this.enabled) {
				this.guiElement.graphics.alpha = 0.9;
			} else {
				this.guiElement.graphics.alpha = 0.5;
			}
		}
	}

	public function setVisible(enabled:Bool) {
		this.guiElement.graphics.visible = enabled;
	}

	public dynamic function onClick() {
		pressed = true;
	}

	public dynamic function onRelease() {
		pressed = false;
	}

	public function dispose() {
		this.guiElement.dispose();
	}
}
