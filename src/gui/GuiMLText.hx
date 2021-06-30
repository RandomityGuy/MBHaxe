package gui;

import gui.GuiText.Justification;
import h2d.HtmlText;
import h2d.Scene;
import hxd.res.BitmapFont;
import h2d.Text;
import src.MarbleGame;

@:publicFields
class GuiMLText extends GuiControl {
	var text:HtmlText;
	var justify:Justification = Left;

	public function new(font:BitmapFont, loadFontFunc:String->h2d.Font) {
		super();
		this.text = new HtmlText(font.toFont());
		this.text.loadFont = loadFontFunc;
	}

	public override function render(scene2d:Scene) {
		var renderRect = this.getRenderRectangle();
		text.maxWidth = renderRect.extent.x;
		if (justify == Left) {
			text.setPosition(Math.round(renderRect.position.x), Math.round(renderRect.position.y));
			text.textAlign = Left;
		}
		if (justify == Right) {
			text.setPosition(Math.round(renderRect.position.x + renderRect.extent.x), Math.round(renderRect.position.y));
			text.textAlign = Right;
		}
		if (justify == Center) {
			text.setPosition(Math.round(renderRect.position.x + renderRect.extent.x / 2), Math.round(renderRect.position.y));
			text.textAlign = Center;
		}
		if (scene2d.contains(text))
			scene2d.removeChild(text);
		scene2d.addChild(text);
		super.render(scene2d);
	}

	public override function dispose() {
		super.dispose();
		this.text.remove();
	}

	public override function onRemove() {
		super.onRemove();
		if (MarbleGame.canvas.scene2d.contains(text)) {
			MarbleGame.canvas.scene2d.removeChild(text); // Refresh "layer"
		}
	}
}
