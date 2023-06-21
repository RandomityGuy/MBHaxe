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

		var scene2d = MarbleGame.canvas.scene2d;

		var offsetX = (scene2d.width - 1280) / 2;
		var offsetY = (scene2d.height - 720) / 2;

		var innerCtrl = new GuiControl();
		innerCtrl.position = new Vector(offsetX, offsetY);
		// innerCtrl.extent = new Vector(640, 480);

		var subX = 640 - (scene2d.width - offsetX * 2) * 640 / scene2d.width;
		var subY = 480 - (scene2d.height - offsetY * 2) * 480 / scene2d.height;

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

		var btnList = new GuiXboxList();
		btnList.position = new Vector(70 - offsetX / 2, 95);
		btnList.horizSizing = Left;
		btnList.extent = new Vector(502, 500);
		innerCtrl.addChild(btnList);

		btnList.addButton(0, "Resume", (evt) -> noFunc(btnList));
		btnList.addButton(0, "Restart", (evt) -> restartFunc(btnList));
		btnList.addButton(4, "Exit Level", (evt) -> yesFunc(btnList));
		btnList.addButton(3, "Help & Options", (evt) -> {}, 20);
		btnList.addButton(2, "Leaderboards", (evt) -> {});
		btnList.addButton(2, "Achievements", (evt) -> {});
		btnList.addButton(4, "Main Menu", (evt) -> yesFunc(btnList));
	}
}
