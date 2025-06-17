package gui;

import net.Net;
import src.MarbleGame;
import hxd.res.BitmapFont;
import h3d.Vector;
import src.ResourceLoader;
import src.Settings;
import src.Util;

class CreateMatchGui extends GuiImage {
	var innerCtrl:GuiControl;

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
		rootTitle.text.text = "CREATE MATCH";
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
		optionCollection.position = new Vector(380, 373);
		optionCollection.extent = new Vector(815, 500);
		innerCtrl.addChild(optionCollection);

		var maxPlayers = 8;
		var privateSlots = 0;
		var privateGame = false;

		var playerOpt = optionCollection.addOption(1, "Max Players", ["2", "3", "4", "5", "6", "7", "8"], (idx) -> {
			var newMaxPlayers = idx + 2;
			if (privateSlots >= newMaxPlayers)
				return false;
			maxPlayers = idx + 2;
			return true;
		}, 0.5, 118);
		playerOpt.setCurrentOption(6);

		var privateOpt = optionCollection.addOption(1, "Private Slots", ["None", "1", "2", "3", "4", "5", "6", "7"], (idx) -> {
			var newPrivateSlotCount = idx;
			if (newPrivateSlotCount >= maxPlayers)
				return false;
			privateSlots = idx;
			return true;
		}, 0.5, 118);

		var privateGameOpt = optionCollection.addOption(1, "Private Game", ["No", "Yes"], (idx) -> {
			privateGame = idx == 1;
			return true;
		}, 0.5, 118);

		var bottomBar = new GuiControl();
		bottomBar.position = new Vector(0, 590);
		bottomBar.extent = new Vector(640, 200);
		bottomBar.horizSizing = Width;
		bottomBar.vertSizing = Bottom;
		innerCtrl.addChild(bottomBar);

		var backButton = new GuiXboxButton("Back", 160);
		backButton.position = new Vector(400, 0);
		backButton.vertSizing = Bottom;
		backButton.horizSizing = Right;
		backButton.gamepadAccelerator = [Settings.gamepadSettings.back];
		backButton.accelerators = [hxd.Key.ESCAPE, hxd.Key.BACKSPACE];
		backButton.pressedAction = (e) -> MarbleGame.canvas.setContent(new MultiplayerGui());
		bottomBar.addChild(backButton);

		var nextButton = new GuiXboxButton("Go", 160);
		nextButton.position = new Vector(960, 0);
		nextButton.vertSizing = Bottom;
		nextButton.horizSizing = Right;
		nextButton.gamepadAccelerator = [Settings.gamepadSettings.ok];
		nextButton.accelerators = [hxd.Key.ENTER];
		nextButton.pressedAction = (e) -> {
			Net.hostServer('${Settings.highscoreName}\'s Server', maxPlayers, privateSlots, privateGame, () -> {
				MarbleGame.canvas.setContent(new MultiplayerLevelSelectGui(true));
			});
		};
		bottomBar.addChild(nextButton);
	}
}
