package gui;

import modes.GameMode.GameModeFactory;
import modes.GameMode.ScoreType;
import h3d.shader.VertexColorAlpha;
import src.Http;
import src.Leaderboards;
import net.ClientConnection.NetPlatform;
import src.Marbleland;
import h2d.filter.DropShadow;
import src.Replay;
import haxe.ds.Option;
import hxd.Key;
import gui.GuiControl.MouseState;
import h3d.Matrix;
import h2d.filter.ColorMatrix;
import h2d.Tile;
import h3d.mat.Texture;
import h2d.Bitmap;
import hxd.BitmapData;
import src.AudioManager;
import src.Settings.Score;
import src.Settings.Settings;
import haxe.io.Path;
import h2d.Scene;
import h2d.Text;
import src.Mission;
import hxd.res.BitmapFont;
import src.ResourceLoader;
import h3d.Vector;
import src.Util;
import src.MarbleGame;
import src.MissionList;

class PlayMissionGui extends GuiControl {
	static var currentSelectionStatic:Int = -1;
	static var currentCategoryStatic:String = "tutorial";
	static var currentGameStatic:String = "platinum";
	static var currentSortType:Int = 1;

	var currentGame:String = "platinum";
	var currentSelection:Int = 0;
	var currentCategory:String = "tutorial";
	var currentList:Array<Mission>;

	var rebuildMissionList:Int->Void;
	var setSelectedFunc:Int->Void;
	var setScoreHover:Bool->Void;
	var setCategoryFunc:(String, String, ?String, ?Bool) -> Void;
	var buttonHoldFunc:(dt:Float, mouseState:MouseState) -> Void;

	var pmScoreButton:GuiButton;
	var scoreButtonHover:Bool = false;
	var scoreButtonDirty:Bool = true;
	var scoreShowing:Bool = false;

	#if js
	var previewTimeoutHandle:Option<Int> = None;
	var lbRequest:Int = 0;
	#end
	#if hl
	var previewToken:Int = 0;
	var lbToken:Int = 0;
	var lbRequest:src.Http.HttpRequest = null;
	#end

	public function new() {
		MissionList.buildMissionList();

		// if (currentSelectionStatic == -1)
		// 	currentSelectionStatic = cast Math.min(MissionList.missionList["platinum"]["beginner"].length - 1,
		// 		Settings.progression[["beginner", "intermediate", "advanced", "expert"].indexOf(currentCategory)]);
		if (currentSelectionStatic == -1) {
			currentSelectionStatic = 0; // start from the beginning please, this is PQ
		}

		function loadButtonImages(path:String) {
			var normal = ResourceLoader.getResource('${path}_n.png', ResourceLoader.getImage, this.imageResources).toTile();
			var hover = ResourceLoader.getResource('${path}_h.png', ResourceLoader.getImage, this.imageResources).toTile();
			var pressed = ResourceLoader.getResource('${path}_d.png', ResourceLoader.getImage, this.imageResources).toTile();
			return [normal, hover, pressed];
		}

		// currentSelection = PlayMissionGui.currentSelectionStatic;
		currentCategory = PlayMissionGui.currentCategoryStatic;
		currentGame = PlayMissionGui.currentGameStatic;

		currentList = currentGame == "platinum" ? MissionList.missionList[currentGame][currentCategory] : Marbleland.getMissionList(currentCategory);

		MarbleGame.instance.toRecord = false;

		super();
		this.horizSizing = Width;
		this.vertSizing = Height;
		this.position = new Vector(0, 0);
		this.extent = new Vector(800, 600);

		var levelPreview = new GuiImage(ResourceLoader.getResource("data/previews_pq/tutorial/TrainingWheels.prev.dds", ResourceLoader.getImage,
			this.imageResources)
			.toTile());
		levelPreview.horizSizing = Width;
		levelPreview.vertSizing = Height;
		levelPreview.position = new Vector(0, 0);
		levelPreview.extent = new Vector(800, 600);
		this.addChild(levelPreview);

		var whatneyFontData = ResourceLoader.getFileEntry("data/font/whatney.fnt");
		var whatneyFontB = new BitmapFont(whatneyFontData.entry);
		@:privateAccess whatneyFontB.loader = ResourceLoader.loader;
		var whatneyFont = whatneyFontB.toSdfFont(cast 21 * Settings.uiScale, MultiChannel);
		var whatneyFont21 = whatneyFontB.toSdfFont(cast 17 * Settings.uiScale, MultiChannel);

		var squishneyFontData = ResourceLoader.getFileEntry("data/font/squishney.fnt");
		var squishneyFontB = new BitmapFont(squishneyFontData.entry);
		@:privateAccess squishneyFontB.loader = ResourceLoader.loader;
		var squishneyFont = squishneyFontB.toSdfFont(cast 28 * Settings.uiScale, MultiChannel);
		var squishney48 = squishneyFontB.toSdfFont(cast 41 * Settings.uiScale, MultiChannel);
		var squishney36 = squishneyFontB.toSdfFont(cast 32 * Settings.uiScale, MultiChannel);
		var squishney26 = squishneyFontB.toSdfFont(cast 21 * Settings.uiScale, MultiChannel);
		var squishney24 = squishneyFontB.toSdfFont(cast 19 * Settings.uiScale, MultiChannel);
		var squishney21 = squishneyFontB.toSdfFont(cast 18 * Settings.uiScale, MultiChannel);

		function mlFontLoader(text:String) {
			switch (text) {
				case "font21":
					return whatneyFont21;
				case "bold21":
					return squishney21;
				case "bold48":
					return squishney48;
				default:
					return null;
			}
		}

		function imgLoader(path:String) {
			var t = switch (path) {
				case "pc":
					ResourceLoader.getResource("data/ui/mp/play/platform_desktop.png", ResourceLoader.getImage, this.imageResources).toTile();
				case "mac":
					ResourceLoader.getResource("data/ui/mp/play/platform_mac.png", ResourceLoader.getImage, this.imageResources).toTile();
				case "web":
					ResourceLoader.getResource("data/ui/mp/play/platform_web.png", ResourceLoader.getImage, this.imageResources).toTile();
				case "android":
					ResourceLoader.getResource("data/ui/mp/play/platform_android.png", ResourceLoader.getImage, this.imageResources).toTile();
				case "unknown":
					ResourceLoader.getResource("data/ui/mp/play/platform_unknown.png", ResourceLoader.getImage, this.imageResources).toTile();
				case "rewind":
					ResourceLoader.getResource("data/ui/mp/play/rewind_ico_black.png", ResourceLoader.getImage, this.imageResources).toTile();
				case "watch":
					ResourceLoader.getResource("data/ui/play/record.png", ResourceLoader.getImage, this.imageResources).toTile();
				case _:
					return null;
			};
			if (t != null)
				t.scaleToSize(t.width * (Settings.uiScale), t.height * (Settings.uiScale));
			return t;
		}

		var squishneyFont28 = squishneyFontB.toSdfFont(cast 25 * Settings.uiScale, MultiChannel);

		var optionsButton = new GuiBorderButtonTextCtrl(ResourceLoader.getResource('data/ui/common/button-plain.png', ResourceLoader.getImage,
			this.imageResources)
			.toTile(), squishneyFont28);
		optionsButton.position = new Vector(650, 525);
		optionsButton.setExtent(new Vector(140, 65));
		optionsButton.vertSizing = Top;
		optionsButton.horizSizing = Left;
		optionsButton.pressedAction = (e) -> {
			MarbleGame.canvas.setContent(new OptionsDlg());
		}
		optionsButton.txtCtrl.text.text = "Options";
		this.addChild(optionsButton);

		var missionBox = new GuiControl();
		missionBox.vertSizing = Height;
		missionBox.position = new Vector(10, 0);
		missionBox.extent = new Vector(360, 600);
		this.addChild(missionBox);

		var mbb = new GuiImage(ResourceLoader.getResource("data/ui/play/missionlist.png", ResourceLoader.getImage, this.imageResources).toTile());
		mbb.horizSizing = Width;
		mbb.vertSizing = Height;
		mbb.position = new Vector(0, 0);
		mbb.extent = new Vector(360, 600);
		mbb.bmp.smooth = true;
		missionBox.addChild(mbb);

		var buttonBox = new GuiControl();
		buttonBox.vertSizing = Top;
		buttonBox.horizSizing = Center;
		buttonBox.position = new Vector(743, 510);
		buttonBox.extent = new Vector(434, 90);
		this.addChild(buttonBox);

		var playMission = new GuiBorderButtonCtrl(ResourceLoader.getResource('data/ui/play/barbuttonleft.png', ResourceLoader.getImage, this.imageResources)
			.toTile(), {
				tl: new Vector(0, 1, 24, 11),
				tr: new Vector(119, 1, 1, 11),
				bl: new Vector(0, 91, 24, 37),
				br: new Vector(119, 91, 1, 17),
				top: new Vector(25, 1, 93, 11),
				left: new Vector(0, 13, 24, 77),
				right: new Vector(119, 13, 1, 77),
				bottom: new Vector(25, 91, 93, 37),
				fill: new Vector(25, 13, 93, 77),
				separation: 128
			});
		playMission.position = new Vector(3, 0);
		playMission.extent = new Vector(119, 128);
		playMission.gamepadAccelerator = ["A"];
		playMission.pressedAction = (sender) -> {
			// Wacky hacks
			currentList[currentSelection].index = currentSelection;
			currentList[currentSelection].difficultyIndex = ["tutorial", "beginner", "intermediate", "advanced", "expert", "bonus"].indexOf(currentCategory);
			currentSelectionStatic = currentSelection;
			currentCategoryStatic = currentCategory;
			cast(this.parent, Canvas).marbleGame.playMission(currentList[currentSelection]);
		}
		buttonBox.addChild(playMission);

		var colorMat = new Matrix();
		colorMat.colorSet(0x555555);

		var playMissionIcon = new GuiImage(ResourceLoader.getResource("data/ui/play/buttons/play.png", ResourceLoader.getImage, this.imageResources).toTile());
		playMissionIcon.position = new Vector(24, 0);
		playMissionIcon.extent = new Vector(95, 128);
		playMissionIcon.bmp.colorMatrix = colorMat;
		playMission.addChild(playMissionIcon);

		var hintsBtn = new GuiBorderButtonCtrl(ResourceLoader.getResource('data/ui/play/barbutton.png', ResourceLoader.getImage, this.imageResources)
			.toTile(), {
				tl: new Vector(0, 1, 1, 11),
				tr: new Vector(96, 1, 1, 11),
				bl: new Vector(0, 91, 1, 11),
				br: new Vector(96, 91, 1, 17),
				top: new Vector(2, 1, 93, 11),
				left: new Vector(0, 13, 1, 77),
				right: new Vector(96, 13, 1, 77),
				bottom: new Vector(2, 91, 93, 37),
				fill: new Vector(2, 13, 93, 77),
				separation: 128
			});
		hintsBtn.position = new Vector(122, 0);
		hintsBtn.extent = new Vector(95, 128);
		hintsBtn.pressedAction = (sender) -> {
			MarbleGame.canvas.pushDialog(new HintsDlg(currentList[currentSelection]));
		}
		buttonBox.addChild(hintsBtn);

		var hintsIcon = new GuiImage(ResourceLoader.getResource("data/ui/play/buttons/hints.png", ResourceLoader.getImage, this.imageResources).toTile());
		hintsIcon.horizSizing = Center;
		hintsIcon.vertSizing = Center;
		hintsIcon.position = new Vector(0, 0);
		hintsIcon.extent = new Vector(95, 128);
		hintsIcon.bmp.colorMatrix = colorMat;
		hintsBtn.addChild(hintsIcon);

		var extrasPopup = new GuiControl();
		extrasPopup.horizSizing = Width;
		extrasPopup.vertSizing = Height;
		extrasPopup.position = new Vector(0, 0);
		extrasPopup.extent = new Vector(800, 600);

		var extrasBox = new GuiControl();
		extrasBox.position = new Vector(753, 420);
		extrasBox.extent = new Vector(389, 256);
		extrasBox.horizSizing = Center;
		extrasBox.vertSizing = Top;
		extrasPopup.addChild(extrasBox);

		var marbleBtn = new GuiBorderButtonCtrl(ResourceLoader.getResource('data/ui/play/barbuttonleft.png', ResourceLoader.getImage, this.imageResources)
			.toTile(), {
				tl: new Vector(0, 1, 24, 11),
				tr: new Vector(119, 1, 1, 11),
				bl: new Vector(0, 91, 24, 37),
				br: new Vector(119, 91, 1, 17),
				top: new Vector(25, 1, 93, 11),
				left: new Vector(0, 13, 24, 77),
				right: new Vector(119, 13, 1, 77),
				bottom: new Vector(25, 91, 93, 37),
				fill: new Vector(25, 13, 93, 77),
				separation: 128
			});
		marbleBtn.position = new Vector(75, 0);
		marbleBtn.extent = new Vector(119, 128);
		marbleBtn.pressedAction = (e) -> {
			MarbleGame.canvas.pushDialog(new MarbleSelectGui());
		}
		extrasBox.addChild(marbleBtn);

		var marbleBtnIcon = new GuiImage(ResourceLoader.getResource("data/ui/play/buttons/marble.png", ResourceLoader.getImage, this.imageResources).toTile());
		marbleBtnIcon.position = new Vector(24, 0);
		marbleBtnIcon.extent = new Vector(95, 128);
		marbleBtnIcon.bmp.colorMatrix = colorMat;
		marbleBtn.addChild(marbleBtnIcon);

		var searchBtn = new GuiBorderButtonCtrl(ResourceLoader.getResource('data/ui/play/barbuttontab.png', ResourceLoader.getImage, this.imageResources)
			.toTile(), {
				tl: new Vector(0, 1, 1, 11),
				tr: new Vector(96, 1, 1, 11),
				bl: new Vector(0, 91, 1, 11),
				br: new Vector(96, 91, 1, 17),
				top: new Vector(2, 1, 93, 11),
				left: new Vector(0, 13, 1, 77),
				right: new Vector(96, 13, 1, 77),
				bottom: new Vector(2, 91, 93, 37),
				fill: new Vector(2, 13, 93, 77),
				separation: 128
			});
		searchBtn.position = new Vector(194, 0);
		searchBtn.extent = new Vector(95, 102);
		searchBtn.pressedAction = (e) -> {
			MarbleGame.canvas.pushDialog(new SearchGui(currentGame, currentGame == "custom"));
		}
		extrasBox.addChild(searchBtn);

		var searchBtnIcon = new GuiImage(ResourceLoader.getResource("data/ui/play/buttons/search.png", ResourceLoader.getImage, this.imageResources).toTile());
		searchBtnIcon.position = new Vector(0, 0);
		searchBtnIcon.extent = new Vector(95, 128);
		searchBtnIcon.bmp.colorMatrix = colorMat;
		searchBtn.addChild(searchBtnIcon);

		var recordBtn = new GuiBorderButtonCtrl(ResourceLoader.getResource('data/ui/play/barbuttonright.png', ResourceLoader.getImage, this.imageResources)
			.toTile(), {
				tl: new Vector(0, 1, 1, 11),
				tr: new Vector(96, 1, 1, 11),
				bl: new Vector(0, 91, 1, 11),
				br: new Vector(96, 91, 1, 17),
				top: new Vector(2, 1, 93, 11),
				left: new Vector(0, 13, 1, 77),
				right: new Vector(96, 13, 1, 77),
				bottom: new Vector(2, 91, 93, 37),
				fill: new Vector(2, 13, 93, 77),
				separation: 128
			});
		recordBtn.position = new Vector(289, 0);
		recordBtn.extent = new Vector(95, 102);
		recordBtn.pressedAction = (sender) -> {
			MarbleGame.instance.toRecord = true;
			MarbleGame.canvas.pushDialog(new MessageBoxOkDlg("The next mission you play will be recorded."));
		};
		extrasBox.addChild(recordBtn);

		var recordBtnIcon = new GuiImage(ResourceLoader.getResource("data/ui/play/buttons/record.png", ResourceLoader.getImage, this.imageResources).toTile());
		recordBtnIcon.position = new Vector(0, 0);
		recordBtnIcon.extent = new Vector(95, 128);
		recordBtnIcon.bmp.colorMatrix = colorMat;
		recordBtn.addChild(recordBtnIcon);

		var temprev = new BitmapData(1, 1);
		temprev.setPixel(0, 0, 0);
		var tmpprevtile = Tile.fromBitmap(temprev);

		var extrasBackBtn = new GuiButton([tmpprevtile, tmpprevtile, tmpprevtile]);
		extrasBackBtn.position = new Vector(194, 102);
		extrasBackBtn.extent = new Vector(95, 128);
		extrasBackBtn.pressedAction = (e) -> {
			MarbleGame.canvas.popDialog(extrasPopup, false);
		};
		extrasBox.addChild(extrasBackBtn);

		var extrasBtn = new GuiBorderButtonCtrl(ResourceLoader.getResource('data/ui/play/barbutton.png', ResourceLoader.getImage, this.imageResources)
			.toTile(), {
				tl: new Vector(0, 1, 1, 11),
				tr: new Vector(96, 1, 1, 11),
				bl: new Vector(0, 91, 1, 11),
				br: new Vector(96, 91, 1, 17),
				top: new Vector(2, 1, 93, 11),
				left: new Vector(0, 13, 1, 77),
				right: new Vector(96, 13, 1, 77),
				bottom: new Vector(2, 91, 93, 37),
				fill: new Vector(2, 13, 93, 77),
				separation: 128
			});
		extrasBtn.position = new Vector(217, 0);
		extrasBtn.extent = new Vector(95, 128);
		extrasBtn.pressedAction = (e) -> {
			MarbleGame.canvas.pushDialog(extrasPopup);
		}
		buttonBox.addChild(extrasBtn);

		var extrasIcon = new GuiImage(ResourceLoader.getResource("data/ui/play/buttons/menu.png", ResourceLoader.getImage, this.imageResources).toTile());
		extrasIcon.horizSizing = Center;
		extrasIcon.vertSizing = Center;
		extrasIcon.position = new Vector(0, 0);
		extrasIcon.extent = new Vector(95, 128);
		extrasIcon.bmp.colorMatrix = colorMat;
		extrasBtn.addChild(extrasIcon);

		var backBtn = new GuiBorderButtonCtrl(ResourceLoader.getResource('data/ui/play/barbuttonright.png', ResourceLoader.getImage, this.imageResources)
			.toTile(), {
				tl: new Vector(0, 1, 1, 11),
				tr: new Vector(96, 1, 1, 11),
				bl: new Vector(0, 91, 1, 11),
				br: new Vector(96, 91, 1, 17),
				top: new Vector(2, 1, 93, 11),
				left: new Vector(0, 13, 1, 77),
				right: new Vector(96, 13, 1, 77),
				bottom: new Vector(2, 91, 93, 37),
				fill: new Vector(2, 13, 93, 77),
				separation: 128
			});
		backBtn.position = new Vector(312, 0);
		backBtn.extent = new Vector(95, 128);
		backBtn.pressedAction = (e) -> {
			cast(this.parent, Canvas).setContent(new MainMenuGui());
		}
		buttonBox.addChild(backBtn);

		var backBtnIcon = new GuiImage(ResourceLoader.getResource("data/ui/play/buttons/back.png", ResourceLoader.getImage, this.imageResources).toTile());
		backBtnIcon.horizSizing = Center;
		backBtnIcon.vertSizing = Center;
		backBtnIcon.position = new Vector(0, 0);
		backBtnIcon.extent = new Vector(95, 128);
		backBtnIcon.bmp.colorMatrix = colorMat;
		backBtn.addChild(backBtnIcon);

		var infoBox = new GuiTransparencyCtrl("data/ui/transparency/pqwindow");
		infoBox.horizSizing = Relative;
		infoBox.vertSizing = Top;
		infoBox.position = new Vector(470, 230);
		infoBox.extent = new Vector(330, 238);
		this.addChild(infoBox);

		var missionInfoPanel = new GuiControl();
		missionInfoPanel.horizSizing = Width;
		missionInfoPanel.vertSizing = Height;
		missionInfoPanel.position = new Vector(19, 57);
		missionInfoPanel.extent = new Vector(317, 238);
		infoBox.addChild(missionInfoPanel);

		var missionTitle = new GuiText(squishney48);
		missionTitle.position = new Vector(16, 14);
		missionTitle.horizSizing = Width;
		missionTitle.extent = new Vector(169, 56);
		missionTitle.text.textColor = 0;
		missionTitle.text.text = "Training Wheels";
		infoBox.addChild(missionTitle);

		var missionScoresTitle = new GuiMLText(squishney36, null);
		missionScoresTitle.position = new Vector(118, 15);
		missionScoresTitle.horizSizing = Left;
		missionScoresTitle.extent = new Vector(186, 41);
		missionScoresTitle.text.textColor = 0;
		missionScoresTitle.text.text = '<p align="center">Top Scores:</p>';
		infoBox.addChild(missionScoresTitle);

		var missionScoresInfoLeft = new GuiMLText(whatneyFont21, null);
		missionScoresInfoLeft.horizSizing = Left;
		missionScoresInfoLeft.position = new Vector(128, 0);
		missionScoresInfoLeft.extent = new Vector(186, 162);
		missionScoresInfoLeft.text.textColor = 0;
		missionScoresInfoLeft.text.text = "Score1";
		missionScoresInfoLeft.text.lineSpacing = 4;
		missionInfoPanel.addChild(missionScoresInfoLeft);

		var missionScoresInfoRight = new GuiMLText(whatneyFont21, null);
		missionScoresInfoRight.horizSizing = Left;
		missionScoresInfoRight.position = new Vector(128, 0);
		missionScoresInfoRight.extent = new Vector(186, 162);
		missionScoresInfoRight.text.textColor = 0;
		missionScoresInfoRight.text.text = "Score1";
		missionScoresInfoRight.text.lineSpacing = 4;
		missionInfoPanel.addChild(missionScoresInfoRight);

		var missionInfoLeft = new GuiMLText(whatneyFont21, mlFontLoader);
		missionInfoLeft.position = new Vector(0, 0);
		missionInfoLeft.extent = new Vector(194, 138);
		missionInfoLeft.text.textColor = 0;
		missionInfoLeft.text.text = "Grab all the gems to finish!";
		missionInfoLeft.text.lineSpacing = 4;
		missionInfoLeft.text.loadImage = imgLoader;
		missionInfoPanel.addChild(missionInfoLeft);

		var missionInfoRight = new GuiMLText(whatneyFont21, mlFontLoader);
		missionInfoRight.position = new Vector(0, 0);
		missionInfoRight.extent = new Vector(194, 138);
		missionInfoRight.text.textColor = 0;
		missionInfoRight.text.text = "Grab all the gems to finish!";
		missionInfoRight.text.lineSpacing = 4;
		missionInfoPanel.addChild(missionInfoRight);

		var missionModesInfo = new GuiMLText(whatneyFont21, mlFontLoader);
		missionModesInfo.horizSizing = Width;
		missionModesInfo.vertSizing = Bottom;
		missionModesInfo.position = new Vector(0, 142);
		missionModesInfo.extent = new Vector(174, 69);
		missionModesInfo.text.textColor = 0;
		missionModesInfo.text.lineSpacing = 4;
		missionModesInfo.text.text = "Gem Collection: Pick up all the gems to finish!";
		missionInfoPanel.addChild(missionModesInfo);

		var sep = new GuiImage(ResourceLoader.getResource("data/ui/play/extras/extraslinev.png", ResourceLoader.getImage, this.imageResources).toTile());
		sep.horizSizing = Left;
		sep.vertSizing = Height;
		sep.position = new Vector(124, 3);
		sep.extent = new Vector(2, 159);
		missionInfoPanel.addChild(sep);

		var setDifficulty:(String, String) -> Void = null;

		var difficultyPopup = new GuiControl();
		difficultyPopup.horizSizing = Width;
		difficultyPopup.vertSizing = Height;
		difficultyPopup.position = new Vector(0, 0);
		difficultyPopup.extent = new Vector(800, 600);

		var difficultyList = new GuiImage(ResourceLoader.getResource("data/ui/transparency/pc_trans/0.png", ResourceLoader.getImage, this.imageResources)
			.toTile());
		difficultyList.position = new Vector(197, 50);
		difficultyList.extent = currentGame == "platinum" ? new Vector(158, 210) : new Vector(158, 105);
		difficultyPopup.addChild(difficultyList);

		if (currentGame == "platinum") {
			for (i in 0...6) {
				var difficultyBtn = new GuiButtonText(loadButtonImages("data/ui/play/difficulty"), squishney26);
				difficultyBtn.ratio = 0.27;
				difficultyBtn.setExtent(new Vector(156, 35));
				difficultyBtn.position = new Vector(1, 35 * i);
				difficultyBtn.txtCtrl.text.textColor = 0;
				difficultyBtn.txtCtrl.text.text = ["Tutorial", "Beginner", "Intermediate", "Advanced", "Expert", "Bonus"][i];
				var diff = ["tutorial", "beginner", "intermediate", "advanced", "expert", "bonus"][i];
				difficultyBtn.pressedAction = (e) -> {
					setDifficulty("platinum", diff);
					MarbleGame.canvas.popDialog(difficultyPopup, false);
				}
				difficultyList.addChild(difficultyBtn);
			}
		} else {
			for (i in 0...3) {
				var difficultyBtn = new GuiButtonText(loadButtonImages("data/ui/play/difficulty"), squishney26);
				difficultyBtn.ratio = 0.27;
				difficultyBtn.setExtent(new Vector(156, 35));
				difficultyBtn.position = new Vector(1, 35 * i);
				difficultyBtn.txtCtrl.text.textColor = 0;
				difficultyBtn.txtCtrl.text.text = ["Relevant", "All", "Alphabetical"][i];
				var diff = ["relevant", "all", "alphabetical"][i];
				difficultyBtn.pressedAction = (e) -> {
					setDifficulty("custom", diff);
					MarbleGame.canvas.popDialog(difficultyPopup, false);
				}
				difficultyList.addChild(difficultyBtn);
			}
		}

		var gamePopup = new GuiControl();
		gamePopup.horizSizing = Width;
		gamePopup.vertSizing = Height;
		gamePopup.position = new Vector(0, 0);
		gamePopup.extent = new Vector(800, 600);

		var gameList = new GuiImage(ResourceLoader.getResource("data/ui/transparency/pc_trans/0.png", ResourceLoader.getImage, this.imageResources).toTile());
		gameList.position = new Vector(23, 50);
		gameList.extent = new Vector(158, 70);
		gamePopup.addChild(gameList);

		var pqBtn = new GuiButtonText(loadButtonImages("data/ui/play/difficulty"), squishney26);
		pqBtn.ratio = 0.27;
		pqBtn.setExtent(new Vector(156, 35));
		pqBtn.position = new Vector(1, 0);
		pqBtn.txtCtrl.text.textColor = 0;
		pqBtn.txtCtrl.text.text = "PlatinumQuest";
		pqBtn.pressedAction = (e) -> {
			setDifficulty("platinum", "tutorial");
			MarbleGame.canvas.popDialog(gamePopup, false);
		}
		gameList.addChild(pqBtn);

		var customBtn = new GuiButtonText(loadButtonImages("data/ui/play/difficulty"), squishney26);
		customBtn.ratio = 0.27;
		customBtn.setExtent(new Vector(156, 35));
		customBtn.position = new Vector(1, 35);
		customBtn.txtCtrl.text.textColor = 0;
		customBtn.txtCtrl.text.text = "Custom";
		customBtn.pressedAction = (e) -> {
			setDifficulty("custom", "relevant");
			MarbleGame.canvas.popDialog(gamePopup, false);
		}
		gameList.addChild(customBtn);

		var gameSelector = new GuiBorderButtonTextCtrl(ResourceLoader.getResource("data/ui/play/selector.png", ResourceLoader.getImage, this.imageResources)
			.toTile(), squishney26, {
				tl: new Vector(0, 2, 17, 31),
				tr: new Vector(159, 2, 41, 31),
				bl: new Vector(0, 74, 17, 31),
				br: new Vector(159, 74, 41, 31),
				top: new Vector(18, 2, 140, 31),
				left: new Vector(0, 34, 17, 39),
				right: new Vector(159, 34, 41, 39),
				bottom: new Vector(18, 74, 140, 31),
				fill: new Vector(18, 34, 140, 39),
				separation: 105
			});
		gameSelector.position = new Vector(-3, -21);
		gameSelector.ratio = 0.4;
		gameSelector.setExtent(new Vector(191, 101));
		gameSelector.txtCtrl.text.textColor = 0;
		gameSelector.txtCtrl.text.text = "PlatinumQuest";
		gameSelector.pressedAction = (e) -> {
			MarbleGame.canvas.pushDialog(gamePopup);
		}
		missionBox.addChild(gameSelector);

		var difficultySelector = new GuiBorderButtonTextCtrl(ResourceLoader.getResource("data/ui/play/selector.png", ResourceLoader.getImage,
			this.imageResources)
			.toTile(), squishney26, {
				tl: new Vector(0, 2, 17, 31),
				tr: new Vector(159, 2, 41, 31),
				bl: new Vector(0, 74, 17, 31),
				br: new Vector(159, 74, 41, 31),
				top: new Vector(18, 2, 140, 31),
				left: new Vector(0, 34, 17, 39),
				right: new Vector(159, 34, 41, 39),
				bottom: new Vector(18, 74, 140, 31),
				fill: new Vector(18, 34, 140, 39),
				separation: 105
			});
		difficultySelector.position = new Vector(171, -21);
		difficultySelector.ratio = 0.4;
		difficultySelector.setExtent(new Vector(191, 101));
		difficultySelector.txtCtrl.text.textColor = 0;
		difficultySelector.txtCtrl.text.text = "Tutorial";
		difficultySelector.pressedAction = (e) -> {
			MarbleGame.canvas.pushDialog(difficultyPopup);
		}
		missionBox.addChild(difficultySelector);

		setDifficulty = (gameName, diffName) -> {
			difficultySelector.txtCtrl.text.text = diffName.charAt(0).toUpperCase() + diffName.substr(1);
			gameSelector.txtCtrl.text.text = gameName == "platinum" ? "PlatinumQuest" : "Custom";

			if (currentGame != gameName) {
				// Rebuild the difficulty list

				// delete everything from difficultylist
				while (difficultyList.children.length > 0) {
					var child = difficultyList.children[difficultyList.children.length - 1];
					child.dispose();
					difficultyList.children.pop();
				}

				if (gameName == "platinum") {
					difficultyList.extent = new Vector(158, 210);

					for (i in 0...6) {
						var difficultyBtn = new GuiButtonText(loadButtonImages("data/ui/play/difficulty"), squishney26);
						difficultyBtn.ratio = 0.27;
						difficultyBtn.setExtent(new Vector(156, 35));
						difficultyBtn.position = new Vector(1, 35 * i);
						difficultyBtn.txtCtrl.text.textColor = 0;
						difficultyBtn.txtCtrl.text.text = ["Tutorial", "Beginner", "Intermediate", "Advanced", "Expert", "Bonus"][i];
						var diff = ["tutorial", "beginner", "intermediate", "advanced", "expert", "bonus"][i];
						difficultyBtn.pressedAction = (e) -> {
							setDifficulty("platinum", diff);
							MarbleGame.canvas.popDialog(difficultyPopup, false);
						}
						difficultyList.addChild(difficultyBtn);
					}
				} else {
					difficultyList.extent = new Vector(158, 105);

					for (i in 0...3) {
						var difficultyBtn = new GuiButtonText(loadButtonImages("data/ui/play/difficulty"), squishney26);
						difficultyBtn.ratio = 0.27;
						difficultyBtn.setExtent(new Vector(156, 35));
						difficultyBtn.position = new Vector(1, 35 * i);
						difficultyBtn.txtCtrl.text.textColor = 0;
						difficultyBtn.txtCtrl.text.text = ["Relevant", "All", "Alphabetical"][i];
						var diff = ["relevant", "all", "alphabetical"][i];
						difficultyBtn.pressedAction = (e) -> {
							setDifficulty("custom", diff);
							MarbleGame.canvas.popDialog(difficultyPopup, false);
						}
						difficultyList.addChild(difficultyBtn);
					}
				}
				// difficultyList.render(MarbleGame.canvas.scene2d, @:privateAccess difficultyPopup._flow);
			}

			currentGame = gameName;
			currentGameStatic = gameName;
			currentCategory = diffName;
			currentCategoryStatic = diffName;
			if (gameName == "platinum")
				currentList = MissionList.missionList[currentGame][currentCategory];
			else {
				currentList = Marbleland.getMissionList(currentCategory);
			}

			rebuildMissionList(0);
		};

		var missionListContainer = new GuiControl();
		missionListContainer.horizSizing = Width;
		missionListContainer.vertSizing = Height;
		missionListContainer.position = new Vector(6, 75);
		missionListContainer.extent = new Vector(358, 526);
		missionBox.addChild(missionListContainer);

		function loadButtonImages(path:String) {
			var normal = ResourceLoader.getResource('${path}_n.png', ResourceLoader.getImage, this.imageResources).toTile();
			var hover = ResourceLoader.getResource('${path}_h.png', ResourceLoader.getImage, this.imageResources).toTile();
			var pressed = ResourceLoader.getResource('${path}_d.png', ResourceLoader.getImage, this.imageResources).toTile();
			return [normal, hover, pressed];
		}

		var temprev = new BitmapData(1, 1);
		temprev.setPixel(0, 0, 0);
		var tmpprevtile = Tile.fromBitmap(temprev);

		var pressedImgs = [];
		var currentPreviewMissions = [];

		rebuildMissionList = function(page:Int) {
			// Clear everything
			while (missionListContainer.children.length > 0) {
				var child = missionListContainer.children[missionListContainer.children.length - 1];
				child.dispose();
				missionListContainer.children.pop();
			}
			for (mis in currentPreviewMissions) {
				mis.cancelLoadingPreview();
			}
			pressedImgs = [];

			var mlist = currentList;

			var containerYSize = missionListContainer.getRenderRectangle().extent.y;

			var maxCount = Math.floor(containerYSize / 40.0) - 1; // size is 40 for each row, reserve one last row for pagination buttons
			var totalPages = Math.ceil(mlist.length / maxCount);

			for (i in 0...maxCount) {
				// build the thing
				if (page * maxCount + i >= mlist.length)
					break;

				var mis = mlist[page * maxCount + i];

				var misIdx = page * maxCount + i;

				var missionFrame = new GuiControl();
				missionFrame.position = new Vector(0, 40 * i);
				missionFrame.extent = new Vector(340, 40);
				missionListContainer.addChild(missionFrame);

				var misButton = new GuiButton(loadButtonImages('data/ui/play/menuhover'));
				misButton.horizSizing = Width;
				misButton.vertSizing = Height;
				misButton.position = new Vector(0, 0);
				misButton.extent = new Vector(340, 40);
				missionFrame.addChild(misButton);

				var misButtonPressed = new GuiImage(ResourceLoader.getResource('data/ui/play/menuhover_d.png', ResourceLoader.getImage, this.imageResources)
					.toTile());
				misButtonPressed.horizSizing = Width;
				misButtonPressed.vertSizing = Height;
				misButtonPressed.position = new Vector(0, 0);
				misButtonPressed.extent = new Vector(340, 40);
				missionFrame.addChild(misButtonPressed);
				misButtonPressed.bmp.visible = false;

				pressedImgs.push(misButtonPressed);

				misButton.pressedAction = (e) -> {
					for (img in pressedImgs)
						img.bmp.visible = false;
					misButtonPressed.bmp.visible = true;

					setSelectedFunc(misIdx);
				}

				var misIcon = new GuiImage(tmpprevtile);
				misIcon.position = new Vector(5, 5);
				misIcon.extent = new Vector(41, 30);
				missionFrame.addChild(misIcon);

				mis.getPreviewImage(prev -> {
					misIcon.bmp.tile = prev;
				});
				currentPreviewMissions.push(mis);
				var scores = Settings.getScores(mis.path);
				var progression = {
					beatPar: false,
					beatPlatinum: false,
					beatUltimate: false,
					beatAwesome: false
				};
				var frameImg = "frame_unlocked";
				if (scores.length != 0)
					progression = mis.calculateProgression(scores[0].time, scores[0].type == 0 ? Time : Score);
				if (progression.beatAwesome)
					frameImg = "frame_awesome";
				else if (progression.beatUltimate)
					frameImg = "frame_ultimate";
				else if (progression.beatPlatinum)
					if (mis.game == "gold" || mis.game.toLowerCase() == "ultra")
						frameImg = "frame_gold";
					else
						frameImg = "frame_platinum";
				else if (progression.beatPar)
					frameImg = "frame_completed";

				var misFrame = new GuiImage(ResourceLoader.getResource('data/ui/play/${frameImg}_n.png', ResourceLoader.getImage, this.imageResources)
					.toTile());
				misFrame.position = new Vector(0, 0);
				misFrame.extent = new Vector(51, 40);
				missionFrame.addChild(misFrame);

				if (mis.hasEgg) {
					var eggCollected = Settings.easterEggs.exists(mis.path);

					var eggIconImg = "";
					if (mis.missionInfo != null && mis.missionInfo.game == "platinumquest")
						eggIconImg = eggCollected ? "data/ui/play/egg_pq_get_ol.png" : "data/ui/play/egg_pq_notfound_ol.png";
					else
						eggIconImg = eggCollected ? "data/ui/play/egg_mbp_get_ol.png" : "data/ui/play/egg_mbp_notfound_ol.png";

					var eggIcon = new GuiImage(ResourceLoader.getResource(eggIconImg, ResourceLoader.getImage, this.imageResources).toTile());
					eggIcon.position = new Vector(320, 8);
					eggIcon.extent = new Vector(18, 24);
					missionFrame.addChild(eggIcon);
				}

				// finally, the title
				var missionTitle = new GuiText(squishney24);
				missionTitle.text.textColor = 0;
				missionTitle.text.text = mis.title;
				missionTitle.position = new Vector(56, 9);
				missionTitle.extent = new Vector(261, 27);
				missionFrame.addChild(missionTitle);
			}

			var paginationBg = new GuiImage(ResourceLoader.getResource('data/ui/play/menuhover_d.png', ResourceLoader.getImage, this.imageResources).toTile());
			paginationBg.position = new Vector(0, maxCount * 40 + 3);
			paginationBg.extent = new Vector(340, 40);
			missionListContainer.addChild(paginationBg);

			var nextBtn = new GuiBorderButtonCtrl(ResourceLoader.getResource('data/ui/common/button.png', ResourceLoader.getImage, this.imageResources)
				.toTile());
			nextBtn.horizSizing = Left;
			nextBtn.position = new Vector(255, maxCount * 40);
			nextBtn.extent = new Vector(45, 45);
			nextBtn.pressedAction = (e) -> {
				rebuildMissionList(Util.adjustediMod(page + 1, totalPages));
			}
			missionListContainer.addChild(nextBtn);

			var nextBtnIcon = new GuiImage(ResourceLoader.getResource("data/ui/play/leftright.png", ResourceLoader.getImage, this.imageResources).toTile());
			nextBtnIcon.position = new Vector(22.5 + 13.0 / 2, 22.5 + 19.0 / 2);
			nextBtnIcon.extent = new Vector(13, 19);
			nextBtnIcon.bmp.colorMatrix = colorMat;
			nextBtnIcon.bmp.rotation = Math.PI;
			nextBtn.addChild(nextBtnIcon);

			var prevBtn = new GuiBorderButtonCtrl(ResourceLoader.getResource('data/ui/common/button.png', ResourceLoader.getImage, this.imageResources)
				.toTile());
			prevBtn.horizSizing = Right;
			prevBtn.position = new Vector(40, maxCount * 40);
			prevBtn.extent = new Vector(45, 45);
			prevBtn.pressedAction = (e) -> {
				rebuildMissionList(Util.adjustediMod(page - 1, totalPages));
			}
			missionListContainer.addChild(prevBtn);

			var prevBtnIcon = new GuiImage(ResourceLoader.getResource("data/ui/play/leftright.png", ResourceLoader.getImage, this.imageResources).toTile());
			prevBtnIcon.horizSizing = Center;
			prevBtnIcon.vertSizing = Center;
			prevBtnIcon.position = new Vector(0, 0);
			prevBtnIcon.extent = new Vector(13, 19);
			prevBtnIcon.bmp.colorMatrix = colorMat;
			prevBtn.addChild(prevBtnIcon);

			var paginationText = new GuiText(squishney24);
			paginationText.text.textColor = 0;
			paginationText.text.text = 'Page: ${page + 1} / ${totalPages}';
			paginationText.position = new Vector(56, maxCount * 40 + 14);
			paginationText.extent = new Vector(340, 40);
			paginationText.justify = Center;
			paginationText.horizSizing = Center;
			missionListContainer.addChild(paginationText);

			missionListContainer.render(MarbleGame.canvas.scene2d, @:privateAccess missionBox._flow);
		}

		var showLeaderboards = false;
		var scoreView:LeaderboardsKind = All;

		setSelectedFunc = (idx) -> {
			var mission = currentList[idx];

			currentSelection = idx;
			currentSelectionStatic = idx;

			var scores = Settings.getScores(mission.path);
			var progression = {
				beatPar: false,
				beatPlatinum: false,
				beatUltimate: false,
				beatAwesome: false
			};
			var frameImg = "frame_unlocked";
			if (scores.length != 0)
				progression = mission.calculateProgression(scores[0].time, scores[0].type == 0 ? Time : Score);

			missionTitle.text.text = mission.title;

			var isScoreMode = (mission.gameMode != null
				&& (mission.gameMode.indexOf("hunt") != -1 || mission.gameMode.indexOf("madness") != -1));

			if (!showLeaderboards) {
				missionScoresTitle.text.text = '<p align="center">Top Scores:</p>';

				var artist = mission.artist != "" ? mission.artist : "No Author";
				var goldTimeLabel = mission.goldTime != 0 ? Util.formatTime(mission.goldTime) : "N/A";
				var ultimateTimeLabel = mission.ultimateTime != 0 ? Util.formatTime(mission.ultimateTime) : "N/A";
				var awesomeTimeLabel = mission.awesomeTime != 0 ? Util.formatTime(mission.awesomeTime) : "N/A";
				var goldScoreLabel = mission.goldScore != 0 ? Util.formatScore(mission.goldScore) : "N/A";
				var ultimateScoreLabel = mission.ultimateScore != 0 ? Util.formatScore(mission.ultimateScore) : "N/A";
				var awesomeScoreLabel = mission.awesomeScore != 0 ? Util.formatScore(mission.awesomeScore) : "N/A";

				var goldLabel = goldTimeLabel == "N/A" ? goldScoreLabel : goldTimeLabel;
				var ultimateLabel = ultimateTimeLabel == "N/A" ? ultimateScoreLabel : ultimateTimeLabel;
				var awesomeLabel = awesomeTimeLabel == "N/A" ? awesomeScoreLabel : awesomeTimeLabel;

				var goldType = goldTimeLabel == "N/A" ? ScoreType.Score : ScoreType.Time;
				var ultimateType = ultimateTimeLabel == "N/A" ? ScoreType.Score : ScoreType.Time;
				var awesomeType = awesomeTimeLabel == "N/A" ? ScoreType.Score : ScoreType.Time;

				var parTimeLabel = mission.qualifyTime != Math.POSITIVE_INFINITY ? Util.formatTime(mission.qualifyTime) : "N/A";
				var parScoreLabel = mission.qualifyingScore != 0 ? Util.formatScore(mission.qualifyingScore) : "N/A";
				var parLabel = parTimeLabel != "N/A" ? parTimeLabel : parScoreLabel;
				var parType = parTimeLabel != "N/A" ? "Time" : "Score";

				var parTitle = mission.game == "gold" ? 'Qualify ${parType}' : 'Par ${parType}';
				var goldTitle = mission.game == "gold" ? '<font color="#FFEE11" shadow="1,1" shadowcolor="#0000007F">Gold ${goldType == Score ? "Score" : "Time"}:</font>' : '<font color="#CCCCCC" shadow="1,1" shadowcolor="#0000007F">Platinum ${goldType == Score ? "Score" : "Time"}:</font>';
				var ultimateTitle = '<font color="#FFCC33" shadow="1,1" shadowcolor="#0000007F">Ultimate ${ultimateType == Score ? "Score" : "Time"}:</font>';
				var awesomeTitle = '<font color="#FF3333" shadow="1,1" shadowcolor="#0000007F">Awesome ${awesomeType == Score ? "Score" : "Time"}:</font>';

				var textLeft = '<font face="font21">';
				var textRight = '<font face="font21">';

				textLeft += '<p align="left">${StringTools.htmlEscape(mission.description)}</p>';
				textRight += '<p align="left"><font opacity="0">${StringTools.htmlEscape(mission.description)}</font></p>';

				textLeft += '<p align="left">Author:</p>';
				textRight += '<p align="right">${artist}</p>';

				if (isScoreMode)
					parTitle = "Duration";

				if (parTimeLabel != "N/A") {
					textLeft += '<p align="left">${parTitle}:</p>';
					textRight += '<p align="right">${parTimeLabel}</p>';
				}
				if (parScoreLabel != "N/A") {
					parTitle = mission.game == "gold" ? 'Qualify Score' : 'Par Score';
					textLeft += '<p align="left">${parTitle}:</p>';
					textRight += '<p align="right">${parScoreLabel}</p>';
				}

				if (goldLabel != "N/A") {
					textLeft += '<p align="left">${goldTitle}</p>';
					if (mission.game == "gold")
						textRight += '<p align="right">${goldLabel}</p>';
					else
						textRight += '<p align="right">${goldLabel}</p>';
				}

				if (ultimateLabel != "N/A") {
					textLeft += '<p align="left">${ultimateTitle}</p>';
					textRight += '<p align="right">${ultimateLabel}</p>';
				}

				if (awesomeLabel != "N/A" && progression.beatAwesome) {
					textLeft += '<p align="left">${awesomeTitle}</p>';
					textRight += '<p align="right">${awesomeLabel}</p>';
				}

				textLeft += "</font>";
				textRight += "</font>";

				missionInfoLeft.text.text = textLeft;
				missionInfoRight.text.text = textRight;

				var gameModeText = "";

				// get all the gamemodes
				var gameModes = mission.gameMode != null ? mission.gameMode.split(' ') : [];
				gameModes = gameModes.filter(x -> x != "null");
				if (gameModes.length == 0)
					gameModes.push("null");

				for (mode in gameModes) {
					var modeData = GameModeFactory.getGameModeDescription(mode);
					gameModeText += '<font face="bold21">${modeData.name}: </font>${modeData.desc}<br/>';
				}

				missionModesInfo.text.text = gameModeText;
			} else {
				// Leaderboards
				missionScoresTitle.text.text = '<p align="center">Your Scores:</p>';

				var text = 'Loading Scores...';
				missionInfoLeft.text.text = text;
				missionInfoRight.text.text = '';

				#if hl
				if (lbRequest != null)
					Http.cancel(lbRequest);
				#end
				#if js
				if (lbRequest != 0)
					Http.cancel(lbRequest);
				#end
				var lTok = lbToken++;
				var lbPath = mission.path;

				var req = Leaderboards.getScores(mission.path, scoreView, (scores) -> {
					if (lTok + 1 != lbToken || !showLeaderboards)
						return;
					var text = '';

					if (scores.length == 0) {
						text += '<p align="center">No scores! Be the first to beat this level!</p>';
					} else {
						var sFmt = [];
						var i = 1;

						var boxRenderRect = missionInfoPanel.getRenderRectangle();

						for (score in scores) {
							sFmt.push('${i}. 
								<offset value="15">${StringTools.htmlEscape(score.name.substr(0, 30))}</offset>
								<offset value="${boxRenderRect.extent.x - 198 - 120}">${Util.formatTime(score.score)}</offset>
								<offset value="${boxRenderRect.extent.x - 198 - 100 + 64}"><img src="${platformToString(score.platform)}"/></offset>
								${score.rewind == 1 ? '<offset value="${boxRenderRect.extent.x - 198 - 16}"><img src="rewind"/></offset> ' : ""}');
							i++;
						}
						text += sFmt.join('<br/>');
					}

					missionInfoLeft.text.text = text;
					missionInfoRight.text.text = '';
				});
				lbRequest = req;

				var kindList = ["All Scores", "Rewind Only", "No Rewind"];
				missionModesInfo.text.text = '<font face="bold21">Showing: </font><font color="#3535CC"><a href="changeMode">${kindList[cast(scoreView, Int)]}</a></font> | <font color="#3535CC"><a href="watchTopReplay">Watch Top Replay</a></font><br/>';
				missionModesInfo.text.onHyperlink = function(url:String) {
					if (url == "changeMode") {
						scoreView = cast((cast(scoreView, Int) + 1) % 3);
						setSelectedFunc(currentSelectionStatic); // re-render the info box with leaderboard data
					} else if (url == "watchTopReplay") {
						// watch top replay

						var currentMission = currentList[currentSelection];
						var lbPath = currentMission.path;
						if (currentMission.isClaMission)
							lbPath = 'custom/${currentMission.id}';
						Leaderboards.watchTopReplay(lbPath, scoreView, (b) -> {
							if (b != null) {
								var replayF = new Replay("");
								if (replayF.read(b)) {
									var repmis = replayF.mission;
									// Strip data/ from the mission name
									if (StringTools.startsWith(repmis, "data/")) {
										repmis = repmis.substr(5);
									}

									var mi = replayF.customId == 0 ? MissionList.missions.get(repmis) : Marbleland.missions.get(replayF.customId);

									// try with data/ added
									if (mi == null && replayF.customId == 0) {
										if (!StringTools.contains(repmis, "data/"))
											repmis = "data/" + repmis;
										mi = MissionList.missions.get(repmis);
									}

									if (mi.isClaMission) {
										mi.download(() -> {
											MarbleGame.instance.watchMissionReplay(mi, replayF, PlayMissionGui);
										});
									} else {
										MarbleGame.instance.watchMissionReplay(mi, replayF, PlayMissionGui);
									}
								} else {
									MarbleGame.canvas.pushDialog(new MessageBoxOkDlg("Could not load replay for this level."));
								}
							} else {
								MarbleGame.canvas.pushDialog(new MessageBoxOkDlg("No top replay found for this level."));
							}
						});
					}
				}
			}

			var boxRenderRect = missionInfoPanel.getRenderRectangle();

			missionInfoLeft.extent.x = boxRenderRect.extent.x - 198;
			missionInfoRight.extent.x = boxRenderRect.extent.x - 198;
			missionModesInfo.extent.x = boxRenderRect.extent.x - 198;

			var descTextHeight = missionInfoLeft.text.textHeight;
			var modeTextHeight = missionModesInfo.text.textHeight;

			var panelSize = 238.0;
			if (descTextHeight > 128)
				panelSize += descTextHeight - 128;
			if (modeTextHeight > 40)
				panelSize += modeTextHeight - 40;

			infoBox.extent.y = panelSize;
			infoBox.position.y = 230 + (238 - panelSize);
			missionModesInfo.position.y = 142 + (panelSize - 238) - (modeTextHeight - 40);

			// now for the scores

			var scoreData:Array<Score> = Settings.getScores(mission.path);
			var scoreCount = Math.min(scoreData.length, 5);
			while (scoreData.length < 5) {
				scoreData.push({name: "Matan W.", time: isScoreMode ? 0 : 5999.999, type: isScoreMode ? 1 : 0});
			}

			var scoreLeft = '';
			var scoreRight = '';

			scoreLeft += '<p align="center"><font color="#3535CC"><a href="showGlobalScores">${showLeaderboards ? "Hide" : "Show"} Global Scores</a></font></p>';
			scoreRight += '<p align="center"><font opacity="0">Show Global Scores</font></p>';

			for (i in 0...5) {
				scoreLeft += '<p align="left">${scoreData[i].name}</p>';

				var scoreColor = Util.getScoreColor(scoreData[i].time, scoreData[i].type == 1 ? Score : Time, mission);
				var formatted = scoreData[i].type == 0 ? Util.formatTime(scoreData[i].time) : Util.formatScore(Std.int(scoreData[i].time));

				var scoreExtra = scoreColor != "#000000" ? ' shadow="1,1" shadowcolor="#0000007F"' : "";
				scoreRight += '<p align="right"><font color="${scoreColor}" ${scoreExtra}>${formatted}</font></p>';
			}

			missionScoresInfoLeft.text.text = scoreLeft;
			missionScoresInfoRight.text.text = scoreRight;

			missionScoresInfoLeft.text.onHyperlink = function(url:String) {
				if (url == "showGlobalScores") {
					// Handle the hyperlink click
					showLeaderboards = !showLeaderboards;
					setSelectedFunc(currentSelectionStatic); // re-render the info box with leaderboard data
				}
			};

			infoBox.render(MarbleGame.canvas.scene2d, @:privateAccess this._flow);

			#if js
			switch (previewTimeoutHandle) {
				case None:
					previewTimeoutHandle = Some(js.Browser.window.setTimeout(() -> {
						var prevpath = mission.getBigPreviewImage(prevImg -> {
							levelPreview.bmp.tile = prevImg;
						});
						if (prevpath != levelPreview.bmp.tile.getTexture().name) {
							levelPreview.bmp.tile = tmpprevtile;
						}
					}, 75));
				case Some(previewTimeoutHandle_id):
					js.Browser.window.clearTimeout(previewTimeoutHandle_id);
					previewTimeoutHandle = Some(js.Browser.window.setTimeout(() -> {
						var prevpath = mission.getBigPreviewImage(prevImg -> {
							levelPreview.bmp.tile = prevImg;
						});
						if (prevpath != levelPreview.bmp.tile.getTexture().name) {
							levelPreview.bmp.tile = tmpprevtile;
						}
					}, 75));
			}
			#end
			#if hl
			var pTok = previewToken++;
			var prevpath = mission.getBigPreviewImage(prevImg -> {
				if (pTok + 1 != previewToken)
					return;
				levelPreview.bmp.tile = prevImg;
			}); // Shit be sync
			if (prevpath != levelPreview.bmp.tile.getTexture().name) {
				levelPreview.bmp.tile = tmpprevtile;
			}
			#end
		}

		setDifficulty(currentGameStatic, currentCategoryStatic);
	}

	public override function render(scene2d:Scene, ?parent:h2d.Flow) {
		super.render(scene2d, parent);
		setSelectedFunc(currentSelectionStatic);
	}

	public override function update(dt:Float, mouseState:MouseState) {
		super.update(dt, mouseState);
	}

	public override function onResize(width:Int, height:Int) {
		super.onResize(width, height);

		rebuildMissionList(0);
		setSelectedFunc(currentSelection); // resize these
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
