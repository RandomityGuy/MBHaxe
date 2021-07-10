package gui;

import hxd.res.BitmapFont;
import h3d.Vector;
import src.ResourceLoader;

class LoadingGui extends GuiImage {
	public var setProgress:Float->Void;

	public function new(missionName:String) {
		super(ResourceLoader.getImage("data/ui/background.jpg").toTile());
		this.horizSizing = Width;
		this.vertSizing = Height;
		this.extent = new Vector(640, 480);
		this.position = new Vector();

		var loadingGui = new GuiImage(ResourceLoader.getImage("data/ui/loading/loadinggui.png").toTile());
		loadingGui.horizSizing = Center;
		loadingGui.vertSizing = Center;
		loadingGui.position = new Vector(86, 77);
		loadingGui.extent = new Vector(468, 325);

		function loadButtonImages(path:String) {
			var normal = ResourceLoader.getImage('${path}_n.png').toTile();
			var hover = ResourceLoader.getImage('${path}_h.png').toTile();
			var pressed = ResourceLoader.getImage('${path}_d.png').toTile();
			return [normal, hover, pressed];
		}

		var domcasual32fontdata = ResourceLoader.getFileEntry("data/font/DomCasual32px.fnt");
		var domcasual32 = new BitmapFont(domcasual32fontdata.entry);
		@:privateAccess domcasual32.loader = ResourceLoader.loader;

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

		var overlay = new GuiImage(ResourceLoader.getImage("data/ui/loading/overlay.png").toTile());
		overlay.position = new Vector(151, 131);
		overlay.extent = new Vector(278, 86);

		loadingGui.addChild(mapName);
		loadingGui.addChild(progress);
		loadingGui.addChild(cancelButton);
		loadingGui.addChild(overlay);

		this.addChild(loadingGui);
	}
}
