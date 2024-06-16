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
	public static var marbleData = [
		[
			{
				name: "Staff's Original",
				dts: "data/shapes/balls/ball-superball.dts",
				skin: "base",
				shader: "Default"
			},
			{
				name: "3D Marble",
				dts: "data/shapes/balls/3dMarble.dts",
				skin: "base",
				shader: "Default"
			},
			{
				name: "Mid P",
				dts: "data/shapes/balls/midp.dts",
				skin: "base",
				shader: "Default"
			},
			{
				name: "Spade",
				dts: "data/shapes/balls/ball-superball.dts",
				skin: "skin4",
				shader: "Default"
			},
			{
				name: "GMD Logo",
				dts: "data/shapes/balls/ball-superball.dts",
				skin: "skin5",
				shader: "Default"
			},
			{
				name: "Textured Marble",
				dts: "data/shapes/balls/ball-superball.dts",
				skin: "skin6",
				shader: "Default"
			},
			{
				name: "Golden Marble",
				dts: "data/shapes/balls/ball-superball.dts",
				skin: "skin7",
				shader: "Default"
			},
			{
				name: "Rainbow Marble",
				dts: "data/shapes/balls/ball-superball.dts",
				skin: "skin8",
				shader: "Default"
			},
			{
				name: "Brown Swirls",
				dts: "data/shapes/balls/ball-superball.dts",
				skin: "skin9",
				shader: "Default"
			},
			{
				name: "Caution Stripes",
				dts: "data/shapes/balls/ball-superball.dts",
				skin: "skin10",
				shader: "Default"
			},
			{
				name: "Earth",
				dts: "data/shapes/balls/ball-superball.dts",
				skin: "skin11",
				shader: "Default"
			},
			{
				name: "Golf Ball",
				dts: "data/shapes/balls/ball-superball.dts",
				skin: "skin12",
				shader: "Default"
			},
			{
				name: "Jupiter",
				dts: "data/shapes/balls/ball-superball.dts",
				skin: "skin13",
				shader: "Default"
			},
			{
				name: "MB Gold Marble",
				dts: "data/shapes/balls/ball-superball.dts",
				skin: "skin14",
				shader: "Default"
			},
			{
				name: "MBP on the Marble!",
				dts: "data/shapes/balls/ball-superball.dts",
				skin: "skin15",
				shader: "Default"
			},
			{
				name: "Moshe",
				dts: "data/shapes/balls/ball-superball.dts",
				skin: "skin16",
				shader: "Default"
			},
			{
				name: "Strong Bad",
				dts: "data/shapes/balls/ball-superball.dts",
				skin: "skin17",
				shader: "Default"
			},
			{
				name: "Venus",
				dts: "data/shapes/balls/ball-superball.dts",
				skin: "skin18",
				shader: "Default"
			},
			{
				name: "Water",
				dts: "data/shapes/balls/ball-superball.dts",
				skin: "skin19",
				shader: "Default"
			},
			{
				name: "Evil Eye",
				dts: "data/shapes/balls/ball-superball.dts",
				skin: "skin20",
				shader: "Default"
			},
			{
				name: "Desert and Sky",
				dts: "data/shapes/balls/ball-superball.dts",
				skin: "skin21",
				shader: "Default"
			},
			{
				name: "Dirt Marble",
				dts: "data/shapes/balls/ball-superball.dts",
				skin: "skin22",
				shader: "Default"
			},
			{
				name: "Friction Textured Marble",
				dts: "data/shapes/balls/ball-superball.dts",
				skin: "skin23",
				shader: "Default"
			},
			{
				name: "Grass",
				dts: "data/shapes/balls/ball-superball.dts",
				skin: "skin24",
				shader: "Default"
			},
			{
				name: "Mars",
				dts: "data/shapes/balls/ball-superball.dts",
				skin: "skin25",
				shader: "Default"
			},
			{
				name: "Phil's Golf Ball",
				dts: "data/shapes/balls/ball-superball.dts",
				skin: "skin26",
				shader: "Default"
			},
			{
				name: "Molten",
				dts: "data/shapes/balls/ball-superball.dts",
				skin: "skin27",
				shader: "Default"
			},
			{
				name: "Lightning",
				dts: "data/shapes/balls/ball-superball.dts",
				skin: "skin28",
				shader: "Default"
			},
			{
				name: "Phil'sEmpire",
				dts: "data/shapes/balls/ball-superball.dts",
				skin: "skin29",
				shader: "Default"
			},
			{
				name: "Matan's Red Dragon",
				dts: "data/shapes/balls/ball-superball.dts",
				skin: "skin30",
				shader: "Default"
			},
			{
				name: "Metallic Marble",
				dts: "data/shapes/balls/ball-superball.dts",
				skin: "skin31",
				shader: "Default"
			},
			{
				name: "Sun",
				dts: "data/shapes/balls/ball-superball.dts",
				skin: "skin32",
				shader: "Default"
			},
			{
				name: "Underwater",
				dts: "data/shapes/balls/ball-superball.dts",
				skin: "skin33",
				shader: "Default"
			},
			{
				name: "GarageGames logo",
				dts: "data/shapes/balls/garageGames.dts",
				skin: "base",
				shader: "Default"
			},
			{
				name: "Big Marble 1",
				dts: "data/shapes/balls/bm1.dts",
				skin: "base",
				shader: "Default"
			},
			{
				name: "Big Marble 2",
				dts: "data/shapes/balls/bm2.dts",
				skin: "base",
				shader: "Default"
			},
			{
				name: "Big Marble 3",
				dts: "data/shapes/balls/bm3.dts",
				skin: "base",
				shader: "Default"
			},
			{
				name: "Small Marble 1",
				dts: "data/shapes/balls/sm1.dts",
				skin: "base",
				shader: "Default"
			},
			{
				name: "Small Marble 2",
				dts: "data/shapes/balls/sm2.dts",
				skin: "base",
				shader: "Default"
			},
			{
				name: "Small Marble 3",
				dts: "data/shapes/balls/sm3.dts",
				skin: "base",
				shader: "Default"
			}
		],
		[
			{
				name: "Deep Blue",
				dts: "data/shapes/balls/pack1/pack1marble.dts",
				skin: "uskin1",
				shader: "ClassicGlassPureSphere"
			},
			{
				name: "Blood Red",
				dts: "data/shapes/balls/pack1/pack1marble.dts",
				skin: "uskin2",
				shader: "Default"
			},
			{
				name: "Gang Green",
				dts: "data/shapes/balls/pack1/pack1marble.dts",
				skin: "uskin6",
				shader: "ClassicGlassPureSphere"
			},
			{
				name: "Pink Candy",
				dts: "data/shapes/balls/pack1/pack1marble.dts",
				skin: "uskin27",
				shader: "Default"
			},
			{
				name: "Chocolate",
				dts: "data/shapes/balls/pack1/pack1marble.dts",
				skin: "uskin5",
				shader: "ClassicGlassPureSphere"
			},
			{
				name: "Grape",
				dts: "data/shapes/balls/pack1/pack1marble.dts",
				skin: "uskin4",
				shader: "ClassicGlassPureSphere"
			},
			{
				name: "Lemon",
				dts: "data/shapes/balls/pack1/pack1marble.dts",
				skin: "uskin28",
				shader: "Default"
			},
			{
				name: "Lime Green",
				dts: "data/shapes/balls/pack1/pack1marble.dts",
				skin: "uskin8",
				shader: "Default"
			},
			{
				name: "Blueberry",
				dts: "data/shapes/balls/pack1/pack1marble.dts",
				skin: "uskin7",
				shader: "ClassicGlassPureSphere"
			},
			{
				name: "Tangerine",
				dts: "data/shapes/balls/pack1/pack1marble.dts",
				skin: "uskin3",
				shader: "ClassicGlassPureSphere"
			},
			{
				name: "8 Ball",
				dts: "data/shapes/balls/pack1/pack1marble.dts",
				skin: "uskin9",
				shader: "ClassicMarb3"
			},
			{
				name: "Ace of Hearts",
				dts: "data/shapes/balls/pack1/pack1marble.dts",
				skin: "uskin22",
				shader: "ClassicMarb3"
			},
			{
				name: "Football",
				dts: "data/shapes/balls/pack1/pack1marble.dts",
				skin: "uskin16",
				shader: "ClassicMarb3"
			},
			{
				name: "9 Ball",
				dts: "data/shapes/balls/pack1/pack1marble.dts",
				skin: "uskin29",
				shader: "ClassicMarb3"
			},
			{
				name: "Ace of Spades",
				dts: "data/shapes/balls/pack1/pack1marble.dts",
				skin: "uskin24",
				shader: "ClassicMarb3"
			},
			{
				name: "GarageGames",
				dts: "data/shapes/balls/pack1/pack1marble.dts",
				skin: "uskin10",
				shader: "ClassicMarb2"
			},
			{
				name: "Bob",
				dts: "data/shapes/balls/pack1/pack1marble.dts",
				skin: "uskin30",
				shader: "ClassicMarb3"
			},
			{
				name: "Skully",
				dts: "data/shapes/balls/pack1/pack1marble.dts",
				skin: "uskin18",
				shader: "Default"
			},
			{
				name: "Jack-o-Lantern",
				dts: "data/shapes/balls/pack1/pack1marble.dts",
				skin: "uskin34",
				shader: "Default"
			},
			{
				name: "Walled Up",
				dts: "data/shapes/balls/pack1/pack1marble.dts",
				skin: "uskin25",
				shader: "ClassicMarb3"
			},
			{
				name: "Sunny Side Up",
				dts: "data/shapes/balls/pack1/pack1marble.dts",
				skin: "uskin11",
				shader: "ClassicMetal"
			},
			{
				name: "Lunar",
				dts: "data/shapes/balls/pack1/pack1marble.dts",
				skin: "uskin31",
				shader: "ClassicMetal"
			},
			{
				name: "Battery",
				dts: "data/shapes/balls/pack1/pack1marble.dts",
				skin: "uskin14",
				shader: "ClassicMarb3"
			},
			{
				name: "Static",
				dts: "data/shapes/balls/pack1/pack1marble.dts",
				skin: "uskin32",
				shader: "ClassicMarb2"
			},
			{
				name: "Earth",
				dts: "data/shapes/balls/pack1/pack1marble.dts",
				skin: "uskin20",
				shader: "ClassicMarbGlass20"
			},
			{
				name: "Red and X",
				dts: "data/shapes/balls/pack1/pack1marble.dts",
				skin: "uskin13",
				shader: "ClassicMarb3"
			},
			{
				name: "Orange Spiral",
				dts: "data/shapes/balls/pack1/pack1marble.dts",
				skin: "uskin12",
				shader: "ClassicGlassPureSphere"
			},
			{
				name: "Blue Spiral",
				dts: "data/shapes/balls/pack1/pack1marble.dts",
				skin: "uskin15",
				shader: "ClassicGlassPureSphere"
			},
			{
				name: "Sliced Marble",
				dts: "data/shapes/balls/pack1/pack1marble.dts",
				skin: "uskin21",
				shader: "ClassicMarb3"
			},
			{
				name: "Orange Checkers",
				dts: "data/shapes/balls/pack1/pack1marble.dts",
				skin: "uskin19",
				shader: "ClassicMarb3"
			},
			{
				name: "Torque",
				dts: "data/shapes/balls/pack1/pack1marble.dts",
				skin: "uskin33",
				shader: "ClassicMarb3"
			},
			{
				name: "Fred",
				dts: "data/shapes/balls/pack1/pack1marble.dts",
				skin: "uskin17",
				shader: "ClassicMarb3"
			},
			{
				name: "Pirate",
				dts: "data/shapes/balls/pack1/pack1marble.dts",
				skin: "uskin26",
				shader: "ClassicMarbGlass18"
			},
			{
				name: "Shuriken",
				dts: "data/shapes/balls/pack1/pack1marble.dts",
				skin: "uskin23",
				shader: "ClassicMarb3"
			},
			{
				name: "Eyeball",
				dts: "data/shapes/balls/pack1/pack1marble.dts",
				skin: "uskin35",
				shader: "Default"
			},
			{
				name: "Woody",
				dts: "data/shapes/balls/pack1/pack1marble.dts",
				skin: "uskin36",
				shader: "Default"
			},
			{
				name: "Dat Nostalgia",
				dts: "data/shapes/balls/pack1/pack1marble.dts",
				skin: "uskin37",
				shader: "Default"
			},
			{
				name: "Graffiti",
				dts: "data/shapes/balls/pack1/pack1marble.dts",
				skin: "uskin38",
				shader: "Default"
			},
			{
				name: "Asteroid",
				dts: "data/shapes/balls/pack1/pack1marble.dts",
				skin: "uskin39",
				shader: "Default"
			},
			{
				name: "Disco Ball",
				dts: "data/shapes/balls/pack1/pack1marble.dts",
				skin: "uskin40",
				shader: "Default"
			}
		],
	];

	public function new() {
		var img = ResourceLoader.getImage("data/ui/marbleSelect/marbleSelect.png");
		super(img.resource.toTile());
		this.horizSizing = Center;
		this.vertSizing = Center;
		this.position = new Vector(73, -59);
		this.extent = new Vector(493, 361);

		var categoryNames = ["Official Marbles", "MBUltra"];

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
						mat.mainPass.culling = Front;
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
			mat.mainPass.culling = Front;
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
