package gui;

import net.Net;
import hxd.res.BitmapFont;
import src.ResourceLoader;
import h3d.Vector;
import src.MarbleGame;
import src.Util;
import src.Settings;

class MPMessageGui extends GuiImage {
	public function new(titleText:String, msgText:String) {
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

		function loadButtonImages(path:String) {
			var normal = ResourceLoader.getResource('${path}_n.png', ResourceLoader.getImage, this.imageResources).toTile();
			var hover = ResourceLoader.getResource('${path}_h.png', ResourceLoader.getImage, this.imageResources).toTile();
			var pressed = ResourceLoader.getResource('${path}_d.png', ResourceLoader.getImage, this.imageResources).toTile();
			return [normal, hover, pressed];
		}

		var markerFelt32fontdata = ResourceLoader.getFileEntry("data/font/MarkerFelt.fnt");
		var markerFelt32b = new BitmapFont(markerFelt32fontdata.entry);
		@:privateAccess markerFelt32b.loader = ResourceLoader.loader;
		var markerFelt48 = markerFelt32b.toSdfFont(cast 42 * Settings.uiScale, MultiChannel);
		var markerFelt28 = markerFelt32b.toSdfFont(cast 26 * Settings.uiScale, MultiChannel);

		this.horizSizing = Width;
		this.vertSizing = Height;
		this.position = new Vector(0, 0);
		this.extent = new Vector(640, 480);

		var container = new GuiControl();
		container.horizSizing = Center;
		container.vertSizing = Center;
		container.position = new Vector(80, 60);
		container.extent = new Vector(640, 480);

		this.addChild(container);

		var wnd = new GuiImage(ResourceLoader.getResource("data/ui/mp/window.png", ResourceLoader.getImage, this.imageResources).toTile());
		wnd.position = new Vector(64, 91);
		wnd.extent = new Vector(511, 297);
		wnd.horizSizing = Center;
		wnd.vertSizing = Center;
		container.addChild(wnd);

		var title = new GuiText(markerFelt48);
		title.text.text = titleText;
		title.text.textColor = 0xFFFFFF;
		title.text.dropShadow = {
			dx: 1 * Settings.uiScale,
			dy: 1 * Settings.uiScale,
			alpha: 0.5,
			color: 0
		};
		title.horizSizing = Center;
		title.position = new Vector(47, 26);
		title.extent = new Vector(416, 14);
		title.justify = Center;
		wnd.addChild(title);

		var msg = new GuiText(markerFelt28);
		msg.text.text = msgText;
		msg.text.textColor = 0xFFFFFF;
		msg.text.dropShadow = {
			dx: 1 * Settings.uiScale,
			dy: 1 * Settings.uiScale,
			alpha: 0.5,
			color: 0
		};
		msg.horizSizing = Relative;
		msg.vertSizing = Relative;
		msg.position = new Vector(15, 136);
		msg.extent = new Vector(483, 65);
		msg.justify = Center;
		wnd.addChild(msg);

		var cancelBtn = new GuiButton(loadButtonImages('data/ui/mp/join/cancel'));
		cancelBtn.position = new Vector(208, 210);
		cancelBtn.extent = new Vector(94, 45);
		cancelBtn.horizSizing = Center;
		cancelBtn.vertSizing = Top;
		cancelBtn.pressedAction = (e) -> {
			Net.disconnect();
			MarbleGame.canvas.setContent(new JoinServerGui());
		}
		wnd.addChild(cancelBtn);

		setTexts = (t, m) -> {
			title.text.text = t;
			msg.text.text = m;
		}
	}

	public dynamic function setTexts(titleText:String, msgText:String) {}
}
