package gui;

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

class MarbleSelectGui extends GuiImage {
	public function new() {
		var img = ResourceLoader.getImage("data/ui/marbleSelect/marbleSelect.png");
		super(img.resource.toTile());
		this.horizSizing = Center;
		this.vertSizing = Center;
		this.position = new Vector(73, -59);
		this.extent = new Vector(493, 361);

		var marbleData = [
			[
				{
					name: "1",
					dts: "data/shapes/balls/marble01.dts",
					skin: "base",
					shader: "ClassicGlassPureSphere"
				},
				{
					name: "2",
					dts: "data/shapes/balls/marble03.dts",
					skin: "base",
					shader: "ClassicGlassPureSphere"
				},
				{
					name: "3",
					dts: "data/shapes/balls/marble04.dts",
					skin: "base",
					shader: "ClassicGlassPureSphere"
				},
				{
					name: "4",
					dts: "data/shapes/balls/marble05.dts",
					skin: "base",
					shader: "ClassicGlassPureSphere"
				},
				{
					name: "5",
					dts: "data/shapes/balls/marble06.dts",
					skin: "base",
					shader: "ClassicGlassPureSphere"
				},
				{
					name: "6",
					dts: "data/shapes/balls/marble07.dts",
					skin: "base",
					shader: "ClassicGlassPureSphere"
				},
				{
					name: "7",
					dts: "data/shapes/balls/marble12.dts",
					skin: "base",
					shader: "ClassicGlassPureSphere"
				},
				{
					name: "8",
					dts: "data/shapes/balls/marble15.dts",
					skin: "base",
					shader: "ClassicGlassPureSphere"
				},
				{
					name: "9",
					dts: "data/shapes/balls/marble02.dts",
					skin: "base",
					shader: "CrystalMarb"
				},
				{
					name: "10",
					dts: "data/shapes/balls/marble26.dts",
					skin: "base",
					shader: "CrystalMarb"
				},
				{
					name: "11",
					dts: "data/shapes/balls/marble27.dts",
					skin: "base",
					shader: "CrystalMarb"
				},
				{
					name: "12",
					dts: "data/shapes/balls/marble28.dts",
					skin: "base",
					shader: "CrystalMarb"
				},
				{
					name: "13",
					dts: "data/shapes/balls/marble29.dts",
					skin: "base",
					shader: "CrystalMarb"
				},
				{
					name: "14",
					dts: "data/shapes/balls/marble30.dts",
					skin: "base",
					shader: "CrystalMarb"
				},
				{
					name: "15",
					dts: "data/shapes/balls/marble11.dts",
					skin: "base",
					shader: "ClassicMetal"
				},
				{
					name: "16",
					dts: "data/shapes/balls/marble18.dts",
					skin: "base",
					shader: "ClassicMarbGlass18"
				},
				{
					name: "17",
					dts: "data/shapes/balls/marble20.dts",
					skin: "base",
					shader: "ClassicMarbGlass20"
				},
				{
					name: "18",
					dts: "data/shapes/balls/marble33.dts",
					skin: "base",
					shader: "ClassicMetal"
				},
				{
					name: "19",
					dts: "data/shapes/balls/marble34.dts",
					skin: "base",
					shader: "ClassicMarb2"
				},
				{
					name: "20",
					dts: "data/shapes/balls/marble09.dts",
					skin: "base",
					shader: "ClassicMarb3"
				},
				{
					name: "21",
					dts: "data/shapes/balls/marble13.dts",
					skin: "base",
					shader: "ClassicMarb3"
				},
				{
					name: "22",
					dts: "data/shapes/balls/marble14.dts",
					skin: "base",
					shader: "ClassicMarb3"
				},
				{
					name: "23",
					dts: "data/shapes/balls/marble17.dts",
					skin: "base",
					shader: "ClassicMarb3"
				},
				{
					name: "24",
					dts: "data/shapes/balls/marble19.dts",
					skin: "base",
					shader: "ClassicMarb3"
				},
				{
					name: "25",
					dts: "data/shapes/balls/marble21.dts",
					skin: "base",
					shader: "ClassicMarb3"
				},
				{
					name: "26",
					dts: "data/shapes/balls/marble22.dts",
					skin: "base",
					shader: "ClassicMarb3"
				},
				{
					name: "27",
					dts: "data/shapes/balls/marble23.dts",
					skin: "base",
					shader: "ClassicMarb3"
				},
				{
					name: "28",
					dts: "data/shapes/balls/marble24.dts",
					skin: "base",
					shader: "ClassicMarb3"
				},
				{
					name: "29",
					dts: "data/shapes/balls/marble25.dts",
					skin: "base",
					shader: "ClassicMarb3"
				},
				{
					name: "30",
					dts: "data/shapes/balls/marble31.dts",
					skin: "base",
					shader: "ClassicMarb3"
				},
				{
					name: "31",
					dts: "data/shapes/balls/marble32.dts",
					skin: "base",
					shader: "ClassicMarb3"
				},
				{
					name: "32",
					dts: "data/shapes/balls/marble08.dts",
					skin: "base",
					shader: "ClassicMarb"
				},
				{
					name: "33",
					dts: "data/shapes/balls/marble10.dts",
					skin: "base",
					shader: "ClassicMarb2"
				},
				{
					name: "34",
					dts: "data/shapes/balls/marble16.dts",
					skin: "base",
					shader: "ClassicMarb3"
				},
				{
					name: "35",
					dts: "data/shapes/balls/marble35.dts",
					skin: "base",
					shader: "ClassicMarb3"
				}
			]
		];

		var categoryNames = ["MBUltra"];

		var curSelection:Int = Settings.optionsSettings.marbleIndex;
		var curCategorySelection:Int = Settings.optionsSettings.marbleCategoryIndex;

		function loadButtonImages(path:String) {
			var normal = ResourceLoader.getResource('${path}_n.png', ResourceLoader.getImage, this.imageResources).toTile();
			var hover = ResourceLoader.getResource('${path}_h.png', ResourceLoader.getImage, this.imageResources).toTile();
			var pressed = ResourceLoader.getResource('${path}_d.png', ResourceLoader.getImage, this.imageResources).toTile();
			var disabled = ResourceLoader.getResource('${path}_i.png', ResourceLoader.getImage, this.imageResources).toTile();
			return [normal, hover, pressed, disabled];
		}

		var markerFelt32fontdata = ResourceLoader.getFileEntry("data/font/MarkerFelt.fnt");
		var markerFelt32b = new BitmapFont(markerFelt32fontdata.entry);
		@:privateAccess markerFelt32b.loader = ResourceLoader.loader;
		var markerFelt32 = markerFelt32b.toSdfFont(cast 26 * Settings.uiScale, MultiChannel);
		var markerFelt24 = markerFelt32b.toSdfFont(cast 18 * Settings.uiScale, MultiChannel);
		var markerFelt28 = markerFelt32b.toSdfFont(cast 26 * Settings.uiScale, MultiChannel);

		var selectBtn = new GuiButton(loadButtonImages("data/ui/marbleSelect/select"));
		selectBtn.horizSizing = Center;
		selectBtn.vertSizing = Top;
		selectBtn.position = new Vector(199, 270);
		selectBtn.extent = new Vector(95, 45);
		selectBtn.pressedAction = (e) -> {
			Settings.optionsSettings.marbleIndex = curSelection;
			Settings.optionsSettings.marbleCategoryIndex = curCategorySelection;
			Settings.optionsSettings.marbleSkin = marbleData[curCategorySelection][curSelection].skin;
			Settings.optionsSettings.marbleModel = marbleData[curCategorySelection][curSelection].dts;
			Settings.optionsSettings.marbleShader = marbleData[curCategorySelection][curSelection].shader;
			Settings.save();
			MarbleGame.canvas.popDialog(this);
		}
		this.addChild(selectBtn);

		var marbleShow = buildObjectShow(marbleData[curCategorySelection][curSelection].dts, new Vector(171, 97), new Vector(150, 150), 2.6, 0,
			["base.marble" => marbleData[curCategorySelection][curSelection].skin + ".marble"]);
		marbleShow.horizSizing = Center;
		marbleShow.vertSizing = Bottom;
		marbleShow.visible = true;
		this.addChild(marbleShow);

		var titleText = new GuiMLText(markerFelt28, null);
		titleText.text.textColor = 0xFFFFFF;
		titleText.text.filter = new DropShadow(1.414, 0.785, 0, 1, 0x0000007F, 0.4, 1, true);
		titleText.horizSizing = Center;
		titleText.vertSizing = Bottom;
		titleText.position = new Vector(140, 67);
		titleText.extent = new Vector(213, 27);
		titleText.text.text = '<p align="center">${categoryNames[curCategorySelection]}</p>';
		this.addChild(titleText);

		var marbleText = new GuiMLText(markerFelt24, null);
		marbleText.text.textColor = 0xFFFFFF;
		marbleText.text.filter = new DropShadow(1.414, 0.785, 0, 1, 0x0000007F, 0.4, 1, true);
		marbleText.horizSizing = Center;
		marbleText.vertSizing = Bottom;
		marbleText.position = new Vector(86, 243);
		marbleText.extent = new Vector(320, 22);
		marbleText.text.text = '<p align="center">${marbleData[curCategorySelection][curSelection].name}</p>';
		this.addChild(marbleText);

		var changeMarbleText = new GuiImage(ResourceLoader.getResource("data/ui/play/change_marble_text.png", ResourceLoader.getImage, this.imageResources)
			.toTile());
		changeMarbleText.horizSizing = Center;
		changeMarbleText.position = new Vector(96, 26);
		changeMarbleText.extent = new Vector(300, 39);
		this.addChild(changeMarbleText);

		function setMarbleSelection(idx:Int, categoryIdx:Int) {
			if (categoryIdx < 0)
				categoryIdx = marbleData.length + categoryIdx;
			if (categoryIdx >= marbleData.length)
				categoryIdx -= marbleData.length;

			if (idx < 0)
				idx = marbleData[categoryIdx].length + idx;
			if (idx >= marbleData[categoryIdx].length)
				idx -= marbleData[categoryIdx].length;
			curSelection = idx;
			curCategorySelection = categoryIdx;
			var marble = marbleData[categoryIdx][idx];

			titleText.text.text = '<p align="center">${categoryNames[curCategorySelection]}</p>';
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
						mat.mainPass.culling = None;
						if (mat.blendMode != Alpha && mat.blendMode != Add)
							mat.mainPass.addShader(new AlphaChannel());
					}
					marbleShow.changeObject(dtsObj);
				});

				for (texPath in texToLoad) {
					worker.loadFile(texPath);
				}
				worker.run();
			});
		}

		var nextBtn = new GuiButton(loadButtonImages("data/ui/marbleSelect/next"));
		nextBtn.position = new Vector(296, 270);
		nextBtn.extent = new Vector(75, 45);
		nextBtn.pressedAction = (e) -> {
			setMarbleSelection(curSelection + 1, curCategorySelection);
		}
		this.addChild(nextBtn);

		var prevBtn = new GuiButton(loadButtonImages("data/ui/marbleSelect/prev"));
		prevBtn.position = new Vector(123, 270);
		prevBtn.extent = new Vector(75, 45);
		prevBtn.pressedAction = (e) -> {
			setMarbleSelection(curSelection - 1, curCategorySelection);
		}

		var nextCategoryBtn = new GuiButton(loadButtonImages("data/ui/marbleSelect/nextcat"));
		nextCategoryBtn.position = new Vector(371, 270);
		nextCategoryBtn.extent = new Vector(85, 45);
		nextCategoryBtn.pressedAction = (e) -> {
			setMarbleSelection(0, curCategorySelection + 1);
		}
		this.addChild(nextCategoryBtn);

		var prevCategoryBtn = new GuiButton(loadButtonImages("data/ui/marbleSelect/prevcat"));
		prevCategoryBtn.position = new Vector(37, 270);
		prevCategoryBtn.extent = new Vector(85, 45);
		prevCategoryBtn.pressedAction = (e) -> {
			setMarbleSelection(0, curCategorySelection - 1);
		}
		this.addChild(prevCategoryBtn);

		setMarbleSelection(curSelection, curCategorySelection);
		this.addChild(prevBtn);
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
			mat.mainPass.culling = None;
			if (mat.blendMode != Alpha && mat.blendMode != Add)
				mat.mainPass.addShader(new AlphaChannel());
		}
		oShow.sceneObject = dtsObj;
		oShow.position = position;
		oShow.extent = extent;
		oShow.renderDistance = dist;
		oShow.renderPitch = pitch;
		return oShow;
	}
}
