package gui;

import h3d.Vector;
import h2d.Scene;
import h2d.Flow;
import h2d.Tile;

class GuiBitmapBorderCtrl extends GuiControl {
	var tiles:Array<Tile>;

	var bmps:Array<h2d.Bitmap>; // [tl, tr, bl, br, top, left, right, bottom, fill]
	var container:h2d.Object;

	public function new(texture:Tile, fill:Int, texs:{
		tl:Vector,
		tr:Vector,
		bl:Vector,
		br:Vector,
		top:Vector,
		left:Vector,
		right:Vector,
		bottom:Vector,
	}) {
		super();
		var tl = texture.sub(texs.tl.x, texs.tl.y, texs.tl.z, texs.tl.w);
		var tr = texture.sub(texs.tr.x, texs.tr.y, texs.tr.z, texs.tr.w);
		var top = texture.sub(texs.top.x, texs.top.y, texs.top.z, texs.top.w);
		var left = texture.sub(texs.left.x, texs.left.y, texs.left.z, texs.left.w);
		var right = texture.sub(texs.right.x, texs.right.y, texs.right.z, texs.right.w);
		var bl = texture.sub(texs.bl.x, texs.bl.y, texs.bl.z, texs.bl.w);
		var bottom = texture.sub(texs.bottom.x, texs.bottom.y, texs.bottom.z, texs.bottom.w);
		var br = texture.sub(texs.br.x, texs.br.y, texs.br.z, texs.br.w);
		var fillTile = Tile.fromColor(fill);
		tiles = [tl, tr, bl, br, top, left, right, bottom, fillTile];

		this.container = new h2d.Object();
		this.bmps = [];
		for (tile in tiles) {
			this.bmps.push(new h2d.Bitmap(tile, container));
		}
	}

	public override function render(scene2d:Scene, ?parent:Flow) {
		if (parent.contains(container))
			parent.removeChild(container);

		parent.addChild(container);
		var props = parent.getProperties(container);
		props.isAbsolute = true;

		var renderRect = this.getRenderRectangle();

		container.setPosition(0, 0);

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
}
