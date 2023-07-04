package gui;

import gui.GuiControl.MouseState;
import h2d.Scene;
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
	var wndTxt:GuiMLText;
	var wndTxtBg:GuiMLText;
	var curScroll:Float = -50;
	var doScroll = false;

	var innerCtrl:GuiControl;

	public function new(index:Int, pauseGui:Bool = false) {
		var res = ResourceLoader.getImage("data/ui/xbox/BG_fadeOutSoftEdge.png").resource.toTile();
		super(res);
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

		var titles = [
			"POWERUPS",
			"BLAST METER",
			"SINGLE PLAYER MODE",
			"MULTIPLAYER MODE",
			"MARBLE CONTROLS",
			"CREDITS"
		];

		var rootTitle = new GuiText(coliseum);
		rootTitle.position = new Vector(100, 30);
		rootTitle.extent = new Vector(1120, 80);
		rootTitle.text.textColor = 0xFFFFFF;
		rootTitle.text.text = titles[index];
		rootTitle.text.alpha = 0.5;
		innerCtrl.addChild(rootTitle);

		var wnd = new GuiImage(ResourceLoader.getResource("data/ui/xbox/helpWindow.png", ResourceLoader.getImage, this.imageResources).toTile());
		wnd.position = new Vector(260, 107);
		wnd.extent = new Vector(736, 460);
		wnd.horizSizing = Right;
		wnd.vertSizing = Bottom;
		innerCtrl.addChild(wnd);

		var arial14fontdata = ResourceLoader.getFileEntry("data/font/Arial Bold.fnt");
		var arial14b = new BitmapFont(arial14fontdata.entry);
		@:privateAccess arial14b.loader = ResourceLoader.loader;
		var arial14 = arial14b.toSdfFont(cast 21 * Settings.uiScale, h2d.Font.SDFChannel.MultiChannel);
		var arial14big = arial14b.toSdfFont(cast 30 * Settings.uiScale, h2d.Font.SDFChannel.MultiChannel);
		var arial14med = arial14b.toSdfFont(cast 26 * Settings.uiScale, h2d.Font.SDFChannel.MultiChannel);
		function mlFontLoader(text:String) {
			switch (text) {
				case "ArialBig":
					return arial14big;
				case "ArialMed":
					return arial14med;
				default:
					return arial14;
			}
		}

		var credits1 = '<p align="center"><font face="ArialBig"><br/>GarageGames Team</font><br/><br/><font face="ArialMed">Development</font><br/>Tim Aste<br/>Jane Chase<br/>Timothy Clarke<br/>Adam deGrandis<br/>Clark Fagot<br/>Matt Fairfax<br/>Mark Frohnmayer<br/>Ben Garney<br/>Tim Gift<br/>Davey Jackson<br/>Justin Kovac<br/>Joe Maruschak<br/>Mark McCoy<br/>Jay Moore<br/>Rick Overman<br/>John Quigley<br/>Brian Ramage<br/>Kevin Ryan<br/>Liam Ryan<br/>Alex Swanson<br/>Jeff Tunnell<br/>Pat Wilson<br/><br/><font face="ArialMed">Special Thanks</font><br/>Cafe Aroma<br/>Cafe Yumm!<br/>Mezza Luna Pizzeria<br/>Pizza Research Institute<br/>The GarageGames Community</p>';
		var credits2 = '<p align="center"><font face="ArialBig">Xbox Live Arcade Team</font><br/><br/><font face="ArialMed">Program Management</font><br/>Katie Stone<br/>Jon David<br/><br/><font face="ArialMed">Test Manager</font><br/>Tony Harlich<br/><br/><font face="ArialMed">Test</font><br/>Michael Jones<br/>Chad Dylan Long (VMC)<br/>Eric Snyder (VMC)<br/>Noriko Fritschle (VMC)<br/>Kevin Hathaway (VMC)<br/>Ty Roberts (VMC)<br/><br/><font face="ArialMed">Release Manager</font><br/>Julie Pitt (VOLT)<br/><br/><font face="ArialMed">Development</font><br/>Brian Ostergren<br/>Eric Heutchy<br/>Eric Fleegal<br/><br/><font face="ArialMed">Group Manager</font><br/>Greg Canessa<br/><br/><font face="ArialMed">Product Planning</font><br/>Ross Erickson<br/>Cherie Lutz<br/><br/><font face="ArialMed">Content Creation</font><br/>Michelle Lomba<br/><br/><font face="ArialMed">Usability</font><br/>Tom Fuller<br/>Chuck Harrison<br/><br/><font face="ArialMed">Special Thanks</font><br/>J Allard<br/>Shane Kim<br/>Don Ryan<br/>Chris Early<br/>Oliver Miyashita<br/>Mike Minahan<br/>VMC Consulting<br/>Ami Blaire<br/>Darryl Saunders<br/>Aaron Greenberg<br/>Michael Wolf<br/>David Hufford<br/>Darren Trencher</p>';
		var credits3 = '<p align="center"><font face="ArialBig">Localization</font><br/><br/><font face="ArialMed">Japan Localization Team</font><br/>Shinya Muto<br/>Junya Chiba<br/>Go Komatsu<br/>Mayumi Koike<br/>Takehiro Kuga<br/>Masao Okamoto<br/>Yutaka Hasegawa<br/>Munetaka Fuse<br/>Takashi Sasaki<br/>Shinji Komiyama<br/><br/><font face="ArialMed">Korea Localization Team</font><br/>Eun Hee Lee<br/>In Goo Kwon<br/>Whi Young Yoon<br/>Ji Young Kim<br/><br/><font face="ArialMed">Taiwan Localization Team</font><br/>Robert Lin<br/>Carole Lin<br/>Lilia Lee<br/>Jason Cheng</p>';

		var texts = [
			"There are many powerups that will help you along.  To collect a powerup, roll over it.  It will appear in the powerup window.<br/><br/>On an Xbox 360 Controller, Pull the right trigger or press B to activate the powerup; Otherwise use left click or the Q key.",
			"The Marble has a blast ability which gives you a slight upward boost.  Use it wisely!<br/><br/>The Blast meter shows the current level of blast that you have available.  It regenerates slowly over time.<br/><br/>On an Xbox 360 Controller, Press X or the right bumper to use your current blast power; Otherwise, use Right Click or the E key.<br/><br/>Collect the Ultra Blast powerup to instantly fill your blast meter - and then some!",
			"Get to the End Pad of each level as fast as possible.<br/><br/>Start Pad - You start the level here.<br/><br/>End Pad - Roll your marble here to end the level.<br/><br/>Gems - Some levels have gems.  You must pick up all of them before you can end the level.<br/><br/>Time Travel - Roll through these to temporarily pause the clock.",
			"Race to the gems and pick them up to earn points.  Get as many gems as you can, but be ready to go when the next group appears!<br/><br/>Some gems are worth more points than others.  More valuable gems are usually harder to reach.<br/><br/>View the leaderboards to compare your ranking with other players around the world.",
			"Xbox 360 Controller:<br/>Use the left stick to move the marble. <br/><br/>Press A or pull the left trigger to make the marble jump.<br/><br/>Use the right stick to look around with the camera.<br/><br/>Keyboard and Mouse:<br/>Use the WASD keys to move.<br/>Move the mouse to look around.<br/>Press Space to Jump."
		];
		texts.push(credits1 + "<br/>" + credits2 + "<br/>" + credits3);

		if (index == 5)
			doScroll = true;

		var textCtrl = new GuiControl();
		textCtrl.position = new Vector(30, 33);
		textCtrl.extent = new Vector(683, 403);
		wnd.addChild(textCtrl);

		wndTxtBg = new GuiMLText(arial14, mlFontLoader);
		wndTxtBg.position = new Vector(2, 7);
		wndTxtBg.extent = new Vector(683, 343);
		wndTxtBg.text.textColor = 0x101010;
		wndTxtBg.text.text = texts[index];
		wndTxtBg.scrollable = true;
		textCtrl.addChild(wndTxtBg);

		wndTxt = new GuiMLText(arial14, mlFontLoader);
		wndTxt.position = new Vector(0, 5);
		wndTxt.extent = new Vector(683, 343);
		wndTxt.text.textColor = 0xEBEBEB;
		wndTxt.text.text = texts[index];
		wndTxt.scrollable = true;
		textCtrl.addChild(wndTxt);

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
		if (pauseGui)
			if (index == 5)
				backButton.pressedAction = (e) -> {
					MarbleGame.canvas.popDialog(this);
					MarbleGame.canvas.pushDialog(new OptionsListGui(true));
				}
			else
				backButton.pressedAction = (e) -> {
					MarbleGame.canvas.popDialog(this);
					MarbleGame.canvas.pushDialog(new AboutMenuOptionsGui(true));
				}
		else {
			if (index == 5)
				backButton.pressedAction = (e) -> MarbleGame.canvas.setContent(new OptionsListGui());
			else
				backButton.pressedAction = (e) -> MarbleGame.canvas.setContent(new AboutMenuOptionsGui());
		}
		bottomBar.addChild(backButton);
	}

	override function update(dt:Float, mouseState:MouseState) {
		super.update(dt, mouseState);

		if (doScroll) {
			curScroll += dt * 20;

			var realScroll = Math.max(curScroll, 0);

			wndTxt.onScroll(0, realScroll);
			wndTxtBg.onScroll(0, realScroll);
		}
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
