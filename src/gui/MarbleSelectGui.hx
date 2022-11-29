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
			{name: "Staff's Original", dts: "data/shapes/balls/ball-superball.dts", skin: "base"},
			{name: "3D Marble", dts: "data/shapes/balls/3dMarble.dts", skin: "base"},
			{name: "Mid P", dts: "data/shapes/balls/midp.dts", skin: "base"},
			{name: "Spade", dts: "data/shapes/balls/ball-superball.dts", skin: "skin4"},
			{name: "GMD Logo", dts: "data/shapes/balls/ball-superball.dts", skin: "skin5"},
			{name: "Textured Marble", dts: "data/shapes/balls/ball-superball.dts", skin: "skin6"},
			{name: "Golden Marble", dts: "data/shapes/balls/ball-superball.dts", skin: "skin7"},
			{name: "Rainbow Marble", dts: "data/shapes/balls/ball-superball.dts", skin: "skin8"},
			{name: "Brown Swirls", dts: "data/shapes/balls/ball-superball.dts", skin: "skin9"},
			{name: "Caution Stripes", dts: "data/shapes/balls/ball-superball.dts", skin: "skin10"},
			{name: "Earth", dts: "data/shapes/balls/ball-superball.dts", skin: "skin11"},
			{name: "Golf Ball", dts: "data/shapes/balls/ball-superball.dts", skin: "skin12"},
			{name: "Jupiter", dts: "data/shapes/balls/ball-superball.dts", skin: "skin13"},
			{name: "MB Gold Marble", dts: "data/shapes/balls/ball-superball.dts", skin: "skin14"},
			{name: "MBP on the Marble!", dts: "data/shapes/balls/ball-superball.dts", skin: "skin15"},
			{name: "Moshe", dts: "data/shapes/balls/ball-superball.dts", skin: "skin16"},
			{name: "Strong Bad", dts: "data/shapes/balls/ball-superball.dts", skin: "skin17"},
			{name: "Venus", dts: "data/shapes/balls/ball-superball.dts", skin: "skin18"},
			{name: "Water", dts: "data/shapes/balls/ball-superball.dts", skin: "skin19"},
			{name: "Evil Eye", dts: "data/shapes/balls/ball-superball.dts", skin: "skin20"},
			{name: "Desert and Sky", dts: "data/shapes/balls/ball-superball.dts", skin: "skin21"},
			{name: "Dirt Marble", dts: "data/shapes/balls/ball-superball.dts", skin: "skin22"},
			{name: "Friction Textured Marble", dts: "data/shapes/balls/ball-superball.dts", skin: "skin23"},
			{name: "Grass", dts: "data/shapes/balls/ball-superball.dts", skin: "skin24"},
			{name: "Mars", dts: "data/shapes/balls/ball-superball.dts", skin: "skin25"},
			{name: "Phil's Golf Ball", dts: "data/shapes/balls/ball-superball.dts", skin: "skin26"},
			{name: "Molten", dts: "data/shapes/balls/ball-superball.dts", skin: "skin27"},
			{name: "Lightning", dts: "data/shapes/balls/ball-superball.dts", skin: "skin28"},
			{name: "Phil'sEmpire", dts: "data/shapes/balls/ball-superball.dts", skin: "skin29"},
			{name: "Matan's Red Dragon", dts: "data/shapes/balls/ball-superball.dts", skin: "skin30"},
			{name: "Metallic Marble", dts: "data/shapes/balls/ball-superball.dts", skin: "skin31"},
			{name: "Sun", dts: "data/shapes/balls/ball-superball.dts", skin: "skin32"},
			{name: "Underwater", dts: "data/shapes/balls/ball-superball.dts", skin: "skin33"},
			{name: "GarageGames logo", dts: "data/shapes/balls/garageGames.dts", skin: "base"},
			{name: "Big Marble 1", dts: "data/shapes/balls/bm1.dts", skin: "base"},
			{name: "Big Marble 2", dts: "data/shapes/balls/bm2.dts", skin: "base"},
			{name: "Big Marble 3", dts: "data/shapes/balls/bm3.dts", skin: "base"},
			{name: "Small Marble 1", dts: "data/shapes/balls/sm1.dts", skin: "base"},
			{name: "Small Marble 2", dts: "data/shapes/balls/sm2.dts", skin: "base"},
			{name: "Small Marble 3", dts: "data/shapes/balls/sm3.dts", skin: "base"},
		];

		var curSelection:Int = Settings.optionsSettings.marbleIndex;

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
			Settings.optionsSettings.marbleSkin = marbleData[curSelection].skin;
			Settings.optionsSettings.marbleModel = marbleData[curSelection].dts;
			Settings.save();
			MarbleGame.canvas.popDialog(this);
		}
		this.addChild(selectBtn);

		var marbleShow = buildObjectShow(marbleData[curSelection].dts, new Vector(171, 97), new Vector(150, 150), 2.6, 0,
			["base.marble" => marbleData[curSelection].skin + ".marble"]);
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
		titleText.text.text = '<p align="center">Official Marbles</p>';
		this.addChild(titleText);

		var marbleText = new GuiMLText(markerFelt24, null);
		marbleText.text.textColor = 0xFFFFFF;
		marbleText.text.filter = new DropShadow(1.414, 0.785, 0, 1, 0x0000007F, 0.4, 1, true);
		marbleText.horizSizing = Center;
		marbleText.vertSizing = Bottom;
		marbleText.position = new Vector(86, 243);
		marbleText.extent = new Vector(320, 22);
		marbleText.text.text = '<p align="center">${marbleData[curSelection].name}</p>';
		this.addChild(marbleText);

		var changeMarbleText = new GuiImage(ResourceLoader.getResource("data/ui/play/change_marble_text.png", ResourceLoader.getImage, this.imageResources)
			.toTile());
		changeMarbleText.horizSizing = Center;
		changeMarbleText.position = new Vector(96, 26);
		changeMarbleText.extent = new Vector(300, 39);
		this.addChild(changeMarbleText);

		function setMarbleSelection(idx:Int) {
			if (idx < 0)
				idx = marbleData.length + idx;
			if (idx >= marbleData.length)
				idx -= marbleData.length;
			curSelection = idx;
			var marble = marbleData[idx];

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
			setMarbleSelection(curSelection + 1);
		}
		this.addChild(nextBtn);

		var prevBtn = new GuiButton(loadButtonImages("data/ui/marbleSelect/prev"));
		prevBtn.position = new Vector(123, 270);
		prevBtn.extent = new Vector(75, 45);
		prevBtn.pressedAction = (e) -> {
			setMarbleSelection(curSelection - 1);
		}
		setMarbleSelection(curSelection);
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
