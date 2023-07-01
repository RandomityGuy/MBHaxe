package gui;

import src.MarbleGame;
import hxd.res.BitmapFont;
import h3d.Vector;
import src.ResourceLoader;
import src.Settings;
import src.Util;

class VideoOptionsGui extends GuiImage {
	var innerCtrl:GuiControl;

	public function new(pauseGui:Bool = false) {
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

		innerCtrl = new GuiControl();
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
		resolutionOpt.optionText.text.text = '${Settings.optionsSettings.screenWidth} x ${Settings.optionsSettings.screenHeight}';
		var curOpt = [
			"1024 x 800",
			"1280 x 720",
			"1366 x 768",
			"1440 x 900",
			"1600 x 900",
			"1920 x 1080"
		].indexOf(resolutionOpt.optionText.text.text);
		if (curOpt != -1)
			resolutionOpt.setCurrentOption(curOpt);
		resolutionOpt.onChangeFunc = (idx) -> {
			switch (idx) {
				case 0:
					Settings.optionsSettings.screenWidth = 1024;
					Settings.optionsSettings.screenHeight = 800;
				case 1:
					Settings.optionsSettings.screenWidth = 1280;
					Settings.optionsSettings.screenHeight = 720;
				case 2:
					Settings.optionsSettings.screenWidth = 1366;
					Settings.optionsSettings.screenHeight = 768;
				case 3:
					Settings.optionsSettings.screenWidth = 1440;
					Settings.optionsSettings.screenHeight = 900;
				case 4:
					Settings.optionsSettings.screenWidth = 1600;
					Settings.optionsSettings.screenHeight = 900;
				case 5:
					Settings.optionsSettings.screenWidth = 1920;
					Settings.optionsSettings.screenHeight = 1080;
			}
			return true;
		}

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
		displayOpt.setCurrentOption(Settings.optionsSettings.isFullScreen ? 0 : 1);
		displayOpt.onChangeFunc = (idx) -> {
			Settings.optionsSettings.isFullScreen = (idx == 0);
			return true;
		}
		innerCtrl.addChild(displayOpt);

		yPos += 60;

		var vsyncOpt = new GuiXboxOptionsList(1, "VSync", ["Disabled", "Enabled"], 0.35);
		vsyncOpt.vertSizing = Bottom;
		vsyncOpt.horizSizing = Right;
		vsyncOpt.position = new Vector(380, yPos);
		vsyncOpt.extent = new Vector(815, 94);
		vsyncOpt.setCurrentOption(Settings.optionsSettings.vsync ? 1 : 0);
		vsyncOpt.onChangeFunc = (idx) -> {
			Settings.optionsSettings.vsync = (idx == 1);
			return true;
		}
		innerCtrl.addChild(vsyncOpt);

		yPos += 60;

		function numberRange(start:Int, stop:Int, step:Int) {
			var range = [];
			while (start <= stop) {
				range.push('${start}');
				start += step;
			}
			return range;
		}

		var fovOpt = new GuiXboxOptionsList(1, "Field of Vision", numberRange(60, 140, 5), 0.35);
		fovOpt.vertSizing = Bottom;
		fovOpt.horizSizing = Right;
		fovOpt.position = new Vector(380, yPos);
		fovOpt.extent = new Vector(815, 94);
		fovOpt.setCurrentOption(Std.int(Util.clamp(Math.floor(((Settings.optionsSettings.fovX - 60) / (140 - 60)) * 16), 0, 16)));
		fovOpt.onChangeFunc = (idx) -> {
			Settings.optionsSettings.fovX = cast(60 + (idx / 16.0) * (140 - 60));
			return true;
		}
		innerCtrl.addChild(fovOpt);

		yPos += 60;

		var rfOpt = new GuiXboxOptionsList(1, "Reflection Detail", ["None", "Sky Only", "Level and Sky", "Level, Sky and Items", "Everything"], 0.35);

		rfOpt.vertSizing = Bottom;
		rfOpt.horizSizing = Right;
		rfOpt.position = new Vector(380, yPos);
		rfOpt.extent = new Vector(815, 94);
		rfOpt.setCurrentOption(Settings.optionsSettings.reflectionDetail);
		rfOpt.onChangeFunc = (idx) -> {
			Settings.optionsSettings.reflectionDetail = idx;
			return true;
		}
		innerCtrl.addChild(rfOpt);

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
		if (pauseGui)
			backButton.pressedAction = (e) -> {
				Settings.applySettings();
				MarbleGame.canvas.popDialog(this);
				MarbleGame.canvas.pushDialog(new OptionsListGui(true));
			}
		else
			backButton.pressedAction = (e) -> {
				Settings.applySettings();
				MarbleGame.canvas.setContent(new OptionsListGui());
			};
		bottomBar.addChild(backButton);
	}

	override function onResize(width:Int, height:Int) {
		var offsetX = (width - 1280) / 2;
		var offsetY = (height - 720) / 2;

		var subX = 640 - (width - offsetX) * 640 / width;
		var subY = 480 - (height - offsetY) * 480 / height;
		innerCtrl.position = new Vector(offsetX, offsetY);
		innerCtrl.extent = new Vector(640 - subX, 480 - subY);

		super.onResize(width, height);
	}
}
