package gui;

import src.Http;
import src.MarbleGame;
import hxd.res.BitmapFont;
import h3d.Vector;
import src.ResourceLoader;
import src.Settings;

class VersionGui extends GuiImage {
	var innerCtrl:GuiControl;

	public function new() {
		var res = ResourceLoader.getImage("data/ui/xbox/BG_fadeOutSoftEdge.png").resource.toTile();
		super(res);

		this.horizSizing = Width;
		this.vertSizing = Height;
		this.position = new Vector();
		this.extent = new Vector(640, 480);

		var scene2d = MarbleGame.canvas.scene2d;

		var offsetX = (scene2d.width - 1280) / 2;
		var offsetY = (scene2d.height - 720) / 2;

		var subX = 640 - (scene2d.width - offsetX) * 640 / scene2d.width;
		var subY = 480 - (scene2d.height - offsetY) * 480 / scene2d.height;

		innerCtrl = new GuiControl();
		innerCtrl.position = new Vector(offsetX, offsetY);
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
		rootTitle.text.text = "CHANGELOG";
		rootTitle.text.alpha = 0.5;
		innerCtrl.addChild(rootTitle);

		var wnd = new GuiImage(ResourceLoader.getResource("data/ui/xbox/helpWindow.png", ResourceLoader.getImage, this.imageResources).toTile());
		wnd.position = new Vector(260, 107);
		wnd.extent = new Vector(736, 460);
		wnd.horizSizing = Right;
		wnd.vertSizing = Bottom;
		innerCtrl.addChild(wnd);

		var arial14fontdata = ResourceLoader.getFileEntry("data/font/Arial Bold.fnt");
		var arial14b = new BitmapFont(arial14fontdata.entry);
		@:privateAccess arial14b.loader = ResourceLoader.loader;
		var arial14 = arial14b.toSdfFont(cast 21 * Settings.uiScale, h2d.Font.SDFChannel.MultiChannel);
		var arial14big = arial14b.toSdfFont(cast 30 * Settings.uiScale, h2d.Font.SDFChannel.MultiChannel);
		var arial14med = arial14b.toSdfFont(cast 26 * Settings.uiScale, h2d.Font.SDFChannel.MultiChannel);

		var bottomBar = new GuiControl();
		bottomBar.position = new Vector(0, 590);
		bottomBar.extent = new Vector(640, 200);
		bottomBar.horizSizing = Width;
		bottomBar.vertSizing = Bottom;
		innerCtrl.addChild(bottomBar);

		var backButton = new GuiXboxButton("Ok", 160);
		backButton.position = new Vector(960, 0);
		backButton.vertSizing = Bottom;
		backButton.horizSizing = Right;
		backButton.gamepadAccelerator = ["A"];
		backButton.accelerators = [hxd.Key.ENTER];
		backButton.pressedAction = (e) -> MarbleGame.canvas.setContent(new MainMenuGui());
		bottomBar.addChild(backButton);

		var textCtrl = new GuiConsoleScrollCtrl(ResourceLoader.getResource("data/ui/common/osxscroll.png", ResourceLoader.getImage, this.imageResources)
			.toTile());
		textCtrl.position = new Vector(30, 33);
		textCtrl.extent = new Vector(683, 403);
		textCtrl.scrollToBottom = false;
		wnd.addChild(textCtrl);

		function mlFontLoader(text:String) {
			switch (text) {
				case "ArialBig":
					return arial14big;
				case "ArialMed":
					return arial14med;
				default:
					return arial14;
			}
		}

		var wndTxtBg = new GuiMLText(arial14, mlFontLoader);
		wndTxtBg.position = new Vector(2, 7);
		wndTxtBg.extent = new Vector(683, 343);
		wndTxtBg.text.textColor = 0x101010;
		wndTxtBg.text.text = "Loading changelog, please wait.<br/>";
		wndTxtBg.scrollable = true;
		textCtrl.addChild(wndTxtBg);

		var wndTxt = new GuiMLText(arial14, mlFontLoader);
		wndTxt.position = new Vector(0, 5);
		wndTxt.extent = new Vector(683, 343);
		wndTxt.text.textColor = 0xEBEBEB;
		wndTxt.text.text = "Loading changelog, please wait.<br/>";
		wndTxt.scrollable = true;
		textCtrl.addChild(wndTxt);

		Http.get("https://raw.githubusercontent.com/RandomityGuy/MBHaxe/master/CHANGELOG.md", (res) -> {
			var mdtext = res.toString();
			var res = "";
			wndTxt.text.text = "";
			wndTxtBg.text.text = "";
			for (line in mdtext.split("\n")) {
				if (StringTools.startsWith(line, "#")) {
					line = StringTools.replace(line, "#", "");
					line = '<font face="ArialMed">' + line + "</font>";
				}
				res += line + "<br/>";
			}
			wndTxt.text.text += res;
			wndTxtBg.text.text += res;
			textCtrl.setScrollMax(wndTxt.text.textHeight);
		}, (e) -> {
			wndTxt.text.text = "Failed to fetch changelog.";
			wndTxtBg.text.text = "Failed to fetch changelog.";
		});
	}

	override function onResize(width:Int, height:Int) {
		var offsetX = (width - 1280) / 2;
		var offsetY = (height - 720) / 2;

		var subX = 640 - (width - offsetX) * 640 / width;
		var subY = 480 - (height - offsetY) * 480 / height;
		innerCtrl.position = new Vector(offsetX, offsetY);
		innerCtrl.extent = new Vector(640 - subX, 480 - subY);

		super.onResize(width, height);
	}
}
