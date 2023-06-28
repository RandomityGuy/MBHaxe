package gui;

import src.Util;
import haxe.io.Path;
import h2d.filter.DropShadow;
import src.MarbleGame;
import gui.GuiControl.MouseState;
import hxd.res.BitmapFont;
import h3d.Vector;
import src.ResourceLoader;
import src.Settings;
import src.MissionList;

class LevelSelectGui extends GuiImage {
	static var currentSelectionStatic:Int = 0;
	static var currentDifficultyStatic:String = "beginner";

	var innerCtrl:GuiControl;

	public function new(difficulty:String) {
		var res = ResourceLoader.getImage("data/ui/game/CloudBG.jpg").resource.toTile();
		super(res);

		var arial14fontdata = ResourceLoader.getFileEntry("data/font/Arial Bold.fnt");
		var arial14b = new BitmapFont(arial14fontdata.entry);
		@:privateAccess arial14b.loader = ResourceLoader.loader;
		var arial14 = arial14b.toSdfFont(cast 21 * Settings.uiScale, h2d.Font.SDFChannel.MultiChannel);
		function mlFontLoader(text:String) {
			return arial14;
		}

		var fadeEdge = new GuiImage(ResourceLoader.getResource("data/ui/xbox/BG_fadeOutSoftEdge.png", ResourceLoader.getImage, this.imageResources).toTile());
		fadeEdge.position = new Vector(0, 0);
		fadeEdge.extent = new Vector(640, 480);
		fadeEdge.vertSizing = Height;
		fadeEdge.horizSizing = Width;
		this.addChild(fadeEdge);

		var loadAnim = new GuiLoadAnim();
		loadAnim.position = new Vector(610, 253);
		loadAnim.extent = new Vector(63, 63);
		loadAnim.horizSizing = Center;
		loadAnim.vertSizing = Bottom;
		this.addChild(loadAnim);

		var loadTextBg = new GuiText(arial14);
		loadTextBg.position = new Vector(608, 335);
		loadTextBg.extent = new Vector(63, 40);
		loadTextBg.horizSizing = Center;
		loadTextBg.vertSizing = Bottom;
		loadTextBg.justify = Center;
		loadTextBg.text.text = "Loading";
		loadTextBg.text.textColor = 0;
		this.addChild(loadTextBg);

		var loadText = new GuiText(arial14);
		loadText.position = new Vector(610, 334);
		loadText.extent = new Vector(63, 40);
		loadText.horizSizing = Center;
		loadText.vertSizing = Bottom;
		loadText.justify = Center;
		loadText.text.text = "Loading";
		this.addChild(loadText);

		if (currentDifficultyStatic != difficulty) {
			currentSelectionStatic = 0;
		}
		currentDifficultyStatic = difficulty;

		var difficultyMissions = MissionList.missionList['ultra'][currentDifficultyStatic];
		var curMission = difficultyMissions[currentSelectionStatic];

		var lock = true;
		var currentToken = 0;
		var requestToken = 0;

		// var misFile = Path.withoutExtension(Path.withoutDirectory(curMission.path));
		// MarbleGame.instance.setPreviewMission(misFile, () -> {
		// 	lock = false;
		// 	if (currentToken != requestToken)
		// 		return;
		// 	this.bmp.visible = false;
		// 	loadAnim.anim.visible = false;
		// 	loadText.text.visible = false;
		// 	loadTextBg.text.visible = false;
		// });

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
		rootTitle.text.text = "SELECT LEVEL";
		rootTitle.text.alpha = 0.5;
		innerCtrl.addChild(rootTitle);
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
		backButton.pressedAction = (e) -> MarbleGame.canvas.setContent(new DifficultySelectGui());
		bottomBar.addChild(backButton);

		var lbButton = new GuiXboxButton("Leaderboard", 220);
		lbButton.position = new Vector(750, 0);
		lbButton.vertSizing = Bottom;
		lbButton.horizSizing = Right;
		bottomBar.addChild(lbButton);

		var nextButton = new GuiXboxButton("Play", 160);
		nextButton.position = new Vector(960, 0);
		nextButton.vertSizing = Bottom;
		nextButton.horizSizing = Right;
		nextButton.pressedAction = (e) -> {
			MarbleGame.instance.playMission(curMission);
		};
		bottomBar.addChild(nextButton);

		var levelWnd = new GuiImage(ResourceLoader.getResource("data/ui/xbox/levelPreviewWindow.png", ResourceLoader.getImage, this.imageResources).toTile());
		levelWnd.position = new Vector(555, 469);
		levelWnd.extent = new Vector(535, 137);
		levelWnd.vertSizing = Bottom;
		levelWnd.horizSizing = Right;
		innerCtrl.addChild(levelWnd);

		var statIcon = new GuiImage(ResourceLoader.getResource("data/ui/xbox/statIcon.png", ResourceLoader.getImage, this.imageResources).toTile());
		statIcon.position = new Vector(29, 54);
		statIcon.extent = new Vector(20, 20);
		levelWnd.addChild(statIcon);

		var c0 = 0xEBEBEB;
		var c1 = 0x8DFF8D;
		var c2 = 0x88BCEE;
		var c3 = 0xFF7575;

		var levelInfoLeft = new GuiMLText(arial14, mlFontLoader);
		levelInfoLeft.position = new Vector(69, 54);
		levelInfoLeft.extent = new Vector(180, 100);
		levelInfoLeft.text.text = '<p align="right"><font color="#EBEBEB">My Best Time:</font><br/><font color="#EBEBEB">Par Time:</font></p>';
		levelInfoLeft.text.lineSpacing = 6;
		levelWnd.addChild(levelInfoLeft);

		var levelInfoMid = new GuiMLText(arial14, mlFontLoader);
		levelInfoMid.position = new Vector(269, 54);
		levelInfoMid.extent = new Vector(180, 100);
		levelInfoMid.text.text = '<p align="left"><font color="#EBEBEB">None</font><br/><font color="#88BCEE">99:59:99</font></p>';
		levelInfoMid.text.lineSpacing = 6;
		levelWnd.addChild(levelInfoMid);

		var levelInfoRight = new GuiMLText(arial14, mlFontLoader);
		levelInfoRight.position = new Vector(379, 54);
		levelInfoRight.extent = new Vector(180, 100);
		levelInfoRight.text.text = '<p align="left"><font color="#EBEBEB">Level 1<br/>Difficulty 1</font></p>';
		levelInfoRight.text.lineSpacing = 6;
		levelWnd.addChild(levelInfoRight);

		function setLevel(idx:Int) {
			// if (lock)
			//	return false;
			this.bmp.visible = true;
			loadAnim.anim.visible = true;
			loadText.text.visible = true;
			loadTextBg.text.visible = true;
			lock = true;
			curMission = difficultyMissions[idx];
			currentSelectionStatic = idx;
			currentToken++;
			var misFile = Path.withoutExtension(Path.withoutDirectory(curMission.path));
			var mis = difficultyMissions[idx];
			var requestToken = currentToken;
			MarbleGame.instance.setPreviewMission(misFile, () -> {
				lock = false;
				if (requestToken != currentToken)
					return;
				this.bmp.visible = false;
				loadAnim.anim.visible = false;
				loadText.text.visible = false;
				loadTextBg.text.visible = false;
			});
			var myScore = Settings.getScores(mis.path);
			var scoreDisp = "None";
			if (myScore.length != 0)
				scoreDisp = Util.formatTime(myScore[0].time);
			var isPar = myScore.length != 0 && myScore[0].time < mis.qualifyTime;
			var scoreColor = "#EBEBEB";
			if (isPar)
				scoreColor = "#8DFF8D";
			levelInfoMid.text.text = '<p align="left"><font color="${scoreColor}">${scoreDisp}</font><br/><font color="#88BCEE">${Util.formatTime(mis.qualifyTime)}</font></p>';
			levelInfoRight.text.text = '<p align="left"><font color="#EBEBEB">Level ${mis.missionInfo.level}<br/>Difficulty ${mis.missionInfo.difficulty}</font></p>';
			return true;
		}

		var levelNames = difficultyMissions.map(x -> x.title);

		var levelSelectOpts = new GuiXboxOptionsList(6, "Level", levelNames);
		levelSelectOpts.position = new Vector(380, 435);
		levelSelectOpts.extent = new Vector(815, 94);
		levelSelectOpts.vertSizing = Bottom;
		levelSelectOpts.horizSizing = Right;
		levelSelectOpts.alwaysActive = true;
		levelSelectOpts.onChangeFunc = setLevel;
		levelSelectOpts.setCurrentOption(currentSelectionStatic);
		setLevel(currentSelectionStatic);
		innerCtrl.addChild(levelSelectOpts);
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
