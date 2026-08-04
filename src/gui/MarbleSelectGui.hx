package gui;

import h3d.Matrix;
import h2d.filter.DropShadow;
import hxd.res.BitmapFont;
import h3d.prim.Polygon;
import h3d.scene.Mesh;
import h3d.shader.AlphaChannel;
import src.MarbleGame;
import h3d.Vector;
import src.ResourceLoader;
import src.DtsObject;
import src.Settings;
import src.ResourceLoaderWorker;
import src.MarbleList;

class MarbleSelectGui extends GuiControl {
	public function new() {
		super();
		this.horizSizing = Center;
		this.vertSizing = Center;
		this.position = new Vector(191, 133);
		this.extent = new Vector(418, 333);

		var categoryNames = [
			"PQ Classic",
			"Abstract",
			"Fruit",
			"Solid Colors",
			"Sports",
			"MBP Official",
			"Fubar",
			"Ultra",
			"Leaderboards Custom",
			"Community Selected"
		];

		var curSelection:Int = Settings.optionsSettings.marbleIndex;
		var curCategorySelection:Int = Settings.optionsSettings.marbleCategoryIndex;

		var wnd = new GuiTransparencyCtrl("data/ui/transparency/pqwindow");
		wnd.horizSizing = Center;
		wnd.vertSizing = Center;
		wnd.position = new Vector(0, 0);
		wnd.extent = new Vector(418, 333);
		this.addChild(wnd);

		var whatneyFontData = ResourceLoader.getFileEntry("data/font/whatney.fnt");
		var whatneyFontB = new BitmapFont(whatneyFontData.entry);
		@:privateAccess whatneyFontB.loader = ResourceLoader.loader;
		var whatneyFont = whatneyFontB.toSdfFont(cast 21 * Settings.uiScale, MultiChannel);
		var whatneyFont20 = whatneyFontB.toSdfFont(cast 17 * Settings.uiScale, MultiChannel);

		var squishneyFontData = ResourceLoader.getFileEntry("data/font/squishney.fnt");
		var squishneyFontB = new BitmapFont(squishneyFontData.entry);
		@:privateAccess squishneyFontB.loader = ResourceLoader.loader;
		var squishneyFont = squishneyFontB.toSdfFont(cast 28 * Settings.uiScale, MultiChannel);
		var squishney48 = squishneyFontB.toSdfFont(cast 44 * Settings.uiScale, MultiChannel);
		var squishney20 = squishneyFontB.toSdfFont(cast 17 * Settings.uiScale, MultiChannel);
		var squishney26 = squishneyFontB.toSdfFont(cast 21 * Settings.uiScale, MultiChannel);

		var squishneyFont28 = squishneyFontB.toSdfFont(cast 25 * Settings.uiScale, MultiChannel);

		function mlFontLoader(font:String) {
			switch (font) {
				case "bold20":
					return squishney20;
				case "font20":
					return whatneyFont20;
			}
			return null;
		}

		var titleText = new GuiMLText(squishneyFont28, null);
		titleText.text.textColor = 0x0;
		titleText.horizSizing = Center;
		titleText.vertSizing = Bottom;
		titleText.position = new Vector(102, 16);
		titleText.extent = new Vector(233, 32);
		titleText.text.text = '<p align="center">Choose Your Marble!</p>';
		wnd.addChild(titleText);

		var selectButton = new GuiBorderButtonTextCtrl(ResourceLoader.getResource('data/ui/common/button.png', ResourceLoader.getImage, this.imageResources)
			.toTile(), whatneyFont);
		selectButton.position = new Vector(162, 261);
		selectButton.setExtent(new Vector(94, 45));
		selectButton.vertSizing = Top;
		selectButton.horizSizing = Center;
		selectButton.pressedAction = (e) -> {
			Settings.optionsSettings.marbleIndex = curSelection;
			Settings.optionsSettings.marbleCategoryIndex = curCategorySelection;
			Settings.optionsSettings.marbleSkin = MarbleList.marbles[curCategorySelection][curSelection].skin;
			Settings.optionsSettings.marbleModel = MarbleList.marbles[curCategorySelection][curSelection].dts;
			Settings.optionsSettings.marbleShader = MarbleList.marbles[curCategorySelection][curSelection].shader;
			Settings.save();
			MarbleGame.canvas.popDialog(this);
		}
		selectButton.txtCtrl.text.text = "Close";
		wnd.addChild(selectButton);

		var marbleShow = buildObjectShow(MarbleList.marbles[curCategorySelection][curSelection].dts, new Vector(121, 32), new Vector(175, 175), 2.6, 0, [
			"base.marble" => MarbleList.marbles[curCategorySelection][curSelection].skin + ".marble"
		]);
		marbleShow.horizSizing = Center;
		marbleShow.vertSizing = Bottom;
		marbleShow.visible = true;
		wnd.addChild(marbleShow);

		var categoryText = new GuiMLText(whatneyFont20, mlFontLoader);
		categoryText.text.textColor = 0x0;
		categoryText.horizSizing = Center;
		categoryText.vertSizing = Top;
		categoryText.position = new Vector(49, 225);
		categoryText.extent = new Vector(320, 22);
		categoryText.text.text = '<p align="center"><font face="bold20">Category: </font>${categoryNames[curCategorySelection]}</p>';
		wnd.addChild(categoryText);

		var marbleText = new GuiMLText(whatneyFont20, mlFontLoader);
		marbleText.text.textColor = 0x0;
		marbleText.horizSizing = Center;
		marbleText.vertSizing = Top;
		marbleText.position = new Vector(49, 182);
		marbleText.extent = new Vector(320, 22);
		marbleText.text.text = '<p align="center">${MarbleList.marbles[curCategorySelection][curSelection].name}</p>';
		wnd.addChild(marbleText);

		function setMarbleSelection(idx:Int, categoryIdx:Int) {
			if (categoryIdx < 0)
				categoryIdx = MarbleList.marbles.length + categoryIdx;
			if (categoryIdx >= MarbleList.marbles.length)
				categoryIdx -= MarbleList.marbles.length;

			if (idx < 0)
				idx = MarbleList.marbles[categoryIdx].length + idx;
			if (idx >= MarbleList.marbles[categoryIdx].length)
				idx -= MarbleList.marbles[categoryIdx].length;
			curSelection = idx;
			curCategorySelection = categoryIdx;
			var marble = MarbleList.marbles[categoryIdx][idx];

			categoryText.text.text = '<p align="center"><font face="bold20">Category: </font>${categoryNames[curCategorySelection]}</p>';
			marbleText.text.text = '<p align="center">${marble.name}</p>';

			var dtsObj = new DtsObject();
			dtsObj.dtsPath = marble.dts;
			dtsObj.ambientRotate = true;
			dtsObj.ambientSpinFactor /= -2;
			dtsObj.showSequences = false;
			dtsObj.useInstancing = false;
			dtsObj.matNameOverride.set("base.marble", marble.skin + ".marble");

			ResourceLoader.load(dtsObj.dtsPath).entry.load(() -> {
				var dtsFile = ResourceLoader.loadDts(dtsObj.dtsPath);
				var directoryPath = haxe.io.Path.directory(dtsObj.dtsPath);
				var texToLoad = [];
				for (i in 0...dtsFile.resource.matNames.length) {
					var matName = dtsObj.matNameOverride.exists(dtsFile.resource.matNames[i]) ? dtsObj.matNameOverride.get(dtsFile.resource.matNames[i]) : dtsFile.resource.matNames[i];
					var fullNames = ResourceLoader.getFullNamesOf(directoryPath + '/' + matName).filter(x -> haxe.io.Path.extension(x) != "dts");
					var fullName = fullNames.length > 0 ? fullNames[0] : null;
					if (fullName != null) {
						texToLoad.push(fullName);
					}
				}

				var worker = new ResourceLoaderWorker(() -> {
					dtsObj.init(null, () -> {}); // The lambda is not gonna run async anyway
					for (mat in dtsObj.materials) {
						mat.mainPass.enableLights = false;
					}
					marbleShow.changeObject(dtsObj);
				});

				for (texPath in texToLoad) {
					worker.loadFile(texPath);
				}
				worker.run();
			});
		}

		var colorMat = new Matrix();
		colorMat.colorSet(0x0);

		var nextBtn = new GuiBorderButtonCtrl(ResourceLoader.getResource('data/ui/common/button.png', ResourceLoader.getImage, this.imageResources).toTile());
		nextBtn.horizSizing = Left;
		nextBtn.vertSizing = Top;
		nextBtn.position = new Vector(346, 171);
		nextBtn.extent = new Vector(45, 45);
		nextBtn.pressedAction = (e) -> {
			setMarbleSelection(curSelection + 1, curCategorySelection);
		}
		wnd.addChild(nextBtn);

		var nextBtnIcon = new GuiImage(ResourceLoader.getResource("data/ui/play/leftright.png", ResourceLoader.getImage, this.imageResources).toTile());
		nextBtnIcon.position = new Vector(22.5 + 13.0 / 2, 22.5 + 19.0 / 2);
		nextBtnIcon.extent = new Vector(13, 19);
		nextBtnIcon.bmp.colorMatrix = colorMat;
		nextBtnIcon.bmp.rotation = Math.PI;
		nextBtn.addChild(nextBtnIcon);

		var prevBtn = new GuiBorderButtonCtrl(ResourceLoader.getResource('data/ui/common/button.png', ResourceLoader.getImage, this.imageResources).toTile());
		prevBtn.horizSizing = Right;
		prevBtn.vertSizing = Top;
		prevBtn.position = new Vector(27, 171);
		prevBtn.extent = new Vector(45, 45);
		prevBtn.pressedAction = (e) -> {
			setMarbleSelection(curSelection - 1, curCategorySelection);
		}
		wnd.addChild(prevBtn);

		var prevBtnIcon = new GuiImage(ResourceLoader.getResource("data/ui/play/leftright.png", ResourceLoader.getImage, this.imageResources).toTile());
		prevBtnIcon.horizSizing = Center;
		prevBtnIcon.vertSizing = Center;
		prevBtnIcon.position = new Vector(0, 0);
		prevBtnIcon.extent = new Vector(13, 19);
		prevBtnIcon.bmp.colorMatrix = colorMat;
		prevBtn.addChild(prevBtnIcon);

		var nextCategoryBtn = new GuiBorderButtonCtrl(ResourceLoader.getResource('data/ui/common/button.png', ResourceLoader.getImage, this.imageResources)
			.toTile());
		nextCategoryBtn.horizSizing = Left;
		nextCategoryBtn.vertSizing = Top;
		nextCategoryBtn.position = new Vector(346, 216);
		nextCategoryBtn.extent = new Vector(45, 45);
		nextCategoryBtn.pressedAction = (e) -> {
			setMarbleSelection(0, curCategorySelection + 1);
		}
		wnd.addChild(nextCategoryBtn);

		var nextCategoryBtnIcon = new GuiImage(ResourceLoader.getResource("data/ui/play/leftright.png", ResourceLoader.getImage, this.imageResources)
			.toTile());
		nextCategoryBtnIcon.position = new Vector(22.5 + 13.0 / 2, 22.5 + 19.0 / 2);
		nextCategoryBtnIcon.extent = new Vector(13, 19);
		nextCategoryBtnIcon.bmp.colorMatrix = colorMat;
		nextCategoryBtnIcon.bmp.rotation = Math.PI;
		nextCategoryBtn.addChild(nextCategoryBtnIcon);

		var prevCategoryBtn = new GuiBorderButtonCtrl(ResourceLoader.getResource('data/ui/common/button.png', ResourceLoader.getImage, this.imageResources)
			.toTile());
		prevCategoryBtn.horizSizing = Right;
		prevCategoryBtn.vertSizing = Top;
		prevCategoryBtn.position = new Vector(27, 216);
		prevCategoryBtn.extent = new Vector(45, 45);
		prevCategoryBtn.pressedAction = (e) -> {
			setMarbleSelection(0, curCategorySelection - 1);
		}
		wnd.addChild(prevCategoryBtn);

		var prevCategoryBtnIcon = new GuiImage(ResourceLoader.getResource("data/ui/play/leftright.png", ResourceLoader.getImage, this.imageResources)
			.toTile());
		prevCategoryBtnIcon.horizSizing = Center;
		prevCategoryBtnIcon.vertSizing = Center;
		prevCategoryBtnIcon.position = new Vector(0, 0);
		prevCategoryBtnIcon.extent = new Vector(13, 19);
		prevCategoryBtnIcon.bmp.colorMatrix = colorMat;
		prevCategoryBtn.addChild(prevCategoryBtnIcon);

		setMarbleSelection(curSelection, curCategorySelection);
	}

	function buildObjectShow(dtsPath:String, position:Vector, extent:Vector, dist:Float = 5, pitch:Float = 0, matnameOverride:Map<String, String> = null) {
		var oShow = new GuiObjectShow();
		var dtsObj = new DtsObject();
		dtsObj.dtsPath = dtsPath;
		dtsObj.ambientRotate = true;
		dtsObj.ambientSpinFactor /= -2;
		dtsObj.showSequences = false;
		dtsObj.useInstancing = false;
		if (matnameOverride != null) {
			for (key => value in matnameOverride) {
				dtsObj.matNameOverride.set(key, value);
			}
		}
		dtsObj.init(null, () -> {}); // The lambda is not gonna run async anyway
		for (mat in dtsObj.materials) {
			mat.mainPass.enableLights = false;
		}
		oShow.sceneObject = dtsObj;
		oShow.position = position;
		oShow.extent = extent;
		oShow.renderDistance = dist;
		oShow.renderPitch = pitch;
		return oShow;
	}
}
