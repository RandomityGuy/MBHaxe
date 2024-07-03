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
		this.extent = new Vector(640, 480);
		this.horizSizing = Width;
		this.vertSizing = Height;

		function loadButtonImages(path:String) {
			var normal = ResourceLoader.getResource('${path}_n.png', ResourceLoader.getImage, this.imageResources).toTile();
			var hover = ResourceLoader.getResource('${path}_h.png', ResourceLoader.getImage, this.imageResources).toTile();
			var pressed = ResourceLoader.getResource('${path}_d.png', ResourceLoader.getImage, this.imageResources).toTile();
			return [normal, hover, pressed];
		}

		var arial14fontdata = ResourceLoader.getFileEntry("data/font/arial.fnt");
		var arial14b = new BitmapFont(arial14fontdata.entry);
		@:privateAccess arial14b.loader = ResourceLoader.loader;
		var arial14 = arial14b.toSdfFont(cast 12 * Settings.uiScale, MultiChannel);

		var domcasual32fontdata = ResourceLoader.getFileEntry("data/font/DomCasualD.fnt");
		var domcasual32b = new BitmapFont(domcasual32fontdata.entry);
		@:privateAccess domcasual32b.loader = ResourceLoader.loader;
		var domcasual32 = domcasual32b.toSdfFont(cast 26 * Settings.uiScale, MultiChannel);
		var domcasual48 = domcasual32b.toSdfFont(cast 42 * Settings.uiScale, MultiChannel);

		function mlFontLoader(text:String) {
			switch (text) {
				case "DomCasual32":
					return domcasual32;
				case "DomCasual48":
					return domcasual48;
				case "Arial14":
					return arial14;
				default:
					return null;
			}
		}

		var dlg = new GuiImage(ResourceLoader.getResource("data/ui/endgame/enternamebox.png", ResourceLoader.getImage, this.imageResources).toTile());
		dlg.horizSizing = Center;
		dlg.vertSizing = Center;
		dlg.position = new Vector(110, 112);
		dlg.extent = new Vector(420, 256);
		this.addChild(dlg);

		var enterNameEdit = new GuiTextInput(domcasual32);
		enterNameEdit.text.textColor = 0;
		enterNameEdit.text.selectionColor.setColor(0xFFFFFFFF);
		enterNameEdit.text.selectionTile = h2d.Tile.fromColor(0x808080, 0, hxd.Math.ceil(enterNameEdit.text.font.lineHeight));
		enterNameEdit.position = new Vector(28, 130);
		enterNameEdit.extent = new Vector(363, 38);
		enterNameEdit.text.text = Settings.highscoreName;
		haxe.Timer.delay(() -> {
			enterNameEdit.text.focus();
		}, 5);

		var okbutton = new GuiButton(loadButtonImages("data/ui/endgame/ok"));
		okbutton.position = new Vector(151, 184);
		okbutton.extent = new Vector(110, 55);
		okbutton.accelerator = hxd.Key.ENTER;
		okbutton.gamepadAccelerator = ["A"];
		okbutton.pressedAction = (sender) -> {
			MarbleGame.canvas.popDialog(this);
			Settings.highscoreName = enterNameEdit.text.text;
			okFunc(enterNameEdit.text.text);
		}
		dlg.addChild(okbutton);

		var wnd = new GuiImage(ResourceLoader.getResource("data/ui/endgame/window.png", ResourceLoader.getImage, this.imageResources).toTile());
		wnd.horizSizing = Width;
		wnd.vertSizing = Height;
		wnd.position = new Vector(16, 119);
		wnd.extent = new Vector(388, 56);
		dlg.addChild(wnd);

		var enterNameText = new GuiMLText(domcasual32, mlFontLoader);
		enterNameText.text.textColor = 0xFFFFFF;
		enterNameText.text.dropShadow = {
			dx: 1,
			dy: 1,
			alpha: 0.5,
			color: 0
		};
		enterNameText.position = new Vector(37, 23);
		enterNameText.extent = new Vector(345, 85);
		// enterNameText.justify = Center;
		if (place != -1)
			enterNameText.text.text = '<font face="Arial14"><br/></font><p align="center"><font face="DomCasual48">Well Done!<br/></font><font face="DomCasual32">You have the${["", " second", " third", " fourth", " fifth"][place]} top time!</font></p>';
		else
			enterNameText.text.text = '<p align="center"><font face="DomCasual32">Enter your desired display name</font></p>';
		dlg.addChild(enterNameText);

		dlg.addChild(enterNameEdit);
	}
}
