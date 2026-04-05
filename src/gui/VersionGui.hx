package gui;

import src.Http;
import src.MarbleGame;
import hxd.res.BitmapFont;
import h3d.Vector;
import src.ResourceLoader;
import src.Settings;

class VersionGui extends GuiImage {
	public function new() {
		var img = ResourceLoader.getImage("data/ui/help/help_gui.png");
		super(img.resource.toTile());
		this.horizSizing = Center;
		this.vertSizing = Center;
		this.position = new Vector(4, 12);
		this.extent = new Vector(609, 460);

		var helpWindow = new GuiImage(ResourceLoader.getResource("data/ui/help/help_window.png", ResourceLoader.getImage, this.imageResources).toTile());
		helpWindow.position = new Vector(30, 31);
		helpWindow.extent = new Vector(549, 338);
		this.addChild(helpWindow);

		function loadButtonImages(path:String) {
			var normal = ResourceLoader.getResource('${path}_n.png', ResourceLoader.getImage, this.imageResources).toTile();
			var hover = ResourceLoader.getResource('${path}_h.png', ResourceLoader.getImage, this.imageResources).toTile();
			var pressed = ResourceLoader.getResource('${path}_d.png', ResourceLoader.getImage, this.imageResources).toTile();
			return [normal, hover, pressed];
		}

		var homeButton = new GuiButton(loadButtonImages("data/ui/play/back"));
		homeButton.position = new Vector(278, 378);
		homeButton.extent = new Vector(79, 61);
		homeButton.accelerator = hxd.Key.ESCAPE;
		homeButton.gamepadAccelerator = ["B"];
		homeButton.pressedAction = (sender) -> {
			MarbleGame.canvas.popDialog(this);
		}
		this.addChild(homeButton);

		var scrollCtrl = new GuiScrollCtrl(ResourceLoader.getResource("data/ui/common/philscroll.png", ResourceLoader.getImage, this.imageResources).toTile());
		scrollCtrl.position = new Vector(31, 30);
		scrollCtrl.extent = new Vector(509, 298);
		helpWindow.addChild(scrollCtrl);

		var arial14fontdata = ResourceLoader.getFileEntry("data/font/arial.fnt");
		var arial14b = new BitmapFont(arial14fontdata.entry);
		@:privateAccess arial14b.loader = ResourceLoader.loader;
		var arial14 = arial14b.toSdfFont(cast 14 * Settings.uiScale, MultiChannel);
		var arial16 = arial14b.toSdfFont(cast 14 * Settings.uiScale, MultiChannel);

		function mlFontLoader(text:String) {
			switch (text) {
				case "Arial16":
					return arial14;
				default:
					return null;
			}
		}

		var changelogContent = new GuiMLText(arial14, mlFontLoader);
		changelogContent.position = new Vector(0, 0);
		changelogContent.extent = new Vector(500, 298);
		changelogContent.text.textColor = 0;
		changelogContent.scrollable = true;
		changelogContent.text.text = "Loading changelog, please wait.<br/>";
		Http.get("https://raw.githubusercontent.com/RandomityGuy/MBHaxe/mbg/CHANGELOG.md", (res) -> {
			var mdtext = res.toString();
			var res = "";
			changelogContent.text.text = "";
			for (line in mdtext.split("\n")) {
				if (StringTools.startsWith(line, "#")) {
					line = StringTools.replace(line, "#", "");
					line = '<font face="Arial16">' + line + "</font>";
				}
				res += line + "<br/>";
			}
			changelogContent.text.text += res;
			scrollCtrl.setScrollMax(changelogContent.text.textHeight);
		}, (e) -> {
			changelogContent.text.text = "Failed to fetch changelog.";
		});
		scrollCtrl.addChild(changelogContent);
	}

	public static function checkVersion() {
		Http.get("https://raw.githubusercontent.com/RandomityGuy/MBHaxe/mbg/CHANGELOG.md", (res) -> {
			var mdtext = res.toString();
			var firstline = mdtext.split("\n")[0];
			firstline = StringTools.replace(firstline, "#", "");
			firstline = StringTools.trim(firstline);
			if (firstline != MarbleGame.currentVersion) {
				// We need to update lol
				var mbo = new MessageBoxOkDlg("New version available! Please update your game.", () -> {
					#if sys
					hxd.System.openURL("https://github.com/RandomityGuy/MBHaxe/blob/mbg/README.md");
					#end
				});
				MarbleGame.canvas.pushDialog(mbo);
			}
		}, (e) -> {});
	}
}
