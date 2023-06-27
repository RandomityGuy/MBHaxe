package gui;

import src.MarbleGame;
import hxd.res.BitmapFont;
import h3d.Vector;
import src.ResourceLoader;
import src.Settings;
import src.Util;

class MiscOptionsGui extends GuiImage {
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
		rootTitle.text.text = "MISC OPTIONS";
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

		var rwOpt = new GuiXboxOptionsList(1, "Rewind", ["Disabled", "Enabled"], 0.5, 118);
		rwOpt.vertSizing = Bottom;
		rwOpt.horizSizing = Right;
		rwOpt.position = new Vector(380, yPos);
		rwOpt.extent = new Vector(815, 94);
		rwOpt.setCurrentOption(Settings.optionsSettings.rewindEnabled ? 1 : 0);
		rwOpt.onChangeFunc = (idx) -> {
			Settings.optionsSettings.rewindEnabled = (idx == 1);
			return true;
		}
		innerCtrl.addChild(rwOpt);

		yPos += 60;

		var rsOpt = new GuiXboxOptionsList(1, "Rewind Speed", numberRange(10, 100, 5), 0.5, 118);

		rsOpt.vertSizing = Bottom;
		rsOpt.horizSizing = Right;
		rsOpt.position = new Vector(380, yPos);
		rsOpt.extent = new Vector(815, 94);
		rsOpt.setCurrentOption(Std.int(Util.clamp(Math.floor(((Settings.optionsSettings.rewindTimescale - 0.1) / (1 - 0.1)) * 18), 0, 18)));
		rsOpt.onChangeFunc = (idx) -> {
			Settings.optionsSettings.rewindTimescale = cast(0.1 + (idx / 18.0) * (1 - 0.1));
			return true;
		}
		innerCtrl.addChild(rsOpt);

		yPos += 60;

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
