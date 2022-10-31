package gui;

import h3d.shader.AlphaChannel;
import src.DtsObject;
import hxd.res.BitmapFont;
import h3d.Vector;
import src.ResourceLoader;
import src.MarbleGame;
import hxd.Key;
import src.Settings;
import src.Util;

class HelpCreditsGui extends GuiImage {
	var page = 0;
	var hcText:GuiMLText;
	var hcText2:GuiMLText;
	var startPadCtrl:GuiObjectShow;
	var endPadCtrl:GuiObjectShow;
	var gem1Ctrl:GuiObjectShow;
	var gem2Ctrl:GuiObjectShow;
	var gem3Ctrl:GuiObjectShow;
	var superSpeedCtrl:GuiObjectShow;
	var superJumpCtrl:GuiObjectShow;
	var shockAbsorberCtrl:GuiObjectShow;
	var helicopterCtrl:GuiObjectShow;
	var timeTravelCtrl:GuiObjectShow;
	var antiGravityCtrl:GuiObjectShow;
	var ductFanCtrl:GuiObjectShow;
	var tornadoCtrl:GuiObjectShow;
	var trapdoorCtrl:GuiObjectShow;
	var oilSlickCtrl:GuiObjectShow;
	var landMineCtrl:GuiObjectShow;
	var bumperCtrl:GuiObjectShow;
	var superBounceCtrl:GuiObjectShow;

	public function new() {
		var img = ResourceLoader.getImage("data/ui/background.jpg");
		super(img.resource.toTile());
		this.position = new Vector();
		this.extent = new Vector(640, 480);
		this.horizSizing = Width;
		this.vertSizing = Height;

		var helpGui = new GuiImage(ResourceLoader.getResource("data/ui/help/help_gui.png", ResourceLoader.getImage, this.imageResources).toTile());
		helpGui.horizSizing = Center;
		helpGui.vertSizing = Center;
		helpGui.position = new Vector(15, 10);
		helpGui.extent = new Vector(609, 460);
		this.addChild(helpGui);

		function loadButtonImages(path:String) {
			var normal = ResourceLoader.getResource('${path}_n.png', ResourceLoader.getImage, this.imageResources).toTile();
			var hover = ResourceLoader.getResource('${path}_h.png', ResourceLoader.getImage, this.imageResources).toTile();
			var pressed = ResourceLoader.getResource('${path}_d.png', ResourceLoader.getImage, this.imageResources).toTile();
			return [normal, hover, pressed];
		}

		var nextButton = new GuiButton(loadButtonImages("data/ui/play/next"));
		nextButton.position = new Vector(482, 376);
		nextButton.extent = new Vector(75, 60);
		nextButton.pressedAction = (sender) -> nextPage();
		helpGui.addChild(nextButton);

		var prevButton = new GuiButton(loadButtonImages("data/ui/play/prev"));
		prevButton.position = new Vector(58, 383);
		prevButton.extent = new Vector(77, 58);
		prevButton.pressedAction = (sender) -> previousPage();
		helpGui.addChild(prevButton);

		var homeButton = new GuiButton(loadButtonImages("data/ui/play/back"));
		homeButton.position = new Vector(278, 378);
		homeButton.extent = new Vector(79, 61);
		homeButton.pressedAction = (sender) -> {
			MarbleGame.canvas.setContent(new MainMenuGui());
		}
		helpGui.addChild(homeButton);

		var helpWindow = new GuiImage(ResourceLoader.getResource("data/ui/help/help_window.png", ResourceLoader.getImage, this.imageResources).toTile());
		helpWindow.position = new Vector(30, 31);
		helpWindow.extent = new Vector(549, 338);
		helpGui.addChild(helpWindow);

		var arial14fontdata = ResourceLoader.getFileEntry("data/font/arial.fnt");
		var arial14b = new BitmapFont(arial14fontdata.entry);
		@:privateAccess arial14b.loader = ResourceLoader.loader;
		var arial14 = arial14b.toSdfFont(cast 12 * Settings.uiScale, MultiChannel);

		var domcasual32fontdata = ResourceLoader.getFileEntry("data/font/DomCasualD.fnt");
		var domcasual32b = new BitmapFont(domcasual32fontdata.entry);
		@:privateAccess domcasual32b.loader = ResourceLoader.loader;
		var domcasual32 = domcasual32b.toSdfFont(cast 26 * Settings.uiScale, MultiChannel);

		var expo50fontdata = ResourceLoader.getFileEntry("data/font/EXPON.fnt");
		var expo50b = new BitmapFont(expo50fontdata.entry);
		@:privateAccess expo50b.loader = ResourceLoader.loader;
		var expo50 = expo50b.toSdfFont(cast 35 * Settings.uiScale, MultiChannel);
		var expo32 = expo50b.toSdfFont(cast 24 * Settings.uiScale, MultiChannel);

		function mlFontLoader(text:String) {
			switch (text) {
				case "DomCasual32":
					return domcasual32;
				case "Arial14":
					return arial14;
				case "Expo32":
					return expo32;
				case "Expo50":
					return expo50;
				default:
					return null;
			}
		}

		hcText = new GuiMLText(domcasual32, mlFontLoader);
		hcText.position = new Vector(40, 24);
		hcText.extent = new Vector(488, 274);
		hcText.text.textColor = 0;
		hcText.text.lineSpacing = 5;
		helpWindow.addChild(hcText);

		hcText2 = new GuiMLText(domcasual32, mlFontLoader);
		hcText2.position = new Vector(40, 24);
		hcText2.extent = new Vector(488, 274);
		hcText2.text.textColor = 0;
		hcText2.text.lineSpacing = 5;
		helpWindow.addChild(hcText2);

		startPadCtrl = buildObjectShow("data/shapes/pads/startarea.dts", new Vector(30, 82), new Vector(79, 66), 8, 0.5);
		helpWindow.addChild(startPadCtrl);

		endPadCtrl = buildObjectShow("data/shapes/pads/endarea.dts", new Vector(31, 146), new Vector(79, 66), 8, 0.5);
		helpWindow.addChild(endPadCtrl);

		gem1Ctrl = buildObjectShow("data/shapes/items/gem.dts", new Vector(17, 234), new Vector(79, 66), 2.5, 0.4);
		helpWindow.addChild(gem1Ctrl);

		gem2Ctrl = buildObjectShow("data/shapes/items/gem.dts", new Vector(43, 215), new Vector(79, 66), 2.5, 0.4, ["base.gem" => "purple.gem"]);
		helpWindow.addChild(gem2Ctrl);

		gem3Ctrl = buildObjectShow("data/shapes/items/gem.dts", new Vector(45, 250), new Vector(79, 66), 2.5, 0.4, ["base.gem" => "green.gem"]);
		helpWindow.addChild(gem3Ctrl);

		superSpeedCtrl = buildObjectShow("data/shapes/items/superspeed.dts", new Vector(30, 73), new Vector(79, 66), 3.5, 0.35);
		helpWindow.addChild(superSpeedCtrl);

		superJumpCtrl = buildObjectShow("data/shapes/items/superjump.dts", new Vector(31, 137), new Vector(79, 66), 3.5, 0.35);
		helpWindow.addChild(superJumpCtrl);

		shockAbsorberCtrl = buildObjectShow("data/shapes/items/shockabsorber.dts", new Vector(33, 204), new Vector(72, 61), 3.5, 0.35);
		helpWindow.addChild(shockAbsorberCtrl);

		superBounceCtrl = buildObjectShow("data/shapes/items/superbounce.dts", new Vector(35, 260), new Vector(72, 61), 3.5, 0.35);
		helpWindow.addChild(superBounceCtrl);

		helicopterCtrl = buildObjectShow("data/shapes/images/helicopter.dts", new Vector(30, 82), new Vector(79, 66), 2, 0.35);
		helpWindow.addChild(helicopterCtrl);

		timeTravelCtrl = buildObjectShow("data/shapes/items/timetravel.dts", new Vector(31, 146), new Vector(79, 66), 3.5, 0.35);
		helpWindow.addChild(timeTravelCtrl);

		antiGravityCtrl = buildObjectShow("data/shapes/items/antigravity.dts", new Vector(35, 217), new Vector(72, 61), 3.5, 0.35);
		helpWindow.addChild(antiGravityCtrl);

		ductFanCtrl = buildObjectShow("data/shapes/hazards/ductfan.dts", new Vector(30, 82), new Vector(79, 66), 4, 0.5);
		helpWindow.addChild(ductFanCtrl);

		tornadoCtrl = buildObjectShow("data/shapes/hazards/tornado.dts", new Vector(26, 155), new Vector(91, 66), 18, 0.35);
		for (mat in tornadoCtrl.sceneObject.materials) {
			mat.blendMode = None;
		}
		helpWindow.addChild(tornadoCtrl);

		trapdoorCtrl = buildObjectShow("data/shapes/hazards/trapdoor.dts", new Vector(35, 217), new Vector(77, 76), 8, 0.35);
		helpWindow.addChild(trapdoorCtrl);

		oilSlickCtrl = buildObjectShow("data/shapes/hazards/oilslick.dts", new Vector(35, 217), new Vector(77, 76), 8, 0.35);
		helpWindow.addChild(oilSlickCtrl);

		landMineCtrl = buildObjectShow("data/shapes/hazards/landmine.dts", new Vector(26, 155), new Vector(91, 66), 1.5, 0.35);
		helpWindow.addChild(landMineCtrl);

		bumperCtrl = buildObjectShow("data/shapes/bumpers/pball_round.dts", new Vector(30, 82), new Vector(79, 66), 1.8, 0.5);
		helpWindow.addChild(bumperCtrl);

		redrawPage();
	}

	function redrawPage() {
		page = cast Util.adjustedMod(page, 12);

		if (page == 0) {
			hcText2.text.text = "";
			hcText.text.text = '<font face="Arial14"><br/></font><font face="Expo50"><p align="center">Overview</p></font><br/>'
				+
				"Roll your marble through a rich cartoon landscape of moving platforms and dangerous hazards. Along the way find power ups to increase your speed, jumping ability or flight power, and use them to collect the hidden gems and race to the finish for the fastest time.";
		}
		if (page == 1) {
			hcText2.text.text = "";
			hcText.text.text = '<font face="Arial14"><br/></font><font face="Expo50"><p align="center">Basic Controls</p></font><br/>'
				+
				formatText("The marble can be moved forward, back, left and right by pressing <func:bind moveforward>, <func:bind movebackward>, <func:bind moveleft> and <func:bind moveright>, respectively.  Pressing <func:bind jump> causes the marble to jump, and pressing <func:bind mouseFire> uses whatever powerup you currently have available.  All movement is relative to the view direction.");
		}
		if (page == 2) {
			startPadCtrl.visible = false;
			endPadCtrl.visible = false;
			gem1Ctrl.visible = false;
			gem2Ctrl.visible = false;
			gem3Ctrl.visible = false;
			hcText2.text.text = "";
			hcText.text.text = '<font face="Arial14"><br/></font><font face="Expo50"><p align="center">Camera Controls</p></font><br/>'
				+
				formatText("The camera direction can be changed by moving the mouse or by pressing <func:bind panUp>, <func:bind panDown>, <func:bind turnLeft> or <func:bind turnRight>.  In order to look up and down freely with the mouse, hold down <func:bind freelook>.  You can turn free look on always from the Mouse pane of the Control Options screen.");
			startPadCtrl.render(MarbleGame.canvas.scene2d);
			endPadCtrl.render(MarbleGame.canvas.scene2d);
			gem1Ctrl.render(MarbleGame.canvas.scene2d);
			gem2Ctrl.render(MarbleGame.canvas.scene2d);
			gem3Ctrl.render(MarbleGame.canvas.scene2d);
		}
		if (page == 3) {
			startPadCtrl.visible = true;
			endPadCtrl.visible = true;
			gem1Ctrl.visible = true;
			gem2Ctrl.visible = true;
			gem3Ctrl.visible = true;
			superJumpCtrl.visible = false;
			superSpeedCtrl.visible = false;
			shockAbsorberCtrl.visible = false;
			superBounceCtrl.visible = false;
			hcText.text.text = '<font face="Arial14"><br/></font><font face="Expo50"><p align="center">Goals</p></font><br/>';
			hcText2.position = new Vector(110, 41);
			hcText2.extent = new Vector(418, 274);
			hcText2.text.text = "<br/><br/>Start Pad - this is where you start the level.<br/><br/>End Pad - roll your marble here to end the level.<br/><br/>Gems - if a level has gems, you must pick them all up before you can exit.";
			startPadCtrl.render(MarbleGame.canvas.scene2d);
			endPadCtrl.render(MarbleGame.canvas.scene2d);
			gem1Ctrl.render(MarbleGame.canvas.scene2d);
			gem2Ctrl.render(MarbleGame.canvas.scene2d);
			gem3Ctrl.render(MarbleGame.canvas.scene2d);
			hcText2.render(MarbleGame.canvas.scene2d);
			superJumpCtrl.render(MarbleGame.canvas.scene2d);
			superSpeedCtrl.render(MarbleGame.canvas.scene2d);
			shockAbsorberCtrl.render(MarbleGame.canvas.scene2d);
			superBounceCtrl.render(MarbleGame.canvas.scene2d);
		}
		if (page == 4) {
			startPadCtrl.visible = false;
			endPadCtrl.visible = false;
			gem1Ctrl.visible = false;
			gem2Ctrl.visible = false;
			gem3Ctrl.visible = false;
			superJumpCtrl.visible = true;
			superSpeedCtrl.visible = true;
			shockAbsorberCtrl.visible = true;
			superBounceCtrl.visible = true;
			helicopterCtrl.visible = false;
			timeTravelCtrl.visible = false;
			antiGravityCtrl.visible = false;
			hcText.text.text = '<font face="Arial14"><br/></font><font face="Expo50"><p align="center">Bonus Items (1/2)</p></font><br/>';
			hcText2.position = new Vector(110, 30);
			hcText2.extent = new Vector(418, 274);
			hcText2.text.text = "<br/><br/>Super Speed PowerUp - gives you a burst of speed.<br/><br/>Super Jump PowerUp - gives you a big jump up.<br/><br/>Shock Absorber PowerUp - absorbs bounce impacts.<br/><br/>Super Bounce PowerUp - makes you bounce higher.";
			startPadCtrl.render(MarbleGame.canvas.scene2d);
			endPadCtrl.render(MarbleGame.canvas.scene2d);
			gem1Ctrl.render(MarbleGame.canvas.scene2d);
			gem2Ctrl.render(MarbleGame.canvas.scene2d);
			gem3Ctrl.render(MarbleGame.canvas.scene2d);
			hcText2.render(MarbleGame.canvas.scene2d);
			superJumpCtrl.render(MarbleGame.canvas.scene2d);
			superSpeedCtrl.render(MarbleGame.canvas.scene2d);
			shockAbsorberCtrl.render(MarbleGame.canvas.scene2d);
			superBounceCtrl.render(MarbleGame.canvas.scene2d);
			helicopterCtrl.render(MarbleGame.canvas.scene2d);
			timeTravelCtrl.render(MarbleGame.canvas.scene2d);
			antiGravityCtrl.render(MarbleGame.canvas.scene2d);
		}
		if (page == 5) {
			superJumpCtrl.visible = false;
			superSpeedCtrl.visible = false;
			shockAbsorberCtrl.visible = false;
			superBounceCtrl.visible = false;
			helicopterCtrl.visible = true;
			timeTravelCtrl.visible = true;
			antiGravityCtrl.visible = true;
			ductFanCtrl.visible = false;
			tornadoCtrl.visible = false;
			trapdoorCtrl.visible = false;
			hcText.text.text = '<font face="Arial14"><br/></font><font face="Expo50"><p align="center">Bonus Items (2/2)</p></font><br/>';
			hcText2.position = new Vector(110, 35);
			hcText2.extent = new Vector(418, 274);
			hcText2.text.text = "<br/><br/>Gyrocopter PowerUp - slows your fall in the air.<br/><br/>Time Travel - takes some time off the clock.<br/><br/>Gravity Modifier - Changes the direction of \"down\" - the new down is in the direction of the arrow.";
			hcText2.render(MarbleGame.canvas.scene2d);
			superJumpCtrl.render(MarbleGame.canvas.scene2d);
			superSpeedCtrl.render(MarbleGame.canvas.scene2d);
			shockAbsorberCtrl.render(MarbleGame.canvas.scene2d);
			superBounceCtrl.render(MarbleGame.canvas.scene2d);
			helicopterCtrl.render(MarbleGame.canvas.scene2d);
			timeTravelCtrl.render(MarbleGame.canvas.scene2d);
			antiGravityCtrl.render(MarbleGame.canvas.scene2d);
			ductFanCtrl.render(MarbleGame.canvas.scene2d);
			tornadoCtrl.render(MarbleGame.canvas.scene2d);
			trapdoorCtrl.render(MarbleGame.canvas.scene2d);
		}
		if (page == 6) {
			helicopterCtrl.visible = false;
			timeTravelCtrl.visible = false;
			antiGravityCtrl.visible = false;
			ductFanCtrl.visible = true;
			tornadoCtrl.visible = true;
			trapdoorCtrl.visible = true;
			bumperCtrl.visible = false;
			landMineCtrl.visible = false;
			oilSlickCtrl.visible = false;
			hcText.text.text = '<font face="Arial14"><br/></font><font face="Expo50"><p align="center">Hazards (1/2)</p></font><br/>';
			hcText2.position = new Vector(110, 38);
			hcText2.extent = new Vector(418, 274);
			hcText2.text.text = "<br/><br/>Duct Fan - be careful this doesn't blow you away!<br/><br/>Tornado - it'll pull you in and spit you out.<br/><br/>Trap Door - keep moving when you're rolling over one of these.";
			hcText2.render(MarbleGame.canvas.scene2d);
			helicopterCtrl.render(MarbleGame.canvas.scene2d);
			timeTravelCtrl.render(MarbleGame.canvas.scene2d);
			antiGravityCtrl.render(MarbleGame.canvas.scene2d);
			ductFanCtrl.render(MarbleGame.canvas.scene2d);
			tornadoCtrl.render(MarbleGame.canvas.scene2d);
			trapdoorCtrl.render(MarbleGame.canvas.scene2d);
			bumperCtrl.render(MarbleGame.canvas.scene2d);
			landMineCtrl.render(MarbleGame.canvas.scene2d);
			oilSlickCtrl.render(MarbleGame.canvas.scene2d);
		}
		if (page == 7) {
			ductFanCtrl.visible = false;
			tornadoCtrl.visible = false;
			trapdoorCtrl.visible = false;
			bumperCtrl.visible = true;
			landMineCtrl.visible = true;
			oilSlickCtrl.visible = true;
			hcText.text.text = '<font face="Arial14"><br/></font><font face="Expo50"><p align="center">Hazards (2/2)</p></font><br/>';
			hcText2.position = new Vector(110, 30);
			hcText2.extent = new Vector(418, 274);
			hcText2.text.text = "<br/><br/>Bumper - this'll bounce you if you touch it.<br/><br/>Land Mine - Warning!  Explodes on contact!<br/><br/>Oil Slick - you won't have much traction on these surfaces";
			hcText2.render(MarbleGame.canvas.scene2d);
			ductFanCtrl.render(MarbleGame.canvas.scene2d);
			tornadoCtrl.render(MarbleGame.canvas.scene2d);
			trapdoorCtrl.render(MarbleGame.canvas.scene2d);
			bumperCtrl.render(MarbleGame.canvas.scene2d);
			landMineCtrl.render(MarbleGame.canvas.scene2d);
			oilSlickCtrl.render(MarbleGame.canvas.scene2d);
		}
		if (page == 8) {
			bumperCtrl.visible = false;
			landMineCtrl.visible = false;
			oilSlickCtrl.visible = false;
			hcText2.text.text = "";
			hcText.text.text = '<font face="Arial14"><br/></font><font face="Expo50"><p align="center">About GarageGames</p></font><br/>'
				+
				"GarageGames is a unique Internet publishing label for independent games and gamemakers.  Our mission is to provide the independent developer with tools, knowledge, co-conspirators - whatever is needed to unleash the creative spirit and get great innovative independent games to market.";
			bumperCtrl.render(MarbleGame.canvas.scene2d);
			landMineCtrl.render(MarbleGame.canvas.scene2d);
			oilSlickCtrl.render(MarbleGame.canvas.scene2d);
		}
		if (page == 9) {
			hcText2.text.text = "";
			hcText.text.text = '<font face="Arial14"><br/></font><font face="Expo50"><p align="center">About the Torque</p></font><br/>'
				+
				"The Torque Game Engine (TGE) is a full featured AAA title engine with the latest in scripting, geometry, particle effects, animation and texturing, as well as award winning multi-player networking code.  For $100 per programmer, you get the source to the engine!";
		}
		if (page == 10) {
			hcText.text.text = '<font face="Arial14"><br/></font><font face="Expo50"><p align="center">The Marble Blast Team</p></font><br/>'
				+ "ÂAlex Swanson<br/>ÂJeff Tunnell<br/>ÂLiam Ryan<br/>ÂRick Overman<br/>ÂTimothy Clarke<br/>ÂPat Wilson";
			hcText2.position = new Vector(343, 24);
			hcText2.extent = new Vector(155, 274);
			hcText2.text.text = '<font face="Arial14"><br/></font><font face="Expo50"><p align="center"> </p></font><br/>'
				+ "Mark Frohnmayer<br/>Brian Hahn<br/>Tim Gift<br/>Kevin Ryan<br/>Jay Moore<br/>John Quigley";
			hcText2.render(MarbleGame.canvas.scene2d);
		}
		if (page == 11) {
			hcText2.text.text = "";
			hcText.text.text = '<font face="Arial14"><br/></font><font face="Expo50"><p align="center">Special Thanks</p></font><br/>'
				+ "We'd like to thank Nullsoft, for the SuperPiMP Install System, "
				+ "and Markus F.X.J. Oberhumer, Laszlo Molnar and the rest of the UPX team for the UPX executable packer."
				+ "  Thanks also to Kurtis Seebaldt for his work on integrating Ogg/Vorbis streaming into the Torque engine, and to the Ogg/Vorbis team.";
		}
	}

	function nextPage() {
		page++;
		redrawPage();
	}

	function previousPage() {
		page--;
		redrawPage();
	}

	function formatText(text:String) {
		var start = 0;
		var pos = text.indexOf("<func:", start);
		while (pos != -1) {
			var end = text.indexOf(">", start + 5);
			if (end == -1)
				break;
			var pre = text.substr(0, pos);
			var post = text.substr(end + 1);
			var func = text.substr(pos + 6, end - (pos + 6));
			var funcdata = func.split(' ').map(x -> x.toLowerCase());
			var val = "";
			if (funcdata[0] == "bind") {
				if (funcdata[1] == "moveforward")
					val = Util.getKeyForButton(Settings.controlsSettings.forward);
				if (funcdata[1] == "movebackward")
					val = Util.getKeyForButton(Settings.controlsSettings.backward);
				if (funcdata[1] == "moveleft")
					val = Util.getKeyForButton(Settings.controlsSettings.left);
				if (funcdata[1] == "moveright")
					val = Util.getKeyForButton(Settings.controlsSettings.right);
				if (funcdata[1] == "panup")
					val = Util.getKeyForButton(Settings.controlsSettings.camForward);
				if (funcdata[1] == "pandown")
					val = Util.getKeyForButton(Settings.controlsSettings.camBackward);
				if (funcdata[1] == "turnleft")
					val = Util.getKeyForButton(Settings.controlsSettings.camLeft);
				if (funcdata[1] == "turnright")
					val = Util.getKeyForButton(Settings.controlsSettings.camRight);
				if (funcdata[1] == "jump")
					val = Util.getKeyForButton(Settings.controlsSettings.jump);
				if (funcdata[1] == "mousefire")
					val = Util.getKeyForButton(Settings.controlsSettings.powerup);
				if (funcdata[1] == "freelook")
					val = Util.getKeyForButton(Settings.controlsSettings.freelook);
			}
			start = val.length + pos;
			text = pre + val + post;
			pos = text.indexOf("<func:", start);
		}
		return text;
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
