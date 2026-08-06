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
		super();
		if (!ResourceLoader.exists(Settings.optionsSettings.previewPath))
			Settings.optionsSettings.previewPath = "data/previews_pq/tutorial/trainingwheels.prev.dds";
		var levelPreview = new GuiImage(ResourceLoader.getResource(Settings.optionsSettings.previewPath, ResourceLoader.getImage, this.imageResources)
			.toTile());
		levelPreview.horizSizing = Width;
		levelPreview.vertSizing = Height;
		levelPreview.position = new Vector(0, 0);
		levelPreview.extent = new Vector(800, 600);
		this.addChild(levelPreview);

		var helveticafontdata = ResourceLoader.getFileEntry("data/font/helveticaneue.fnt");
		var helveticafont = new BitmapFont(helveticafontdata.entry);
		@:privateAccess helveticafont.loader = ResourceLoader.loader;
		var helveticafont60 = helveticafont.toSdfFont(cast 52 * Settings.uiScale, MultiChannel);

		var squishneyfontdata = ResourceLoader.getFileEntry("data/font/squishney.fnt");
		var squishneyb = new BitmapFont(squishneyfontdata.entry);
		@:privateAccess squishneyb.loader = ResourceLoader.loader;
		var squishney32 = squishneyb.toSdfFont(cast 29 * Settings.uiScale, MultiChannel);
		var squishney24 = squishneyb.toSdfFont(cast 21 * Settings.uiScale, MultiChannel);

		this.horizSizing = Width;
		this.vertSizing = Height;
		this.position = new Vector();
		this.extent = new Vector(800, 600);

		var menuCircle1 = new GuiImage(ResourceLoader.getResource("data/ui/menu/bgcircle-large.png", ResourceLoader.getImage, this.imageResources).toTile());
		menuCircle1.horizSizing = Right;
		menuCircle1.vertSizing = Height;
		menuCircle1.position = new Vector(0, 0);
		menuCircle1.extent = new Vector(116, 720);
		this.addChild(menuCircle1);

		var menuCircle2 = new GuiImage(ResourceLoader.getResource("data/ui/menu/bgcircle-small.png", ResourceLoader.getImage, this.imageResources).toTile());
		menuCircle2.horizSizing = Left;
		menuCircle2.vertSizing = Top;
		menuCircle2.position = new Vector(550, 470);
		menuCircle2.extent = new Vector(260, 145);
		this.addChild(menuCircle2);

		var menuTitle = new GuiImage(ResourceLoader.getResource("data/ui/menu/bgtitle.png", ResourceLoader.getImage, this.imageResources).toTile());
		menuTitle.position = new Vector(56, 57);
		menuTitle.extent = new Vector(864, 114);
		this.addChild(menuTitle);

		var mainMenuContent = new GuiControl();
		mainMenuContent.horizSizing = Width;
		mainMenuContent.vertSizing = Height;
		mainMenuContent.position = new Vector(0, 0);
		mainMenuContent.extent = new Vector(800, 600);

		function loadButtonImages(path:String) {
			var normal = ResourceLoader.getResource('${path}_n.png', ResourceLoader.getImage, this.imageResources).toTile();
			var hover = ResourceLoader.getResource('${path}_h.png', ResourceLoader.getImage, this.imageResources).toTile();
			var pressed = ResourceLoader.getResource('${path}_d.png', ResourceLoader.getImage, this.imageResources).toTile();
			return [normal, hover, pressed];
		}

		function loadStaticButtonImages(path:String) {
			var normal = ResourceLoader.getResource('${path}.png', ResourceLoader.getImage, this.imageResources).toTile();
			var hover = ResourceLoader.getResource('${path}.png', ResourceLoader.getImage, this.imageResources).toTile();
			var pressed = ResourceLoader.getResource('${path}.png', ResourceLoader.getImage, this.imageResources).toTile();
			return [normal, hover, pressed];
		}

		var playButton = new GuiButtonText(loadButtonImages("data/ui/menu/menu"), helveticafont60);
		playButton.position = new Vector(75, 178);
		playButton.setExtent(new Vector(500, 84));
		playButton.gamepadAccelerator = ["A"];
		playButton.pressedAction = (sender) -> {
			cast(this.parent, Canvas).setContent(new PlayMissionGui());
		}
		playButton.txtCtrl.text.textColor = 0;
		playButton.txtCtrl.text.text = "      Play";
		playButton.txtCtrl.justify = Left;
		mainMenuContent.addChild(playButton);

		var optionsButton = new GuiButtonText(loadButtonImages("data/ui/menu/menu"), helveticafont60);
		optionsButton.position = new Vector(75, 268);
		optionsButton.setExtent(new Vector(500, 84));
		optionsButton.pressedAction = (sender) -> {
			cast(this.parent, Canvas).setContent(new OptionsDlg());
		}
		optionsButton.txtCtrl.text.textColor = 0;
		optionsButton.txtCtrl.text.text = "      Options";
		optionsButton.txtCtrl.justify = Left;
		mainMenuContent.addChild(optionsButton);

		var replButton = new GuiButtonText(loadButtonImages("data/ui/menu/menu"), helveticafont60);
		replButton.position = new Vector(75, 358);
		replButton.setExtent(new Vector(500, 84));
		replButton.pressedAction = (sender) -> {
			#if hl
			MarbleGame.canvas.pushDialog(new ReplayCenterGui());
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
		};
		replButton.txtCtrl.text.textColor = 0;
		replButton.txtCtrl.text.text = "      Replays";
		replButton.txtCtrl.justify = Left;
		mainMenuContent.addChild(replButton);

		var changelogButton = new GuiButtonText(loadButtonImages("data/ui/menu/menu"), helveticafont60);
		changelogButton.position = new Vector(75, 448);
		changelogButton.setExtent(new Vector(500, 84));
		changelogButton.pressedAction = (sender) -> {
			MarbleGame.canvas.pushDialog(new VersionGui());
		}
		changelogButton.txtCtrl.text.textColor = 0;
		changelogButton.txtCtrl.text.text = "      Changelog";
		changelogButton.txtCtrl.justify = Left;
		mainMenuContent.addChild(changelogButton);

		#if hl
		var exitButton = new GuiButtonText(loadButtonImages("data/ui/menu/menu"), helveticafont60);
		exitButton.position = new Vector(75, 538);
		exitButton.setExtent(new Vector(500, 84));
		exitButton.pressedAction = (sender) -> {
			#if hl
			Sys.exit(0);
			#end
		}
		exitButton.txtCtrl.text.textColor = 0;
		exitButton.txtCtrl.text.text = "      Quit";
		exitButton.txtCtrl.justify = Left;
		mainMenuContent.addChild(exitButton);
		#end
		#if js
		var exitButton = new GuiButtonText(loadButtonImages("data/ui/menu/menu"), helveticafont60);
		exitButton.position = new Vector(75, 538);
		exitButton.setExtent(new Vector(500, 84));
		exitButton.pressedAction = (sender) -> {
			js.Browser.window.open("https://github.com/RandomityGuy/MBHaxe");
		}
		exitButton.txtCtrl.text.textColor = 0;
		exitButton.txtCtrl.text.text = "     Download";
		exitButton.txtCtrl.justify = Left;
		mainMenuContent.addChild(exitButton);
		#end

		this.addChild(mainMenuContent);

		var versionText = new GuiMLText(squishney32, null);

		versionText.horizSizing = Left;
		versionText.vertSizing = Top;
		versionText.position = new Vector(690, 564);
		versionText.extent = new Vector(97, 72);
		versionText.text.text = '<p align=\"right\">${MarbleGame.currentVersion}</p>';
		versionText.text.dropShadow = {
			dx: 1 * Settings.uiScale,
			dy: 1 * Settings.uiScale,
			alpha: 0.5,
			color: 0
		};
		this.addChild(versionText);

		var kofi = new GuiButton(loadButtonImages("data/ui/kofi1"));
		kofi.horizSizing = Left;
		kofi.vertSizing = Bottom;
		kofi.position = new Vector(650, 2);
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
		github.vertSizing = Bottom;
		github.position = new Vector(700, 46);
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

		var dlText = new GuiMLText(squishney24, null);

		dlText.horizSizing = Left;
		dlText.vertSizing = Top;
		dlText.position = new Vector(0, 564);
		dlText.extent = new Vector(497, 72);
		dlText.text.text = '<a href="download">Click here to get the original game at MarbleBlast.com</a>';
		dlText.text.dropShadow = {
			dx: 1 * Settings.uiScale,
			dy: 1 * Settings.uiScale,
			alpha: 0.5,
			color: 0
		};
		dlText.text.onHyperlink = (v) -> {
			#if sys
			Settings.open_web_url("https://marbleblast.com/index.php/downloads");
			#end
			#if js
			js.Browser.window.open("https://marbleblast.com/index.php/downloads");
			#end
		};
		this.addChild(dlText);

		#if js
		var mbg = new GuiButton(loadStaticButtonImages("data/ui/icon_mbg"));
		mbg.horizSizing = Right;
		mbg.vertSizing = Top;
		mbg.position = new Vector(0, 510);
		mbg.extent = new Vector(76, 76);
		mbg.pressedAction = (sender) -> {
			js.Browser.window.open("https://marbleblastgold.randomityguy.me");
		}
		this.addChild(mbg);

		var mbp = new GuiButton(loadStaticButtonImages("data/ui/icon_mbp"));
		mbp.horizSizing = Right;
		mbp.vertSizing = Top;
		mbp.position = new Vector(76, 510);
		mbp.extent = new Vector(76, 76);
		mbp.pressedAction = (sender) -> {
			js.Browser.window.open("https://marbleblast.randomityguy.me");
		}
		this.addChild(mbp);

		var mbu = new GuiButton(loadStaticButtonImages("data/ui/icon_mbu"));
		mbu.horizSizing = Right;
		mbu.vertSizing = Top;
		mbu.position = new Vector(152, 510);
		mbu.extent = new Vector(76, 76);
		mbu.pressedAction = (sender) -> {
			js.Browser.window.open("https://marbleblastultra.randomityguy.me");
		}
		this.addChild(mbu);

		var discord = new GuiButton(loadStaticButtonImages("data/ui/discord"));
		discord.horizSizing = Left;
		discord.vertSizing = Bottom;
		discord.position = new Vector(650, 90);
		discord.extent = new Vector(152, 60);
		discord.pressedAction = (sender) -> {
			js.Browser.window.open("https://discord.gg/q4JdnRbVhF");
		}
		this.addChild(discord);
		#end

		#if js
		var urlParams = new js.html.URLSearchParams(js.Browser.window.location.search);
		var playParam = urlParams.get("app");
		if (playParam == "1" || playParam == "true") {
			// Get people to download the native app instead! Bruh
			if (!Util.isIOS()) {
				// If we aren't on iOS, then only we force them to download the native app, since thats the only valid use of PWA in this case
				haxe.Timer.delay(() -> {
					MarbleGame.canvas.pushDialog(new MessageBoxOkDlg("Please download the native app for a better experience! The game will run better and smoother that way!",
						() -> {
						js.Browser.window.open("https://github.com/RandomityGuy/MBHaxe/blob/master/README.md");
					}));
				}, 100);
			}
		}
		#end
	}
}
