package gui;

import src.Marble;
import src.MarbleGame;
import gui.GuiControl.MouseState;
import hxd.res.BitmapFont;
import h3d.Vector;
import src.ResourceLoader;
import src.Settings;

class MarblePickerGui extends GuiImage {
	var innerCtrl:GuiControl;

	static var marbleData = [
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
	];

	public function new() {
		var res = ResourceLoader.getImage("data/ui/game/CloudBG.jpg").resource.toTile();
		super(res);

		var fadeEdge = new GuiImage(ResourceLoader.getResource("data/ui/xbox/BG_fadeOutSoftEdge.png", ResourceLoader.getImage, this.imageResources).toTile());
		fadeEdge.position = new Vector(0, 0);
		fadeEdge.extent = new Vector(640, 480);
		fadeEdge.vertSizing = Height;
		fadeEdge.horizSizing = Width;
		this.addChild(fadeEdge);

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
		rootTitle.text.text = "SELECT MARBLE APPEARANCE";
		rootTitle.text.alpha = 0.5;
		innerCtrl.addChild(rootTitle);
		var myMarb:Marble = null;

		var prevPreview = @:privateAccess MarbleGame.instance.previewWorld.currentMission;

		MarbleGame.instance.setPreviewMission("marblepicker", () -> {
			this.bmp.visible = false;
			@:privateAccess MarbleGame.instance.previewWorld.spawnMarble(marb -> {
				var spawnPos = @:privateAccess MarbleGame.instance.scene.camera.pos.add(new Vector(0, 1, 1));
				var velAdd = new Vector((1 - 2 * Math.random()) * 2, (1 - 2 * Math.random()) * 1.5, (1 - 2 * Math.random()) * 1);
				velAdd = velAdd.add(new Vector(0, 3, 0));
				marb.setMarblePosition(spawnPos.x, spawnPos.y, spawnPos.z);
				marb.velocity.load(velAdd);
				myMarb = marb;
			});
		}, true);

		var yPos = 160;

		var mbOpt = new GuiXboxOptionsList(1, "Marble Type", marbleData.map(x -> x.name), 0.5, 118);
		mbOpt.vertSizing = Bottom;
		mbOpt.horizSizing = Right;
		mbOpt.alwaysActive = true;
		mbOpt.position = new Vector(380, yPos);
		mbOpt.extent = new Vector(815, 94);
		mbOpt.setCurrentOption(Settings.optionsSettings.marbleIndex);
		var curToken = 0;

		mbOpt.onChangeFunc = (idx) -> {
			var selectedMarble = marbleData[idx];
			Settings.optionsSettings.marbleIndex = idx;
			Settings.optionsSettings.marbleCategoryIndex = 0;
			Settings.optionsSettings.marbleSkin = selectedMarble.skin;
			Settings.optionsSettings.marbleModel = selectedMarble.dts;
			Settings.optionsSettings.marbleShader = selectedMarble.shader;
			ResourceLoader.load(Settings.optionsSettings.marbleModel).entry.load(() -> {
				if (changeToken + 1 != curToken)
					return;
				@:privateAccess MarbleGame.instance.previewWorld.removeMarble(myMarb);
				@:privateAccess MarbleGame.instance.previewWorld.spawnMarble(marb -> {
					if (changeToken + 1 != curToken) {
						@:privateAccess MarbleGame.instance.previewWorld.removeMarble(marb);
						return;
					}
					var spawnPos = @:privateAccess MarbleGame.instance.scene.camera.pos.add(new Vector(0, 1, 1));
					var velAdd = new Vector((1 - 2 * Math.random()) * 2, (1 - 2 * Math.random()) * 1.5, (1 - 2 * Math.random()) * 1);
					velAdd = velAdd.add(new Vector(0, 3, 0));
					marb.setMarblePosition(spawnPos.x, spawnPos.y, spawnPos.z);
					marb.velocity.load(velAdd);
					myMarb = marb;
				});
			});
			return true;
		}
		innerCtrl.addChild(mbOpt);

		var bottomBar = new GuiControl();
		bottomBar.position = new Vector(0, 590);
		bottomBar.extent = new Vector(640, 200);
		bottomBar.horizSizing = Width;
		bottomBar.vertSizing = Bottom;
		innerCtrl.addChild(bottomBar);

		var backButton = new GuiXboxButton("Ok", 160);
		backButton.position = new Vector(960, 0);
		backButton.vertSizing = Bottom;
		backButton.horizSizing = Right;
		backButton.gamepadAccelerator = ["A"];
		backButton.accelerators = [hxd.Key.ENTER];
		backButton.pressedAction = (e) -> {
			this.bmp.visible = true;
			mbOpt.onChangeFunc = (e) -> {
				return false;
			}; // Fix that marbug
			MarbleGame.instance.setPreviewMission(prevPreview, () -> {
				MarbleGame.canvas.setContent(new OptionsListGui());
			}, false);
		};

		bottomBar.addChild(backButton);
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
