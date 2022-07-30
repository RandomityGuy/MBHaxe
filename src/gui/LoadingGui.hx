package gui;

import hxd.res.BitmapFont;
import h3d.Vector;
import src.ResourceLoader;
import src.MarbleGame;

class LoadingGui extends GuiImage {
	public var setProgress:Float->Void;

	public function new(missionName:String) {
		var img = ResourceLoader.getImage("data/ui/background.jpg");
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
		var domcasual32 = domcasual32b.toSdfFont(26, MultiChannel);

		var mapName = new GuiText(domcasual32);
		mapName.position = new Vector(134, 78);
		mapName.extent = new Vector(323, 32);
		mapName.text.text = missionName;
		mapName.text.textColor = 0;
		mapName.justify = Center;

		var progress = new GuiProgress();
		progress.vertSizing = Bottom;
		progress.position = new Vector(153, 133);
		progress.extent = new Vector(269, 78);
		progress.progress = 0.5;

		setProgress = (progressPz) -> {
			progress.progress = progressPz;
		}

		var cancelButton = new GuiButton(loadButtonImages("data/ui/loading/cancel"));
		cancelButton.position = new Vector(320, 233);
		cancelButton.extent = new Vector(88, 50);
		cancelButton.pressedAction = (sender) -> {
			MarbleGame.instance.quitMission();
		}

		var overlay = new GuiImage(ResourceLoader.getResource("data/ui/loading/overlay.png", ResourceLoader.getImage, this.imageResources).toTile());
		overlay.position = new Vector(151, 131);
		overlay.extent = new Vector(278, 86);

		loadingGui.addChild(mapName);
		loadingGui.addChild(progress);
		loadingGui.addChild(cancelButton);
		loadingGui.addChild(overlay);

		this.addChild(loadingGui);
	}
}
