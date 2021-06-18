package gui;

import h2d.Scene;
import hxd.res.BitmapFont;
import h2d.Text;

enum Justification {
	Left;
	Right;
	Center;
}

@:publicFields
class GuiText extends GuiControl {
	var text:Text;
	var justify:Justification = Left;

	public function new(font:BitmapFont) {
		super();
		this.text = new Text(font.toFont());
	}

	public override function render(scene2d:Scene) {
		super.render(scene2d);
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
		if (!scene2d.contains(text))
			scene2d.addChild(text);
	}
}
