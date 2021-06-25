package gui;

import hxd.Key;
import gui.GuiControl.MouseState;
import src.Util;

class GuiSlider extends GuiImage {
	public var sliderValue:Float = 0;

	public override function update(dt:Float, mouseState:MouseState) {
		var renderRect = getRenderRectangle();
		if (renderRect.inRect(mouseState.position)) {
			if (Key.isDown(Key.MOUSE_LEFT)) {
				sliderValue = (mouseState.position.x - renderRect.position.x - bmp.width / 2) / renderRect.extent.x;
				sliderValue = Util.clamp(sliderValue, 0, 1);
			}
		}
		super.update(dt, mouseState);
		this.bmp.x = renderRect.position.x + renderRect.extent.x * sliderValue;
		this.bmp.width = this.bmp.tile.width;
	}
}
