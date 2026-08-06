package gui;

import src.Http;
import src.MarbleGame;
import hxd.res.BitmapFont;
import h3d.Vector;
import src.ResourceLoader;
import src.Settings;

class VersionGui extends GuiControl {
	public function new() {
		super();
		this.horizSizing = Width;
		this.vertSizing = Height;
		this.position = new Vector(0, 0);
		this.extent = new Vector(800, 600);

		var wnd = new GuiTransparencyCtrl("data/ui/transparency/pqwindow");
		wnd.horizSizing = Center;
		wnd.vertSizing = Center;
		wnd.position = new Vector(196, 159);
		wnd.extent = new Vector(631, 455);
		this.addChild(wnd);

		var whatneyFontData = ResourceLoader.getFileEntry("data/font/whatney.fnt");
		var whatneyFontB = new BitmapFont(whatneyFontData.entry);
		@:privateAccess whatneyFontB.loader = ResourceLoader.loader;
		var whatneyFont17 = whatneyFontB.toSdfFont(cast 15 * Settings.uiScale, MultiChannel, 0.5, 0.5);
		var whatneyFont = whatneyFontB.toSdfFont(cast 21 * Settings.uiScale, MultiChannel, 0.5, 0.5);

		var squishneyFontData = ResourceLoader.getFileEntry("data/font/squishney.fnt");
		var squishneyFontB = new BitmapFont(squishneyFontData.entry);
		@:privateAccess squishneyFontB.loader = ResourceLoader.loader;
		var squishneyFont28 = squishneyFontB.toSdfFont(cast 25 * Settings.uiScale, MultiChannel, 0.5, 0.5);

		var dlButton = new GuiBorderButtonTextCtrl(ResourceLoader.getResource('data/ui/common/button.png', ResourceLoader.getImage, this.imageResources)
			.toTile(), whatneyFont);
		dlButton.position = new Vector(510, 383);
		dlButton.setExtent(new Vector(94, 45));
		dlButton.vertSizing = Top;
		dlButton.horizSizing = Right;
		dlButton.pressedAction = (sender) -> {
			MarbleGame.canvas.popDialog(this);
		}
		dlButton.txtCtrl.text.text = "Close";
		wnd.addChild(dlButton);

		var scrollCtrl = new GuiScrollCtrl(ResourceLoader.getResource("data/ui/common/philscroll.png", ResourceLoader.getImage, this.imageResources).toTile());
		scrollCtrl.position = new Vector(30, 35);
		scrollCtrl.extent = new Vector(568, 337);
		wnd.addChild(scrollCtrl);

		function mlFontLoader(text:String) {
			switch (text) {
				case "title":
					return squishneyFont28;
				case "text":
					return whatneyFont17;
				default:
					return null;
			}
		}

		var changelogContent = new GuiMLText(whatneyFont17, mlFontLoader);
		changelogContent.position = new Vector(0, 0);
		changelogContent.extent = new Vector(568, 337);
		changelogContent.text.textColor = 0;
		changelogContent.scrollable = true;
		changelogContent.text.text = "Loading changelog, please wait.<br/>";
		Http.get("https://raw.githubusercontent.com/RandomityGuy/MBHaxe/pq/CHANGELOG.md", (res) -> {
			var mdtext = res.toString();
			var res = "<br/>";
			changelogContent.text.text = "";
			for (line in mdtext.split("\n")) {
				if (StringTools.startsWith(line, "#")) {
					line = StringTools.replace(line, "#", "");
					line = '<font face="title">' + line + "</font>";
				}
				res += line + "<br/>";
			}
			changelogContent.text.text += res;
			scrollCtrl.setScrollMax(changelogContent.text.textHeight);
		}, (e) -> {
			changelogContent.text.text = "<br/>Failed to fetch changelog.";
		});
		scrollCtrl.addChild(changelogContent);
	}

	public static function checkVersion() {
		Http.get("https://raw.githubusercontent.com/RandomityGuy/MBHaxe/pq/CHANGELOG.md", (res) -> {
			var mdtext = res.toString();
			var firstline = mdtext.split("\n")[0];
			firstline = StringTools.replace(firstline, "#", "");
			firstline = StringTools.trim(firstline);
			if (firstline != MarbleGame.currentVersion) {
				// We need to update lol
				var mbo = new MessageBoxOkDlg("New version available! Please update your game.", () -> {
					#if sys
					hxd.System.openURL("https://github.com/RandomityGuy/MBHaxe/blob/master/README.md");
					#end
				});
				MarbleGame.canvas.pushDialog(mbo);
			}
		}, (e) -> {});
	}
}
