package gui;

import h2d.Graphics;
import h2d.Scene;
import src.MarbleGame;

class GuiProgress extends GuiControl {
	public var progress(get, set):Float;

	var _progress:Float = 0;

	public var progressColor:Int = 0x2C98A264;

	var progressRect:h2d.Graphics;

	public function new() {
		super();
	}

	public override function render(scene2d:Scene, ?parent:h2d.Flow) {
		var renderRect = getRenderRectangle();
		if (this.progressRect == null) {
			this.progressRect = new Graphics();
		}
		if (parent != null) {
			if (parent.contains(this.progressRect)) {
				parent.removeChild(this.progressRect);
			}
			parent.addChild(this.progressRect);
			var off = this.getOffsetFromParent();
			var props = parent.getProperties(this.progressRect);
			props.isAbsolute = true;
			this.progressRect.setPosition(off.x, off.y);
		}
		// if (scene2d.contains(progressRect))
		// 	progressRect.remove();
		// scene2d.addChild(progressRect);
		var rgb = progressColor >> 2;
		var a = progressColor & 0xFF;
		this.progressRect.clear();
		this.progressRect.beginFill(rgb, a / 0xFF);
		this.progressRect.drawRect(0, 0, renderRect.extent.x * progress, renderRect.extent.y);
		this.progressRect.endFill();
		super.render(scene2d, parent);
	}

	public override function dispose() {
		if (progressRect != null)
			progressRect.remove();
		super.dispose();
	}

	public override function onRemove() {
		super.onRemove();
		if (MarbleGame.canvas.scene2d.contains(progressRect)) {
			MarbleGame.canvas.scene2d.removeChild(progressRect); // Refresh "layer"
		}
		this.progressRect.remove();
	}

	function get_progress() {
		return this._progress;
	}

	function set_progress(value:Float) {
		this._progress = value;
		if (progressRect != null) {
			var renderRect = getRenderRectangle();
			var rgb = progressColor >> 2;
			var a = progressColor & 0xFF;
			this.progressRect.clear();
			this.progressRect.beginFill(rgb, a / 0xFF);
			this.progressRect.drawRect(0, 0, renderRect.extent.x * progress, renderRect.extent.y);
			this.progressRect.endFill();
		}
		return value;
	}
}
