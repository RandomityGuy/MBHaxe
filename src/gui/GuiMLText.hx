package gui;

import h2d.Flow;
import h3d.mat.Texture;
import h2d.Tile;
import h2d.Bitmap;
import h3d.Engine;
import h3d.Vector;
import shaders.GuiRender;
import gui.GuiText.Justification;
import h2d.HtmlText;
import h2d.Scene;
import hxd.res.BitmapFont;
import h2d.Text;
import src.MarbleGame;
import src.Settings;

@:publicFields
class GuiMLText extends GuiControl {
	var text:HtmlText;
	var justify:Justification = Left;
	var flow:Flow;

	public var scrollable:Bool = false;

	public function new(font:h2d.Font, loadFontFunc:String->h2d.Font) {
		super();
		this.text = new HtmlText(font);
		this.text.loadFont = loadFontFunc;
	}

	public override function render(scene2d:Scene) {
		var renderRect = this.getRenderRectangle();
		text.maxWidth = renderRect.extent.x;

		if (this.scrollable) {
			this.flow = new Flow();
			this.flow.addChild(this.text);

			this.flow.maxWidth = cast renderRect.extent.x;
			this.flow.maxHeight = cast renderRect.extent.y;
			this.flow.multiline = true;
			this.flow.overflow = FlowOverflow.Hidden;
		}

		var obj:h2d.Object = this.scrollable ? flow : text;

		if (justify == Left) {
			obj.setPosition(Math.floor(renderRect.position.x), Math.floor(renderRect.position.y));
			text.textAlign = Left;
		}
		if (justify == Right) {
			obj.setPosition(Math.floor(renderRect.position.x + renderRect.extent.x), Math.floor(renderRect.position.y));
			text.textAlign = Right;
		}
		if (justify == Center) {
			obj.setPosition(Math.floor(renderRect.position.x + renderRect.extent.x / 2), Math.floor(renderRect.position.y));
			text.textAlign = Center;
		}

		if (scene2d.contains(obj))
			scene2d.removeChild(obj);

		scene2d.addChild(obj);

		scene2d.addChild(obj);
		super.render(scene2d);
	}

	public override function dispose() {
		super.dispose();
		if (!this.scrollable) {
			this.text.remove();
		} else {
			this.flow.remove();
		}
	}

	public override function onRemove() {
		super.onRemove();
		if (MarbleGame.canvas.scene2d.contains(flow)) {
			MarbleGame.canvas.scene2d.removeChild(flow); // Refresh "layer"
		}
		if (MarbleGame.canvas.scene2d.contains(text)) {
			MarbleGame.canvas.scene2d.removeChild(text); // Refresh "layer"
		}
	}

	public override function onScroll(scrollX:Float, scrollY:Float) {
		text.setPosition(0, -scrollY);
	}
}
