package gui;

import h2d.Tile;
import hxd.BitmapData;
import h2d.filter.DropShadow;
import src.Settings;
import hxd.res.BitmapFont;
import h3d.Vector;
import src.ResourceLoader;
import src.MarbleGame;

class EnterNameDlg extends GuiControl {
	public function new(place:Int, okFunc:String->Void) {
		super();
		this.position = new Vector();
		this.extent = new Vector(800, 600);
		this.horizSizing = Width;
		this.vertSizing = Height;

		var whatneyFontData = ResourceLoader.getFileEntry("data/font/whatney.fnt");
		var whatneyFontB = new BitmapFont(whatneyFontData.entry);
		@:privateAccess whatneyFontB.loader = ResourceLoader.loader;
		var whatneyFont = whatneyFontB.toSdfFont(cast 21 * Settings.uiScale, MultiChannel);

		var squishneyFontData = ResourceLoader.getFileEntry("data/font/squishney.fnt");
		var squishneyFontB = new BitmapFont(squishneyFontData.entry);
		@:privateAccess squishneyFontB.loader = ResourceLoader.loader;
		var squishneyFont = squishneyFontB.toSdfFont(cast 28 * Settings.uiScale, MultiChannel);

		var squishneyFont28 = squishneyFontB.toSdfFont(cast 25 * Settings.uiScale, MultiChannel);

		function mlFontLoader(text:String) {
			switch (text) {
				case "bold28":
					return squishneyFont28;
				case "font24":
					return whatneyFont;
				default:
					return null;
			}
		}

		var dlg = new GuiTransparencyCtrl("data/ui/transparency/pqwindow");
		dlg.horizSizing = Center;
		dlg.vertSizing = Center;
		dlg.position = new Vector(226, 209);
		dlg.extent = new Vector(420, 256);
		this.addChild(dlg);

		var enterNameEdit = new GuiTextInput(whatneyFont);
		enterNameEdit.text.textColor = 0;
		enterNameEdit.text.selectionColor.setColor(0xFFFFFFFF);
		enterNameEdit.text.selectionTile = h2d.Tile.fromColor(0x808080, 0, hxd.Math.ceil(enterNameEdit.text.font.lineHeight));
		enterNameEdit.position = new Vector(28, 130);
		enterNameEdit.extent = new Vector(363, 38);
		enterNameEdit.text.text = Settings.highscoreName;
		haxe.Timer.delay(() -> {
			enterNameEdit.text.focus();
		}, 5);
		enterNameEdit.text.onFocus = (e) -> {
			dlg.vertSizing = Bottom;
			dlg.position = new Vector(110, 56);
			dlg.render(MarbleGame.canvas.scene2d);
		}
		enterNameEdit.text.onFocusLost = (e) -> {
			dlg.vertSizing = Center;
			dlg.position = new Vector(110, 112);
			dlg.render(MarbleGame.canvas.scene2d);
		}

		var okbutton = new GuiBorderButtonTextCtrl(ResourceLoader.getResource('data/ui/common/button.png', ResourceLoader.getImage, this.imageResources)
			.toTile(), whatneyFont);
		okbutton.position = new Vector(151, 184);
		okbutton.setExtent(new Vector(98, 49));
		okbutton.accelerator = hxd.Key.ENTER;
		okbutton.gamepadAccelerator = ["A"];
		okbutton.pressedAction = (sender) -> {
			MarbleGame.canvas.popDialog(this);
			Settings.highscoreName = enterNameEdit.text.text;
			if (StringTools.trim(Settings.highscoreName) == "")
				Settings.highscoreName = "Player";
			okFunc(Settings.highscoreName);
		}
		okbutton.txtCtrl.text.text = "Ok";
		dlg.addChild(okbutton);

		var boxbg = new GuiTransparencyCtrl("data/ui/transparency/75square");
		boxbg.position = new Vector(15, 113);
		boxbg.extent = new Vector(391, 55);
		dlg.addChild(boxbg);

		var enterNameText = new GuiMLText(whatneyFont, mlFontLoader);
		enterNameText.text.textColor = 0x0;
		enterNameText.text.dropShadow = {
			dx: 1 * Settings.uiScale,
			dy: 1 * Settings.uiScale,
			alpha: 0.5,
			color: 0
		};
		enterNameText.position = new Vector(37, 43);
		enterNameText.extent = new Vector(345, 85);
		// enterNameText.justify = Center;
		if (place != -1)
			enterNameText.text.text = '<p align="center"><font face="bold28">Well Done!<br/></font><font face="bold28">You have the${["", " second", " third", " fourth", " fifth"][place]} top score!</font></p>';
		else
			enterNameText.text.text = '<p align="center"><font face="font24">Enter your desired display name</font></p>';
		dlg.addChild(enterNameText);

		dlg.addChild(enterNameEdit);
	}
}
