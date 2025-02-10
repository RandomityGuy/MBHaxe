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
import src.MarbleGame;

class MainMenuGui extends GuiImage {
	var innerCtrl:GuiControl;
	var btnList:GuiXboxList;

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

		MarbleGame.instance.toRecord = false;

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

		var logo = new GuiImage(ResourceLoader.getResource('data/ui/logo.png', ResourceLoader.getImage, this.imageResources).toTile());
		logo.position = new Vector(200, 50);
		logo.extent = new Vector(512, 400);
		innerCtrl.addChild(logo);

		var glogo = new GuiImage(ResourceLoader.getResource('data/ui/g.png', ResourceLoader.getImage, this.imageResources).toTile());
		glogo.position = new Vector(240, 536);
		glogo.extent = new Vector(128, 128);
		innerCtrl.addChild(glogo);

		btnList = new GuiXboxList();
		btnList.position = new Vector(70 - offsetX, 95);
		btnList.horizSizing = Left;
		btnList.extent = new Vector(502, 530);
		innerCtrl.addChild(btnList);

		btnList.addButton(0, "Single Player Game", (sender) -> {
			cast(this.parent, Canvas).setContent(new DifficultySelectGui());
		});
		btnList.addButton(0, "Multiplayer Game", (sender) -> {
			if (MPCustoms.missionList.length == 0) {
				cast(this.parent, Canvas).pushDialog(new MessageBoxOkDlg("Custom levels not loaded yet, please wait."));
				MPCustoms.loadMissionList();
			} else {
				if (StringTools.trim(Settings.highscoreName) == ""
					|| Settings.highscoreName == "Player"
					|| Settings.highscoreName == "Player Name") {
					MarbleGame.canvas.setContent(new EnterNameDlg());
				} else
					cast(this.parent, Canvas).setContent(new MultiplayerGui());
			}
		});
		btnList.addButton(2, "Leaderboards", (e) -> {
			cast(this.parent, Canvas).setContent(new LeaderboardsGui(0, "beginner", false));
		}, 20);
		btnList.addButton(2, "Achievements", (e) -> {
			cast(this.parent, Canvas).setContent(new AchievementsGui());
		});
		btnList.addButton(3, "Replays", (sender) -> {
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
								MarbleGame.instance.watchMissionReplay(mi, replay, MainMenuGui);
							});
						} else {
							if (mi != null) {
								cast(this.parent, Canvas).marbleGame.watchMissionReplay(mi, replay, MainMenuGui);
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
		});
		btnList.addButton(3, "Help & Options", (sender) -> {
			cast(this.parent, Canvas).setContent(new OptionsListGui());
		});
		btnList.addButton(2, "Changelog", (sender) -> {
			MarbleGame.canvas.setContent(new VersionGui());
		});
		#if hl
		btnList.addButton(4, "Return to Arcade", (sender) -> {
			#if hl
			Sys.exit(0);
			#end
		});
		#end
		#if js
		btnList.addButton(4, "Download", (sender) -> {
			js.Browser.window.open("https://github.com/RandomityGuy/MBHaxe");
		});
		#end

		function loadButtonImages(path:String) {
			var normal = ResourceLoader.getResource('${path}_n.png', ResourceLoader.getImage, this.imageResources).toTile();
			var hover = ResourceLoader.getResource('${path}_h.png', ResourceLoader.getImage, this.imageResources).toTile();
			var pressed = ResourceLoader.getResource('${path}_d.png', ResourceLoader.getImage, this.imageResources).toTile();
			return [normal, hover, pressed];
		}

		var versionText = new GuiMLText(domcasual32, null);

		versionText.horizSizing = Left;
		versionText.vertSizing = Bottom;
		versionText.position = new Vector(502, 61);
		versionText.extent = new Vector(97, 72);
		versionText.text.text = '<p align=\"center\">${MarbleGame.currentVersion}</p>';
		versionText.text.filter = new DropShadow(1.414, 0.785, 0x3333337F, 1, 0, 0.7, 1, true);
		this.addChild(versionText);

		var kofi = new GuiButton(loadButtonImages("data/ui/kofi1"));
		kofi.horizSizing = Left;
		kofi.vertSizing = Top;
		kofi.position = new Vector(473, 424);
		kofi.extent = new Vector(143, 36);
		kofi.pressedAction = (sender) -> {
			#if sys
			hxd.System.openURL("https://ko-fi.com/H2H5FRTTL");
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
			hxd.System.openURL("https://github.com/RandomityGuy/MBHaxe");
			#end
			#if js
			js.Browser.window.open("https://github.com/RandomityGuy/MBHaxe");
			#end
		}
		this.addChild(github);
	}

	override function onResize(width:Int, height:Int) {
		var offsetX = (width - 1280) / 2;
		var offsetY = (height - 720) / 2;

		var subX = 640 - (width - offsetX) * 640 / width;
		var subY = 480 - (height - offsetY) * 480 / height;
		innerCtrl.position = new Vector(offsetX, offsetY);
		innerCtrl.extent = new Vector(640 - subX, 480 - subY);
		btnList.position = new Vector(70 - offsetX, 95);

		super.onResize(width, height);
	}
}
