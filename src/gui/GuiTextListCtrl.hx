package gui;

import h2d.Flow;
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
import src.Settings;

class GuiTextListCtrl extends GuiControl {
	public var texts:Array<String>;
	public var onSelectedFunc:Int->Void;

	var font:Font;
	var textObjs:Array<Text>;
	var g:Graphics;
	var _prevSelected:Int = -1;

	public var selectedColor:Int = 0x206464;
	public var selectedFillColor:Int = 0xC8C8C8;
	public var textColor:Int = 0;

	public var textYOffset:Int = 0;

	public var scroll:Float = 0;

	public var scrollable:Bool = false;

	var flow:Flow;

	public function new(font:Font, texts:Array<String>, textColor:Int = 0) {
		super();
		this.font = font;
		this.texts = texts;
		this._manualScroll = true;
		this.textObjs = [];
		this.textColor = textColor;
		for (text in texts) {
			var tobj = new Text(font);
			tobj.text = text;
			tobj.textColor = textColor;
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
			tobj.textColor = textColor;
			textObjs.push(tobj);

			if (this.scrollable && this.flow != null) {
				if (this.flow.contains(tobj))
					this.flow.removeChild(tobj);

				this.flow.addChild(tobj);

				this.flow.getProperties(tobj).isAbsolute = true;
			}
		}
		this.texts = texts;
		this._prevSelected = -1;
		if (this.onSelectedFunc != null)
			this.onSelectedFunc(-1);

		redrawSelectionRect(renderRect);

		for (i in 0...textObjs.length) {
			var text = textObjs[i];
			text.setPosition(Math.floor((!scrollable ? renderRect.position.x : 0) + 5),
				Math.floor((!scrollable ? renderRect.position.y : 0)
					+ (i * (text.font.size + 4 * Settings.uiScale) + (5 + textYOffset) * Settings.uiScale - this.scroll)));

			if (_prevSelected == i) {
				text.textColor = selectedColor;
			}
		}
	}

	public override function render(scene2d:Scene, ?parent:h2d.Flow) {
		var renderRect = this.getRenderRectangle();
		var htr = this.getHitTestRect(false);

		if (parent != null) {
			if (parent.contains(g))
				parent.removeChild(g);
			parent.addChild(g);

			var off = this.getOffsetFromParent();
			parent.getProperties(g).isAbsolute = true;

			g.setPosition(off.x, off.y - this.scroll);
		}

		if (scrollable) {
			this.flow = new Flow();

			this.flow.maxWidth = cast htr.extent.x;
			this.flow.maxHeight = cast htr.extent.y;
			this.flow.multiline = true;
			this.flow.layout = Stack;
			this.flow.overflow = FlowOverflow.Hidden;

			if (parent != null) {
				if (parent.contains(this.flow)) {
					parent.removeChild(this.flow);
				}
				parent.addChild(this.flow);
				var off = this.getOffsetFromParent();
				var props = parent.getProperties(this.flow);
				props.isAbsolute = true;

				this.flow.setPosition(off.x, off.y);
			}
		}

		for (i in 0...textObjs.length) {
			var text = textObjs[i];
			if (!scrollable) {
				if (scene2d.contains(text))
					scene2d.removeChild(text);
				scene2d.addChild(text);
			} else {
				if (this.flow.contains(text))
					this.flow.removeChild(text);
				this.flow.addChild(text);

				this.flow.getProperties(text).isAbsolute = true;
			}

			text.setPosition(Math.floor((!scrollable ? renderRect.position.x : 0) + 5),
				Math.floor((!scrollable ? renderRect.position.y : 0)
					+ (i * (text.font.size + 4 * Settings.uiScale) + (5 + textYOffset) * Settings.uiScale - this.scroll)));

			if (_prevSelected == i) {
				text.textColor = selectedColor;
			}
		}

		redrawSelectionRect(htr);
		super.render(scene2d, parent);
	}

	public function calculateFullHeight() {
		return (this.texts.length * (font.size + 4 * Settings.uiScale));
	}

	public override function dispose() {
		super.dispose();
		for (text in textObjs) {
			text.remove();
		}
		this.g.remove();
		if (this.scrollable) {
			this.flow.remove();
		}
	}

	public override function onRemove() {
		super.onRemove();
		for (text in textObjs) {
			if (MarbleGame.canvas.scene2d.contains(text)) {
				MarbleGame.canvas.scene2d.removeChild(text); // Refresh "layer"
			}
			text.remove();
		}
		if (MarbleGame.canvas.scene2d.contains(g))
			MarbleGame.canvas.scene2d.removeChild(g);
		g.remove();
	}

	public override function onMouseMove(mouseState:MouseState) {
		var mousePos = mouseState.position;
		var renderRect = this.getRenderRectangle();
		var yStart = renderRect.position.y;
		var dy = mousePos.y - yStart;
		var hoverIndex = Math.floor(dy / (font.size + 4 * Settings.uiScale));
		if (hoverIndex >= this.texts.length) {
			hoverIndex = -1;
		}

		// Update the texts
		for (i in 0...textObjs.length) {
			var selected = i == hoverIndex || i == this._prevSelected;
			var text = textObjs[i];
			text.textColor = selected ? selectedColor : textColor;
			// fill color = 0xC8C8C8
		}
		// obviously in renderRect
	}

	public override function onMouseLeave(mouseState:MouseState) {
		for (i in 0...textObjs.length) {
			if (i == this._prevSelected)
				continue;
			var text = textObjs[i];
			text.textColor = textColor;
			// fill color = 0xC8C8C8
		}
	}

	public override function onMousePress(mouseState:MouseState) {
		super.onMousePress(mouseState);

		var mousePos = mouseState.position;
		var renderRect = this.getRenderRectangle();
		var yStart = renderRect.position.y;
		var dy = mousePos.y - yStart;
		var selectedIndex = Math.floor((dy + this.scroll) / (font.size + 4 * Settings.uiScale));
		if (selectedIndex >= this.texts.length) {
			selectedIndex = -1;
		}
		if (_prevSelected != selectedIndex) {
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

			var off = this.getOffsetFromParent();
			// Check if we are between the top and bottom, render normally in that case
			var topY = 2 * Settings.uiScale + (_prevSelected * (font.size + 4 * Settings.uiScale)) + g.y;
			var bottomY = 2 * Settings.uiScale + (_prevSelected * (font.size + 4 * Settings.uiScale)) + g.y + font.size + 4 * Settings.uiScale;
			var topRectY = off.y;
			var bottomRectY = off.y + renderRect.extent.y;

			if (topY >= topRectY && bottomY <= bottomRectY)
				g.drawRect(0, 5 * Settings.uiScale
					+ (_prevSelected * (font.size + 4 * Settings.uiScale))
					- 3 * Settings.uiScale, renderRect.extent.x,
					font.size
					+ 4 * Settings.uiScale);
			// We need to do math the draw the partially visible top selected
			if (topY <= topRectY && bottomY >= topRectY) {
				g.drawRect(0, this.scroll, renderRect.extent.x, topY + font.size + 4 * Settings.uiScale - off.y);
			}
			// Same for the bottom
			if (topY <= bottomRectY && bottomY >= bottomRectY) {
				g.drawRect(0, this.scroll
					+ renderRect.extent.y
					- font.size
					- 4 * Settings.uiScale
					+ (topY + font.size + 4 * Settings.uiScale - bottomRectY),
					renderRect.extent.x, off.y
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
		var hittestrect = this.getHitTestRect(false);
		for (i in 0...textObjs.length) {
			var text = textObjs[i];
			text.y = Math.floor((i * (text.font.size + 4 * Settings.uiScale) + (5 + textYOffset) * Settings.uiScale - scrollY));
			g.y = -scrollY;
		}
		redrawSelectionRect(hittestrect);
	}
}
