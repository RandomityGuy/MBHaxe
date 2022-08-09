package touch;

import gui.GuiControl.MouseState;
import gui.GuiGraphics;
import h3d.Vector;
import hxd.res.Image;

class TouchEditButton extends GuiGraphics {
	public var radius:Float;

	public var selected = false;

	public var onClick:(TouchEditButton, MouseState) -> Void;

	var imgTile:h2d.Tile;

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
		if (this.parent == null)
			return thisRect;
		else {
			return thisRect.intersect(this.parent.getRenderRectangle());
		}
	}

	public override function onMousePress(mouseState:MouseState) {
		super.onMousePress(mouseState);
		onClick(this, mouseState);
	}

	public function setSelected(selected:Bool) {
		if (selected) {
			this.graphics.beginFill(0xffffff);
			this.graphics.drawPieInner(0, 0, radius + 8, radius + 5, 0, 2 * Math.PI);
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
