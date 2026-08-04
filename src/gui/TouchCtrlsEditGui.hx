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

class TouchCtrlsEditGui extends GuiControl {
	public function new() {
		super();
		this.horizSizing = Width;
		this.vertSizing = Height;
		this.position = new Vector();
		this.extent = new Vector(800, 600);

		if (!ResourceLoader.exists(Settings.optionsSettings.previewPath))
			Settings.optionsSettings.previewPath = "data/previews_pq/tutorial/trainingwheels.prev.dds";
		var levelPreview = new GuiImage(ResourceLoader.getResource(Settings.optionsSettings.previewPath, ResourceLoader.getImage, this.imageResources)
			.toTile());
		levelPreview.horizSizing = Width;
		levelPreview.vertSizing = Height;
		levelPreview.position = new Vector(0, 0);
		levelPreview.extent = new Vector(800, 600);
		this.addChild(levelPreview);

		var whatneyFontData = ResourceLoader.getFileEntry("data/font/whatney.fnt");
		var whatneyFontB = new BitmapFont(whatneyFontData.entry);
		@:privateAccess whatneyFontB.loader = ResourceLoader.loader;
		var whatneyFont = whatneyFontB.toSdfFont(cast 21 * Settings.uiScale, MultiChannel);

		var squishneyFontData = ResourceLoader.getFileEntry("data/font/squishney.fnt");
		var squishneyFontB = new BitmapFont(squishneyFontData.entry);
		@:privateAccess squishneyFontB.loader = ResourceLoader.loader;
		var squishneyFont = squishneyFontB.toSdfFont(cast 28 * Settings.uiScale, MultiChannel);

		var mainMenuButton = new GuiBorderButtonTextCtrl(ResourceLoader.getResource('data/ui/common/button.png', ResourceLoader.getImage, this.imageResources)
			.toTile(), whatneyFont);
		mainMenuButton.position = new Vector(650, 15);
		mainMenuButton.ratio = 0.42;
		mainMenuButton.setExtent(new Vector(141, 141));
		mainMenuButton.txtCtrl.text.text = "Home";
		mainMenuButton.horizSizing = Left;
		mainMenuButton.vertSizing = Bottom;
		mainMenuButton.pressedAction = (sender) -> {
			MarbleGame.canvas.setContent(new OptionsDlg());
		}

		var touchControlsTxt = new GuiText(squishneyFont);
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

		this.addChild(mainMenuButton);
		this.addChild(touchControlsTxt);
		this.addChild(joystick);
		this.addChild(jumpBtn);
		this.addChild(powerupBtn);
		this.addChild(blastBtn);
		this.addChild(rewindBtn);
	}
}
