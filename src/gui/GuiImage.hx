package gui;

import h2d.Flow;
import shaders.GuiClipFilter;
import h2d.filter.Mask;
import gui.GuiControl.MouseState;
import h2d.Scene;
import h2d.Tile;
import h2d.Bitmap;
import src.MarbleGame;

@:publicFields
class GuiImage extends GuiControl {
	var bmp:Bitmap;
	var bmpFlow:Flow;

	public var pressedAction:GuiEvent->Void = null;

	public var doClipping:Bool = false;

	public function new(texture:Tile) {
		super();
		this.bmp = new Bitmap(texture);
	}

	public override function render(scene2d:Scene, ?parent:h2d.Flow) {
		if (parent != null) {
			if (parent.contains(this.bmp)) {
				parent.removeChild(this.bmp);
			}
			parent.addChild(this.bmp);
			var off = this.getOffsetFromParent();
			var props = parent.getProperties(this.bmp);
			props.isAbsolute = true;
			this.bmp.setPosition(off.x, off.y);
		}
		super.render(scene2d, parent);
		var renderRect = this.getRenderRectangle();
		bmp.width = renderRect.extent.x;
		bmp.height = renderRect.extent.y;
	}

	public override function dispose() {
		super.dispose();
		this.bmp.remove();
	}

	public override function onMouseRelease(mouseState:MouseState) {
		super.onMouseRelease(mouseState);
		if (this.pressedAction != null) {
			this.pressedAction(new GuiEvent(this));
		}
	}

	public override function onRemove() {
		super.onRemove();
		if (MarbleGame.canvas.scene2d.contains(bmpFlow)) {
			MarbleGame.canvas.scene2d.removeChild(bmpFlow); // Refresh "layer"
		}
		if (MarbleGame.canvas.scene2d.contains(bmp)) {
			MarbleGame.canvas.scene2d.removeChild(bmp); // Refresh "layer"
		}
		this.bmp.remove();
	}
}
