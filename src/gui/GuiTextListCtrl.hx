package gui;

import h3d.Engine;
import h2d.Tile;
import h2d.Bitmap;
import h3d.mat.Texture;
import shaders.GuiClipFilter;
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

	var bmp:Bitmap;
	var textTexture:Texture;
	var _dirty = true;

	public var selectedColor:Int = 0x206464;
	public var selectedFillColor:Int = 0xC8C8C8;

	public var textYOffset:Int = 0;

	public var scroll:Float = 0;

	public var scrollable:Bool = false;

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

	public function setTexts(texts:Array<String>) {
		var renderRect = this.getRenderRectangle();
		for (textObj in this.textObjs) {
			textObj.remove();
		}
		this.textObjs = [];
		for (text in texts) {
			var tobj = new Text(font);
			tobj.text = text;
			tobj.textColor = 0;
			textObjs.push(tobj);
		}
		this.texts = texts;
		this._prevSelected = -1;
		if (this.onSelectedFunc != null)
			this.onSelectedFunc(-1);
		this._dirty = true;

		redrawSelectionRect(renderRect);

		for (i in 0...textObjs.length) {
			var text = textObjs[i];
			text.setPosition(Math.floor((!scrollable ? renderRect.position.x : 0) + 5),
				Math.floor((!scrollable ? renderRect.position.y : 0) + (i * (text.font.size + 4) + 5 + textYOffset - this.scroll)));

			if (_prevSelected == i) {
				text.textColor = selectedColor;
			}
		}
	}

	public override function render(scene2d:Scene) {
		var renderRect = this.getRenderRectangle();

		if (scene2d.contains(g))
			scene2d.removeChild(g);
		scene2d.addChild(g);
		g.setPosition(renderRect.position.x, renderRect.position.y - this.scroll);

		if (scrollable) {
			if (textTexture != null)
				textTexture.dispose();

			var htr = this.getHitTestRect();

			textTexture = new Texture(cast htr.extent.x, cast htr.extent.y, [Target]);
			if (bmp != null) {
				bmp.tile = Tile.fromTexture(textTexture);
			} else {
				bmp = new Bitmap(Tile.fromTexture(textTexture));
			}

			if (scene2d.contains(bmp))
				scene2d.removeChild(bmp);

			scene2d.addChild(bmp);

			bmp.setPosition(htr.position.x, htr.position.y);
		}

		for (i in 0...textObjs.length) {
			var text = textObjs[i];
			text.setPosition(Math.floor((!scrollable ? renderRect.position.x : 0) + 5),
				Math.floor((!scrollable ? renderRect.position.y : 0) + (i * (text.font.size + 4) + 5 + textYOffset - this.scroll)));
			if (!scrollable) {
				if (scene2d.contains(text))
					scene2d.removeChild(text);
				scene2d.addChild(text);
			}

			if (_prevSelected == i) {
				text.textColor = selectedColor;
			}
		}

		redrawSelectionRect(renderRect);
		redrawText();

		super.render(scene2d);
	}

	public function calculateFullHeight() {
		return (this.texts.length * (font.size + 4));
	}

	public override function dispose() {
		super.dispose();
		for (text in textObjs) {
			text.remove();
		}
		this.g.remove();
		if (this.scrollable) {
			this.textTexture.dispose();
			this.bmp.remove();
		}
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
			text.textColor = selected ? selectedColor : 0;
			// fill color = 0xC8C8C8
		}
		this._dirty = true;
		// obviously in renderRect
	}

	public override function onMouseLeave(mouseState:MouseState) {
		for (i in 0...textObjs.length) {
			if (i == this._prevSelected)
				continue;
			var text = textObjs[i];
			text.textColor = 0;
			// fill color = 0xC8C8C8
		}
		this._dirty = true;
	}

	public override function onMousePress(mouseState:MouseState) {
		super.onMousePress(mouseState);

		var mousePos = mouseState.position;
		var renderRect = this.getRenderRectangle();
		var yStart = renderRect.position.y;
		var dy = mousePos.y - yStart;
		var selectedIndex = Math.floor((dy + this.scroll) / (font.size + 4));
		if (selectedIndex >= this.texts.length) {
			selectedIndex = -1;
		}
		if (_prevSelected != selectedIndex) {
			this._dirty = true;
			_prevSelected = selectedIndex;

			redrawSelectionRect(renderRect);
		}

		if (onSelectedFunc != null) {
			onSelectedFunc(selectedIndex);
		}
	}

	function redrawSelectionRect(renderRect:Rect) {
		if (_prevSelected != -1) {
			g.clear();
			g.beginFill(selectedFillColor);

			// Check if we are between the top and bottom, render normally in that case
			var topY = 2 + (_prevSelected * (font.size + 4)) + g.y;
			var bottomY = 2 + (_prevSelected * (font.size + 4)) + g.y + font.size + 4;
			var topRectY = renderRect.position.y;
			var bottomRectY = renderRect.position.y + renderRect.extent.y;

			if (topY >= topRectY && bottomY <= bottomRectY)
				g.drawRect(0, 5 + (_prevSelected * (font.size + 4)) - 3, renderRect.extent.x, font.size + 4);
			// We need to do math the draw the partially visible top selected
			if (topY <= topRectY && bottomY >= topRectY) {
				g.drawRect(0, this.scroll, renderRect.extent.x, topY + font.size + 4 - renderRect.position.y);
			}
			// Same for the bottom
			if (topY <= bottomRectY && bottomY >= bottomRectY) {
				g.drawRect(0, this.scroll
					+ renderRect.extent.y
					- font.size
					- 4
					+ (topY + font.size + 4 - bottomRectY), renderRect.extent.x,
					renderRect.position.y
					+ renderRect.extent.y
					- (topY));
			}
			g.endFill();
		} else {
			g.clear();
		}
	}

	public override function onScroll(scrollX:Float, scrollY:Float) {
		super.onScroll(scrollX, scrollY);
		var renderRect = this.getRenderRectangle();

		this.scroll = scrollY;
		var hittestrect = this.getHitTestRect();
		for (i in 0...textObjs.length) {
			var text = textObjs[i];
			text.y = Math.floor((i * (text.font.size + 4) + 5 + textYOffset - scrollY));
			g.y = renderRect.position.y - scrollY;

			// if (text.y < hittestrect.position.y - text.textHeight || text.y > hittestrect.position.y + hittestrect.extent.y)
			// 	text.visible = false;
			// else {
			// 	text.visible = true;
			// }
		}
		redrawSelectionRect(hittestrect);
		this._dirty = true;
	}

	function redrawText() {
		if (this.scrollable) {
			#if hl
			if (this._dirty) {
			#end
				textTexture.clear(0, 0);
				for (txt in this.textObjs) {
					txt.drawTo(textTexture);
				}
			#if hl
			this._dirty = false;
			}
			#end
		}
	}

	public override function renderEngine(engine:Engine) {
		redrawText();
		super.renderEngine(engine);
	}
}
