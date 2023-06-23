package gui;

import h2d.filter.DropShadow;
import src.MarbleGame;
import gui.GuiControl.MouseState;
import hxd.res.BitmapFont;
import h3d.Vector;
import src.ResourceLoader;
import src.Settings;

class DifficultySelectGui extends GuiImage {
	public function new() {
		var res = ResourceLoader.getImage("data/ui/xbox/BG_fadeOutSoftEdge.png").resource.toTile();
		super(res);
		var domcasual32fontdata = ResourceLoader.getFileEntry("data/font/DomCasualD.fnt");
		var domcasual32b = new BitmapFont(domcasual32fontdata.entry);
		@:privateAccess domcasual32b.loader = ResourceLoader.loader;
		var domcasual32 = domcasual32b.toSdfFont(cast 42 * Settings.uiScale, MultiChannel);

		this.horizSizing = Width;
		this.vertSizing = Height;
		this.position = new Vector();
		this.extent = new Vector(640, 480);

		var scene2d = MarbleGame.canvas.scene2d;

		var offsetX = (scene2d.width - 1280) / 2;
		var offsetY = (scene2d.height - 720) / 2;

		var subX = 640 - (scene2d.width - offsetX) * 640 / scene2d.width;
		var subY = 480 - (scene2d.height - offsetY) * 480 / scene2d.height;

		var innerCtrl = new GuiControl();
		innerCtrl.position = new Vector(offsetX, offsetY);
		innerCtrl.extent = new Vector(640 - subX, 480 - subY);
		innerCtrl.horizSizing = Width;
		innerCtrl.vertSizing = Height;
		this.addChild(innerCtrl);

		var coliseumfontdata = ResourceLoader.getFileEntry("data/font/ColiseumRR.fnt");
		var coliseumb = new BitmapFont(coliseumfontdata.entry);
		@:privateAccess coliseumb.loader = ResourceLoader.loader;
		var coliseum = coliseumb.toSdfFont(cast 44 * Settings.uiScale, MultiChannel);

		var rootTitle = new GuiText(coliseum);
		rootTitle.position = new Vector(100, 30);
		rootTitle.extent = new Vector(1120, 80);
		rootTitle.text.textColor = 0xFFFFFF;
		rootTitle.text.text = "SELECT DIFFICULTY";
		rootTitle.text.alpha = 0.5;
		innerCtrl.addChild(rootTitle);

		var btnList = new GuiXboxList();
		btnList.position = new Vector(70 - offsetX, 165);
		btnList.horizSizing = Left;
		btnList.extent = new Vector(502, 500);
		innerCtrl.addChild(btnList);

		btnList.addButton(0, 'Beginner Levels', (e) -> {});
		btnList.addButton(0, 'Intermediate Levels', (e) -> {});
		btnList.addButton(0, 'Advanced Levels', (e) -> {});
		btnList.addButton(0, 'Gem Hunt', (e) -> {}, 20);

		var bottomBar = new GuiControl();
		bottomBar.position = new Vector(0, innerCtrl.extent.x * 590 / 480);
		bottomBar.extent = new Vector(640, 200);
		bottomBar.horizSizing = Width;
		bottomBar.vertSizing = Bottom;
		this.addChild(bottomBar);

		var backButton = new GuiXboxButton("Back", 160);
		backButton.position = new Vector(-240, 0);
		backButton.vertSizing = Bottom;
		backButton.horizSizing = Left;
		backButton.gamepadAccelerator = ["B"];
		backButton.pressedAction = (e) -> MarbleGame.canvas.setContent(new MainMenuGui());
		bottomBar.addChild(backButton);
	}
}
