package gui;

import h2d.Graphics;
import gui.GuiControl.MouseState;
import h2d.Scene;
import h2d.Text;
import h2d.Font;
import src.MarbleGame;

class GuiTextListCtrl extends GuiControl {
	public var texts:Array<String>;

	public var onSelectedFunc:Int->Void;

	var font:Font;
	var textObjs:Array<Text>;
	var g:Graphics;
	var _prevSelected:Int = -1;

	public function new(font:Font, texts:Array<String>) {
		super();
		this.font = font;
		this.texts = texts;
		this.textObjs = [];
		for (text in texts) {
			var tobj = new Text(font);
			tobj.text = text;
			tobj.textColor = 0;
			textObjs.push(tobj);
		}
		this.g = new Graphics();
	}

	public override function render(scene2d:Scene) {
		var renderRect = this.getRenderRectangle();

		g.setPosition(renderRect.position.x, renderRect.position.y);
		if (scene2d.contains(g))
			scene2d.removeChild(g);
		scene2d.addChild(g);

		for (i in 0...textObjs.length) {
			var text = textObjs[i];
			text.setPosition(Math.floor(renderRect.position.x + 5), Math.floor(renderRect.position.y + (i * (text.font.size + 4) + 5)));
			if (scene2d.contains(text))
				scene2d.removeChild(text);
			scene2d.addChild(text);
		}

		super.render(scene2d);
	}

	public override function dispose() {
		super.dispose();
		for (text in textObjs) {
			text.remove();
		}
		this.g.remove();
	}

	public override function onRemove() {
		super.onRemove();
		for (text in textObjs) {
			if (MarbleGame.canvas.scene2d.contains(text)) {
				MarbleGame.canvas.scene2d.removeChild(text); // Refresh "layer"
			}
		}
		if (MarbleGame.canvas.scene2d.contains(g))
			MarbleGame.canvas.scene2d.removeChild(g);
	}

	public override function onMouseMove(mouseState:MouseState) {
		var mousePos = mouseState.position;
		var renderRect = this.getRenderRectangle();
		var yStart = renderRect.position.y;
		var dy = mousePos.y - yStart;
		var hoverIndex = Math.floor(dy / (font.size + 4));
		if (hoverIndex >= this.texts.length) {
			hoverIndex = -1;
		}

		// Update the texts
		for (i in 0...textObjs.length) {
			var selected = i == hoverIndex || i == this._prevSelected;
			var text = textObjs[i];
			text.textColor = selected ? 0x206464 : 0;
			// fill color = 0xC8C8C8
		}
		// obviously in renderRect
	}

	public override function onMouseLeave(mouseState:MouseState) {
		for (i in 0...textObjs.length) {
			var text = textObjs[i];
			text.textColor = 0;
			// fill color = 0xC8C8C8
		}
	}

	public override function onMousePress(mouseState:MouseState) {
		super.onMousePress(mouseState);

		var mousePos = mouseState.position;
		var renderRect = this.getRenderRectangle();
		var yStart = renderRect.position.y;
		var dy = mousePos.y - yStart;
		var selectedIndex = Math.floor(dy / (font.size + 4));
		if (selectedIndex >= this.texts.length) {
			selectedIndex = -1;
		}
		if (_prevSelected != selectedIndex) {
			_prevSelected = selectedIndex;

			if (selectedIndex != -1) {
				g.clear();
				g.beginFill(0xC8C8C8);
				g.drawRect(0, 5 + (selectedIndex * (font.size + 4)) - 3, renderRect.extent.x, font.size + 4);
				g.endFill();
			} else {
				g.clear();
			}
		}

		if (onSelectedFunc != null) {
			onSelectedFunc(selectedIndex);
		}
	}
}
