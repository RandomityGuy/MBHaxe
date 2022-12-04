package gui;

import hxd.res.BitmapFont;
import h3d.Vector;
import src.ResourceLoader;
import src.MarbleGame;
import src.Settings;
import src.Util;

class LoadingGui extends GuiImage {
	public var setProgress:Float->Void;

	public function new(missionName:String, game:String) {
		var img = game == "platinum" ? ResourceLoader.getImage('data/ui/backgrounds/platinum/${cast (Math.floor(Util.lerp(1, 28, Math.random())), Int)}.jpg') : ResourceLoader.getImage('data/ui/backgrounds/gold/${cast (Math.floor(Util.lerp(1, 12, Math.random())), Int)}.jpg');
		super(img.resource.toTile());
		this.horizSizing = Width;
		this.vertSizing = Height;
		this.extent = new Vector(640, 480);
		this.position = new Vector();

		var loadingGui = new GuiImage(ResourceLoader.getResource("data/ui/loading/loadinggui.png", ResourceLoader.getImage, this.imageResources).toTile());
		loadingGui.horizSizing = Center;
		loadingGui.vertSizing = Center;
		loadingGui.position = new Vector(86, 77);
		loadingGui.extent = new Vector(468, 325);

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

		var mapName = new GuiText(domcasual32);
		mapName.position = new Vector(6, 33);
		mapName.extent = new Vector(456, 14);
		mapName.text.text = missionName;
		mapName.text.textColor = 0;
		mapName.justify = Center;

		var progress = new GuiProgress();
		progress.vertSizing = Top;
		progress.position = new Vector(194, 145);
		progress.extent = new Vector(225, 56);
		progress.progress = 0.5;

		setProgress = (progressPz) -> {
			progress.progress = progressPz;
		}

		var cancelButton = new GuiButton(loadButtonImages("data/ui/loading/cancel"));
		cancelButton.position = new Vector(333, 243);
		cancelButton.extent = new Vector(112, 59);
		cancelButton.pressedAction = (sender) -> {
			MarbleGame.instance.quitMission();
		}

		var overlay = new GuiImage(ResourceLoader.getResource("data/ui/loading/overlay.png", ResourceLoader.getImage, this.imageResources).toTile());
		overlay.position = new Vector(188, 139);
		overlay.extent = new Vector(242, 75);

		loadingGui.addChild(mapName);
		loadingGui.addChild(progress);
		loadingGui.addChild(cancelButton);
		loadingGui.addChild(overlay);

		this.addChild(loadingGui);
	}
}
