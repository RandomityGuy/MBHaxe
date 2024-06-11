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
	var innerCtrl:GuiControl;

	public function new(paused:Bool) {
		var res = ResourceLoader.getImage("data/ui/xbox/BG_fadeOutSoftEdge.png").resource.toTile();
		super(res);
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
		rootTitle.text.text = "TOUCH CONTROLS";
		rootTitle.text.alpha = 0.5;
		innerCtrl.addChild(rootTitle);

		var bottomBar = new GuiControl();
		bottomBar.position = new Vector(0, 590);
		bottomBar.extent = new Vector(640, 200);
		bottomBar.horizSizing = Width;
		bottomBar.vertSizing = Bottom;
		innerCtrl.addChild(bottomBar);

		var nextButton = new GuiXboxButton("Save", 160);
		nextButton.position = new Vector(960, 100);
		nextButton.vertSizing = Bottom;
		nextButton.horizSizing = Right;
		nextButton.gamepadAccelerator = ["A"];
		nextButton.accelerators = [hxd.Key.ENTER];
		nextButton.pressedAction = (e) -> {
			if (paused) {
				MarbleGame.canvas.popDialog(this);
				MarbleGame.canvas.pushDialog(new TouchOptionsGui(true));
			} else {
				MarbleGame.canvas.setContent(new TouchOptionsGui());
			}
		};
		innerCtrl.addChild(nextButton);

		var joystick = new MovementInputEdit();

		var jumpBtn = new TouchEditButton(ResourceLoader.getImage("data/ui/touch/up-arrow.png").resource,
			new Vector(Settings.touchSettings.jumpButtonPos[0], Settings.touchSettings.jumpButtonPos[1]), Settings.touchSettings.jumpButtonSize);

		var powerupBtn = new TouchEditButton(ResourceLoader.getImage("data/ui/touch/energy.png").resource,
			new Vector(Settings.touchSettings.powerupButtonPos[0], Settings.touchSettings.powerupButtonPos[1]), Settings.touchSettings.powerupButtonSize);

		var blastBtn = new TouchEditButton(ResourceLoader.getImage("data/ui/touch/explosion.png").resource,
			new Vector(Settings.touchSettings.blastButtonPos[0], Settings.touchSettings.blastButtonPos[1]), Settings.touchSettings.blastButtonSize);

		var rewindBtn = new TouchEditButton(ResourceLoader.getImage("data/ui/touch/rewind.png").resource,
			new Vector(Settings.touchSettings.rewindButtonPos[0], Settings.touchSettings.rewindButtonPos[1]), Settings.touchSettings.rewindButtonSize);

		jumpBtn.onClick = (sender, mousePos) -> {
			sender.setSelected(true);
			powerupBtn.setSelected(false);
			joystick.setSelected(false);
			blastBtn.setSelected(false);
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
			blastBtn.setSelected(false);
			rewindBtn.setSelected(false);
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
			rewindBtn.setSelected(false);
		}

		blastBtn.onChangeCb = (sender, value, rvalue) -> {
			Settings.touchSettings.blastButtonPos = [value.x, value.y];
			Settings.touchSettings.blastButtonSize = rvalue;
		}

		rewindBtn.onClick = (sender, mousePos) -> {
			sender.setSelected(true);
			jumpBtn.setSelected(false);
			powerupBtn.setSelected(false);
			joystick.setSelected(false);
			blastBtn.setSelected(false);
		}

		rewindBtn.onChangeCb = (sender, value, rvalue) -> {
			Settings.touchSettings.rewindButtonPos = [value.x, value.y];
			Settings.touchSettings.rewindButtonSize = rvalue;
		}

		joystick.onClick = (mousePos) -> {
			joystick.setSelected(true);
			jumpBtn.setSelected(false);
			powerupBtn.setSelected(false);
			blastBtn.setSelected(false);
			rewindBtn.setSelected(false);
		}

		joystick.onChangeCb = (value, rvalue) -> {
			Settings.touchSettings.joystickPos = [value.x, value.y];
			Settings.touchSettings.joystickSize = rvalue;
		}

		this.addChild(joystick);
		this.addChild(jumpBtn);
		this.addChild(powerupBtn);
		this.addChild(blastBtn);
		this.addChild(rewindBtn);
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
