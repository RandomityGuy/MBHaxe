package gui;

import h2d.Graphics;
import h2d.Scene;
import h3d.Vector;

class GuiProgress extends GuiControl {
	public var progress:Float = 0;
	public var progressColor:Int = 0x2C98A264;

	var progressRect:h2d.Graphics;

	public function new() {
		super();
	}

	public override function render(scene2d:Scene) {
		var renderRect = getRenderRectangle();
		if (this.progressRect == null) {
			this.progressRect = new Graphics();
		}
		if (scene2d.contains(progressRect))
			progressRect.remove();
		scene2d.addChild(progressRect);
		var rgb = progressColor >> 2;
		var a = progressColor & 0xFF;
		this.progressRect.clear();
		this.progressRect.beginFill(rgb, a / 0xFF);
		this.progressRect.drawRect(0, 0, renderRect.extent.x * progress, renderRect.extent.y);
		this.progressRect.endFill();
		this.progressRect.x = renderRect.position.x;
		this.progressRect.y = renderRect.position.y;
		super.render(scene2d);
	}

	public override function dispose() {
		if (progressRect != null)
			progressRect.remove();
		super.dispose();
	}
}
