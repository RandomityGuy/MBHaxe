package gui;

import gui.GuiText.Justification;
import h2d.HtmlText;
import h2d.Scene;
import hxd.res.BitmapFont;
import h2d.Text;

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
		if (justify == Left) {
			text.setPosition(renderRect.position.x, renderRect.position.y);
			text.textAlign = Left;
		}
		if (justify == Right) {
			text.setPosition(renderRect.position.x + renderRect.extent.x, renderRect.position.y);
			text.textAlign = Right;
		}
		if (justify == Center) {
			text.setPosition(renderRect.position.x + renderRect.extent.x / 2, renderRect.position.y);
			text.textAlign = Center;
		}
		if (scene2d.contains(text))
			scene2d.removeChild(text);
		scene2d.addChild(text);
		text.maxWidth = renderRect.extent.x;
		super.render(scene2d);
	}

	public override function dispose() {
		super.dispose();
		this.text.remove();
	}
}
