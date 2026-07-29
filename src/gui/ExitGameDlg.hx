package gui;

import src.MarbleGame;
import hxd.res.BitmapFont;
import h3d.Vector;
import src.ResourceLoader;
import src.Settings;

class ExitGameDlg extends GuiControl {
	public function new(yesFunc:GuiControl->Void, noFunc:GuiControl->Void, restartFunc:GuiControl->Void) {
		super();

		this.horizSizing = Width;
		this.vertSizing = Height;
		this.position = new Vector();
		this.extent = new Vector(800, 600);

		var bg = new GuiImage(ResourceLoader.getResource('data/ui/exit/black.png', ResourceLoader.getImage, this.imageResources).toTile());
		bg.horizSizing = Width;
		bg.vertSizing = Height;
		bg.position = new Vector();
		bg.extent = new Vector(800, 600);
		this.addChild(bg);

		var wnd = new GuiTransparencyCtrl("data/ui/transparency/pqwindow");
		wnd.horizSizing = Center;
		wnd.vertSizing = Center;
		wnd.position = new Vector(226, 209);
		wnd.extent = new Vector(348, 182);
		this.addChild(wnd);

		var whatneyFontData = ResourceLoader.getFileEntry("data/font/whatney.fnt");
		var whatneyFontB = new BitmapFont(whatneyFontData.entry);
		@:privateAccess whatneyFontB.loader = ResourceLoader.loader;
		var whatneyFont = whatneyFontB.toSdfFont(cast 21 * Settings.uiScale, MultiChannel);

		var squishneyFontData = ResourceLoader.getFileEntry("data/font/squishney.fnt");
		var squishneyFontB = new BitmapFont(squishneyFontData.entry);
		@:privateAccess squishneyFontB.loader = ResourceLoader.loader;
		var squishneyFont = squishneyFontB.toSdfFont(cast 28 * Settings.uiScale, MultiChannel);

		var squishneyFont28 = squishneyFontB.toSdfFont(cast 25 * Settings.uiScale, MultiChannel);

		var exitGameTitle = new GuiText(squishneyFont);
		exitGameTitle.text.textColor = 0x000000;
		exitGameTitle.text.text = "Exit from this level?";
		exitGameTitle.justify = Center;
		exitGameTitle.horizSizing = Center;
		exitGameTitle.position = new Vector(18, 35);
		exitGameTitle.extent = new Vector(312, 36);

		var yesButton = new GuiBorderButtonTextCtrl(ResourceLoader.getResource('data/ui/common/button.png', ResourceLoader.getImage, this.imageResources)
			.toTile(), whatneyFont);
		yesButton.position = new Vector(27, 106);
		yesButton.setExtent(new Vector(98, 49));
		yesButton.vertSizing = Top;
		yesButton.horizSizing = Right;
		yesButton.accelerator = hxd.Key.ENTER;
		yesButton.gamepadAccelerator = ["A"];
		yesButton.pressedAction = (sender) -> yesFunc(yesButton);
		yesButton.txtCtrl.text.text = "Yes";

		var noButton = new GuiBorderButtonTextCtrl(ResourceLoader.getResource('data/ui/common/button.png', ResourceLoader.getImage, this.imageResources)
			.toTile(), whatneyFont);
		noButton.position = new Vector(125, 106);
		noButton.setExtent(new Vector(98, 49));
		noButton.vertSizing = Top;
		noButton.horizSizing = Right;
		noButton.gamepadAccelerator = ["B"];
		noButton.pressedAction = (sender) -> noFunc(noButton);
		noButton.txtCtrl.text.text = "No";

		var restartButton = new GuiBorderButtonTextCtrl(ResourceLoader.getResource('data/ui/common/button.png', ResourceLoader.getImage, this.imageResources)
			.toTile(), whatneyFont);
		restartButton.position = new Vector(223, 106);
		restartButton.setExtent(new Vector(98, 49));
		restartButton.vertSizing = Top;
		restartButton.horizSizing = Right;
		restartButton.gamepadAccelerator = ["X"];
		restartButton.pressedAction = (sender) -> restartFunc(restartButton);
		restartButton.txtCtrl.text.text = "Restart";

		wnd.addChild(exitGameTitle);
		wnd.addChild(yesButton);
		wnd.addChild(noButton);
		wnd.addChild(restartButton);

		var jukeboxButton = new GuiBorderButtonTextCtrl(ResourceLoader.getResource('data/ui/common/button-plain.png', ResourceLoader.getImage,
			this.imageResources)
			.toTile(), squishneyFont28);
		jukeboxButton.position = new Vector(650, 525);
		jukeboxButton.setExtent(new Vector(140, 65));
		jukeboxButton.vertSizing = Top;
		jukeboxButton.horizSizing = Left;
		jukeboxButton.pressedAction = (e) -> {
			MarbleGame.canvas.pushDialog(new JukeboxDlg());
		}
		jukeboxButton.txtCtrl.text.text = "Jukebox";

		this.addChild(jukeboxButton);
	}
}
