package gui;

import src.MarbleGame;
import hxd.res.BitmapFont;
import h3d.Vector;
import src.ResourceLoader;
import src.Settings;
import src.Util;

class MiscOptionsGui extends GuiImage {
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

		#if hl
		var scene2d = hxd.Window.getInstance();
		#end
		#if js
		var scene2d = MarbleGame.instance.scene2d;
		#end

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

		var optionCollection = new GuiXboxOptionsListCollection();
		optionCollection.position = new Vector(380, 160);
		optionCollection.extent = new Vector(815, 500);
		innerCtrl.addChild(optionCollection);

		var rwOpt = optionCollection.addOption(1, "Rewind", ["Disabled", "Enabled"], (idx) -> {
			Settings.optionsSettings.rewindEnabled = (idx == 1);
			return true;
		}, 0.5, 118);
		rwOpt.setCurrentOption(Settings.optionsSettings.rewindEnabled ? 1 : 0);

		var rsOpt = optionCollection.addOption(1, "Rewind Speed", numberRange(10, 100, 5), (idx) -> {
			Settings.optionsSettings.rewindTimescale = cast(0.1 + (idx / 18.0) * (1 - 0.1));
			return true;
		}, 0.5, 118);
		rsOpt.setCurrentOption(Std.int(Util.clamp(Math.floor(((Settings.optionsSettings.rewindTimescale - 0.1) / (1 - 0.1)) * 18), 0, 18)));

		var sgOpt = optionCollection.addOption(1, "Seeded Gem Hunt", ["Disabled", "Enabled"], (idx) -> {
			Settings.optionsSettings.huntRandom = (idx == 0);
			return true;
		}, 0.5, 118);
		sgOpt.setCurrentOption(Settings.optionsSettings.huntRandom ? 0 : 1);

		// #if hl
		var flOpt = optionCollection.addOption(1, "Fast Loading", ["Disabled", "Enabled"], (idx) -> {
			Settings.optionsSettings.fastLoad = (idx == 1);
			return true;
		}, 0.5, 118);
		flOpt.setCurrentOption(Settings.optionsSettings.fastLoad ? 1 : 0);
		// #end

		var oobResOpt = optionCollection.addOption(1, "OOB Respawn Key", ["Jump", "Powerup"], (idx) -> {
			Settings.controlsSettings.oobRespawnKeyByPowerup = (idx == 1);
			return true;
		}, 0.5, 118);
		oobResOpt.setCurrentOption(Settings.controlsSettings.oobRespawnKeyByPowerup ? 1 : 0);

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
		backButton.gamepadAccelerator = ["A"];
		backButton.accelerators = [hxd.Key.ENTER];
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
