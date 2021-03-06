package gui;

import h2d.TextInput;
import h2d.Scene;
import hxd.res.BitmapFont;
import gui.GuiText.Justification;
import h2d.Text;
import src.ResourceLoader;
import src.MarbleGame;

class GuiTextInput extends GuiControl {
	var text:TextInput;
	var justify:Justification = Left;

	public function new(font:BitmapFont) {
		super();
		this.text = new TextInput(font.toFont());
		this.text.textColor = 0;
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
		this.text.inputWidth = cast renderRect.extent.x;
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
