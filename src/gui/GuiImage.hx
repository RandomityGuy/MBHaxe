package gui;

import gui.GuiControl.MouseState;
import h2d.Scene;
import h2d.Tile;
import h2d.Bitmap;

@:publicFields
class GuiImage extends GuiControl {
	var bmp:Bitmap;

	public var pressedAction:GuiControl->Void = null;

	public function new(texture:Tile) {
		super();
		this.bmp = new Bitmap(texture);
	}

	public override function render(scene2d:Scene) {
		var renderRect = this.getRenderRectangle();
		bmp.setPosition(renderRect.position.x, renderRect.position.y);
		// bmp.scaleX = renderRect.extent.x / bmp.tile.width;
		// bmp.scaleY = renderRect.extent.y / bmp.tile.height;
		bmp.width = renderRect.extent.x;
		bmp.height = renderRect.extent.y;
		if (scene2d.contains(bmp)) {
			scene2d.removeChild(bmp); // Refresh "layer"
		}
		scene2d.addChild(bmp);
		super.render(scene2d);
	}

	public override function dispose() {
		super.dispose();
		this.bmp.remove();
	}

	public override function onMouseRelease(mouseState:MouseState) {
		super.onMouseRelease(mouseState);
		if (this.pressedAction != null) {
			this.pressedAction(this);
		}
	}
}
