package gui;

import src.MarbleGame;
import hxd.res.BitmapFont;
import h3d.Vector;
import src.ResourceLoader;
import src.Settings;
import src.Util;

class InputOptionsGui extends GuiImage {
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
		rootTitle.text.text = "INPUT & SOUND OPTIONS";
		rootTitle.text.alpha = 0.5;
		innerCtrl.addChild(rootTitle);

		function numberRange(start:Int, stop:Int, step:Int) {
			var range = [];
			while (start <= stop) {
				range.push('${start}');
				start += step;
			}
			return range;
		}

		var yPos = 160;

		var iyOpt = new GuiXboxOptionsList(1, "Camera Y-Axis", ["Normal", "Inverted"], 0.5, 118);
		iyOpt.vertSizing = Bottom;
		iyOpt.horizSizing = Right;
		iyOpt.position = new Vector(380, yPos);
		iyOpt.extent = new Vector(815, 94);
		iyOpt.setCurrentOption(Settings.controlsSettings.invertYAxis ? 1 : 0);
		iyOpt.onChangeFunc = (idx) -> {
			Settings.controlsSettings.invertYAxis = (idx == 1);
			return true;
		}
		innerCtrl.addChild(iyOpt);

		yPos += 60;

		var musicOpt = new GuiXboxOptionsList(1, "Music Volume", numberRange(0, 100, 5), 0.5, 118);

		musicOpt.vertSizing = Bottom;
		musicOpt.horizSizing = Right;
		musicOpt.position = new Vector(380, yPos);
		musicOpt.extent = new Vector(815, 94);
		musicOpt.setCurrentOption(Std.int(Util.clamp(Math.floor(Settings.optionsSettings.musicVolume * 20), 0, 20)));
		musicOpt.onChangeFunc = (idx) -> {
			Settings.optionsSettings.musicVolume = (idx / 20.0);
			return true;
		}
		innerCtrl.addChild(musicOpt);

		yPos += 60;

		var soundOpt = new GuiXboxOptionsList(1, "Effects Volume", numberRange(0, 100, 5), 0.5, 118);

		soundOpt.vertSizing = Bottom;
		soundOpt.horizSizing = Right;
		soundOpt.position = new Vector(380, yPos);
		soundOpt.extent = new Vector(815, 94);
		soundOpt.setCurrentOption(Std.int(Util.clamp(Math.floor(Settings.optionsSettings.soundVolume * 20), 0, 20)));
		soundOpt.onChangeFunc = (idx) -> {
			Settings.optionsSettings.soundVolume = (idx / 20.0);
			return true;
		}
		innerCtrl.addChild(soundOpt);

		yPos += 60;

		var flOpt = new GuiXboxOptionsList(1, "Free-Look", ["Disabled", "Enabled"], 0.5, 118);
		flOpt.vertSizing = Bottom;
		flOpt.horizSizing = Right;
		flOpt.position = new Vector(380, yPos);
		flOpt.extent = new Vector(815, 94);
		flOpt.setCurrentOption(Settings.optionsSettings.vsync ? 1 : 0);
		flOpt.onChangeFunc = (idx) -> {
			Settings.controlsSettings.alwaysFreeLook = (idx == 1);
			return true;
		}
		innerCtrl.addChild(flOpt);

		yPos += 60;

		var msOpt = new GuiXboxOptionsList(1, "Mouse Sensitivity", numberRange(10, 100, 5), 0.5, 118);
		msOpt.vertSizing = Bottom;
		msOpt.horizSizing = Right;
		msOpt.position = new Vector(380, yPos);
		msOpt.extent = new Vector(815, 94);
		msOpt.setCurrentOption(Std.int(Util.clamp(Math.floor(((Settings.controlsSettings.cameraSensitivity - 0.2) / (3 - 0.2)) * 18), 0, 18)));
		msOpt.onChangeFunc = (idx) -> {
			Settings.controlsSettings.cameraSensitivity = cast(0.2 + (idx / 18.0) * (3 - 0.2));
			return true;
		}
		innerCtrl.addChild(msOpt);

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
}
