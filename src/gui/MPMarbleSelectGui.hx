package gui;

import net.Net;
import net.NetCommands;
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

class MPMarbleSelectGui extends GuiImage {
	public function new() {
		var img = ResourceLoader.getImage("data/ui/mp/team/teamcreate.png");
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

		var selectBtn = new GuiButton(loadButtonImages("data/ui/mp/play/choose"));
		selectBtn.horizSizing = Center;
		selectBtn.vertSizing = Top;
		selectBtn.position = new Vector(199, 270);
		selectBtn.extent = new Vector(95, 45);
		selectBtn.pressedAction = (e) -> {
			Settings.optionsSettings.marbleIndex = curSelection;
			Settings.optionsSettings.marbleCategoryIndex = curCategorySelection;
			Settings.optionsSettings.marbleSkin = MarbleSelectGui.marbleData[curCategorySelection][curSelection].skin;
			Settings.optionsSettings.marbleModel = MarbleSelectGui.marbleData[curCategorySelection][curSelection].dts;
			Settings.optionsSettings.marbleShader = MarbleSelectGui.marbleData[curCategorySelection][curSelection].shader;
			Settings.save();
			MarbleGame.canvas.popDialog(this);

			// Transmit changes to the server/clients
			if (Net.isClient) {
				NetCommands.setPlayerData(Net.clientId, Settings.highscoreName, Settings.optionsSettings.marbleIndex,
					Settings.optionsSettings.marbleCategoryIndex, true);
			}
			if (Net.isHost) {
				var b = Net.sendPlayerInfosBytes();
				for (cc in Net.clients) {
					cc.sendBytes(b);
				}
			}
		}
		this.addChild(selectBtn);

		var marbleShow = buildObjectShow(MarbleSelectGui.marbleData[curCategorySelection][curSelection].dts, new Vector(171, 97), new Vector(150, 150), 2.6,
			0, [
				"base.marble" => MarbleSelectGui.marbleData[curCategorySelection][curSelection].skin + ".marble"
			]);
		marbleShow.horizSizing = Center;
		marbleShow.vertSizing = Bottom;
		marbleShow.visible = true;
		this.addChild(marbleShow);

		var titleText = new GuiMLText(markerFelt28, null);
		titleText.text.textColor = 0xFFFFFF;
		titleText.text.dropShadow = {
			dx: 1 * Settings.uiScale,
			dy: 1 * Settings.uiScale,
			alpha: 0.5,
			color: 0
		};
		titleText.horizSizing = Center;
		titleText.vertSizing = Bottom;
		titleText.position = new Vector(140, 67);
		titleText.extent = new Vector(213, 27);
		titleText.text.text = '<p align="center">${categoryNames[curCategorySelection]}</p>';
		this.addChild(titleText);

		var marbleText = new GuiMLText(markerFelt24, null);
		marbleText.text.textColor = 0xFFFFFF;
		marbleText.text.dropShadow = {
			dx: 1 * Settings.uiScale,
			dy: 1 * Settings.uiScale,
			alpha: 0.5,
			color: 0
		};
		marbleText.horizSizing = Center;
		marbleText.vertSizing = Bottom;
		marbleText.position = new Vector(86, 243);
		marbleText.extent = new Vector(320, 22);
		marbleText.text.text = '<p align="center">${MarbleSelectGui.marbleData[curCategorySelection][curSelection].name}</p>';
		this.addChild(marbleText);

		var changeMarbleText = new GuiImage(ResourceLoader.getResource("data/ui/play/change_marble_text.png", ResourceLoader.getImage, this.imageResources)
			.toTile());
		changeMarbleText.horizSizing = Center;
		changeMarbleText.position = new Vector(96, 26);
		changeMarbleText.extent = new Vector(300, 39);
		this.addChild(changeMarbleText);

		function setMarbleSelection(idx:Int, categoryIdx:Int) {
			if (categoryIdx < 0)
				categoryIdx = MarbleSelectGui.marbleData.length + categoryIdx;
			if (categoryIdx >= MarbleSelectGui.marbleData.length)
				categoryIdx -= MarbleSelectGui.marbleData.length;

			if (idx < 0)
				idx = MarbleSelectGui.marbleData[categoryIdx].length + idx;
			if (idx >= MarbleSelectGui.marbleData[categoryIdx].length)
				idx -= MarbleSelectGui.marbleData[categoryIdx].length;
			curSelection = idx;
			curCategorySelection = categoryIdx;
			var marble = MarbleSelectGui.marbleData[categoryIdx][idx];

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

		var nextBtn = new GuiButton(loadButtonImages("data/ui/mp/play/next"));
		nextBtn.position = new Vector(296, 270);
		nextBtn.extent = new Vector(75, 45);
		nextBtn.pressedAction = (e) -> {
			setMarbleSelection(curSelection + 1, curCategorySelection);
		}
		this.addChild(nextBtn);

		var prevBtn = new GuiButton(loadButtonImages("data/ui/mp/play/prev"));
		prevBtn.position = new Vector(123, 270);
		prevBtn.extent = new Vector(75, 45);
		prevBtn.pressedAction = (e) -> {
			setMarbleSelection(curSelection - 1, curCategorySelection);
		}

		var nextCategoryBtn = new GuiButton(loadButtonImages("data/ui/mp/play/nextcat"));
		nextCategoryBtn.position = new Vector(371, 270);
		nextCategoryBtn.extent = new Vector(85, 45);
		nextCategoryBtn.pressedAction = (e) -> {
			setMarbleSelection(0, curCategorySelection + 1);
		}
		this.addChild(nextCategoryBtn);

		var prevCategoryBtn = new GuiButton(loadButtonImages("data/ui/mp/play/prevcat"));
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
