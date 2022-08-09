package gui;

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

		var mainMenuButton = new GuiButton(loadButtonImages("data/ui/options/mainm"));
		mainMenuButton.position = new Vector(500, 400);
		mainMenuButton.extent = new Vector(121, 53);
		mainMenuButton.horizSizing = Left;
		mainMenuButton.vertSizing = Top;
		mainMenuButton.pressedAction = (sender) -> {
			MarbleGame.canvas.setContent(new OptionsDlg());
		}

		var joystick = new MovementInputEdit();

		var jumpBtn = new TouchEditButton(ResourceLoader.getImage("data/ui/touch/up-arrow.png").resource, Settings.touchSettings.jumpButtonPos,
			Settings.touchSettings.jumpButtonSize);

		var powerupBtn = new TouchEditButton(ResourceLoader.getImage("data/ui/touch/energy.png").resource, Settings.touchSettings.powerupButtonPos,
			Settings.touchSettings.powerupButtonSize);

		jumpBtn.onClick = (sender, mousePos) -> {
			sender.setSelected(true);
			powerupBtn.setSelected(false);
		}

		powerupBtn.onClick = (sender, mousePos) -> {
			sender.setSelected(true);
			jumpBtn.setSelected(false);
		}

		this.addChild(mainMenuButton);
		this.addChild(joystick);
		this.addChild(jumpBtn);
		this.addChild(powerupBtn);
	}
}
