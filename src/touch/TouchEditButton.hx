package touch;

import src.Util;
import gui.GuiControl.MouseState;
import gui.GuiGraphics;
import h3d.Vector;
import hxd.res.Image;

class TouchEditButton extends GuiGraphics {
	public var radius:Float;

	public var selected = false;

	public var onClick:(TouchEditButton, MouseState) -> Void;

	public var onChangeCb:(TouchEditButton, Vector, Float) -> Void;

	var imgTile:h2d.Tile;

	var mousePos:Vector;

	var state = 0;

	public function new(img:Image, position:Vector, radius:Float) {
		this.imgTile = img.toTile();

		var iconScale = 1.5;

		var g = new h2d.Graphics();
		g.beginFill(0xffffff);
		g.drawCircle(0, 0, radius);
		g.beginTileFill(-(imgTile.width * iconScale * radius / imgTile.width) / 2, -(imgTile.height * iconScale * radius / imgTile.width) / 2,
			iconScale * radius / imgTile.width, iconScale * radius / imgTile.height, imgTile);
		g.drawRect(-(imgTile.width * iconScale * radius / imgTile.width) / 2, -(imgTile.height * iconScale * radius / imgTile.width / 2),
			(imgTile.width * iconScale * radius / imgTile.width), (imgTile.height * iconScale * radius / imgTile.width));
		g.endFill();

		super(g);

		this.position = position;
		this.extent = new Vector(2 * radius, 2 * radius);
		this.horizSizing = Left;
		this.vertSizing = Top;
		this.radius = radius;
	}

	public override function getHitTestRect() {
		var thisRect = this.getRenderRectangle();
		thisRect.position = thisRect.position.sub(new Vector(radius, radius));

		if (selected) {
			thisRect.position = thisRect.position.add(new Vector(-15 - 6.5, -15 - 6.5));
			thisRect.extent = thisRect.extent.add(new Vector(30 + 13, 30 + 13));
		}

		if (this.parent == null)
			return thisRect;
		else {
			return thisRect.intersect(this.parent.getRenderRectangle());
		}
	}

	public override function onMousePress(mouseState:MouseState) {
		onClick(this, mouseState);
		this.mousePos = mouseState.position;

		var renderRect = getHitTestRect();
		var knobPos = new Vector(renderRect.position.x + renderRect.extent.x / 2, renderRect.position.y + 15);
		if (mouseState.position.sub(knobPos).length() < 15) {
			state = 1;
		} else {
			state = 2;
		}
	}

	public override function onMouseDown(mouseState:MouseState) {
		if (selected) {
			var deltaPos = mouseState.position.sub(this.mousePos);
			this.mousePos = mouseState.position;

			if (state == 1) {
				var renderRect = getHitTestRect();
				var newRadius = Util.clamp(mouseState.position.sub(renderRect.position.add(renderRect.extent.multiply(0.5))).length(), 15, 80);
				this.radius = newRadius;
				this.extent = new Vector(2 * newRadius, 2 * newRadius);

				// Redraw lmao
				this.setSelected(false);
				this.setSelected(true);
				onChangeCb(this, this.position, this.radius);
			}
			if (state == 2) {
				this.graphics.setPosition(this.graphics.x + deltaPos.x, this.graphics.y + deltaPos.y);
				this.position = this.position.add(deltaPos);
				onChangeCb(this, this.position, this.radius);
			}
		}
	}

	public override function onMouseRelease(mouseState:MouseState) {
		state = 0;
	}

	public function setSelected(selected:Bool) {
		this.selected = selected;
		if (selected) {
			this.graphics.beginFill(0xffffff);
			this.graphics.drawPieInner(0, 0, radius + 8, radius + 5, 0, 2 * Math.PI);
			this.graphics.endFill();
			this.graphics.beginFill(0x8B8B8B);
			this.graphics.drawCircle(0, -radius - 6.5, 15);
			this.graphics.endFill();
		} else {
			this.graphics.clear();

			var iconScale = 1.5;

			this.graphics.beginFill(0xffffff);
			this.graphics.drawCircle(0, 0, radius);
			this.graphics.beginTileFill(-(imgTile.width * iconScale * radius / imgTile.width) / 2, -(imgTile.height * iconScale * radius / imgTile.width) / 2,
				iconScale * radius / imgTile.width, iconScale * radius / imgTile.height, imgTile);
			this.graphics.drawRect(-(imgTile.width * iconScale * radius / imgTile.width) / 2, -(imgTile.height * iconScale * radius / imgTile.width / 2),
				(imgTile.width * iconScale * radius / imgTile.width), (imgTile.height * iconScale * radius / imgTile.width));
			this.graphics.endFill();
		}
	}
}
