package gui;

import hxd.Key;
import gui.GuiControl.MouseState;
import h2d.Scene;
import src.Console.ConsoleEntry;
import h2d.Graphics;
import h2d.Tile;
import h3d.mat.Texture;
import hxd.res.BitmapFont;
import src.ResourceLoader;
import h3d.Vector;
import src.Settings;
import src.Console;

class ConsoleDlg extends GuiControl {
	var onConsoleEntry:(e:ConsoleEntry) -> Void;
	var isShowing = false;

	var consoleContent:GuiMLText;
	var scroll:GuiConsoleScrollCtrl;
	var consoleInput:GuiTextInput;

	var cmdHistory:Array<String> = [];
	var cmdHistoryIndex = 0;

	public function new() {
		super();
		this.position = new Vector(0, 0);
		this.extent = new Vector(640, 370);

		var white = Tile.fromColor(0xFFFFFF);
		var black = Tile.fromColor(0x000000);
		var consoleWhite = new GuiImage(white);
		consoleWhite.position = new Vector(0, 0);
		consoleWhite.extent = new Vector(640, 350);
		consoleWhite.horizSizing = Width;
		consoleWhite.vertSizing = Top;
		this.addChild(consoleWhite);

		scroll = new GuiConsoleScrollCtrl(ResourceLoader.getResource("data/ui/common/darkscroll.png", ResourceLoader.getImage, this.imageResources).toTile());
		scroll.position = new Vector(0, 0);
		scroll.extent = new Vector(640, 350);
		scroll.horizSizing = Width;
		scroll.vertSizing = Height;

		consoleWhite.addChild(scroll);

		var consolefontdata = ResourceLoader.getFileEntry("data/font/Lucida Console.fnt");
		var consoleb = new BitmapFont(consolefontdata.entry);
		@:privateAccess consoleb.loader = ResourceLoader.loader;
		var consoleb = consoleb.toSdfFont(cast 11.7 * Settings.uiScale, MultiChannel);

		function mlFontLoader(text:String) {
			return null;
		}

		consoleContent = new GuiMLText(consoleb, mlFontLoader);
		consoleContent.position = new Vector(0, 0);
		consoleContent.extent = new Vector(640, 350);
		consoleContent.horizSizing = Width;
		consoleContent.vertSizing = Top;
		consoleContent.text.textColor = 0;
		consoleContent.scrollable = true;
		scroll.addChild(consoleContent);

		consoleContent.text.text = "";

		// Generate console text
		for (entry in Console.instance.entries) {
			var txt = '[${entry.time}] ${StringTools.htmlEscape(entry.text)}<br/>';
			consoleContent.text.text += txt;
		}

		scroll.setScrollMax(consoleContent.text.textHeight);
		scroll.updateScrollVisual();

		var arial14fontdata = ResourceLoader.getFileEntry("data/font/arial.fnt");
		var arial14b = new BitmapFont(arial14fontdata.entry);
		@:privateAccess arial14b.loader = ResourceLoader.loader;
		var arial14 = arial14b.toSdfFont(cast 14 * Settings.uiScale, MultiChannel);

		var bord = new GuiImage(black);
		bord.position = new Vector(0, 350);
		bord.extent = new Vector(640, 18);
		bord.horizSizing = Width;
		this.addChild(bord);

		consoleInput = new GuiTextInput(arial14);
		consoleInput.position = new Vector(1, 351);
		consoleInput.extent = new Vector(638, 20);
		consoleInput.horizSizing = Width;
		consoleInput.vertSizing = Top;
		consoleInput.text.textColor = 0;
		consoleInput.text.backgroundColor = 0xFFFFFFFF;
		consoleInput.text.selectionColor.set(1, 1, 1);
		consoleInput.text.selectionTile = h2d.Tile.fromColor(0x808080, 0, hxd.Math.ceil(consoleInput.text.font.lineHeight));

		this.addChild(consoleInput);

		onConsoleEntry = (e) -> {
			var txt = '[${e.time}] ${StringTools.htmlEscape(e.text)}<br/>';
			consoleContent.text.text += txt;
			if (isShowing) {
				scroll.setScrollMax(consoleContent.text.textHeight);
			}
		};

		Console.addConsumer(onConsoleEntry);
	}

	override function dispose() {
		super.dispose();
		Console.removeConsumer(onConsoleEntry);
	}

	public override function render(scene2d:Scene) {
		super.render(scene2d);

		scroll.setScrollMax(consoleContent.text.textHeight);
	}

	public override function update(dt:Float, mouseState:MouseState) {
		super.update(dt, mouseState);

		if (Key.isPressed(Key.ENTER) && consoleInput.text.text != "") {
			var cmdText = consoleInput.text.text;
			cmdHistory.push(cmdText);
			consoleContent.text.text += '==> ${cmdText}<br/>';
			Console.eval(cmdText);
			consoleInput.text.text = "";
			consoleInput.text.focus();
		}

		if (Key.isPressed(Key.UP)) {
			if (cmdHistoryIndex < cmdHistory.length) {
				cmdHistoryIndex++;
				consoleInput.text.text = cmdHistory[cmdHistory.length - cmdHistoryIndex];
			}
		}

		if (Key.isPressed(Key.DOWN)) {
			if (cmdHistoryIndex > 1) {
				cmdHistoryIndex--;
				consoleInput.text.text = cmdHistory[cmdHistory.length - cmdHistoryIndex];
			}
		}
	}
}
