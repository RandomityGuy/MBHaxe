package gui;

import src.MarbleGame;
import hxd.res.BitmapFont;
import h3d.Vector;
import src.ResourceLoader;
import src.Settings;

class VersionGui extends GuiImage {
	public function new() {
		var img = ResourceLoader.getImage("data/ui/motd/messagewindow.png");
		super(img.resource.toTile());
		this.horizSizing = Center;
		this.vertSizing = Center;
		this.position = new Vector(4, 12);
		this.extent = new Vector(631, 455);

		function loadButtonImages(path:String) {
			var normal = ResourceLoader.getResource('${path}_n.png', ResourceLoader.getImage, this.imageResources).toTile();
			var hover = ResourceLoader.getResource('${path}_h.png', ResourceLoader.getImage, this.imageResources).toTile();
			var pressed = ResourceLoader.getResource('${path}_d.png', ResourceLoader.getImage, this.imageResources).toTile();
			return [normal, hover, pressed];
		}

		var noButton = new GuiButton(loadButtonImages("data/ui/loading/cancel"));
		noButton.position = new Vector(400, 370);
		noButton.extent = new Vector(88, 41);
		noButton.vertSizing = Top;
		noButton.accelerator = hxd.Key.ESCAPE;
		noButton.gamepadAccelerator = ["B"];
		noButton.pressedAction = (sender) -> {
			MarbleGame.canvas.popDialog(this);
		}
		this.addChild(noButton);

		var dlButton = new GuiButton(loadButtonImages("data/ui/motd/ok"));
		dlButton.position = new Vector(500, 370);
		dlButton.extent = new Vector(88, 41);
		dlButton.vertSizing = Top;
		dlButton.pressedAction = (sender) -> {
			MarbleGame.canvas.popDialog(this);
		}
		this.addChild(dlButton);

		var scrollCtrl = new GuiScrollCtrl(ResourceLoader.getResource("data/ui/common/philscroll.png", ResourceLoader.getImage, this.imageResources).toTile());
		scrollCtrl.position = new Vector(31, 10);
		scrollCtrl.extent = new Vector(568, 337);
		this.addChild(scrollCtrl);

		var arial14fontdata = ResourceLoader.getFileEntry("data/font/arial.fnt");
		var arial14b = new BitmapFont(arial14fontdata.entry);
		@:privateAccess arial14b.loader = ResourceLoader.loader;
		var arial14 = arial14b.toSdfFont(cast 14 * Settings.uiScale, MultiChannel);

		var markerFelt32fontdata = ResourceLoader.getFileEntry("data/font/MarkerFelt.fnt");
		var markerFelt32b = new BitmapFont(markerFelt32fontdata.entry);
		@:privateAccess markerFelt32b.loader = ResourceLoader.loader;
		var markerFelt32 = markerFelt32b.toSdfFont(cast 26 * Settings.uiScale, MultiChannel);
		var markerFelt24 = markerFelt32b.toSdfFont(cast 18 * Settings.uiScale, MultiChannel);
		var markerFelt18 = markerFelt32b.toSdfFont(cast 14 * Settings.uiScale, MultiChannel);

		function mlFontLoader(text:String) {
			switch (text) {
				case "MarkerFelt32":
					return markerFelt32;
				case "MarkerFelt24":
					return markerFelt24;
				case "MarkerFelt18":
					return markerFelt18;
				case "Arial16":
					return arial14;
				default:
					return null;
			}
		}

		var changelogContent = new GuiMLText(arial14, mlFontLoader);
		changelogContent.position = new Vector(0, 20);
		changelogContent.extent = new Vector(566, 81);
		changelogContent.text.textColor = 0;
		changelogContent.scrollable = true;
		changelogContent.text.text = "CHNAGELOG";
		scrollCtrl.addChild(changelogContent);
	}
}
