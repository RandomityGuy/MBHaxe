package gui;

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

		var expo50fontdata = ResourceLoader.getFileEntry("data/font/EXPON.fnt");
		var expo50b = new BitmapFont(expo50fontdata.entry);
		@:privateAccess expo50b.loader = ResourceLoader.loader;
		var expo50 = expo50b.toSdfFont(cast 35 * Settings.uiScale, MultiChannel);
		var expo32 = expo50b.toSdfFont(cast 24 * Settings.uiScale, MultiChannel);

		function mlFontLoader(text:String) {
			switch (text) {
				case "DomCasual32":
					return domcasual32;
				case "Arial14":
					return arial14;
				case "Expo50":
					return expo50;
				default:
					return null;
			}
		}

		var dlg = new GuiImage(ResourceLoader.getResource("data/ui/common/dialog.png", ResourceLoader.getImage, this.imageResources).toTile());
		dlg.horizSizing = Center;
		dlg.vertSizing = Center;
		dlg.position = new Vector(112, 111);
		dlg.extent = new Vector(416, 257);
		this.addChild(dlg);

		var enterNameEdit = new GuiTextInput(domcasual32);
		enterNameEdit.text.textColor = 0;
		enterNameEdit.text.selectionColor.setColor(0xFFFFFFFF);
		enterNameEdit.text.selectionTile = h2d.Tile.fromColor(0x808080, 0, hxd.Math.ceil(enterNameEdit.text.font.lineHeight));
		enterNameEdit.position = new Vector(87, 136);
		enterNameEdit.extent = new Vector(255, 36);
		enterNameEdit.text.text = Settings.highscoreName;
		haxe.Timer.delay(() -> {
			enterNameEdit.text.focus();
		}, 5);

		var okbutton = new GuiButton(loadButtonImages("data/ui/common/ok"));
		okbutton.position = new Vector(163, 182);
		okbutton.extent = new Vector(78, 59);
		okbutton.accelerator = hxd.Key.ENTER;
		okbutton.pressedAction = (sender) -> {
			MarbleGame.canvas.popDialog(this);
			Settings.highscoreName = enterNameEdit.text.text;
			okFunc(enterNameEdit.text.text);
		}
		dlg.addChild(okbutton);

		var wnd = new GuiImage(ResourceLoader.getResource("data/ui/common/window.png", ResourceLoader.getImage, this.imageResources).toTile());
		wnd.position = new Vector(58, 124);
		wnd.extent = new Vector(295, 55);
		dlg.addChild(wnd);

		var enterNameText = new GuiMLText(domcasual32, mlFontLoader);
		enterNameText.text.textColor = 0;
		enterNameText.position = new Vector(41, 30);
		enterNameText.extent = new Vector(345, 14);
		// enterNameText.justify = Center;
		enterNameText.text.text = '<font face="Arial14"><br/></font><p align="center"><font face="Expo50">Congratulations!<br/></font>You got the${["", " 2nd", " 3rd"][place]} best time!</p>';
		dlg.addChild(enterNameText);

		dlg.addChild(enterNameEdit);
	}
}
