package gui;

import hxd.Key;
import src.MarbleGame;
import hxd.res.BitmapFont;
import h3d.Vector;
import src.ResourceLoader;
import src.Settings;

class AboutMenuOptionsGui extends GuiImage {
	var innerCtrl:GuiControl;
	var btnList:GuiXboxList;

	public function new(pauseGui:Bool = false) {
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

		#if hl
		var scene2d = hxd.Window.getInstance();
		#end
		#if js
		var scene2d = MarbleGame.instance.scene2d;
		#end

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
		rootTitle.text.text = "HOW TO PLAY";
		rootTitle.text.alpha = 0.5;
		innerCtrl.addChild(rootTitle);

		btnList = new GuiXboxList();
		btnList.position = new Vector(70 - offsetX, 165);
		btnList.horizSizing = Left;
		btnList.extent = new Vector(502, 500);
		innerCtrl.addChild(btnList);

		if (pauseGui) {
			btnList.addButton(5, 'Marble Controls', (e) -> {
				MarbleGame.canvas.popDialog(this);
				MarbleGame.canvas.pushDialog(new HelpCreditsGui(4, true));
			});
			btnList.addButton(5, 'Powerups', (e) -> {
				MarbleGame.canvas.popDialog(this);
				MarbleGame.canvas.pushDialog(new HelpCreditsGui(0, true));
			});
			btnList.addButton(5, 'Blast Meter', (e) -> {
				MarbleGame.canvas.popDialog(this);
				MarbleGame.canvas.pushDialog(new HelpCreditsGui(1, true));
			});
			btnList.addButton(5, 'Single Player Mode', (e) -> {
				MarbleGame.canvas.popDialog(this);
				MarbleGame.canvas.pushDialog(new HelpCreditsGui(2, true));
			});
			btnList.addButton(5, 'Multiplayer Mode', (e) -> {
				MarbleGame.canvas.popDialog(this);
				MarbleGame.canvas.pushDialog(new HelpCreditsGui(3, true));
			});
		} else {
			btnList.addButton(5, 'Marble Controls', (e) -> {
				MarbleGame.canvas.setContent(new HelpCreditsGui(4));
			});
			btnList.addButton(5, 'Powerups', (e) -> {
				MarbleGame.canvas.setContent(new HelpCreditsGui(0));
			});
			btnList.addButton(5, 'Blast Meter', (e) -> {
				MarbleGame.canvas.setContent(new HelpCreditsGui(1));
			});
			btnList.addButton(5, 'Single Player Mode', (e) -> {
				MarbleGame.canvas.setContent(new HelpCreditsGui(2));
			});
			btnList.addButton(5, 'Multiplayer Mode', (e) -> {
				MarbleGame.canvas.setContent(new HelpCreditsGui(3));
			});
		}

		var bottomBar = new GuiControl();
		bottomBar.position = new Vector(0, 590);
		bottomBar.extent = new Vector(640, 200);
		bottomBar.horizSizing = Width;
		bottomBar.vertSizing = Bottom;
		innerCtrl.addChild(bottomBar);

		var backButton = new GuiXboxButton("Back", 160);
		backButton.position = new Vector(400, 0);
		backButton.vertSizing = Bottom;
		backButton.horizSizing = Right;
		backButton.gamepadAccelerator = [Settings.gamepadSettings.back];
		backButton.accelerators = [Key.ESCAPE, Key.BACKSPACE];
		if (pauseGui)
			backButton.pressedAction = (e) -> {
				MarbleGame.canvas.popDialog(this);
				MarbleGame.canvas.pushDialog(new OptionsListGui(true));
			}
		else
			backButton.pressedAction = (e) -> MarbleGame.canvas.setContent(new OptionsListGui());
		bottomBar.addChild(backButton);
	}

	override function onResize(width:Int, height:Int) {
		var offsetX = (width - 1280) / 2;
		var offsetY = (height - 720) / 2;

		var subX = 640 - (width - offsetX) * 640 / width;
		var subY = 480 - (height - offsetY) * 480 / height;
		innerCtrl.position = new Vector(offsetX, offsetY);
		innerCtrl.extent = new Vector(640 - subX, 480 - subY);
		btnList.position = new Vector(70 - offsetX, 165);

		super.onResize(width, height);
	}
}
