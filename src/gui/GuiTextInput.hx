package gui;

import src.JSPlatform;
import src.Util;
import gui.GuiControl.MouseState;
import h2d.TextInput;
import h2d.Scene;
import hxd.res.BitmapFont;
import gui.GuiText.Justification;
import h2d.Text;
import src.Gamepad;
import src.ResourceLoader;
import src.MarbleGame;

class GuiTextInput extends GuiControl {
	var text:TextInput;
	var justify:Justification = Left;

	var onTextChange:String->Void;

	public function new(font:h2d.Font) {
		super();
		this.text = new TextInput(font);
		// this.text.textColor = 0;
		this.text.onChange = () -> {
			if (onTextChange != null) {
				onTextChange(this.text.text);
			}
		};
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
		this.text.inputWidth = cast renderRect.extent.x;
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
		text.remove();
	}

	public override function onMousePress(mouseState:MouseState) {
		super.onMousePress(mouseState);

		#if js
		if (Util.isTouchDevice()) {
			text.text = js.Browser.window.prompt("Enter your input", text.text);
			onTextChange(this.text.text);
			var canvas = js.Browser.document.querySelector("#webgl");
			// canvas.focus();
			// js.Browser.document.documentElement.requestFullscreen();
		}
		#end
	}

	public function setCaretColor(col:Int) {
		text.cursorTile = h2d.Tile.fromColor(col, Std.int(1 / hxd.Window.getInstance().windowToPixelRatio), text.font.size);
		text.cursorTile.dy = 2 / hxd.Window.getInstance().windowToPixelRatio;
	}

	#if uwp
	override public function update(dt:Float, mouseState:MouseState) {
		super.update(dt, mouseState);

		// Calling focus on init causes issue with cursor pos and event tracking but works fine here
		// This will break if there are ever multiple text inputs, but works nice for simple popup dialogs
		if (Gamepad.isPressed(["dpadUp"]) || (Gamepad.getAxis('analogY') < -0.75)) {
			this.text.focus();
		}
	}
	#end
}
