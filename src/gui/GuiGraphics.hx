package gui;

import h2d.Graphics;
import gui.GuiControl.MouseState;
import h2d.Scene;
import h2d.Tile;
import h2d.Bitmap;
import src.MarbleGame;

@:publicFields
class GuiGraphics extends GuiControl {
	var graphics:Graphics;

	public var pressedAction:GuiControl->Void = null;

	public function new(graphics:Graphics) {
		super();
		this.graphics = graphics;
	}

	public override function render(scene2d:Scene, ?parent:h2d.Flow) {
		var renderRect = this.getRenderRectangle();
		graphics.setPosition(Math.floor(renderRect.position.x), Math.floor(renderRect.position.y));
		// bmp.scaleX = renderRect.extent.x / bmp.tile.width;
		// bmp.scaleY = renderRect.extent.y / bmp.tile.height;
		if (scene2d.contains(graphics)) {
			scene2d.removeChild(graphics); // Refresh "layer"
		}
		scene2d.addChild(graphics);
		super.render(scene2d);
	}

	public override function dispose() {
		super.dispose();
		this.graphics.remove();
	}

	public override function onMouseRelease(mouseState:MouseState) {
		super.onMouseRelease(mouseState);
		if (this.pressedAction != null) {
			this.pressedAction(this);
		}
	}

	public override function onRemove() {
		super.onRemove();
		if (MarbleGame.canvas.scene2d.contains(graphics)) {
			MarbleGame.canvas.scene2d.removeChild(graphics); // Refresh "layer"
		}
	}
}
