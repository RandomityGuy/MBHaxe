package gui;

import h2d.Scene;
import h3d.shader.AlphaChannel;
import src.DtsObject;
import hxd.res.BitmapFont;
import h3d.Vector;
import src.ResourceLoader;
import src.MarbleGame;
import hxd.Key;
import src.Settings;
import src.Util;

class HelpCreditsGui extends GuiImage {
	var manualPageList:GuiTextListCtrl;

	public function new() {
		function chooseBg() {
			var rand = Math.random();
			if (rand >= 0 && rand <= 0.244)
				return ResourceLoader.getImage('data/ui/backgrounds/gold/${cast (Math.floor(Util.lerp(1, 12, Math.random())), Int)}.jpg');
			if (rand > 0.244 && rand <= 0.816)
				return ResourceLoader.getImage('data/ui/backgrounds/platinum/${cast (Math.floor(Util.lerp(1, 28, Math.random())), Int)}.jpg');
			return ResourceLoader.getImage('data/ui/backgrounds/ultra/${cast (Math.floor(Util.lerp(1, 9, Math.random())), Int)}.jpg');
		}
		var img = chooseBg();
		super(img.resource.toTile());
		this.position = new Vector(0, 0);
		this.extent = new Vector(640, 480);
		this.horizSizing = Width;
		this.vertSizing = Height;

		var wnd = new GuiImage(ResourceLoader.getResource("data/ui/manual/window.png", ResourceLoader.getImage, this.imageResources).toTile());
		wnd.position = new Vector(0, 0);
		wnd.extent = new Vector(640, 480);
		wnd.horizSizing = Center;
		wnd.vertSizing = Center;
		this.addChild(wnd);

		function loadButtonImages(path:String) {
			var normal = ResourceLoader.getResource('${path}_n.png', ResourceLoader.getImage, this.imageResources).toTile();
			var hover = ResourceLoader.getResource('${path}_h.png', ResourceLoader.getImage, this.imageResources).toTile();
			var pressed = ResourceLoader.getResource('${path}_d.png', ResourceLoader.getImage, this.imageResources).toTile();
			return [normal, hover, pressed];
		}

		var homeButton = new GuiButton(loadButtonImages("data/ui/manual/home"));
		homeButton.position = new Vector(274, 385);
		homeButton.extent = new Vector(94, 46);
		homeButton.accelerator = hxd.Key.ESCAPE;
		homeButton.gamepadAccelerator = ["B"];
		homeButton.pressedAction = (sender) -> {
			MarbleGame.canvas.setContent(new MainMenuGui());
		}
		wnd.addChild(homeButton);

		var arial14fontdata = ResourceLoader.getFileEntry("data/font/arial.fnt");
		var arial14b = new BitmapFont(arial14fontdata.entry);
		@:privateAccess arial14b.loader = ResourceLoader.loader;
		var arial14 = arial14b.toSdfFont(cast 11.7 * Settings.uiScale, MultiChannel);

		var pagefiles = [];
		for (i in 1...23) {
			var pg = ResourceLoader.load('ui/manual/pages/${i}.txt').entry;
			pagefiles.push(pg);
		}
		var pagetxt = pagefiles.map(x -> x.getText());
		var pageheadings = pagetxt.map(x -> x.substr(0, x.indexOf("\n")));

		var scrollCtrl1 = new GuiControl();
		scrollCtrl1.position = new Vector(29, 24);
		scrollCtrl1.extent = new Vector(176, 352);
		wnd.addChild(scrollCtrl1);

		manualPageList = new GuiTextListCtrl(arial14, pageheadings);
		manualPageList.position = new Vector(0, 0);
		manualPageList.extent = new Vector(176, 352);
		scrollCtrl1.addChild(manualPageList);

		var scrollCtrl2 = new GuiScrollCtrl(ResourceLoader.getResource("data/ui/common/philscroll.png", ResourceLoader.getImage, this.imageResources)
			.toTile());
		scrollCtrl2.position = new Vector(219, 28);
		scrollCtrl2.extent = new Vector(386, 342);
		scrollCtrl2.childrenHandleScroll = true;
		wnd.addChild(scrollCtrl2);

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

		var manualContent = new GuiMLText(arial14, mlFontLoader);
		manualContent.position = new Vector(0, 20);
		manualContent.extent = new Vector(376, 322);
		manualContent.text.textColor = 0;
		manualContent.scrollable = true;
		scrollCtrl2.addChild(manualContent);

		manualPageList.onSelectedFunc = (idx) -> {
			if (idx != -1) {
				var txt = pagetxt[idx];
				var txtlines = txt.split('\n');
				txtlines[0] = '<br/><font face="MarkerFelt32"><p align="center">${txtlines[0]}</p></font>';
				var finaltxt = txtlines.join('<br/>') + '<br/>';
				manualContent.text.text = finaltxt;
				scrollCtrl2.setScrollMax(manualContent.text.textHeight);
				scrollCtrl2.updateScrollVisual();
			}
		};
	}

	public override function render(scene2d:Scene, ?parent:h2d.Flow) {
		super.render(scene2d, parent);

		manualPageList.onSelectedFunc(0);
	}
}
