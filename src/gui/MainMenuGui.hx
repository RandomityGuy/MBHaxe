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

class MainMenuGui extends GuiControl {
	public function new() {
		// var img = ResourceLoader.getImage('data/ui/EngineSplashBG.jpg');
		// super(img.resource.toTile());
		super();
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

		var logo = new GuiImage(ResourceLoader.getResource('data/ui/logo.png', ResourceLoader.getImage, this.imageResources).toTile());
		logo.position = new Vector(200, 50);
		logo.extent = new Vector(512, 400);
		innerCtrl.addChild(logo);

		var glogo = new GuiImage(ResourceLoader.getResource('data/ui/g.png', ResourceLoader.getImage, this.imageResources).toTile());
		glogo.position = new Vector(240, 536);
		glogo.extent = new Vector(128, 128);
		innerCtrl.addChild(glogo);

		var btnList = new GuiXboxList();
		btnList.position = new Vector(70 - offsetX, 95);
		btnList.horizSizing = Left;
		btnList.extent = new Vector(502, 500);
		innerCtrl.addChild(btnList);

		btnList.addButton(0, "Single Player Game", (sender) -> {
			cast(this.parent, Canvas).setContent(new PlayMissionGui());
		});
		btnList.addButton(2, "Leaderboards", (e) -> {}, 20);
		btnList.addButton(2, "Achievements", (e) -> {});
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
		});
		btnList.addButton(3, "Help & Options", (sender) -> {
			cast(this.parent, Canvas).setContent(new OptionsDlg());
		});
		btnList.addButton(2, "Changelog", (sender) -> {
			MarbleGame.canvas.pushDialog(new VersionGui());
		});
		btnList.addButton(4, "Return to Arcade", (sender) -> {
			#if hl
			Sys.exit(0);
			#end
		});

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
		versionText.text.text = "<p align=\"center\">1.5.2</p>";
		versionText.text.filter = new DropShadow(1.414, 0.785, 0x3333337F, 1, 0, 0.7, 1, true);
		this.addChild(versionText);

		#if js
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
		#end
	}
}
