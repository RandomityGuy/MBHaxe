package gui;

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

	public function new() {
		super(ResourceLoader.getImage("data/ui/background.jpg").toTile());
		this.position = new Vector();
		this.extent = new Vector(640, 480);
		this.horizSizing = Width;
		this.vertSizing = Height;

		var helpGui = new GuiImage(ResourceLoader.getImage("data/ui/help/help_gui.png").toTile());
		helpGui.horizSizing = Center;
		helpGui.vertSizing = Center;
		helpGui.position = new Vector(15, 10);
		helpGui.extent = new Vector(609, 460);
		this.addChild(helpGui);

		function loadButtonImages(path:String) {
			var normal = ResourceLoader.getImage('${path}_n.png').toTile();
			var hover = ResourceLoader.getImage('${path}_h.png').toTile();
			var pressed = ResourceLoader.getImage('${path}_d.png').toTile();
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

		var helpWindow = new GuiImage(ResourceLoader.getImage("data/ui/help/help_window.png").toTile());
		helpWindow.position = new Vector(30, 31);
		helpWindow.extent = new Vector(549, 338);
		helpGui.addChild(helpWindow);

		var arial14fontdata = ResourceLoader.loader.load("data/font/Arial14.fnt");
		var arial14 = new BitmapFont(arial14fontdata.entry);
		@:privateAccess arial14.loader = ResourceLoader.loader;

		var domcasual32fontdata = ResourceLoader.loader.load("data/font/DomCasual32px.fnt");
		var domcasual32 = new BitmapFont(domcasual32fontdata.entry);
		@:privateAccess domcasual32.loader = ResourceLoader.loader;

		var expo50fontdata = ResourceLoader.loader.load("data/font/Expo50.fnt");
		var expo50 = new BitmapFont(expo50fontdata.entry);
		@:privateAccess expo50.loader = ResourceLoader.loader;

		var expo32fontdata = ResourceLoader.loader.load("data/font/Expo32.fnt");
		var expo32 = new BitmapFont(expo32fontdata.entry);
		@:privateAccess expo32.loader = ResourceLoader.loader;

		function mlFontLoader(text:String) {
			switch (text) {
				case "DomCasual32":
					return domcasual32.toFont();
				case "Arial14":
					return arial14.toFont();
				case "Expo32":
					return expo32.toFont();
				case "Expo50":
					return expo50.toFont();
				default:
					return null;
			}
		}

		hcText = new GuiMLText(domcasual32, mlFontLoader);
		hcText.position = new Vector(40, 24);
		hcText.extent = new Vector(488, 274);
		hcText.text.textColor = 0;
		helpWindow.addChild(hcText);

		hcText2 = new GuiMLText(domcasual32, mlFontLoader);
		hcText2.position = new Vector(40, 24);
		hcText2.extent = new Vector(488, 274);
		hcText2.text.textColor = 0;
		helpWindow.addChild(hcText2);

		redrawPage();
	}

	function redrawPage() {
		page = cast Util.adjustedMod(page, 12);

		if (page == 0) {
			hcText2.text.text = "";
			hcText.text.text = '<font face="Expo50"><p align="center">Overview</p></font><br/>'
				+
				"Roll your marble through a rich cartoon landscape of moving platforms and dangerous hazards.  Along the way find power ups to increase your speed, jumping ability or flight power, and use them to collect the hidden gems and race to the finish for the fastest time.";
		}
		if (page == 1) {
			hcText2.text.text = "";
			hcText.text.text = '<font face="Expo50"><p align="center">Basic Controls</p></font><br/>'
				+
				formatText("The marble can be moved forward, back, left and right by pressing <func:bind moveforward>, <func:bind movebackward>, <func:bind moveleft> and <func:bind moveright>, respectively.  Pressing <func:bind jump> causes the marble to jump, and pressing <func:bind mouseFire> uses whatever powerup you currently have available.  All movement is relative to the view direction.");
		}
		if (page == 2) {
			hcText2.text.text = "";
			hcText.text.text = '<font face="Expo50"><p align="center">Camera Controls</p></font><br/>'
				+
				formatText("The camera direction can be changed by moving the mouse or by pressing <func:bind panUp>, <func:bind panDown>, <func:bind turnLeft> or <func:bind turnRight>.  In order to look up and down freely with the mouse, hold down <func:bind freelook>.  You can turn free look on always from the Mouse pane of the Control Options screen.");
		}
		if (page == 3) {
			hcText.text.text = '<font face="Expo50"><p align="center">Goals</p></font><br/>';
			hcText2.position = new Vector(110, 24);
			hcText2.extent = new Vector(418, 274);
			hcText2.text.text = "<br/><br/>Start Pad - this is where you start the level.<br/><br/>End Pad - roll your marble here to end the level.<br/><br/>Gems - if a level has gems, you must pick them all up before you can exit.";
			hcText2.render(MarbleGame.canvas.scene2d);
		}
		if (page == 4) {
			hcText.text.text = '<font face="Expo50"><p align="center">Bonus Items (1/2)</p></font><br/>';
			hcText2.position = new Vector(110, 24);
			hcText2.extent = new Vector(418, 274);
			hcText2.text.text = "<br/><br/>Super Speed PowerUp - gives you a burst of speed.<br/><br/>Super Jump PowerUp - gives you a big jump up.<br/><br/>Shock Absorber PowerUp - absorbs bounce impacts.<br/><br/>Super Bounce PowerUp - makes you bounce higher.";
			hcText2.render(MarbleGame.canvas.scene2d);
		}
		if (page == 5) {
			hcText.text.text = '<font face="Expo50"><p align="center">Bonus Items (2/2)</p></font><br/>';
			hcText2.position = new Vector(110, 24);
			hcText2.extent = new Vector(418, 274);
			hcText2.text.text = "<br/><br/>Gyrocopter PowerUp - slows your fall in the air.<br/><br/>Time Travel - takes some time off the clock.<br/><br/>Gravity Modifier - Changes the direction of \"down\" - the new down is in the direction of the arrow.";
			hcText2.render(MarbleGame.canvas.scene2d);
		}
		if (page == 6) {
			hcText.text.text = '<font face="Expo50"><p align="center">Hazards (1/2)</p></font><br/>';
			hcText2.position = new Vector(110, 24);
			hcText2.extent = new Vector(418, 274);
			hcText2.text.text = "<br/><br/>Duct Fan - be careful this doesn't blow you away!<br/><br/>Tornado - it'll pull you in and spit you out.<br/><br/>Trap Door - keep moving when you're rolling over one of these.";
			hcText2.render(MarbleGame.canvas.scene2d);
		}
		if (page == 7) {
			hcText.text.text = '<font face="Expo50"><p align="center">Hazards (2/2)</p></font><br/>';
			hcText2.position = new Vector(110, 24);
			hcText2.extent = new Vector(418, 274);
			hcText2.text.text = "<br/><br/>Bumper - this'll bounce you if you touch it.<br/><br/>Land Mine - Warning!  Explodes on contact!<br/><br/>Oil Slick - you won't have much traction on these surfaces";
			hcText2.render(MarbleGame.canvas.scene2d);
		}
		if (page == 8) {
			hcText2.text.text = "";
			hcText.text.text = '<font face="Expo50"><p align="center">About GarageGames</p></font><br/>'
				+
				"GarageGames is a unique Internet publishing label for independent games and gamemakers.  Our mission is to provide the independent developer with tools, knowledge, co-conspirators - whatever is needed to unleash the creative spirit and get great innovative independent games to market.";
		}
		if (page == 9) {
			hcText2.text.text = "";
			hcText.text.text = '<font face="Expo50"><p align="center">About the Torque</p></font><br/>'
				+
				"The Torque Game Engine (TGE) is a full featured AAA title engine with the latest in scripting, geometry, particle effects, animation and texturing, as well as award winning multi-player networking code.  For $100 per programmer, you get the source to the engine!";
		}
		if (page == 10) {
			hcText.text.text = '<font face="Expo50"><p align="center">The Marble Blast Team</p></font><br/>'
				+ "ÂAlex Swanson<br/>ÂJeff Tunnell<br/>ÂLiam Ryan<br/>ÂRick Overman<br/>ÂTimothy Clarke<br/>ÂPat Wilson";
			hcText2.position = new Vector(343, 24);
			hcText2.extent = new Vector(155, 274);
			hcText2.text.text = '<font face="Expo50"><p align="center"> </p></font><br/>'
				+ "Mark Frohnmayer<br/>Brian Hahn<br/>Tim Gift<br/>Kevin Ryan<br/>Jay Moore<br/>John Quigley";
			hcText2.render(MarbleGame.canvas.scene2d);
		}
		if (page == 11) {
			hcText2.text.text = "";
			hcText.text.text = '<font face="Expo50"><p align="center">Special Thanks</p></font><br/>'
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
					val = Key.getKeyName(Settings.controlsSettings.forward);
				if (funcdata[1] == "movebackward")
					val = Key.getKeyName(Settings.controlsSettings.backward);
				if (funcdata[1] == "moveleft")
					val = Key.getKeyName(Settings.controlsSettings.left);
				if (funcdata[1] == "moveright")
					val = Key.getKeyName(Settings.controlsSettings.right);
				if (funcdata[1] == "panup")
					val = Key.getKeyName(Settings.controlsSettings.camForward);
				if (funcdata[1] == "pandown")
					val = Key.getKeyName(Settings.controlsSettings.camBackward);
				if (funcdata[1] == "turnleft")
					val = Key.getKeyName(Settings.controlsSettings.camLeft);
				if (funcdata[1] == "turnright")
					val = Key.getKeyName(Settings.controlsSettings.camRight);
				if (funcdata[1] == "jump")
					val = Key.getKeyName(Settings.controlsSettings.jump);
				if (funcdata[1] == "mousefire")
					val = Key.getKeyName(Settings.controlsSettings.powerup);
				if (funcdata[1] == "freelook")
					val = Key.getKeyName(Settings.controlsSettings.freelook);
			}
			start = val.length + pos;
			text = pre + val + post;
			pos = text.indexOf("<func:", start);
		}
		return text;
	}
}
