package gui;

import hxd.res.BitmapFont;
import h3d.prim.Quads;
import touch.TouchEditButton;
import touch.MovementInputEdit;
import h3d.Vector;
import src.ResourceLoader;
import src.MarbleGame;
import src.Settings;
import src.Util;

class TouchCtrlsEditGui extends GuiImage {
	public function new() {
		function chooseBg() {
			var rand = Math.random();
			if (rand >= 0 && rand <= 0.244)
				return ResourceLoader.getImage('data/ui/backgrounds/gold/${cast (Math.floor(Util.lerp(1, 12, Math.random())), Int)}.jpg');
			if (rand > 0.244 && rand <= 0.816)
				return ResourceLoader.getImage('data/ui/backgrounds/platinum/${cast (Math.floor(Util.lerp(1, 28, Math.random())), Int)}.jpg');
			return ResourceLoader.getImage('data/ui/backgrounds/ultra/${cast (Math.floor(Util.lerp(1, 9, Math.random())), Int)}.jpg');
		}
		var img = chooseBg();
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

		var mainMenuButton = new GuiButton(loadButtonImages("data/ui/menu/options"));
		mainMenuButton.position = new Vector(380, 15);
		mainMenuButton.extent = new Vector(247, 164);
		mainMenuButton.horizSizing = Left;
		mainMenuButton.vertSizing = Bottom;
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

		var blastBtn = new TouchEditButton(ResourceLoader.getImage("data/ui/touch/explosion.png").resource,
			new Vector(Settings.touchSettings.blastButtonPos[0], Settings.touchSettings.blastButtonPos[1]), Settings.touchSettings.blastButtonSize);

		jumpBtn.onClick = (sender, mousePos) -> {
			sender.setSelected(true);
			powerupBtn.setSelected(false);
			joystick.setSelected(false);
			blastBtn.setSelected(false);
		}

		jumpBtn.onChangeCb = (sender, value, rvalue) -> {
			Settings.touchSettings.jumpButtonPos = [value.x, value.y];
			Settings.touchSettings.jumpButtonSize = rvalue;
		}

		powerupBtn.onClick = (sender, mousePos) -> {
			sender.setSelected(true);
			jumpBtn.setSelected(false);
			joystick.setSelected(false);
			blastBtn.setSelected(false);
		}

		powerupBtn.onChangeCb = (sender, value, rvalue) -> {
			Settings.touchSettings.powerupButtonPos = [value.x, value.y];
			Settings.touchSettings.powerupButtonSize = rvalue;
		}

		blastBtn.onClick = (sender, mousePos) -> {
			sender.setSelected(true);
			jumpBtn.setSelected(false);
			powerupBtn.setSelected(false);
			joystick.setSelected(false);
		}

		blastBtn.onChangeCb = (sender, value, rvalue) -> {
			Settings.touchSettings.blastButtonPos = [value.x, value.y];
			Settings.touchSettings.blastButtonSize = rvalue;
		}

		joystick.onClick = (mousePos) -> {
			joystick.setSelected(true);
			jumpBtn.setSelected(false);
			powerupBtn.setSelected(false);
			blastBtn.setSelected(false);
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
		this.addChild(blastBtn);
	}
}
