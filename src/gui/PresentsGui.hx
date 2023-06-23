package gui;

import h3d.Vector;
import src.ResourceLoader;
import gui.GuiImage;

class PresentsGui extends GuiImage {
	public function new() {
		var img = ResourceLoader.getImage('data/ui/EngineSplashBG.jpg');
		super(img.resource.toTile());

		this.horizSizing = Width;
		this.vertSizing = Height;
		this.position = new Vector();
		this.extent = new Vector(640, 480);

		var ggLogo = new GuiImage(ResourceLoader.getResource('data/ui/GG_logo.png', ResourceLoader.getImage, this.imageResources).toTile());
		ggLogo.horizSizing = Center;
		ggLogo.vertSizing = Center;
		ggLogo.position = new Vector(69, 99);
		ggLogo.extent = new Vector(500, 383);
		this.addChild(ggLogo);
	}
}
