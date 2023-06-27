package gui;

import src.MarbleGame;
import hxd.res.BitmapFont;
import h3d.Vector;
import src.ResourceLoader;
import src.Settings;

class VideoOptionsGui extends GuiImage {
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
		rootTitle.text.text = "VIDEO OPTIONS";
		rootTitle.text.alpha = 0.5;
		innerCtrl.addChild(rootTitle);

		var yPos = 160;

		var resolutionOpt = new GuiXboxOptionsList(1, "Fullscreen Res", [
			"1024 x 800",
			"1280 x 720",
			"1366 x 768",
			"1440 x 900",
			"1600 x 900",
			"1920 x 1080"
		], 0.35);

		resolutionOpt.vertSizing = Bottom;
		resolutionOpt.horizSizing = Right;
		resolutionOpt.position = new Vector(380, yPos);
		resolutionOpt.extent = new Vector(815, 94);
		innerCtrl.addChild(resolutionOpt);

		yPos += 60;

		var displayOpt = new GuiXboxOptionsList(1, "Resolution", ["Fullscreen", "Windowed"], 0.35);
		displayOpt.vertSizing = Bottom;
		displayOpt.horizSizing = Right;
		displayOpt.position = new Vector(380, yPos);
		displayOpt.extent = new Vector(815, 94);
		innerCtrl.addChild(displayOpt);

		yPos += 60;

		var vsyncOpt = new GuiXboxOptionsList(1, "VSync", ["Disabled", "Enabled"], 0.35);
		vsyncOpt.vertSizing = Bottom;
		vsyncOpt.horizSizing = Right;
		vsyncOpt.position = new Vector(380, yPos);
		vsyncOpt.extent = new Vector(815, 94);
		innerCtrl.addChild(vsyncOpt);

		var bottomBar = new GuiControl();
		bottomBar.position = new Vector(0, 590);
		bottomBar.extent = new Vector(640, 200);
		bottomBar.horizSizing = Width;
		bottomBar.vertSizing = Bottom;
		innerCtrl.addChild(bottomBar);

		var backButton = new GuiXboxButton("Ok", 160);
		backButton.position = new Vector(960, 0);
		backButton.vertSizing = Bottom;
		backButton.horizSizing = Right;
		backButton.gamepadAccelerator = ["OK"];
		backButton.pressedAction = (e) -> MarbleGame.canvas.setContent(new OptionsListGui());
		bottomBar.addChild(backButton);
	}
}
