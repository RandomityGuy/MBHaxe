package gui;

import h2d.Scene;
import h2d.Tile;
import h2d.Bitmap;

@:publicFields
class GuiImage extends GuiControl {
	var bmp:Bitmap;

	public function new(texture:Tile) {
		super();
		this.bmp = new Bitmap(texture);
	}

	public override function render(scene2d:Scene) {
		super.render(scene2d);
		var renderRect = this.getRenderRectangle();
		bmp.setPosition(renderRect.position.x, renderRect.position.y);
		bmp.scaleX = renderRect.extent.x / bmp.tile.width;
		bmp.scaleY = renderRect.extent.y / bmp.tile.height;
		if (!scene2d.contains(bmp))
			scene2d.addChild(bmp);
	}
}
