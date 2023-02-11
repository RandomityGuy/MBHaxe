package gui;

import src.MarbleGame;
import hxd.res.BitmapFont;
import h3d.Vector;
import src.ResourceLoader;
import src.Settings;

class ExitGameDlg extends GuiControl {
	public function new(yesFunc:GuiControl->Void, noFunc:GuiControl->Void, restartFunc:GuiControl->Void) {
		super();

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

		var dialogImg = new GuiImage(ResourceLoader.getResource("data/ui/common/dialog.png", ResourceLoader.getImage, this.imageResources).toTile());
		dialogImg.horizSizing = Center;
		dialogImg.vertSizing = Center;
		dialogImg.position = new Vector(162, 160);
		dialogImg.extent = new Vector(315, 160);

		var overlay = new GuiImage(ResourceLoader.getResource("data/ui/common/quitfromthislvl_overlay.png", ResourceLoader.getImage, this.imageResources)
			.toTile());
		overlay.horizSizing = Right;
		overlay.vertSizing = Bottom;
		overlay.position = new Vector(36, 22);
		overlay.extent = new Vector(235, 42);

		var yesButton = new GuiButton(loadButtonImages("data/ui/common/yes"));
		yesButton.position = new Vector(19, 103);
		yesButton.extent = new Vector(86, 40);
		yesButton.vertSizing = Top;
		yesButton.horizSizing = Right;
		yesButton.accelerator = hxd.Key.ENTER;
		yesButton.gamepadAccelerator = ["A"];
		yesButton.pressedAction = (sender) -> yesFunc(yesButton);

		var noButton = new GuiButton(loadButtonImages("data/ui/common/no"));
		noButton.position = new Vector(105, 102);
		noButton.extent = new Vector(86, 40);
		noButton.vertSizing = Top;
		noButton.horizSizing = Right;
		noButton.gamepadAccelerator = ["B"];
		noButton.pressedAction = (sender) -> noFunc(noButton);

		var restartButton = new GuiButton(loadButtonImages("data/ui/common/restart"));
		restartButton.position = new Vector(214, 104);
		restartButton.extent = new Vector(86, 40);
		restartButton.vertSizing = Top;
		restartButton.horizSizing = Right;
		restartButton.gamepadAccelerator = ["X"];
		restartButton.pressedAction = (sender) -> restartFunc(restartButton);

		dialogImg.addChild(overlay);
		dialogImg.addChild(yesButton);
		dialogImg.addChild(noButton);
		dialogImg.addChild(restartButton);

		this.addChild(dialogImg);

		var jukeboxButton = new GuiButton(loadButtonImages("data/ui/jukebox/jb_pausemenu"));
		jukeboxButton.vertSizing = Top;
		jukeboxButton.horizSizing = Left;
		jukeboxButton.position = new Vector(439, 403);
		jukeboxButton.extent = new Vector(187, 65);
		jukeboxButton.pressedAction = (e) -> {
			MarbleGame.canvas.pushDialog(new JukeboxDlg());
		}

		this.addChild(jukeboxButton);
	}
}
