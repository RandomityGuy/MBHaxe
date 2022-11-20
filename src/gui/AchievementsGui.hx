package gui;

import h3d.Vector;
import src.ResourceLoader;
import src.MarbleGame;

class AchievementsGui extends GuiImage {
	public function new() {
		var img = ResourceLoader.getImage("data/ui/achiev/window.png");
		super(img.resource.toTile());
		this.horizSizing = Center;
		this.vertSizing = Center;
		this.position = new Vector(73, -21);
		this.extent = new Vector(493, 512);

		var achiev = new GuiImage(ResourceLoader.getResource("data/ui/achiev/achiev.png", ResourceLoader.getImage, this.imageResources).toTile());
		achiev.position = new Vector(152, 26);
		achiev.extent = new Vector(176, 50);
		this.addChild(achiev);

		function loadButtonImages(path:String) {
			var normal = ResourceLoader.getResource('${path}_n.png', ResourceLoader.getImage, this.imageResources).toTile();
			var hover = ResourceLoader.getResource('${path}_h.png', ResourceLoader.getImage, this.imageResources).toTile();
			var pressed = ResourceLoader.getResource('${path}_d.png', ResourceLoader.getImage, this.imageResources).toTile();
			var disabled = ResourceLoader.getResource('${path}_i.png', ResourceLoader.getImage, this.imageResources).toTile();
			return [normal, hover, pressed, disabled];
		}

		var closeButton = new GuiButton(loadButtonImages("data/ui/achiev/close"));
		closeButton.position = new Vector(355, 426);
		closeButton.extent = new Vector(95, 45);
		closeButton.pressedAction = (e) -> {
			MarbleGame.canvas.popDialog(this);
		}
		this.addChild(closeButton);
	}
}
