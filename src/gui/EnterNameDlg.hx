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
			var normal = ResourceLoader.getImage('${path}_n.png').toTile();
			var hover = ResourceLoader.getImage('${path}_h.png').toTile();
			var pressed = ResourceLoader.getImage('${path}_d.png').toTile();
			return [normal, hover, pressed];
		}

		var arial14fontdata = ResourceLoader.loader.load("data/font/Arial14.fnt");
		var arial14 = new BitmapFont(arial14fontdata.entry);
		@:privateAccess arial14.loader = ResourceLoader.loader;

		var domcasual32fontdata = ResourceLoader.loader.load("data/font/DomCasual32px.fnt");
		var domcasual32 = new BitmapFont(domcasual32fontdata.entry);
		@:privateAccess domcasual32.loader = ResourceLoader.loader;

		var expo50fontdata = ResourceLoader.loader.load("data/font/Expo50.fnt");
		var expo50 = new BitmapFont(expo50fontdata.entry);
		@:privateAccess expo50.loader = ResourceLoader.loader;

		var expo32fontdata = ResourceLoader.loader.load("data/font/Expo32.fnt");
		var expo32 = new BitmapFont(expo32fontdata.entry);
		@:privateAccess expo32.loader = ResourceLoader.loader;

		function mlFontLoader(text:String) {
			switch (text) {
				case "DomCasual32":
					return domcasual32.toFont();
				case "Arial14":
					return arial14.toFont();
				case "Expo50":
					return expo50.toFont();
				default:
					return null;
			}
		}

		var dlg = new GuiImage(ResourceLoader.getImage("data/ui/common/dialog.png").toTile());
		dlg.horizSizing = Center;
		dlg.vertSizing = Center;
		dlg.position = new Vector(112, 111);
		dlg.extent = new Vector(416, 257);
		this.addChild(dlg);

		var enterNameEdit = new GuiTextInput(domcasual32);
		enterNameEdit.position = new Vector(87, 136);
		enterNameEdit.extent = new Vector(255, 36);
		enterNameEdit.text.text = Settings.highscoreName;

		var okbutton = new GuiButton(loadButtonImages("data/ui/common/ok"));
		okbutton.position = new Vector(163, 182);
		okbutton.extent = new Vector(78, 59);
		okbutton.pressedAction = (sender) -> {
			MarbleGame.canvas.popDialog(this);
			Settings.highscoreName = enterNameEdit.text.text;
			okFunc(enterNameEdit.text.text);
		}
		dlg.addChild(okbutton);

		var wnd = new GuiImage(ResourceLoader.getImage("data/ui/common/window.png").toTile());
		wnd.position = new Vector(58, 124);
		wnd.extent = new Vector(295, 55);
		dlg.addChild(wnd);

		var enterNameText = new GuiMLText(domcasual32, mlFontLoader);
		enterNameText.text.textColor = 0;
		enterNameText.position = new Vector(41, 30);
		enterNameText.extent = new Vector(345, 14);
		// enterNameText.justify = Center;
		enterNameText.text.text = '<p align="center"><font face="Expo50">Congratulations<br/></font>You got the${["", " 2nd", " 3rd"][place]} best time!</p>';
		dlg.addChild(enterNameText);

		dlg.addChild(enterNameEdit);
	}
}
