package gui;

import hxd.Window;
import gui.GuiControl.MouseState;
import hxd.res.BitmapFont;
import h3d.Vector;
import src.ResourceLoader;

class MainMenuGui {
	var scene2d:h2d.Scene;

	var mainCtrl:GuiControl;

	public function new() {}

	public function init(scene2d:h2d.Scene) {
		this.scene2d = scene2d;

		var fontdata = ResourceLoader.loader.load("data/font/DomCasual32px.fnt");
		var bfont = new BitmapFont(fontdata.entry);
		@:privateAccess bfont.loader = ResourceLoader.loader;

		mainCtrl = new GuiImage(ResourceLoader.getImage("data/ui/background.jpg").toTile());
		mainCtrl.horizSizing = Width;
		mainCtrl.vertSizing = Height;
		mainCtrl.position = new Vector();
		mainCtrl.extent = new Vector(640, 480);

		var versionText = new GuiText(bfont);
		versionText.horizSizing = Center;
		versionText.vertSizing = Top;
		versionText.position = new Vector(289, 457);
		versionText.extent = new Vector(62, 18);
		versionText.text.text = "1.0.0";
		mainCtrl.addChild(versionText);

		var homebase = new GuiImage(ResourceLoader.getImage("data/ui/home/homegui.png").toTile());
		homebase.horizSizing = Center;
		homebase.vertSizing = Center;
		homebase.extent = new Vector(349, 477);
		homebase.position = new Vector(145, 1);
		mainCtrl.addChild(homebase);

		function loadButtonImages(path:String) {
			var normal = ResourceLoader.getImage('${path}_n.png').toTile();
			var hover = ResourceLoader.getImage('${path}_h.png').toTile();
			var pressed = ResourceLoader.getImage('${path}_d.png').toTile();
			return [normal, hover, pressed];
		}

		var playButton = new GuiButton(loadButtonImages("data/ui/home/play"));
		playButton.position = new Vector(50, 113);
		playButton.extent = new Vector(270, 95);
		homebase.addChild(playButton);

		var helpButton = new GuiButton(loadButtonImages("data/ui/home/help"));
		helpButton.position = new Vector(59, 200);
		helpButton.extent = new Vector(242, 84);
		homebase.addChild(helpButton);

		var optionsButton = new GuiButton(loadButtonImages("data/ui/home/options"));
		optionsButton.position = new Vector(55, 279);
		optionsButton.extent = new Vector(253, 83);
		homebase.addChild(optionsButton);

		var exitButton = new GuiButton(loadButtonImages("data/ui/home/exit"));
		exitButton.position = new Vector(82, 358);
		exitButton.extent = new Vector(203, 88);
		homebase.addChild(exitButton);

		mainCtrl.render(scene2d);
	}

	public function update(dt:Float) {
		var wnd = Window.getInstance();
		var mouseState:MouseState = {
			position: new Vector(wnd.mouseX, wnd.mouseY)
		}
		mainCtrl.update(dt, mouseState);
	}
}
