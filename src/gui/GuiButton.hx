package gui;

import hxd.Key;
import gui.GuiControl.MouseState;
import hxd.Window;
import h2d.Tile;

class GuiButton extends GuiAnim {
	// 0 is normal
	// 1 is hover
	// 2 is pressed
	// 3 is disabled
	public function new(anim:Array<Tile>) {
		super(anim);
	}

	public override function update(dt:Float, mouseState:MouseState) {
		var renderRect = getRenderRectangle();
		if (renderRect.inRect(mouseState.position)) {
			if (Key.isDown(Key.MOUSE_LEFT)) {
				this.anim.currentFrame = 2;
			} else {
				this.anim.currentFrame = 1;
			}
		} else
			this.anim.currentFrame = 0;
		super.update(dt, mouseState);
	}
}
