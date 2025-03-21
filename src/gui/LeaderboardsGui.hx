package gui;

import net.ClientConnection.NetPlatform;
import src.Util;
import src.Leaderboards.LeaderboardsKind;
import src.Mission;
import hxd.res.BitmapFont;
import src.ResourceLoader;
import src.Settings;
import h3d.Vector;
import src.MarbleGame;
import src.MissionList;
import src.Leaderboards;
import src.Replay;
import gui.HtmlText;

class LeaderboardsGui extends GuiImage {
	var innerCtrl:GuiControl;

	public function new(index:Int, levelSelectDifficulty:String, levelSelectGui:Bool = false,) {
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
		rootTitle.text.text = "LEADERBOARDS";
		rootTitle.text.alpha = 0.5;
		innerCtrl.addChild(rootTitle);

		var levelTitle = new GuiText(coliseum);
		levelTitle.position = new Vector(-100, 30);
		levelTitle.extent = new Vector(1120, 80);
		levelTitle.text.textColor = 0xFFFFFF;
		levelTitle.text.text = "Level 1";
		levelTitle.text.textAlign = Right;
		levelTitle.justify = Right;
		levelTitle.text.alpha = 0.5;
		innerCtrl.addChild(levelTitle);

		var scoreWnd = new GuiImage(ResourceLoader.getResource("data/ui/xbox/helpWindow.png", ResourceLoader.getImage, this.imageResources).toTile());
		scoreWnd.horizSizing = Right;
		scoreWnd.vertSizing = Bottom;
		scoreWnd.position = new Vector(260, 107);
		scoreWnd.extent = new Vector(736, 325);
		innerCtrl.addChild(scoreWnd);

		function imgLoader(path:String) {
			var t = switch (path) {
				case "ready":
					ResourceLoader.getResource("data/ui/xbox/Ready.png", ResourceLoader.getImage, this.imageResources).toTile();
				case "notready":
					ResourceLoader.getResource("data/ui/xbox/NotReady.png", ResourceLoader.getImage, this.imageResources).toTile();
				case "pc":
					ResourceLoader.getResource("data/ui/xbox/platform_desktop_white.png", ResourceLoader.getImage, this.imageResources).toTile();
				case "mac":
					ResourceLoader.getResource("data/ui/xbox/platform_mac_white.png", ResourceLoader.getImage, this.imageResources).toTile();
				case "web":
					ResourceLoader.getResource("data/ui/xbox/platform_web_white.png", ResourceLoader.getImage, this.imageResources).toTile();
				case "android":
					ResourceLoader.getResource("data/ui/xbox/platform_android_white.png", ResourceLoader.getImage, this.imageResources).toTile();
				case "unknown":
					ResourceLoader.getResource("data/ui/xbox/platform_unknown_white.png", ResourceLoader.getImage, this.imageResources).toTile();
				case "rewind":
					ResourceLoader.getResource("data/ui/xbox/rewind_ico.png", ResourceLoader.getImage, this.imageResources).toTile();
				case _:
					return null;
			};
			if (t != null)
				t.scaleToSize(t.width * (Settings.uiScale), t.height * (Settings.uiScale));
			return t;
		}

		var arial14fontdata = ResourceLoader.getFileEntry("data/font/Arial Bold.fnt");
		var arial14b = new BitmapFont(arial14fontdata.entry);
		@:privateAccess arial14b.loader = ResourceLoader.loader;
		var arial14 = arial14b.toSdfFont(cast 21 * Settings.uiScale, h2d.Font.SDFChannel.MultiChannel);
		var arial12 = arial14b.toSdfFont(cast 16 * Settings.uiScale, h2d.Font.SDFChannel.MultiChannel);
		function mlFontLoader(text:String) {
			switch (text) {
				case "arial14":
					return arial14;
				case "arial12":
					return arial12;
			}
			return null;
		}

		var headerText = '<font face="arial12">Rank<offset value="50">Name</offset><offset value="500">Score</offset><offset value="600">Platform</offset></font>';

		var scores = [
			'<offset value="10">1. </offset><offset value="50">Nardo Polo</offset><offset value="500">99:59:999</offset><offset value="625"><img src="unknown"/></offset>',
			'<offset value="10">2. </offset><offset value="50">Nardo Polo</offset><offset value="500">99:59:999</offset><offset value="625"><img src="pc"/></offset>',
			'<offset value="10">3. </offset><offset value="50">Nardo Polo</offset><offset value="500">99:59:999</offset><offset value="625"><img src="mac"/></offset>',
			'<offset value="10">4. </offset><offset value="50">Nardo Polo</offset><offset value="500">99:59:999</offset><offset value="625"><img src="web"/></offset>',
			'<offset value="10">5. </offset><offset value="50">Nardo Polo</offset><offset value="500">99:59:999</offset><offset value="625"><img src="android"/></offset>',
			'<offset value="10">6. </offset><offset value="50">Nardo Polo</offset><offset value="500">99:59:999</offset><offset value="625"><img src="unknown"/></offset>',
			'<offset value="10">7. </offset><offset value="50">Nardo Polo</offset><offset value="500">99:59:999</offset><offset value="625"><img src="pc"/></offset>',
			'<offset value="10">8. </offset><offset value="50">Nardo Polo</offset><offset value="500">99:59:999</offset><offset value="625"><img src="mac"/></offset>',
			'<offset value="10">9. </offset><offset value="50">Nardo Polo</offset><offset value="500">99:59:999</offset><offset value="625"><img src="web"/></offset>',
			'<offset value="10">10. </offset><offset value="50">Nardo Polo</offset><offset value="500">99:59:999</offset><offset value="625"><img src="android"/></offset>',
		];

		var scoreCtrl = new GuiMLText(arial14, mlFontLoader);
		scoreCtrl.position = new Vector(30, 20);
		scoreCtrl.extent = new Vector(706, 305);
		scoreCtrl.text.imageVerticalAlign = Top;
		scoreCtrl.text.loadImage = imgLoader;
		scoreCtrl.text.text = headerText + "<br/><br/><br/><br/><br/>" + '<p align="center">Loading...</p>';
		scoreWnd.addChild(scoreCtrl);

		var allMissions = MissionList.missionList.get('ultra')
			.get('beginner')
			.concat(MissionList.missionList.get('ultra').get('intermediate'))
			.concat(MissionList.missionList.get('ultra').get('advanced'))
			.concat(MissionList.missionList.get('ultra').get('multiplayer'));

		var actualIndex = allMissions.indexOf(MissionList.missionList.get('ultra').get(levelSelectDifficulty)[index]);

		levelTitle.text.text = 'Level ${actualIndex + 1}';

		var levelNames = allMissions.map(x -> x.title);

		var scoreCategories = ["Overall", "Rewind", "Non-Rewind"];
		var scoreView:LeaderboardsKind = All;

		var currentMission = allMissions[actualIndex];

		var isHuntScore = currentMission.difficultyIndex == 3;

		var scoreTok = 0;

		function fetchScores() {
			var ourToken = scoreTok++;
			Leaderboards.getScores(currentMission.path, scoreView, (scoreList) -> {
				if (ourToken + 1 != scoreTok)
					return;
				var scoreTexts = [];
				var i = 1;
				for (score in scoreList) {
					var scoreText = '<offset value="10">${i}. </offset>
					<offset value="50">${score.name}</offset>
					<offset value="475">${score.rewind > 0 ? "<img src='rewind'/>" : ""}</offset>
					<offset value="500">${isHuntScore ? Std.string(1000 - score.score) : Util.formatTime(score.score)}</offset>
					<offset value="625"><img src="${platformToString(score.platform)}"/></offset>';
					scoreTexts.push(scoreText);
					i++;
				}
				while (i <= 10) {
					var scoreText = '<offset value="10">${i}. </offset><offset value="50">Nardo Polo</offset><offset value="500">99:59.99</offset><offset value="625"><img src="unknown"/></offset>';
					scoreTexts.push(scoreText);
					i++;
				}
				scoreCtrl.text.text = headerText + "<br/>" + scoreTexts.join('<br/>');
			});
			scoreCtrl.text.text = headerText + "<br/><br/><br/><br/><br/>" + '<p align="center">Loading...</p>';
		}

		var levelSelectOpts = new GuiXboxOptionsList(2, "Overall", levelNames);
		levelSelectOpts.position = new Vector(380, 485);
		levelSelectOpts.extent = new Vector(815, 94);
		levelSelectOpts.vertSizing = Bottom;
		levelSelectOpts.horizSizing = Right;
		levelSelectOpts.alwaysActive = true;
		levelSelectOpts.onChangeFunc = (l) -> {
			levelTitle.text.text = 'Level ${l + 1}';
			currentMission = allMissions[l];
			fetchScores();
			return true;
		}
		levelSelectOpts.setCurrentOption(actualIndex);
		innerCtrl.addChild(levelSelectOpts);

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
		backButton.gamepadAccelerator = ["B"];
		backButton.accelerators = [hxd.Key.ESCAPE, hxd.Key.BACKSPACE];
		if (levelSelectGui)
			backButton.pressedAction = (e) -> MarbleGame.canvas.setContent(new LevelSelectGui(levelSelectDifficulty));
		else {
			backButton.pressedAction = (e) -> MarbleGame.canvas.setContent(new MainMenuGui());
		}
		bottomBar.addChild(backButton);

		var changeViewButton = new GuiXboxButton("Change View", 200);
		changeViewButton.position = new Vector(560, 0);
		changeViewButton.vertSizing = Bottom;
		changeViewButton.horizSizing = Right;
		changeViewButton.gamepadAccelerator = ["X"];
		changeViewButton.pressedAction = (e) -> {
			scoreView = scoreView == All ? Rewind : (scoreView == Rewind ? NoRewind : All);
			levelSelectOpts.labelText.text.text = scoreCategories[cast(scoreView, Int)];
			fetchScores();
		}
		bottomBar.addChild(changeViewButton);

		var replayButton = new GuiXboxButton("Watch Replay", 220);
		replayButton.position = new Vector(750, 0);
		replayButton.vertSizing = Bottom;
		replayButton.gamepadAccelerator = ["Y"];
		replayButton.horizSizing = Right;
		replayButton.pressedAction = (e) -> {
			Leaderboards.watchTopReplay(currentMission.path, scoreView, (b) -> {
				if (b != null) {
					var replayF = new Replay("");
					if (replayF.read(b)) {
						var repmis = replayF.mission;
						// Strip data/ from the mission name
						if (StringTools.startsWith(repmis, "data/")) {
							repmis = repmis.substr(5);
						}

						var mi = MissionList.missions.get(repmis);

						// try with data/ added
						if (mi == null) {
							if (!StringTools.contains(repmis, "data/"))
								repmis = "data/" + repmis;
							mi = MissionList.missions.get(repmis);
						}

						MarbleGame.instance.watchMissionReplay(mi, replayF, DifficultySelectGui);
					} else {
						MarbleGame.canvas.pushDialog(new MessageBoxOkDlg("Could not load replay for this level."));
					}
				} else {
					MarbleGame.canvas.pushDialog(new MessageBoxOkDlg("No top replay found for this level."));
				}
			});
		}
		bottomBar.addChild(replayButton);

		fetchScores();
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

	inline function platformToString(platform:NetPlatform) {
		return switch (platform) {
			case Unknown: return "unknown";
			case Android: return "android";
			case MacOS: return "mac";
			case PC: return "pc";
			case Web: return "web";
		}
	}
}
