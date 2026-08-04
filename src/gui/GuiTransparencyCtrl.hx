package gui;

import h2d.Scene;
import h2d.Flow;
import h2d.Bitmap;
import h2d.Tile;
import src.ResourceLoader;

class GuiTransparencyCtrl extends GuiControl {
	var tiles:Array<Tile>;
	var bmps:Array<Bitmap>;

	var container:h2d.Object;

	public function new(path:String) {
		super();
		var b = ResourceLoader.getResource('${path}/transparency-b.png', ResourceLoader.getImage, this.imageResources).toTile();
		var bl = ResourceLoader.getResource('${path}/transparency-bl.png', ResourceLoader.getImage, this.imageResources).toTile();
		var br = ResourceLoader.getResource('${path}/transparency-br.png', ResourceLoader.getImage, this.imageResources).toTile();
		var t = ResourceLoader.getResource('${path}/transparency-t.png', ResourceLoader.getImage, this.imageResources).toTile();
		var tl = ResourceLoader.getResource('${path}/transparency-tl.png', ResourceLoader.getImage, this.imageResources).toTile();
		var tr = ResourceLoader.getResource('${path}/transparency-tr.png', ResourceLoader.getImage, this.imageResources).toTile();
		var l = ResourceLoader.getResource('${path}/transparency-l.png', ResourceLoader.getImage, this.imageResources).toTile();
		var r = ResourceLoader.getResource('${path}/transparency-r.png', ResourceLoader.getImage, this.imageResources).toTile();
		var f = ResourceLoader.getResource('${path}/transparencyfill.png', ResourceLoader.getImage, this.imageResources).toTile();

		container = new h2d.Object();

		tiles = [b, bl, br, t, tl, tr, l, r, f];
		bmps = [];
		for (tile in tiles) {
			tile.getTexture().filter = Nearest;
			tile.getTexture().mipMap = None;
			bmps.push(new Bitmap(tile, container));
		}
	}

	public override function render(scene2d:Scene) {
		if (scene2d.contains(container))
			scene2d.removeChild(container);

		scene2d.addChild(container);

		var renderRect = this.getRenderRectangle();

		container.setPosition(Math.floor(renderRect.position.x), Math.floor(renderRect.position.y));

		var bottom = bmps[0];
		var bl = bmps[1];
		var br = bmps[2];
		var top = bmps[3];
		var tl = bmps[4];
		var tr = bmps[5];
		var left = bmps[6];
		var right = bmps[7];

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

	public override function dispose() {
		super.dispose();
		container.remove();
		for (bmp in this.bmps) {
			bmp.remove();
		}
	}
}
