package gui;

import src.AudioManager;
import src.MarbleGame;
import hxd.res.BitmapFont;
import h3d.Vector;
import src.ResourceLoader;
import src.Settings;

class ExitGameDlg extends GuiImage {
	public function new(yesFunc:GuiControl->Void, noFunc:GuiControl->Void, restartFunc:GuiControl->Void) {
		var res = ResourceLoader.getImage("data/ui/xbox/BG_fadeOutSoftEdge.png").resource.toTile();
		super(res);

		AudioManager.playSound(ResourceLoader.getResource('data/sound/level_text.wav', ResourceLoader.getAudio, this.soundResources));

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

		var innerCtrl = new GuiControl();
		innerCtrl.position = new Vector(320, 180);
		innerCtrl.extent = new Vector(1280, 720);

		var scene2d = MarbleGame.canvas.scene2d;

		// var subX = 640 - (scene2d.width - 145 * 2) * 640 g/ scene2d.width;
		// var subY = 480 - (scene2d.height - 82 * 2) * 480 / scene2d.height;

		// innerCtrl.extent = new Vector(640 - subX, 480 - subY);
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
		rootTitle.text.text = "Paused";
		rootTitle.text.alpha = 0.5;
		innerCtrl.addChild(rootTitle);

		var levelTitle = new GuiText(coliseum);
		levelTitle.position = new Vector(100, 75);
		levelTitle.extent = new Vector(1120, 80);
		levelTitle.text.textColor = 0xFFFFFF;
		levelTitle.text.alpha = 0.5;
		levelTitle.text.text = 'Level ${MarbleGame.instance.world.mission.index + 1}';
		innerCtrl.addChild(levelTitle);

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
	}
}
