package gui;

import net.NetCommands;
import net.Net;
import h3d.shader.AlphaChannel;
import hxd.res.BitmapFont;
import src.MarbleGame;
import src.ResourceLoader;
import h3d.Vector;
import src.Settings;
import src.DtsObject;

class MPEndGameGui extends GuiImage {
	public function new() {
		var img = ResourceLoader.getImage('data/ui/exit/black.png');
		super(img.resource.toTile());
		this.horizSizing = Width;
		this.vertSizing = Height;
		this.position = new Vector(0, 0);
		this.extent = new Vector(640, 480);

		var domcasual24fontdata = ResourceLoader.getFileEntry("data/font/DomCasualD.fnt");
		var domcasual24b = new BitmapFont(domcasual24fontdata.entry);
		@:privateAccess domcasual24b.loader = ResourceLoader.loader;
		var domcasual24 = domcasual24b.toSdfFont(cast 20 * Settings.uiScale, MultiChannel);

		var domcasual36 = domcasual24b.toSdfFont(cast 32 * Settings.uiScale, MultiChannel);

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

		var expo50fontdata = ResourceLoader.getFileEntry("data/font/EXPON.fnt");
		var expo50b = new BitmapFont(expo50fontdata.entry);
		@:privateAccess expo50b.loader = ResourceLoader.loader;
		var expo50 = expo50b.toSdfFont(cast 35 * Settings.uiScale, MultiChannel);

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

		function loadButtonImages(path:String) {
			var normal = ResourceLoader.getResource('${path}_n.png', ResourceLoader.getImage, this.imageResources).toTile();
			var hover = ResourceLoader.getResource('${path}_h.png', ResourceLoader.getImage, this.imageResources).toTile();
			var pressed = ResourceLoader.getResource('${path}_d.png', ResourceLoader.getImage, this.imageResources).toTile();
			return [normal, hover, pressed];
		}

		function loadButtonImagesExt(path:String) {
			var normal = ResourceLoader.getResource('${path}_n.png', ResourceLoader.getImage, this.imageResources).toTile();
			var hover = ResourceLoader.getResource('${path}_h.png', ResourceLoader.getImage, this.imageResources).toTile();
			var pressed = ResourceLoader.getResource('${path}_d.png', ResourceLoader.getImage, this.imageResources).toTile();
			var disabled = ResourceLoader.getResource('${path}_i.png', ResourceLoader.getImage, this.imageResources).toTile();
			return [normal, hover, pressed, disabled];
		}

		var sidebar = new GuiImage(ResourceLoader.getResource("data/ui/mp/end/window.png", ResourceLoader.getImage, this.imageResources).toTile());
		sidebar.position = new Vector(587, 141);
		sidebar.extent = new Vector(53, 198);
		sidebar.horizSizing = Left;
		sidebar.vertSizing = Center;
		this.addChild(sidebar);

		var lobbyBtn = new GuiButton(loadButtonImagesExt("data/ui/mp/end/lobby"));
		lobbyBtn.position = new Vector(5, 53);
		lobbyBtn.extent = new Vector(49, 49);
		lobbyBtn.vertSizing = Top;
		lobbyBtn.pressedAction = (e) -> {
			MarbleGame.instance.quitMission();
		}
		if (Net.isClient) {
			lobbyBtn.disabled = true;
		}
		sidebar.addChild(lobbyBtn);

		var restartBtn = new GuiButton(loadButtonImagesExt("data/ui/mp/end/restart"));
		restartBtn.position = new Vector(5, 7);
		restartBtn.extent = new Vector(49, 49);
		restartBtn.pressedAction = (e) -> {
			MarbleGame.canvas.popDialog(this);
			MarbleGame.instance.paused = false;
			NetCommands.completeRestartGame();
		}
		if (Net.isClient) {
			restartBtn.disabled = true;
		}
		sidebar.addChild(restartBtn);

		var exitBtn = new GuiButton(loadButtonImagesExt("data/ui/mp/end/exit"));
		exitBtn.position = new Vector(5, 99);
		exitBtn.extent = new Vector(49, 49);
		exitBtn.vertSizing = Top;
		exitBtn.horizSizing = Left;
		sidebar.addChild(exitBtn);

		var middleCtrl = new GuiControl();
		middleCtrl.horizSizing = Center;
		middleCtrl.vertSizing = Height;
		middleCtrl.position = new Vector(-80, 0);
		middleCtrl.extent = new Vector(800, 480);
		this.addChild(middleCtrl);

		var headerML = new GuiText(domcasual36);
		headerML.position = new Vector(25, 83);
		headerML.extent = new Vector(750, 14);
		headerML.horizSizing = Width;
		headerML.text.textColor = 0xFFFFFF;
		headerML.text.text = "   Name                        Score                      Marble";
		middleCtrl.addChild(headerML);

		var scores = @:privateAccess MarbleGame.instance.world.playGui.playerList;
		var ourRank = scores.indexOf(scores.filter(x -> x.us == true)[0]) + 1;
		var rankSuffix = ourRank == 1 ? "st" : (ourRank == 2 ? "nd" : (ourRank == 3 ? "rd" : "th"));

		var col0 = 0xCFB52B;
		var col1 = 0xCDCDCD;
		var col2 = 0xD19275;
		var col3 = 0xFFEE99;

		var rankColor = ourRank == 1 ? col0 : (ourRank == 2 ? col1 : (ourRank == 3 ? col2 : col3));

		var titleML = new GuiText(expo50);
		titleML.position = new Vector(25, 6);
		titleML.extent = new Vector(750, 14);
		titleML.justify = Center;
		titleML.horizSizing = Width;
		titleML.text.textColor = rankColor;
		titleML.text.dropShadow = {
			dx: 1,
			dy: 1,
			alpha: 0.5,
			color: 0
		};
		titleML.text.text = 'You have won ' + ourRank + rankSuffix + ' place!';
		middleCtrl.addChild(titleML);

		var redGem = buildObjectShow("data/shapes/items/gem.dts", new Vector(365, 65), new Vector(64, 64), 2.5, 0, ["base.gem" => "red.gem"]);
		middleCtrl.addChild(redGem);
		var yellowGem = buildObjectShow("data/shapes/items/gem.dts", new Vector(417, 65), new Vector(64, 64), 2.5, 0, ["base.gem" => "yellow.gem"]);
		middleCtrl.addChild(yellowGem);
		var blueGem = buildObjectShow("data/shapes/items/gem.dts", new Vector(469, 65), new Vector(64, 64), 2.5, 0, ["base.gem" => "blue.gem"]);
		middleCtrl.addChild(blueGem);

		var playerContainer = new GuiControl();
		playerContainer.horizSizing = Center;
		playerContainer.vertSizing = Height;
		playerContainer.position = new Vector(25, 125);
		playerContainer.extent = new Vector(750, 275);
		middleCtrl.addChild(playerContainer);

		var idx = 0;

		function addPlayer(rank:Int, playerName:String, score:Int, r:Int, y:Int, b:Int, marbleCat:Int, marbleSel:Int) {
			var container = new GuiControl();
			container.position = new Vector(0, 44 * idx);
			container.extent = new Vector(750, 44);

			var playerNameT = new GuiText(domcasual36);
			playerNameT.text.textColor = 0xFFFFFF;
			playerNameT.text.text = '${rank}. ${playerName}';
			playerNameT.position = new Vector(0, 3);
			playerNameT.extent = new Vector(300, 14);
			container.addChild(playerNameT);

			var playerScore = new GuiText(domcasual36);
			playerScore.text.textColor = 0xFFFFFF;
			playerScore.text.text = '${score}';
			playerScore.position = new Vector(287, 3);
			playerScore.extent = new Vector(310, 14);
			container.addChild(playerScore);

			var playerR = new GuiText(domcasual36);
			playerR.text.textColor = 0xFF0000;
			playerR.text.text = '${r}';
			playerR.justify = Center;
			playerR.position = new Vector(348, 3);
			playerR.extent = new Vector(52, 14);
			container.addChild(playerR);

			var playerY = new GuiText(domcasual36);
			playerY.text.textColor = 0xFFFF00;
			playerY.text.text = '${y}';
			playerY.justify = Center;
			playerY.position = new Vector(400, 3);
			playerY.extent = new Vector(52, 14);
			container.addChild(playerY);

			var playerB = new GuiText(domcasual36);
			playerB.text.textColor = 0x0000FF;
			playerB.text.text = '${b}';
			playerB.justify = Center;
			playerB.position = new Vector(452, 3);
			playerB.extent = new Vector(52, 14);
			container.addChild(playerB);

			var marble = buildObjectShow(MarbleSelectGui.marbleData[marbleCat][marbleSel].dts, new Vector(524, -10), new Vector(64, 64), 2.4, 0, [
				"base.marble" => MarbleSelectGui.marbleData[marbleCat][marbleSel].skin + ".marble"
			]);

			container.addChild(marble);

			playerContainer.addChild(container);

			idx += 1;
		}

		var r = 1;
		for (player in scores) {
			var cat = Settings.optionsSettings.marbleCategoryIndex;
			var marb = Settings.optionsSettings.marbleIndex;
			if (!player.us) {
				var c = Net.clientIdMap[player.id];
				cat = c.marbleCatId;
				marb = c.marbleId;
			}

			addPlayer(r, player.name, player.score, player.r, player.y, player.b, cat, marb);
			r += 1;
		}
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
