package gui;

import h2d.filter.DropShadow;
import src.MarbleGame;
import gui.GuiControl.MouseState;
import hxd.res.BitmapFont;
import h3d.Vector;
import src.ResourceLoader;
import src.Settings;
import src.Util;
import src.Replay;
import src.Marbleland;
import src.MissionList;

class MainMenuGui extends GuiImage {
	public function new() {
		function chooseBg() {
			var rand = Math.random();
			if (rand >= 0 && rand <= 0.244)
				return ResourceLoader.getImage('data/ui/backgrounds/gold/${cast (Math.floor(Util.lerp(1, 12, Math.random())), Int)}.jpg');
			if (rand > 0.244 && rand <= 0.816)
				return ResourceLoader.getImage('data/ui/backgrounds/platinum/${cast (Math.floor(Util.lerp(1, 28, Math.random())), Int)}.jpg');
			return ResourceLoader.getImage('data/ui/backgrounds/ultra/${cast (Math.floor(Util.lerp(1, 9, Math.random())), Int)}.jpg');
		}
		var img = chooseBg();
		super(img.resource.toTile());
		var domcasual32fontdata = ResourceLoader.getFileEntry("data/font/DomCasualD.fnt");
		var domcasual32b = new BitmapFont(domcasual32fontdata.entry);
		@:privateAccess domcasual32b.loader = ResourceLoader.loader;
		var domcasual32 = domcasual32b.toSdfFont(cast 42 * Settings.uiScale, MultiChannel);

		this.horizSizing = Width;
		this.vertSizing = Height;
		this.position = new Vector();
		this.extent = new Vector(640, 480);

		var mainMenuContent = new GuiControl();
		mainMenuContent.horizSizing = Center;
		mainMenuContent.vertSizing = Center;
		mainMenuContent.position = new Vector(-130, -110);
		mainMenuContent.extent = new Vector(900, 700);

		function loadButtonImages(path:String) {
			var normal = ResourceLoader.getResource('${path}_n.png', ResourceLoader.getImage, this.imageResources).toTile();
			var hover = ResourceLoader.getResource('${path}_h.png', ResourceLoader.getImage, this.imageResources).toTile();
			var pressed = ResourceLoader.getResource('${path}_d.png', ResourceLoader.getImage, this.imageResources).toTile();
			return [normal, hover, pressed];
		}

		var siteButton = new GuiButton(loadButtonImages('data/ui/menu/site'));
		siteButton.horizSizing = Right;
		siteButton.vertSizing = Top;
		siteButton.position = new Vector(363, 664);
		siteButton.extent = new Vector(400, 30);
		siteButton.pressedAction = (sender) -> {
			#if sys
			Settings.open_web_url("https://marbleblast.com");
			#end
			#if js
			js.Browser.window.open("https://marbleblast.com");
			#end
		}
		mainMenuContent.addChild(siteButton);

		var motdButton = new GuiButton(loadButtonImages('data/ui/menu/changelog'));
		motdButton.horizSizing = Left;
		motdButton.vertSizing = Top;
		motdButton.position = new Vector(706, 536);
		motdButton.extent = new Vector(191, 141);
		motdButton.pressedAction = (sender) -> {
			MarbleGame.canvas.pushDialog(new VersionGui());
		}
		mainMenuContent.addChild(motdButton);

		var playButton = new GuiButton(loadButtonImages("data/ui/menu/play"));
		playButton.position = new Vector(-5, -2);
		playButton.extent = new Vector(247, 164);
		playButton.gamepadAccelerator = ["A"];
		playButton.pressedAction = (sender) -> {
			cast(this.parent, Canvas).setContent(new PlayMissionGui());
		}
		mainMenuContent.addChild(playButton);

		var lbButton = new GuiButton(loadButtonImages("data/ui/menu/online"));
		lbButton.position = new Vector(-5, 128);
		lbButton.extent = new Vector(247, 164);
		lbButton.pressedAction = (sender) -> {
			MarbleGame.canvas.setContent(new JoinServerGui());
		}
		mainMenuContent.addChild(lbButton);

		var optionsButton = new GuiButton(loadButtonImages("data/ui/menu/options"));
		optionsButton.position = new Vector(-5, 258);
		optionsButton.extent = new Vector(247, 164);
		optionsButton.pressedAction = (sender) -> {
			cast(this.parent, Canvas).setContent(new OptionsDlg());
		}
		mainMenuContent.addChild(optionsButton);

		var exitButton = new GuiButton(loadButtonImages("data/ui/menu/quit"));
		exitButton.position = new Vector(-5, 388);
		exitButton.extent = new Vector(247, 164);
		exitButton.pressedAction = (sender) -> {
			#if hl
			Sys.exit(0);
			#end
		};
		mainMenuContent.addChild(exitButton);

		var replButton = new GuiButton(loadButtonImages("data/ui/menu/replay"));
		replButton.horizSizing = Left;
		replButton.vertSizing = Top;
		replButton.position = new Vector(552, 536);
		replButton.extent = new Vector(191, 141);
		replButton.pressedAction = (sender) -> {
			#if hl
			MarbleGame.canvas.setContent(new ReplayCenterGui());
			#end
			#if js
			hxd.File.browse((replayToLoad) -> {
				replayToLoad.load((replayData) -> {
					var replay = new Replay("");
					if (!replay.read(replayData)) {
						cast(this.parent, Canvas).pushDialog(new MessageBoxOkDlg("Cannot load replay."));
						// Idk do something to notify the user here
					} else {
						var repmis = replay.mission;
						#if js
						repmis = StringTools.replace(repmis, "data/", "");
						#end
						if (MissionList.missions == null)
							MissionList.buildMissionList();
						var mi = replay.customId == 0 ? MissionList.missions.get(repmis) : Marbleland.missions.get(replay.customId);
						if (mi.isClaMission) {
							mi.download(() -> {
								MarbleGame.instance.watchMissionReplay(mi, replay);
							});
						} else {
							if (mi != null) {
								cast(this.parent, Canvas).marbleGame.watchMissionReplay(mi, replay);
							} else {
								cast(this.parent, Canvas).pushDialog(new MessageBoxOkDlg("Cannot load replay."));
							}
						}
					}
				});
			}, {
				title: "Select replay file",
				fileTypes: [
					{
						name: "Replay (*.mbr)",
						extensions: ["mbr"]
					}
				],
			});
			#end
		};
		mainMenuContent.addChild(replButton);

		var helpButton = new GuiButton(loadButtonImages("data/ui/menu/help"));
		helpButton.horizSizing = Left;
		helpButton.vertSizing = Top;
		helpButton.position = new Vector(398, 536);
		helpButton.extent = new Vector(191, 141);
		helpButton.pressedAction = (sender) -> {
			MarbleGame.canvas.setContent(new HelpCreditsGui());
		}
		mainMenuContent.addChild(helpButton);

		this.addChild(mainMenuContent);

		var mbp = new GuiImage(ResourceLoader.getResource("data/ui/menu/mbp.png", ResourceLoader.getImage, this.imageResources).toTile());
		mbp.horizSizing = Left;
		mbp.vertSizing = Bottom;
		mbp.position = new Vector(476, 12);
		mbp.extent = new Vector(153, 150);
		this.addChild(mbp);

		var versionText = new GuiMLText(domcasual32, null);

		versionText.horizSizing = Left;
		versionText.vertSizing = Bottom;
		versionText.position = new Vector(502, 61);
		versionText.extent = new Vector(97, 72);
		versionText.text.text = "<p align=\"center\">1.5.4</p>";
		versionText.text.dropShadow = {
			dx: 1,
			dy: 1,
			alpha: 0.5,
			color: 0
		};
		this.addChild(versionText);

		var kofi = new GuiButton(loadButtonImages("data/ui/kofi1"));
		kofi.horizSizing = Left;
		kofi.vertSizing = Top;
		kofi.position = new Vector(473, 424);
		kofi.extent = new Vector(143, 36);
		kofi.pressedAction = (sender) -> {
			#if sys
			Settings.open_web_url("https://ko-fi.com/H2H5FRTTL");
			#end
			#if js
			js.Browser.window.open("https://ko-fi.com/H2H5FRTTL");
			#end
		}
		this.addChild(kofi);

		var github = new GuiButton(loadButtonImages("data/ui/github"));
		github.horizSizing = Left;
		github.vertSizing = Top;
		github.position = new Vector(522, 380);
		github.extent = new Vector(94, 38);
		github.pressedAction = (sender) -> {
			#if sys
			Settings.open_web_url("https://github.com/RandomityGuy/MBHaxe");
			#end
			#if js
			js.Browser.window.open("https://github.com/RandomityGuy/MBHaxe");
			#end
		}
		this.addChild(github);
	}
}
