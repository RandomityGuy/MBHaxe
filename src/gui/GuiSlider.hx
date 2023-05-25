package gui;

import h2d.Scene;
import hxd.snd.Channel;
import hxd.res.Sound;
import hxd.Key;
import gui.GuiControl.MouseState;
import src.Util;
import src.Settings;

class GuiSlider extends GuiImage {
	public var sliderValue:Float = 0;

	public var slidingSound:Channel;

	public override function update(dt:Float, mouseState:MouseState) {
		var renderRect = getRenderRectangle();
		if (renderRect.inRect(mouseState.position)) {
			if (Key.isDown(Key.MOUSE_LEFT)) {
				sliderValue = (mouseState.position.x - renderRect.position.x - bmp.width / 2) / renderRect.extent.x;
				sliderValue = Util.clamp(sliderValue, 0, 1);

				if (this.pressedAction != null)
					this.pressedAction(this);

				if (slidingSound != null)
					slidingSound.pause = false;
			}
		} else if (slidingSound != null)
			slidingSound.pause = true;
		super.update(dt, mouseState);
		this.bmp.x = renderRect.position.x + renderRect.extent.x * sliderValue;
		this.bmp.x = Util.clamp(this.bmp.x, renderRect.position.x, renderRect.position.x + renderRect.extent.x - bmp.width / 2);
		this.bmp.width = this.bmp.tile.width * Settings.uiScale;
		super.update(dt, mouseState);
	}

	public override function render(scene2d:Scene) {
		super.render(scene2d);
		var renderRect = getRenderRectangle();
		this.bmp.width = this.bmp.tile.width * Settings.uiScale;
		this.bmp.x = renderRect.position.x + renderRect.extent.x * sliderValue;
		this.bmp.x = Util.clamp(this.bmp.x, renderRect.position.x, renderRect.position.x + renderRect.extent.x - bmp.width / 2);
		this.bmp.width = this.bmp.tile.width * Settings.uiScale;
	}
}
