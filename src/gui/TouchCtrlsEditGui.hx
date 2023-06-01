package gui;

import hxd.res.BitmapFont;
import h3d.prim.Quads;
import touch.TouchEditButton;
import touch.MovementInputEdit;
import h3d.Vector;
import src.ResourceLoader;
import src.MarbleGame;
import src.Settings;

class TouchCtrlsEditGui extends GuiImage {
	public function new() {
		var img = ResourceLoader.getImage("data/ui/background.jpg");
		super(img.resource.toTile());
		this.horizSizing = Width;
		this.vertSizing = Height;
		this.position = new Vector();
		this.extent = new Vector(640, 480);

		function loadButtonImages(path:String) {
			var normal = ResourceLoader.getResource('${path}_n.png', ResourceLoader.getImage, this.imageResources).toTile();
			var hover = ResourceLoader.getResource('${path}_h.png', ResourceLoader.getImage, this.imageResources).toTile();
			var pressed = ResourceLoader.getResource('${path}_d.png', ResourceLoader.getImage, this.imageResources).toTile();
			return [normal, hover, pressed];
		}

		var domcasual32fontdata = ResourceLoader.getFileEntry("data/font/DomCasualD.fnt");
		var domcasual32b = new BitmapFont(domcasual32fontdata.entry);
		@:privateAccess domcasual32b.loader = ResourceLoader.loader;
		var domcasual32 = domcasual32b.toSdfFont(cast 26 * Settings.uiScale, MultiChannel);

		var mainMenuButton = new GuiButton(loadButtonImages("data/ui/options/mainm"));
		mainMenuButton.position = new Vector(500, 400);
		mainMenuButton.extent = new Vector(121, 53);
		mainMenuButton.horizSizing = Left;
		mainMenuButton.vertSizing = Top;
		mainMenuButton.pressedAction = (sender) -> {
			MarbleGame.canvas.setContent(new OptionsDlg());
		}

		var touchControlsTxt = new GuiText(domcasual32);
		touchControlsTxt.position = new Vector(350, 415);
		touchControlsTxt.extent = new Vector(121, 53);
		touchControlsTxt.text.text = "Edit Touch Controls";
		touchControlsTxt.horizSizing = Center;
		touchControlsTxt.vertSizing = Top;
		touchControlsTxt.text.textColor = 0;

		var joystick = new MovementInputEdit();

		var jumpBtn = new TouchEditButton(ResourceLoader.getImage("data/ui/touch/up-arrow.png").resource,
			new Vector(Settings.touchSettings.jumpButtonPos[0], Settings.touchSettings.jumpButtonPos[1]), Settings.touchSettings.jumpButtonSize);

		var powerupBtn = new TouchEditButton(ResourceLoader.getImage("data/ui/touch/energy.png").resource,
			new Vector(Settings.touchSettings.powerupButtonPos[0], Settings.touchSettings.powerupButtonPos[1]), Settings.touchSettings.powerupButtonSize);

		var rewindBtn = new TouchEditButton(ResourceLoader.getImage("data/ui/touch/rewind.png").resource,
			new Vector(Settings.touchSettings.rewindButtonPos[0], Settings.touchSettings.rewindButtonPos[1]), Settings.touchSettings.rewindButtonSize);

		jumpBtn.onClick = (sender, mousePos) -> {
			sender.setSelected(true);
			powerupBtn.setSelected(false);
			joystick.setSelected(false);
			rewindBtn.setSelected(false);
		}

		jumpBtn.onChangeCb = (sender, value, rvalue) -> {
			Settings.touchSettings.jumpButtonPos = [value.x, value.y];
			Settings.touchSettings.jumpButtonSize = rvalue;
		}

		powerupBtn.onClick = (sender, mousePos) -> {
			sender.setSelected(true);
			jumpBtn.setSelected(false);
			joystick.setSelected(false);
			rewindBtn.setSelected(false);
		}

		powerupBtn.onChangeCb = (sender, value, rvalue) -> {
			Settings.touchSettings.powerupButtonPos = [value.x, value.y];
			Settings.touchSettings.powerupButtonSize = rvalue;
		}

		rewindBtn.onClick = (sender, mousePos) -> {
			sender.setSelected(true);
			jumpBtn.setSelected(false);
			powerupBtn.setSelected(false);
			joystick.setSelected(false);
		}

		rewindBtn.onChangeCb = (sender, value, rvalue) -> {
			Settings.touchSettings.rewindButtonPos = [value.x, value.y];
			Settings.touchSettings.rewindButtonSize = rvalue;
		}

		joystick.onClick = (mousePos) -> {
			joystick.setSelected(true);
			jumpBtn.setSelected(false);
			powerupBtn.setSelected(false);
			rewindBtn.setSelected(false);
		}

		joystick.onChangeCb = (value, rvalue) -> {
			Settings.touchSettings.joystickPos = [value.x, value.y];
			Settings.touchSettings.joystickSize = rvalue;
		}

		this.addChild(mainMenuButton);
		this.addChild(touchControlsTxt);
		this.addChild(joystick);
		this.addChild(jumpBtn);
		this.addChild(powerupBtn);
		this.addChild(rewindBtn);
	}
}
