package gui;

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

	public function new(font:h2d.Font, loadFontFunc:String->h2d.Font) {
		super();
		this.text = new HtmlText(font);
		this.text.loadFont = loadFontFunc;
		var uiScaleFactor = Settings.uiScale;
		this.text.scale(uiScaleFactor);
	}

	public override function render(scene2d:Scene) {
		var renderRect = this.getRenderRectangle();
		text.maxWidth = renderRect.extent.x;
		if (justify == Left) {
			text.setPosition(Math.floor(renderRect.position.x), Math.floor(renderRect.position.y));
			text.textAlign = Left;
		}
		if (justify == Right) {
			text.setPosition(Math.floor(renderRect.position.x + renderRect.extent.x), Math.floor(renderRect.position.y));
			text.textAlign = Right;
		}
		if (justify == Center) {
			text.setPosition(Math.floor(renderRect.position.x + renderRect.extent.x / 2), Math.floor(renderRect.position.y));
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
