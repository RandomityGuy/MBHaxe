package gui;

import src.MarbleGame;
import hxd.res.BitmapFont;
import h3d.Vector;
import src.ResourceLoader;
import src.Settings;
import src.Util;

class OptionsListGui extends GuiImage {
	var innerCtrl:GuiControl;

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
		rootTitle.text.text = "HELP & OPTIONS";
		rootTitle.text.alpha = 0.5;
		innerCtrl.addChild(rootTitle);

		var btnList = new GuiXboxList();
		btnList.position = new Vector(70 - offsetX, 165);
		btnList.horizSizing = Left;
		btnList.extent = new Vector(502, 500);
		innerCtrl.addChild(btnList);

		if (!pauseGui) {
			btnList.addButton(3, 'Marble Appearance', (e) -> {
				MarbleGame.canvas.setContent(new MarblePickerGui());
			});
		}
		btnList.addButton(3, 'Input and Sound Options', (e) -> {
			MarbleGame.canvas.setContent(new InputOptionsGui(pauseGui));
		});

		btnList.addButton(3, 'Input Controls', (e) -> {
			MarbleGame.canvas.setContent(new InputSelectGui(pauseGui));
		});

		btnList.addButton(3, 'Video Options', (e) -> {
			MarbleGame.canvas.setContent(new VideoOptionsGui(pauseGui));
		});
		if (!pauseGui) {
			btnList.addButton(3, 'Misc Options', (e) -> {
				MarbleGame.canvas.setContent(new MiscOptionsGui(pauseGui));
			});
		}
		btnList.addButton(5, 'How to Play', (e) -> {
			MarbleGame.canvas.setContent(new AboutMenuOptionsGui(pauseGui));
		});
		btnList.addButton(5, 'Credits', (e) -> {
			MarbleGame.canvas.setContent(new HelpCreditsGui(5, pauseGui));
		});

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
		backButton.accelerators = [hxd.Key.ESCAPE, hxd.Key.BACKSPACE];
		if (pauseGui)
			backButton.pressedAction = (e) -> {
				MarbleGame.canvas.popDialog(this);
				MarbleGame.instance.showPauseUI();
			}
		else
			backButton.pressedAction = (e) -> MarbleGame.canvas.setContent(new MainMenuGui());
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
