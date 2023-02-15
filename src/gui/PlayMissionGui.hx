package gui;

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

class PlayMissionGui extends GuiImage {
	static var currentSelectionStatic:Int = -1;
	static var currentCategoryStatic:String = "beginner";
	static var currentGameStatic:String = "platinum";

	var currentGame:String = "platinum";
	var currentSelection:Int = 0;
	var currentCategory:String = "beginner";
	var currentList:Array<Mission>;

	var setSelectedFunc:Int->Void;
	var setScoreHover:Bool->Void;
	var setCategoryFunc:(String, String, ?Bool) -> Void;
	var buttonHoldFunc:(dt:Float, mouseState:MouseState) -> Void;

	var pmScoreButton:GuiButton;
	var scoreButtonHover:Bool = false;
	var scoreButtonDirty:Bool = true;
	var scoreShowing:Bool = false;

	var buttonCooldown:Float = 0.5;
	var maxButtonCooldown:Float = 0.5;

	#if js
	var previewTimeoutHandle:Option<Int> = None;
	#end
	#if hl
	var previewToken:Int = 0;
	#end

	public function new() {
		MissionList.buildMissionList();

		// if (currentSelectionStatic == -1)
		// 	currentSelectionStatic = cast Math.min(MissionList.missionList["platinum"]["beginner"].length - 1,
		// 		Settings.progression[["beginner", "intermediate", "advanced", "expert"].indexOf(currentCategory)]);
		if (currentSelectionStatic == -1) {
			currentSelectionStatic = MissionList.missionList["platinum"]["beginner"].length - 1;
		}

		// currentSelection = PlayMissionGui.currentSelectionStatic;
		currentCategory = PlayMissionGui.currentCategoryStatic;
		currentGame = PlayMissionGui.currentGameStatic;

		MarbleGame.instance.toRecord = false;

		function chooseBg() {
			if (currentGame == "gold")
				return ResourceLoader.getImage('data/ui/backgrounds/gold/${cast (Math.floor(Util.lerp(1, 12, Math.random())), Int)}.jpg');
			if (currentGame == "platinum")
				return ResourceLoader.getImage('data/ui/backgrounds/platinum/${cast (Math.floor(Util.lerp(1, 28, Math.random())), Int)}.jpg');
			if (currentGame == "ultra")
				return ResourceLoader.getImage('data/ui/backgrounds/ultra/${cast (Math.floor(Util.lerp(1, 9, Math.random())), Int)}.jpg');
			return null;
		}

		var img = chooseBg();
		super(img.resource.toTile());

		this.horizSizing = Width;
		this.vertSizing = Height;
		this.extent = new Vector(640, 480);
		this.position = new Vector(0, 0);

		var container = new GuiControl();
		container.horizSizing = Width;
		container.vertSizing = Height;
		container.extent = new Vector(640, 480);
		container.position = new Vector(0, 0);
		this.addChild(container);

		function loadButtonImages(path:String) {
			var normal = ResourceLoader.getResource('${path}_n.png', ResourceLoader.getImage, this.imageResources).toTile();
			var hover = ResourceLoader.getResource('${path}_h.png', ResourceLoader.getImage, this.imageResources).toTile();
			var pressed = ResourceLoader.getResource('${path}_d.png', ResourceLoader.getImage, this.imageResources).toTile();
			var disabled = ResourceLoader.getResource('${path}_i.png', ResourceLoader.getImage, this.imageResources).toTile();
			return [normal, hover, pressed, disabled];
		}

		var domcasual24fontdata = ResourceLoader.getFileEntry("data/font/DomCasualD.fnt");
		var domcasual24b = new BitmapFont(domcasual24fontdata.entry);
		@:privateAccess domcasual24b.loader = ResourceLoader.loader;
		var domcasual24 = domcasual24b.toSdfFont(cast 20 * Settings.uiScale, MultiChannel);

		var domcasual32 = domcasual24b.toSdfFont(cast 26 * Settings.uiScale, MultiChannel);

		var arial14fontdata = ResourceLoader.getFileEntry("data/font/arial.fnt");
		var arial14b = new BitmapFont(arial14fontdata.entry);
		@:privateAccess arial14b.loader = ResourceLoader.loader;
		var arial14 = arial14b.toSdfFont(cast 12 * Settings.uiScale, MultiChannel);

		var arialb14fontdata = ResourceLoader.getFileEntry("data/font/Arial Bold.fnt");
		var arialb14b = new BitmapFont(arialb14fontdata.entry);
		@:privateAccess arialb14b.loader = ResourceLoader.loader;
		var arialBold14 = arialb14b.toSdfFont(cast 12 * Settings.uiScale, MultiChannel);

		var markerFelt32fontdata = ResourceLoader.getFileEntry("data/font/MarkerFelt.fnt");
		var markerFelt32b = new BitmapFont(markerFelt32fontdata.entry);
		@:privateAccess markerFelt32b.loader = ResourceLoader.loader;
		var markerFelt32 = markerFelt32b.toSdfFont(cast 26 * Settings.uiScale, MultiChannel);
		var markerFelt24 = markerFelt32b.toSdfFont(cast 20 * Settings.uiScale, MultiChannel);
		var markerFelt20 = markerFelt32b.toSdfFont(cast 18.5 * Settings.uiScale, MultiChannel);
		var markerFelt18 = markerFelt32b.toSdfFont(cast 17 * Settings.uiScale, MultiChannel);
		var markerFelt26 = markerFelt32b.toSdfFont(cast 22 * Settings.uiScale, MultiChannel);

		function mlFontLoader(text:String) {
			switch (text) {
				case "DomCasual24":
					return domcasual24;
				case "Arial14":
					return arial14;
				case "ArialBold14":
					return arialBold14;
				case "MarkerFelt32":
					return markerFelt32;
				case "MarkerFelt24":
					return markerFelt24;
				case "MarkerFelt18":
					return markerFelt18;
				case "MarkerFelt20":
					return markerFelt20;
				case "MarkerFelt26":
					return markerFelt26;
				default:
					return null;
			}
		}

		var pmBox = new GuiImage(ResourceLoader.getResource('data/ui/play/window.png', ResourceLoader.getImage, this.imageResources).toTile());
		pmBox.horizSizing = Center;
		pmBox.vertSizing = Center;
		pmBox.position = new Vector(-80. - 10);
		pmBox.extent = new Vector(800, 500);
		container.addChild(pmBox);

		var pmDifficultyPopup:GuiControl = null;

		var pmDifficulty = new GuiButton(loadButtonImages("data/ui/play/difficulty_beginner"));
		pmDifficulty.position = new Vector(168, 98);
		pmDifficulty.extent = new Vector(203, 43);
		pmDifficulty.pressedAction = (e) -> {
			MarbleGame.canvas.pushDialog(pmDifficultyPopup);
		};
		pmBox.addChild(pmDifficulty);

		var pmDifficultyMarble = new GuiImage(ResourceLoader.getResource('data/ui/play/marble_platinum.png', ResourceLoader.getImage, this.imageResources)
			.toTile());
		pmDifficultyMarble.position = new Vector(151, 11);
		pmDifficultyMarble.extent = new Vector(21, 22);
		pmDifficulty.addChild(pmDifficultyMarble);

		var pmMenuButton = new GuiButton(loadButtonImages("data/ui/play/menu"));
		pmMenuButton.position = new Vector(119, 325);
		pmMenuButton.extent = new Vector(92, 43);
		pmMenuButton.accelerator = hxd.Key.ESCAPE;
		pmMenuButton.gamepadAccelerator = ["B"];
		pmMenuButton.pressedAction = (sender) -> {
			cast(this.parent, Canvas).setContent(new MainMenuGui());
		};
		pmBox.addChild(pmMenuButton);

		var pmMorePop:GuiControl = null;

		var pmMore = new GuiButton(loadButtonImages("data/ui/play/more"));
		pmMore.position = new Vector(217, 325);
		pmMore.extent = new Vector(92, 43);
		pmMore.pressedAction = (e) -> {
			MarbleGame.canvas.pushDialog(pmMorePop);
		};
		pmBox.addChild(pmMore);

		var pmSearch = new GuiButton(loadButtonImages("data/ui/play/search"));
		pmSearch.position = new Vector(315, 325);
		pmSearch.extent = new Vector(43, 43);
		pmSearch.pressedAction = (e) -> {
			MarbleGame.canvas.pushDialog(new SearchGui(currentGame, currentCategory == "custom"));
		}
		pmBox.addChild(pmSearch);

		var pmPrev = new GuiButton(loadButtonImages("data/ui/play/prev"));
		pmPrev.position = new Vector(436, 325);
		pmPrev.extent = new Vector(72, 43);
		pmPrev.gamepadAccelerator = ["dpadLeft"];
		pmPrev.pressedAction = (sender) -> {
			setSelectedFunc(currentSelection - 1);
		}
		pmBox.addChild(pmPrev);

		var pmPlay = new GuiButton(loadButtonImages("data/ui/play/play"));
		pmPlay.position = new Vector(510, 325);
		pmPlay.extent = new Vector(92, 43);
		pmPlay.gamepadAccelerator = ["A"];
		pmPlay.pressedAction = (sender) -> {
			// Wacky hacks
			currentList[currentSelection].index = currentSelection;
			currentList[currentSelection].difficultyIndex = ["beginner", "intermediate", "advanced", "expert"].indexOf(currentCategory);
			currentSelectionStatic = currentSelection;
			currentCategoryStatic = currentCategory;
			cast(this.parent, Canvas).marbleGame.playMission(currentList[currentSelection]);
		}
		pmBox.addChild(pmPlay);

		var pmNext = new GuiButton(loadButtonImages("data/ui/play/next"));
		pmNext.position = new Vector(604, 325);
		pmNext.extent = new Vector(72, 43);
		pmNext.gamepadAccelerator = ["dpadRight"];
		pmNext.pressedAction = (sender) -> {
			setSelectedFunc(currentSelection + 1);
		}
		pmBox.addChild(pmNext);

		var temprev = new BitmapData(1, 1);
		temprev.setPixel(0, 0, 0);
		var tmpprevtile = Tile.fromBitmap(temprev);

		var pmPreview = new GuiImage(tmpprevtile);
		pmPreview.position = new Vector(429, 96);
		pmPreview.extent = new Vector(256, 194);
		var filt = new ColorMatrix(Matrix.I());
		pmPreview.bmp.filter = filt;
		pmBox.addChild(pmPreview);

		var pmPreviewFrame = new GuiImage(ResourceLoader.getResource('data/ui/play/levelframe.png', ResourceLoader.getImage, this.imageResources).toTile());
		pmPreviewFrame.position = new Vector(0, 0);
		pmPreviewFrame.extent = new Vector(256, 194);
		pmPreview.addChild(pmPreviewFrame);

		var noQualText = new GuiText(markerFelt32);
		noQualText.position = new Vector(0, 78);
		noQualText.extent = new Vector(256, 14);
		noQualText.text.textColor = 0xCCCCCC;
		noQualText.justify = Center;
		noQualText.text.text = "Not Qualified!";
		pmPreview.addChild(noQualText);

		var pmEgg = new GuiImage(ResourceLoader.getResource('data/ui/play/eggfound.png', ResourceLoader.getImage, this.imageResources).toTile());
		pmEgg.position = new Vector(228, 157);
		pmEgg.extent = new Vector(14, 21);
		pmPreview.addChild(pmEgg);

		var pmDescription = new GuiMLText(markerFelt18, mlFontLoader);
		pmDescription.position = new Vector(110, 145);
		pmDescription.extent = new Vector(320, 146);
		pmBox.addChild(pmDescription);

		var pmDescriptionRight = new GuiMLText(markerFelt18, mlFontLoader);
		pmDescriptionRight.position = new Vector(110, 145);
		pmDescriptionRight.extent = new Vector(320, 146);
		pmBox.addChild(pmDescriptionRight);

		var pmParText = new GuiMLText(markerFelt18, mlFontLoader);
		pmParText.position = new Vector(110, 292);
		pmParText.extent = new Vector(320, 14);
		pmBox.addChild(pmParText);

		var pmParTextRight = new GuiMLText(markerFelt18, mlFontLoader);
		pmParTextRight.position = new Vector(110, 292);
		pmParTextRight.extent = new Vector(320, 14);
		pmBox.addChild(pmParTextRight);

		var pmScoreText = new GuiMLText(markerFelt18, mlFontLoader);
		pmScoreText.position = new Vector(441, 292);
		pmScoreText.extent = new Vector(235, 14);
		pmBox.addChild(pmScoreText);

		pmScoreButton = new GuiButton([tmpprevtile, tmpprevtile, tmpprevtile]);
		pmScoreButton.position = new Vector(438, 282);
		pmScoreButton.extent = new Vector(240, 39);
		pmScoreButton.pressedAction = (e) -> {
			scoreShowing = !scoreShowing;
			setSelectedFunc(currentSelection);
		};
		pmBox.addChild(pmScoreButton);

		// Difficulty popup
		pmDifficultyPopup = new GuiControl();
		pmDifficultyPopup.horizSizing = Width;
		pmDifficultyPopup.vertSizing = Height;
		pmDifficultyPopup.position = new Vector(0, 0);
		pmDifficultyPopup.extent = new Vector(640, 480);

		var pmDifficultyPopupInner = new GuiImage(tmpprevtile);
		pmDifficultyPopupInner.position = new Vector(-80, -10);
		pmDifficultyPopupInner.extent = new Vector(800, 500);
		pmDifficultyPopupInner.horizSizing = Center;
		pmDifficultyPopupInner.vertSizing = Center;
		pmDifficultyPopup.addChild(pmDifficultyPopupInner);
		pmDifficultyPopupInner.pressedAction = (e) -> {
			MarbleGame.canvas.popDialog(pmDifficultyPopup, false);
		}

		var pmDifficultyCtrl = new GuiImage(tmpprevtile);
		pmDifficultyCtrl.position = new Vector(-19, 116);
		pmDifficultyCtrl.extent = new Vector(583, 252);
		pmDifficultyPopupInner.addChild(pmDifficultyCtrl);

		var pmDifficultyBgCtrl = new GuiControl();
		pmDifficultyBgCtrl.position = new Vector(0, 0);
		pmDifficultyBgCtrl.extent = new Vector(583, 252);
		pmDifficultyBgCtrl.horizSizing = Width;
		pmDifficultyBgCtrl.vertSizing = Height;
		pmDifficultyCtrl.addChild(pmDifficultyBgCtrl);

		var pmDifficultyBgTL = new GuiImage(ResourceLoader.getResource('data/ui/menu/brown/tl.png', ResourceLoader.getImage, this.imageResources).toTile());
		pmDifficultyBgTL.position = new Vector(0, 0);
		pmDifficultyBgTL.extent = new Vector(49, 45);
		pmDifficultyBgTL.horizSizing = Right;
		pmDifficultyBgTL.vertSizing = Bottom;
		pmDifficultyBgCtrl.addChild(pmDifficultyBgTL);

		var pmDifficultyBgTR = new GuiImage(ResourceLoader.getResource('data/ui/menu/brown/tr.png', ResourceLoader.getImage, this.imageResources).toTile());
		pmDifficultyBgTR.position = new Vector(534, 0);
		pmDifficultyBgTR.extent = new Vector(49, 45);
		pmDifficultyBgTR.horizSizing = Left;
		pmDifficultyBgTR.vertSizing = Bottom;
		pmDifficultyBgCtrl.addChild(pmDifficultyBgTR);

		var pmDifficultyBgBL = new GuiImage(ResourceLoader.getResource('data/ui/menu/brown/bl.png', ResourceLoader.getImage, this.imageResources).toTile());
		pmDifficultyBgBL.position = new Vector(0, 190);
		pmDifficultyBgBL.extent = new Vector(49, 62);
		pmDifficultyBgBL.horizSizing = Right;
		pmDifficultyBgBL.vertSizing = Top;
		pmDifficultyBgCtrl.addChild(pmDifficultyBgBL);

		var pmDifficultyBgBR = new GuiImage(ResourceLoader.getResource('data/ui/menu/brown/br.png', ResourceLoader.getImage, this.imageResources).toTile());
		pmDifficultyBgBR.position = new Vector(534, 190);
		pmDifficultyBgBR.extent = new Vector(49, 62);
		pmDifficultyBgBR.horizSizing = Left;
		pmDifficultyBgBR.vertSizing = Top;
		pmDifficultyBgCtrl.addChild(pmDifficultyBgBR);

		var pmDifficultyBgL = new GuiImage(ResourceLoader.getResource('data/ui/menu/brown/l.png', ResourceLoader.getImage, this.imageResources).toTile());
		pmDifficultyBgL.position = new Vector(0, 45);
		pmDifficultyBgL.extent = new Vector(49, 145);
		pmDifficultyBgL.horizSizing = Right;
		pmDifficultyBgL.vertSizing = Height;
		pmDifficultyBgCtrl.addChild(pmDifficultyBgL);

		var pmDifficultyBgR = new GuiImage(ResourceLoader.getResource('data/ui/menu/brown/r.png', ResourceLoader.getImage, this.imageResources).toTile());
		pmDifficultyBgR.position = new Vector(534, 45);
		pmDifficultyBgR.extent = new Vector(49, 145);
		pmDifficultyBgR.horizSizing = Left;
		pmDifficultyBgR.vertSizing = Height;
		pmDifficultyBgCtrl.addChild(pmDifficultyBgR);

		var pmDifficultyBgB = new GuiImage(ResourceLoader.getResource('data/ui/menu/brown/b.png', ResourceLoader.getImage, this.imageResources).toTile());
		pmDifficultyBgB.position = new Vector(49, 190);
		pmDifficultyBgB.extent = new Vector(485, 62);
		pmDifficultyBgB.horizSizing = Width;
		pmDifficultyBgB.vertSizing = Top;
		pmDifficultyBgCtrl.addChild(pmDifficultyBgB);

		var pmDifficultyBgC = new GuiImage(ResourceLoader.getResource('data/ui/menu/brown/c.png', ResourceLoader.getImage, this.imageResources).toTile());
		pmDifficultyBgC.position = new Vector(49, 45);
		pmDifficultyBgC.extent = new Vector(485, 145);
		pmDifficultyBgC.horizSizing = Width;
		pmDifficultyBgC.vertSizing = Height;
		pmDifficultyBgCtrl.addChild(pmDifficultyBgC);

		var pmDifficultyTopC = new GuiControl();
		pmDifficultyTopC.horizSizing = Width;
		pmDifficultyTopC.vertSizing = Bottom;
		pmDifficultyTopC.position = new Vector(49, 0);
		pmDifficultyTopC.extent = new Vector(485, 45);
		pmDifficultyBgCtrl.addChild(pmDifficultyTopC);

		var pmDifficultyTopCT = new GuiImage(ResourceLoader.getResource('data/ui/menu/brown/t.png', ResourceLoader.getImage, this.imageResources).toTile());
		pmDifficultyTopCT.position = new Vector(0, 0);
		pmDifficultyTopCT.extent = new Vector(231, 45);
		pmDifficultyTopCT.horizSizing = Width;
		pmDifficultyTopCT.vertSizing = Bottom;
		pmDifficultyTopC.addChild(pmDifficultyTopCT);

		var pmDifficultyTopCTab = new GuiImage(ResourceLoader.getResource('data/ui/menu/brown/tabt.png', ResourceLoader.getImage, this.imageResources)
			.toTile());
		pmDifficultyTopCTab.position = new Vector(231, 0);
		pmDifficultyTopCTab.extent = new Vector(25, 45);
		pmDifficultyTopCTab.horizSizing = Left;
		pmDifficultyTopCTab.vertSizing = Bottom;
		pmDifficultyTopC.addChild(pmDifficultyTopCTab);

		var pmDifficultyTopC2 = new GuiControl();
		pmDifficultyTopC2.horizSizing = Left;
		pmDifficultyTopC2.vertSizing = Bottom;
		pmDifficultyTopC2.position = new Vector(293, 0);
		pmDifficultyTopC2.extent = new Vector(243, 45);
		pmDifficultyBgCtrl.addChild(pmDifficultyTopC2);

		var pmDifficultyTopCT2 = new GuiImage(ResourceLoader.getResource('data/ui/menu/brown/t.png', ResourceLoader.getImage, this.imageResources).toTile());
		pmDifficultyTopCT2.position = new Vector(13, 0);
		pmDifficultyTopCT2.extent = new Vector(230, 45);
		pmDifficultyTopCT2.horizSizing = Width;
		pmDifficultyTopCT2.vertSizing = Bottom;
		pmDifficultyTopC2.addChild(pmDifficultyTopCT2);

		var pmDifficultyTopCTab2 = new GuiImage(ResourceLoader.getResource('data/ui/menu/brown/tabt.png', ResourceLoader.getImage, this.imageResources)
			.toTile());
		pmDifficultyTopCTab2.position = new Vector(-12, 0);
		pmDifficultyTopCTab2.extent = new Vector(25, 45);
		pmDifficultyTopCTab2.horizSizing = Right;
		pmDifficultyTopCTab2.vertSizing = Bottom;
		pmDifficultyTopC2.addChild(pmDifficultyTopCTab2);

		var pmDifficultyUltraAdvanced = new GuiButtonText(loadButtonImages("data/ui/play/difficulty_highlight-120"), markerFelt24);
		pmDifficultyUltraAdvanced.position = new Vector(277, 134);
		pmDifficultyUltraAdvanced.ratio = -1 / 16;
		pmDifficultyUltraAdvanced.setExtent(new Vector(120, 31));
		pmDifficultyUltraAdvanced.txtCtrl.text.text = " Advanced";
		pmDifficultyUltraAdvanced.pressedAction = (e) -> {
			currentList = MissionList.missionList["ultra"]["advanced"];
			currentCategory = "advanced";
			setCategoryFunc("ultra", "advanced");
		}
		pmDifficultyCtrl.addChild(pmDifficultyUltraAdvanced);

		var pmDifficultyUltraBeginner = new GuiButtonText(loadButtonImages("data/ui/play/difficulty_highlight-120"), markerFelt24);
		pmDifficultyUltraBeginner.position = new Vector(277, 75);
		pmDifficultyUltraBeginner.ratio = -1 / 16;
		pmDifficultyUltraBeginner.setExtent(new Vector(120, 31));
		pmDifficultyUltraBeginner.txtCtrl.text.text = " Beginner";
		pmDifficultyUltraBeginner.pressedAction = (e) -> {
			currentList = MissionList.missionList["ultra"]["beginner"];
			currentCategory = "beginner";
			setCategoryFunc("ultra", "beginner");
		}
		pmDifficultyCtrl.addChild(pmDifficultyUltraBeginner);

		var pmDifficultyUltraIntermediate = new GuiButtonText(loadButtonImages("data/ui/play/difficulty_highlight-120"), markerFelt24);
		pmDifficultyUltraIntermediate.position = new Vector(277, 104);
		pmDifficultyUltraIntermediate.ratio = -1 / 16;
		pmDifficultyUltraIntermediate.setExtent(new Vector(120, 31));
		pmDifficultyUltraIntermediate.txtCtrl.text.text = " Intermediate";
		pmDifficultyUltraIntermediate.pressedAction = (e) -> {
			currentList = MissionList.missionList["ultra"]["intermediate"];
			currentCategory = "intermediate";
			setCategoryFunc("ultra", "intermediate");
		}
		pmDifficultyCtrl.addChild(pmDifficultyUltraIntermediate);

		var pmDifficultyGoldAdvanced = new GuiButtonText(loadButtonImages("data/ui/play/difficulty_highlight-120"), markerFelt24);
		pmDifficultyGoldAdvanced.position = new Vector(37, 134);
		pmDifficultyGoldAdvanced.ratio = -1 / 16;
		pmDifficultyGoldAdvanced.setExtent(new Vector(120, 31));
		pmDifficultyGoldAdvanced.txtCtrl.text.text = " Advanced";
		pmDifficultyGoldAdvanced.pressedAction = (e) -> {
			currentList = MissionList.missionList["gold"]["advanced"];
			currentCategory = "advanced";
			setCategoryFunc("gold", "advanced");
		}
		pmDifficultyCtrl.addChild(pmDifficultyGoldAdvanced);

		var pmDifficultyGoldBeginner = new GuiButtonText(loadButtonImages("data/ui/play/difficulty_highlight-120"), markerFelt24);
		pmDifficultyGoldBeginner.position = new Vector(37, 75);
		pmDifficultyGoldBeginner.ratio = -1 / 16;
		pmDifficultyGoldBeginner.setExtent(new Vector(120, 31));
		pmDifficultyGoldBeginner.txtCtrl.text.text = " Beginner";
		pmDifficultyGoldBeginner.pressedAction = (e) -> {
			currentList = MissionList.missionList["gold"]["beginner"];
			currentCategory = "beginner";
			setCategoryFunc("gold", "beginner");
		}
		pmDifficultyCtrl.addChild(pmDifficultyGoldBeginner);

		var pmDifficultyGoldIntermediate = new GuiButtonText(loadButtonImages("data/ui/play/difficulty_highlight-120"), markerFelt24);
		pmDifficultyGoldIntermediate.position = new Vector(37, 104);
		pmDifficultyGoldIntermediate.ratio = -1 / 16;
		pmDifficultyGoldIntermediate.setExtent(new Vector(120, 31));
		pmDifficultyGoldIntermediate.txtCtrl.text.text = " Intermediate";
		pmDifficultyGoldIntermediate.pressedAction = (e) -> {
			currentList = MissionList.missionList["gold"]["intermediate"];
			currentCategory = "intermediate";
			setCategoryFunc("gold", "intermediate");
		}
		pmDifficultyCtrl.addChild(pmDifficultyGoldIntermediate);

		var pmDifficultyPlatinumAdvanced = new GuiButtonText(loadButtonImages("data/ui/play/difficulty_highlight-120"), markerFelt24);
		pmDifficultyPlatinumAdvanced.position = new Vector(157, 134);
		pmDifficultyPlatinumAdvanced.ratio = -1 / 16;
		pmDifficultyPlatinumAdvanced.setExtent(new Vector(120, 31));
		pmDifficultyPlatinumAdvanced.txtCtrl.text.text = " Advanced";
		pmDifficultyPlatinumAdvanced.pressedAction = (e) -> {
			currentList = MissionList.missionList["platinum"]["advanced"];
			currentCategory = "advanced";
			setCategoryFunc("platinum", "advanced");
		}
		pmDifficultyCtrl.addChild(pmDifficultyPlatinumAdvanced);

		var pmDifficultyPlatinumBeginner = new GuiButtonText(loadButtonImages("data/ui/play/difficulty_highlight-120"), markerFelt24);
		pmDifficultyPlatinumBeginner.position = new Vector(157, 75);
		pmDifficultyPlatinumBeginner.ratio = -1 / 16;
		pmDifficultyPlatinumBeginner.setExtent(new Vector(120, 31));
		pmDifficultyPlatinumBeginner.txtCtrl.text.text = " Beginner";
		pmDifficultyPlatinumBeginner.pressedAction = (e) -> {
			currentList = MissionList.missionList["platinum"]["beginner"];
			currentCategory = "beginner";
			setCategoryFunc("platinum", "beginner");
		}
		pmDifficultyCtrl.addChild(pmDifficultyPlatinumBeginner);

		var pmDifficultyPlatinumIntermediate = new GuiButtonText(loadButtonImages("data/ui/play/difficulty_highlight-120"), markerFelt24);
		pmDifficultyPlatinumIntermediate.position = new Vector(157, 104);
		pmDifficultyPlatinumIntermediate.ratio = -1 / 16;
		pmDifficultyPlatinumIntermediate.setExtent(new Vector(120, 31));
		pmDifficultyPlatinumIntermediate.txtCtrl.text.text = " Intermediate";
		pmDifficultyPlatinumIntermediate.pressedAction = (e) -> {
			currentList = MissionList.missionList["platinum"]["intermediate"];
			currentCategory = "intermediate";
			setCategoryFunc("platinum", "intermediate");
		}
		pmDifficultyCtrl.addChild(pmDifficultyPlatinumIntermediate);

		var pmDifficultyPlatinumExpert = new GuiButtonText(loadButtonImages("data/ui/play/difficulty_highlight-120"), markerFelt24);
		pmDifficultyPlatinumExpert.position = new Vector(157, 164);
		pmDifficultyPlatinumExpert.ratio = -1 / 16;
		pmDifficultyPlatinumExpert.setExtent(new Vector(120, 31));
		pmDifficultyPlatinumExpert.txtCtrl.text.text = " Expert";
		pmDifficultyPlatinumExpert.pressedAction = (e) -> {
			currentList = MissionList.missionList["platinum"]["expert"];
			currentCategory = "expert";
			setCategoryFunc("platinum", "expert");
		}
		pmDifficultyCtrl.addChild(pmDifficultyPlatinumExpert);

		var pmGameUltra = new GuiText(markerFelt24);
		pmGameUltra.text.text = " Ultra";
		pmGameUltra.text.textColor = 0;
		pmGameUltra.position = new Vector(277, 33);
		pmGameUltra.extent = new Vector(120, 31);
		pmDifficultyCtrl.addChild(pmGameUltra);

		var pmGameUltraMarble = new GuiImage(ResourceLoader.getResource('data/ui/play/marble_ultra.png', ResourceLoader.getImage, this.imageResources)
			.toTile());
		pmGameUltraMarble.position = new Vector(95, 5);
		pmGameUltraMarble.extent = new Vector(21, 22);
		pmGameUltra.addChild(pmGameUltraMarble);

		var pmGameGold = new GuiText(markerFelt24);
		pmGameGold.text.text = " Gold Levels";
		pmGameGold.text.textColor = 0;
		pmGameGold.position = new Vector(37, 33);
		pmGameGold.extent = new Vector(120, 31);
		pmDifficultyCtrl.addChild(pmGameGold);

		var pmGameGoldMarble = new GuiImage(ResourceLoader.getResource('data/ui/play/marble_gold.png', ResourceLoader.getImage, this.imageResources).toTile());
		pmGameGoldMarble.position = new Vector(95, 5);
		pmGameGoldMarble.extent = new Vector(21, 22);
		pmGameGold.addChild(pmGameGoldMarble);

		var pmGamePlatinum = new GuiText(markerFelt24);
		pmGamePlatinum.text.text = " Platinum";
		pmGamePlatinum.text.textColor = 0;
		pmGamePlatinum.position = new Vector(157, 33);
		pmGamePlatinum.extent = new Vector(120, 31);
		pmDifficultyCtrl.addChild(pmGamePlatinum);

		var pmGamePlatinumMarble = new GuiImage(ResourceLoader.getResource('data/ui/play/marble_platinum.png', ResourceLoader.getImage, this.imageResources)
			.toTile());
		pmGamePlatinumMarble.position = new Vector(95, 5);
		pmGamePlatinumMarble.extent = new Vector(21, 22);
		pmGamePlatinum.addChild(pmGamePlatinumMarble);

		var pmGameCustom = new GuiText(markerFelt24);
		pmGameCustom.horizSizing = Left;
		pmGameCustom.text.text = " Custom Levels";
		pmGameCustom.text.textColor = 0;
		pmGameCustom.position = new Vector(395, 33);
		pmGameCustom.extent = new Vector(120, 31);
		pmDifficultyCtrl.addChild(pmGameCustom);

		var pmDifficultyGoldCustom = new GuiButtonText(loadButtonImages("data/ui/play/difficulty_highlight-120"), markerFelt24);
		pmDifficultyGoldCustom.position = new Vector(397, 75);
		pmDifficultyGoldCustom.ratio = -1 / 16;
		pmDifficultyGoldCustom.setExtent(new Vector(120, 31));
		pmDifficultyGoldCustom.txtCtrl.text.text = " Gold";
		pmDifficultyGoldCustom.pressedAction = (e) -> {
			currentList = Marbleland.goldMissions;
			currentCategory = "custom";
			setCategoryFunc("gold", "custom");
		}
		pmDifficultyCtrl.addChild(pmDifficultyGoldCustom);

		var pmDifficultyPlatinumCustom = new GuiButtonText(loadButtonImages("data/ui/play/difficulty_highlight-120"), markerFelt24);
		pmDifficultyPlatinumCustom.position = new Vector(397, 104);
		pmDifficultyPlatinumCustom.ratio = -1 / 16;
		pmDifficultyPlatinumCustom.setExtent(new Vector(120, 31));
		pmDifficultyPlatinumCustom.txtCtrl.text.text = " Platinum";
		pmDifficultyPlatinumCustom.pressedAction = (e) -> {
			currentList = Marbleland.goldMissions;
			currentCategory = "custom";
			setCategoryFunc("platinum", "custom");
		}
		pmDifficultyCtrl.addChild(pmDifficultyPlatinumCustom);

		var pmDifficultyUltraCustom = new GuiButtonText(loadButtonImages("data/ui/play/difficulty_highlight-120"), markerFelt24);
		pmDifficultyUltraCustom.position = new Vector(397, 134);
		pmDifficultyUltraCustom.ratio = -1 / 16;
		pmDifficultyUltraCustom.setExtent(new Vector(120, 31));
		pmDifficultyUltraCustom.txtCtrl.text.text = " Ultra";
		pmDifficultyUltraCustom.pressedAction = (e) -> {
			currentList = Marbleland.goldMissions;
			currentCategory = "custom";
			setCategoryFunc("ultra", "custom");
		}
		pmDifficultyCtrl.addChild(pmDifficultyUltraCustom);

		var pmDividerR = new GuiImage(ResourceLoader.getResource('data/ui/menu/brown/divider-orange-r.png', ResourceLoader.getImage, this.imageResources)
			.toTile());
		pmDividerR.horizSizing = Left;
		pmDividerR.position = new Vector(530, 62);
		pmDividerR.extent = new Vector(12, 12);
		pmDifficultyCtrl.addChild(pmDividerR);

		var pmDividerL = new GuiImage(ResourceLoader.getResource('data/ui/menu/brown/divider-orange-l.png', ResourceLoader.getImage, this.imageResources)
			.toTile());
		pmDividerL.horizSizing = Right;
		pmDividerL.position = new Vector(39, 62);
		pmDividerL.extent = new Vector(12, 12);
		pmDifficultyCtrl.addChild(pmDividerL);

		var pmDividerC = new GuiImage(ResourceLoader.getResource('data/ui/menu/brown/divider-orange-c.png', ResourceLoader.getImage, this.imageResources)
			.toTile());
		pmDividerC.horizSizing = Width;
		pmDividerC.position = new Vector(51, 62);
		pmDividerC.extent = new Vector(479, 12);
		pmDifficultyCtrl.addChild(pmDividerC);

		pmMorePop = new GuiControl();
		pmMorePop.horizSizing = Width;
		pmMorePop.vertSizing = Height;
		pmMorePop.position = new Vector(0, 0);
		pmMorePop.extent = new Vector(640, 480);

		var pmMorePopInner = new GuiImage(tmpprevtile);
		pmMorePopInner.position = new Vector(0, 0);
		pmMorePopInner.extent = new Vector(640, 480);
		pmMorePopInner.horizSizing = Center;
		pmMorePopInner.vertSizing = Center;
		pmMorePop.addChild(pmMorePopInner);
		pmMorePopInner.pressedAction = (e) -> {
			MarbleGame.canvas.popDialog(pmMorePop, false);
		}

		var pmMorePopCtrl = new GuiControl();
		pmMorePopCtrl.horizSizing = Center;
		pmMorePopCtrl.vertSizing = Center;
		pmMorePopCtrl.position = new Vector(-80, -10);
		pmMorePopCtrl.extent = new Vector(800, 500);
		pmMorePop.addChild(pmMorePopCtrl);

		var pmMorePopDlg = new GuiButton(loadButtonImages("data/ui/play/moremenu"));
		pmMorePopDlg.position = new Vector(92, 204);
		pmMorePopDlg.extent = new Vector(338, 146);
		pmMorePopCtrl.addChild(pmMorePopDlg);

		var pmMarbleSelect = new GuiButton(loadButtonImages("data/ui/play/marble"));
		pmMarbleSelect.position = new Vector(50, 46);
		pmMarbleSelect.extent = new Vector(43, 43);
		pmMarbleSelect.pressedAction = (e) -> {
			MarbleGame.canvas.pushDialog(new MarbleSelectGui());
		}
		pmMorePopDlg.addChild(pmMarbleSelect);

		var pmStats = new GuiButton(loadButtonImages("data/ui/play/statistics"));
		pmStats.position = new Vector(101, 46);
		pmStats.extent = new Vector(43, 43);
		pmStats.pressedAction = (e) -> {
			MarbleGame.canvas.pushDialog(new StatisticsGui(this.currentGame));
		}
		pmMorePopDlg.addChild(pmStats);

		var pmAchievements = new GuiButton(loadButtonImages("data/ui/play/achiev"));
		pmAchievements.position = new Vector(150, 46);
		pmAchievements.extent = new Vector(43, 43);
		pmAchievements.pressedAction = (e) -> {
			MarbleGame.canvas.pushDialog(new AchievementsGui());
		}
		pmMorePopDlg.addChild(pmAchievements);

		var pmEditorToggle = new GuiButton(loadButtonImages("data/ui/play/editor"));
		pmEditorToggle.position = new Vector(198, 46);
		pmEditorToggle.extent = new Vector(43, 43);
		pmEditorToggle.disabled = true;
		pmMorePopDlg.addChild(pmEditorToggle);

		var pmRecord = new GuiButton(loadButtonImages("data/ui/play/replay"));
		pmRecord.position = new Vector(247, 46);
		pmRecord.extent = new Vector(43, 43);
		pmRecord.pressedAction = (sender) -> {
			MarbleGame.instance.toRecord = true;
			MarbleGame.canvas.pushDialog(new MessageBoxOkDlg("The next mission you play will be recorded."));
		};
		pmMorePopDlg.addChild(pmRecord);

		// var replayPlayButton = new GuiImage(ResourceLoader.getResource("data/ui/play/playback.png", ResourceLoader.getImage, this.imageResources).toTile());
		// replayPlayButton.position = new Vector(38, 315);
		// replayPlayButton.extent = new Vector(18, 18);
		// replayPlayButton.pressedAction = (sender) -> {
		// 	hxd.File.browse((replayToLoad) -> {
		// 		replayToLoad.load((replayData) -> {
		// 			var replay = new Replay("");
		// 			if (!replay.read(replayData)) {
		// 				cast(this.parent, Canvas).pushDialog(new MessageBoxOkDlg("Cannot load replay."));
		// 				// Idk do something to notify the user here
		// 			} else {
		// 				var repmis = replay.mission;
		// 				#if js
		// 				repmis = StringTools.replace(repmis, "data/", "");
		// 				#end
		// 				var playMis = MissionList.missions.get(repmis);
		// 				if (playMis != null) {
		// 					cast(this.parent, Canvas).marbleGame.watchMissionReplay(playMis, replay);
		// 				} else {
		// 					cast(this.parent, Canvas).pushDialog(new MessageBoxOkDlg("Cannot load replay."));
		// 				}
		// 			}
		// 		});
		// 	}, {
		// 		title: "Select replay file",
		// 		fileTypes: [
		// 			{
		// 				name: "Replay (*.mbr)",
		// 				extensions: ["mbr"]
		// 			}
		// 		],
		// 	});
		// };
		// pmBox.addChild(replayPlayButton);

		buttonHoldFunc = (dt:Float, mouseState:MouseState) -> {
			var prevBox = pmPrev.getRenderRectangle();
			var nextBox = pmNext.getRenderRectangle();

			if (prevBox.inRect(mouseState.position) && mouseState.button == Key.MOUSE_LEFT) {
				if (buttonCooldown <= 0) {
					pmPrev.pressedAction(new GuiEvent(pmPrev));
					buttonCooldown = maxButtonCooldown;
					maxButtonCooldown *= 0.75;
				}
			}

			if (nextBox.inRect(mouseState.position) && mouseState.button == Key.MOUSE_LEFT) {
				if (buttonCooldown <= 0) {
					pmNext.pressedAction(new GuiEvent(pmNext));
					buttonCooldown = maxButtonCooldown;
					maxButtonCooldown *= 0.75;
				}
			}

			if (buttonCooldown > 0 && mouseState.button == Key.MOUSE_LEFT)
				buttonCooldown -= dt;

			if (mouseState.button != Key.MOUSE_LEFT) {
				maxButtonCooldown = 0.5;
				buttonCooldown = maxButtonCooldown;
			}
		}

		currentList = MissionList.missionList["platinum"]["beginner"];

		setCategoryFunc = function(game:String, category:String, ?doRender:Bool = true) {
			currentList = category == "custom" ? (switch (game) {
				case 'gold' if (Marbleland.goldMissions.length != 0): Marbleland.goldMissions;
				case 'platinum' if (Marbleland.platinumMissions.length != 0): Marbleland.platinumMissions;
				case 'ultra' if (Marbleland.ultraMissions.length != 0): Marbleland.ultraMissions;
				default: currentList;
			}) : MissionList.missionList[game][category];
			@:privateAccess pmDifficulty.anim.frames = loadButtonImages('data/ui/play/difficulty_${category}');
			pmDifficultyMarble.bmp.tile = ResourceLoader.getResource('data/ui/play/marble_${game}.png', ResourceLoader.getImage, this.imageResources).toTile();

			if (game == "platinum") {
				pmAchievements.disabled = false;
			} else {
				pmAchievements.disabled = true;
			}

			currentCategoryStatic = currentCategory;

			if (currentGame != game) {
				currentGameStatic = game;
				currentGame = game;
				this.bmp.tile = chooseBg().resource.toTile();
			}

			setSelectedFunc(currentList.length - 1);
			if (doRender)
				this.render(cast(this.parent, Canvas).scene2d);
		}

		setScoreHover = (isHover) -> {
			var currentMission = currentList[currentSelection];

			pmScoreText.text.filter = new DropShadow(1.414, 0.785, 0x0000000F, 1, 0, 0.4, 1, true);

			var scoreTextTime = "";
			var scoreData = Settings.getScores(currentMission.path);
			if (scoreData.length == 0) {
				scoreTextTime = '<font color="#FFFFFF">99:59.999</font>';
			} else {
				var topScore = scoreData[0];
				var scoreColor = "#FFFFFF";
				if (topScore.time < currentMission.ultimateTime) {
					scoreColor = "#FFCC33";
				} else if (topScore.time < currentMission.goldTime) {
					if (currentMission.game == "gold" || currentMission.game == "Ultra")
						scoreColor = "#FFFF00"
					else
						scoreColor = "#CCCCCC";
				}

				scoreTextTime = '<font color="${scoreColor}">${Util.formatTime(topScore.time)}</font>';
			}

			if (isHover) {
				pmScoreText.text.text = '<font color="#DDC1C1" face="MarkerFelt24"><p align="center">${this.scoreShowing ? "Hide" : "Show"} 5 Top Times</p></font>';
			} else {
				pmScoreText.text.text = '<font color="#FFE3E3" face="MarkerFelt24"><p align="center">Best Time: ${scoreTextTime}</p></font>';
			}
		}

		setSelectedFunc = function setSelected(index:Int) {
			if (index > currentList.length - 1) {
				index = currentList.length - 1;
			}
			if (index < 0) {
				index = 0;
			}

			currentSelection = index;
			currentSelectionStatic = currentSelection;

			var currentMission = currentList[currentSelection];

			if (index == 0) {
				pmPrev.disabled = true;
			} else
				pmPrev.disabled = false;
			if (index == Math.max(currentList.length - 1, 0)) {
				pmNext.disabled = true;
			} else
				pmNext.disabled = false;

			if (pmPreview.children.contains(pmEgg))
				pmPreview.removeChild(pmEgg);
			if (currentMission.hasEgg) {
				if (Settings.easterEggs.exists(currentMission.path)) {
					pmEgg.bmp.tile = ResourceLoader.getResource('data/ui/play/eggfound.png', ResourceLoader.getImage, this.imageResources).toTile();
				} else {
					pmEgg.bmp.tile = ResourceLoader.getResource('data/ui/play/eggnotfound.png', ResourceLoader.getImage, this.imageResources).toTile();
				}

				pmPreview.addChild(pmEgg);
				pmEgg.render(MarbleGame.canvas.scene2d);
			}

			// if (currentCategory != "custom"
			// 	&& Settings.progression[["beginner", "intermediate", "advanced", "expert"].indexOf(currentCategory)] < currentSelection) {
			// 	noQualText.text.visible = true;
			// 	filt.matrix.identity();
			// 	filt.matrix.colorGain(0, 96 / 255);
			// 	pmPlay.disabled = true;
			// } else {
			noQualText.text.visible = false;
			filt.matrix.identity();
			pmPlay.disabled = false;
			// }

			if (currentMission == null) {
				noQualText.text.visible = true;
				filt.matrix.identity();
				filt.matrix.colorGain(0, 96 / 255);
				pmPlay.disabled = true;
			}

			if (currentMission == null) {
				currentMission = new Mission();
				currentMission.title = "";
				currentMission.description = "";
				currentMission.path = "bruh";
				currentSelection = -1;
			}

			pmDescription.text.filter = new DropShadow(1.414, 0.785, 0x0000000F, 1, 0, 0.4, 1, true);
			pmDescription.text.lineSpacing = -1;

			pmDescriptionRight.text.filter = new DropShadow(1.414, 0.785, 0x0000000F, 1, 0, 0.4, 1, true);
			pmDescriptionRight.text.lineSpacing = -1;

			var descText = '<font color="#FDFEFE" face="MarkerFelt26"><p align="center">#${currentList.indexOf(currentMission) + 1}: ${currentMission.title}</p></font>';

			if (this.scoreShowing) {
				var scoreData:Array<Score> = Settings.getScores(currentMission.path);
				while (scoreData.length < 5) {
					scoreData.push({name: "Matan W.", time: 5999.999});
				}

				var rightText = '<font color="#FDFEFE" face="MarkerFelt26"><br/></font><font color="#F4EFE3" face="MarkerFelt18"></font>';

				for (i in 0...5) {
					var score = scoreData[i];

					var scoreColor = "#FFFFFF";
					if (score.time < currentMission.ultimateTime) {
						scoreColor = "#FFCC33";
					} else if (score.time < currentMission.goldTime) {
						if (currentMission.game == "gold" || currentMission.game.toLowerCase() == "ultra")
							scoreColor = "#FFFF00";
						else
							scoreColor = "#CCCCCC";
					}

					var scoreTextTime = '<p align="right"><font color="${scoreColor}" face="MarkerFelt18">${Util.formatTime(score.time)}</font></p>';
					rightText += scoreTextTime;

					descText += '<font color="#F4E4CE" face="MarkerFelt18">${i + 1}. <font color="#FFFFFF">${StringTools.htmlEscape(score.name)}</font></font><br/>';
				}

				pmDescriptionRight.text.text = rightText;
			} else {
				descText += '<font color="#F4EFE3" face="MarkerFelt18"><p align="center">Author: ${StringTools.htmlEscape(currentMission.artist)}</p></font>';
				descText += '<font color="#F4E4CE" face="MarkerFelt18">${StringTools.htmlEscape(currentMission.description)}</font>';
				pmDescriptionRight.text.text = '';
			}
			pmDescription.text.text = descText;

			pmParText.text.filter = new DropShadow(1.414, 0.785, 0x0000000F, 1, 0, 0.4, 1, true);
			pmParTextRight.text.filter = new DropShadow(1.414, 0.785, 0x0000000F, 1, 0, 0.4, 1, true);
			if (this.scoreShowing) {
				if (currentMission.game == "platinum") {
					pmParText.text.text = '<font color="#FFE3E3" face="MarkerFelt20">Platinum: <font color="#CCCCCC">${Util.formatTime(currentMission.goldTime)}</font></font>';
					pmParTextRight.text.text = '<p align="right"><font color="#FFE3E3" face="MarkerFelt20">Ultimate: <font color="#FFCC33">${Util.formatTime(currentMission.ultimateTime)}</font></font></p>';
				}
				if (currentMission.game == "gold") {
					pmParText.text.text = '<font color="#FFE3E3" face="MarkerFelt20">Qualify: <font color="#FFFFFF">${(currentMission.qualifyTime != Math.POSITIVE_INFINITY) ? Util.formatTime(currentMission.qualifyTime) : "N/A"}</font></font>';
					pmParTextRight.text.text = '<p align="right"><font color="#FFE3E3" face="MarkerFelt20">Gold: <font color="#FFFF00">${Util.formatTime(currentMission.goldTime)}</font></font></p>';
				}
				if (currentMission.game.toLowerCase() == "ultra") {
					pmParText.text.text = '<font color="#FFE3E3" face="MarkerFelt20">Gold: <font color="#FFFF00">${Util.formatTime(currentMission.goldTime)}</font></font>';
					pmParTextRight.text.text = '<p align="right"><font color="#FFE3E3" face="MarkerFelt20">Ultimate: <font color="#FFCC33">${Util.formatTime(currentMission.ultimateTime)}</font></font></p>';
				}
			} else {
				pmParText.text.text = '<font color="#FFE3E3" face="MarkerFelt24"><p align="center">${currentMission.game == "gold" ? "Qualify" : "Par"} Time: <font color="#FFFFFF">${(currentMission.qualifyTime != Math.POSITIVE_INFINITY) ? Util.formatTime(currentMission.qualifyTime) : "N/A"}</font></p></font>';
				pmParTextRight.text.text = '';
			}

			setScoreHover(scoreButtonHover);

			// pmPreview.bmp.tile = tmpprevtile;
			#if js
			switch (previewTimeoutHandle) {
				case None:
					previewTimeoutHandle = Some(js.Browser.window.setTimeout(() -> {
						var prevpath = currentMission.getPreviewImage(prevImg -> {
							pmPreview.bmp.tile = prevImg;
						});
						if (prevpath != pmPreview.bmp.tile.getTexture().name) {
							pmPreview.bmp.tile = tmpprevtile;
						}
					}, 75));
				case Some(previewTimeoutHandle_id):
					js.Browser.window.clearTimeout(previewTimeoutHandle_id);
					previewTimeoutHandle = Some(js.Browser.window.setTimeout(() -> {
						var prevpath = currentMission.getPreviewImage(prevImg -> {
							pmPreview.bmp.tile = prevImg;
						});
						if (prevpath != pmPreview.bmp.tile.getTexture().name) {
							pmPreview.bmp.tile = tmpprevtile;
						}
					}, 75));
			}
			#end
			#if hl
			var pTok = previewToken++;
			var prevpath = currentMission.getPreviewImage(prevImg -> {
				if (pTok + 1 != previewToken)
					return;
				pmPreview.bmp.tile = prevImg;
			}); // Shit be sync
			if (prevpath != pmPreview.bmp.tile.getTexture().name) {
				pmPreview.bmp.tile = tmpprevtile;
			}
			#end
		}

		setCategoryFunc(currentGame, currentCategoryStatic, false);
	}

	public override function render(scene2d:Scene) {
		super.render(scene2d);
		setSelectedFunc(currentSelectionStatic);
	}

	public override function update(dt:Float, mouseState:MouseState) {
		super.update(dt, mouseState);

		buttonHoldFunc(dt, mouseState);

		if (Key.isPressed(Key.LEFT))
			setSelectedFunc(currentSelection - 1);
		if (Key.isPressed(Key.RIGHT))
			setSelectedFunc(currentSelection + 1);

		if (scoreButtonDirty) {
			setScoreHover(scoreButtonHover);
			scoreButtonDirty = false;
		}

		if (pmScoreButton.getHitTestRect().inRect(mouseState.position)) {
			if (!scoreButtonHover) {
				scoreButtonDirty = true;
			}
			scoreButtonHover = true;
		} else {
			if (scoreButtonHover) {
				scoreButtonDirty = true;
			}
			scoreButtonHover = false;
		}
	}
}
