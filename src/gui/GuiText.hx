package gui;

import h2d.Font;
import src.Settings;
import h2d.Scene;
import hxd.res.BitmapFont;
import h2d.Text;
import src.MarbleGame;

enum Justification {
	Left;
	Right;
	Center;
}

@:publicFields
class GuiText extends GuiControl {
	var text:Text;
	var justify:Justification = Left;

	public function new(font:Font) {
		super();
		this.text = new Text(font);
	}

	public override function render(scene2d:Scene, ?parent:h2d.Flow) {
		var renderRect = this.getRenderRectangle();
		if (parent != null) {
			if (parent.contains(this.text)) {
				parent.removeChild(this.text);
			}
			parent.addChild(this.text);
			var off = this.getOffsetFromParent();
			var props = parent.getProperties(this.text);
			props.isAbsolute = true;

			if (justify == Left) {
				text.setPosition(Math.floor(off.x), Math.floor(off.y));
				text.textAlign = Left;
			}
			if (justify == Right) {
				text.setPosition(Math.floor(off.x + renderRect.extent.x), Math.floor(off.y));
				text.textAlign = Right;
			}
			if (justify == Center) {
				text.setPosition(Math.floor(off.x + renderRect.extent.x / 2), Math.floor(off.y));
				text.textAlign = Center;
			}
		}
		// if (justify == Left) {
		// 	text.setPosition(Math.floor(renderRect.position.x), Math.floor(renderRect.position.y));
		// 	text.textAlign = Left;
		// }
		// if (justify == Right) {
		// 	text.setPosition(Math.floor(renderRect.position.x + renderRect.extent.x), Math.floor(renderRect.position.y));
		// 	text.textAlign = Right;
		// }
		// if (justify == Center) {
		// 	text.setPosition(Math.floor(renderRect.position.x + renderRect.extent.x / 2), Math.floor(renderRect.position.y));
		// 	text.textAlign = Center;
		// }
		// if (scene2d.contains(text))
		// 	scene2d.removeChild(text);
		// scene2d.addChild(text);
		super.render(scene2d, parent);
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
		this.text.remove();
	}
}
