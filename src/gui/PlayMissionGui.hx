package gui;

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

	var setSelectedFunc:Int->Void;
	var setScoreHover:Bool->Void;
	var setCategoryFunc:(String, String, ?String, ?Bool) -> Void;
	var buttonHoldFunc:(dt:Float, mouseState:MouseState) -> Void;

	var pmScoreButton:GuiButton;
	var scoreButtonHover:Bool = false;
	var scoreButtonDirty:Bool = true;
	var scoreShowing:Bool = false;

	var buttonCooldown:Float = 0.5;
	var maxButtonCooldown:Float = 0.5;

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
			currentSelectionStatic = MissionList.missionList["platinum"]["beginner"].length - 1;
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

		// var wnd = new GuiTransparencyCtrl("data/ui/transparency/pqwindow");
		// wnd.horizSizing = Center;
		// wnd.vertSizing = Center;
		// wnd.position = new Vector(226, 209);
		// wnd.extent = new Vector(348, 182);
		// this.addChild(wnd);

		var whatneyFontData = ResourceLoader.getFileEntry("data/font/whatney.fnt");
		var whatneyFontB = new BitmapFont(whatneyFontData.entry);
		@:privateAccess whatneyFontB.loader = ResourceLoader.loader;
		var whatneyFont = whatneyFontB.toSdfFont(cast 21 * Settings.uiScale, MultiChannel);
		var whatneyFont21 = whatneyFontB.toSdfFont(cast 18 * Settings.uiScale, MultiChannel);

		var squishneyFontData = ResourceLoader.getFileEntry("data/font/squishney.fnt");
		var squishneyFontB = new BitmapFont(squishneyFontData.entry);
		@:privateAccess squishneyFontB.loader = ResourceLoader.loader;
		var squishneyFont = squishneyFontB.toSdfFont(cast 28 * Settings.uiScale, MultiChannel);
		var squishney48 = squishneyFontB.toSdfFont(cast 44 * Settings.uiScale, MultiChannel);
		var squishney36 = squishneyFontB.toSdfFont(cast 32 * Settings.uiScale, MultiChannel);
		var squishney26 = squishneyFontB.toSdfFont(cast 21 * Settings.uiScale, MultiChannel);

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
			MarbleGame.canvas.pushDialog(new SearchGui(currentGame, currentCategory == "custom"));
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

		var scoreBox = new GuiMLText(markerFelt16, mlFontLoader);
		scoreBox.text.loadImage = imgLoader;
		scoreBox.text.onHyperlink = (url) -> {
			if (url == "watch") {
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
		scoreBox.text.textColor = 0xF4E4CE;
		scoreBox.text.dropShadow = {
			dx: 1 * Settings.uiScale,
			dy: 1 * Settings.uiScale,
			alpha: 0.5,
			color: 0
		};
		scoreBox.text.lineSpacing = -1;
		scoreBox.horizSizing = Width;
		scoreBox.position = new Vector(0, 0);
		scoreBox.extent = new Vector(407, 1184);
		var scores = [
			'1. <offset value="15">Nardo Polo</offset><offset value="215">99:59:999</offset><offset value="279"><img src="unknown"/></offset>',
			'2. <offset value="15">Nardo Polo</offset><offset value="215">99:59:999</offset><offset value="279"><img src="pc"/></offset>',
			'3. <offset value="15">Nardo Polo</offset><offset value="215">99:59:999</offset><offset value="279"><img src="mac"/></offset>',
			'4. <offset value="15">Nardo Polo</offset><offset value="215">99:59:999</offset><offset value="279"><img src="web"/></offset>',
			'5. <offset value="15">Nardo Polo</offset><offset value="215">99:59:999</offset><offset value="279"><img src="android"/></offset>',
		];
		scoreBox.text.text = '<p align="center">Loading scores</p>'; // scores.join('<br/>');
		scoreBox.text.imageVerticalAlign = Top;
		scoreScroll.addChild(scoreBox);

		var lbImgs = loadButtonImages("data/ui/play/lb");
		var infoImgs = loadButtonImages("data/ui/play/info");

		var pmLBToggle = new GuiButton(lbImgs);
		pmLBToggle.position = new Vector(118, 98);
		pmLBToggle.extent = new Vector(43, 43);
		pmLBToggle.pressedAction = (e) -> {
			showLBs = !showLBs;
			if (!showLBs) {
				@:privateAccess pmLBToggle.anim.frames = lbImgs;
			} else {
				@:privateAccess pmLBToggle.anim.frames = infoImgs;
			}

			// pmScoreButton.disabled = showLBs;
			// pmScoreText.text.visible = !showLBs;

			setSelectedFunc(currentSelection);
			if (showLBs) {
				pmBox.addChild(scoreScroll);
			} else {
				pmBox.removeChild(scoreScroll);
			}
			pmBox.render(MarbleGame.canvas.scene2d);
			// setCategoryFunc(currentGame, currentCategoryStatic, currentSortType == 1 ? "date" : "alpha");
			// MarbleGame.canvas.pushDialog(new SearchGui(currentGame, currentCategory == "custom"));
		}

		if (!showLBs) {
			@:privateAccess pmLBToggle.anim.frames = lbImgs;
		} else {
			@:privateAccess pmLBToggle.anim.frames = infoImgs;
		}

		pmBox.addChild(pmLBToggle);
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
		infoBox.extent = new Vector(330, 213);
		this.addChild(infoBox);

		var missionInfoPanel = new GuiControl();
		missionInfoPanel.horizSizing = Width;
		missionInfoPanel.vertSizing = Height;
		missionInfoPanel.position = new Vector(19, 57);
		missionInfoPanel.extent = new Vector(277, 165);
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

		var missionScoresInfo = new GuiMLText(whatneyFont21, null);
		missionScoresInfo.horizSizing = Left;
		missionScoresInfo.position = new Vector(180, 0);
		missionScoresInfo.extent = new Vector(186, 162);
		missionScoresInfo.text.textColor = 0;
		missionScoresInfo.text.text = "Score1";
		missionInfoPanel.addChild(missionScoresInfo);

		var missionInfo = new GuiMLText(whatneyFont21, null);
		missionInfo.horizSizing = Width;
		missionInfo.position = new Vector(0, 0);
		missionInfo.extent = new Vector(169, 138);
		missionInfo.text.textColor = 0;
		missionInfo.text.text = "Grab all the gems to finish!";
		missionInfoPanel.addChild(missionInfo);

		var missionModesInfo = new GuiMLText(whatneyFont21, null);
		missionModesInfo.horizSizing = Width;
		missionModesInfo.vertSizing = Top;
		missionModesInfo.position = new Vector(0, 142);
		missionModesInfo.extent = new Vector(169, 69);
		missionModesInfo.text.textColor = 0;
		missionInfo.text.text = "Gem Collection: Pick up all the gems to finish!";
		missionInfoPanel.addChild(missionModesInfo);

		var sep = new GuiImage(ResourceLoader.getResource("data/ui/play/extras/extraslinev.png", ResourceLoader.getImage, this.imageResources).toTile());
		sep.horizSizing = Left;
		sep.vertSizing = Height;
		sep.position = new Vector(174, 3);
		sep.extent = new Vector(2, 159);
		missionInfoPanel.addChild(sep);

		var setDifficulty:String->Void = null;

		var difficultyPopup = new GuiControl();
		difficultyPopup.horizSizing = Width;
		difficultyPopup.vertSizing = Height;
		difficultyPopup.position = new Vector(0, 0);
		difficultyPopup.extent = new Vector(800, 600);

		var difficultyList = new GuiImage(ResourceLoader.getResource("data/ui/transparency/pc_trans/0.png", ResourceLoader.getImage, this.imageResources)
			.toTile());
		difficultyList.position = new Vector(197, 50);
		difficultyList.extent = new Vector(158, 210);
		difficultyPopup.addChild(difficultyList);

		for (i in 0...6) {
			var difficultyBtn = new GuiButtonText(loadButtonImages("data/ui/play/difficulty"), squishney26);
			difficultyBtn.ratio = 0.27;
			difficultyBtn.setExtent(new Vector(156, 35));
			difficultyBtn.position = new Vector(1, 35 * i);
			difficultyBtn.txtCtrl.text.textColor = 0;
			difficultyBtn.txtCtrl.text.text = ["Tutorial", "Beginner", "Intermediate", "Advanced", "Expert", "Bonus"][i];
			var diff = ["tutorial", "beginner", "intermediate", "advanced", "expert", "bonus"][i];
			difficultyBtn.pressedAction = (e) -> {
				setDifficulty(diff);
				MarbleGame.canvas.popDialog(difficultyPopup, false);
			}
			difficultyList.addChild(difficultyBtn);
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
		gameList.addChild(pqBtn);

		var customBtn = new GuiButtonText(loadButtonImages("data/ui/play/difficulty"), squishney26);
		customBtn.ratio = 0.27;
		customBtn.setExtent(new Vector(156, 35));
		customBtn.position = new Vector(1, 35);
		customBtn.txtCtrl.text.textColor = 0;
		customBtn.txtCtrl.text.text = "Custom";
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

		setDifficulty = (diffName) -> {
			difficultySelector.txtCtrl.text.text = diffName.charAt(0).toUpperCase() + diffName.substr(1);
			currentCategory = diffName;
			currentCategoryStatic = diffName;
		};

		setDifficulty(currentCategoryStatic);
	}

	public override function render(scene2d:Scene) {
		super.render(scene2d);
	}

	public override function update(dt:Float, mouseState:MouseState) {
		super.update(dt, mouseState);
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
