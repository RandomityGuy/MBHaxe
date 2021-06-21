package gui;

import h3d.Vector;
import src.ResourceLoader;

class ExitGameDlg extends GuiControl {
	public function new() {
		super();

		this.horizSizing = Width;
		this.vertSizing = Height;
		this.position = new Vector();
		this.extent = new Vector(640, 480);

		function loadButtonImages(path:String) {
			var normal = ResourceLoader.getImage('${path}_n.png').toTile();
			var hover = ResourceLoader.getImage('${path}_h.png').toTile();
			var pressed = ResourceLoader.getImage('${path}_d.png').toTile();
			return [normal, hover, pressed];
		}

		var dialogImg = new GuiImage(ResourceLoader.getImage("data/ui/common/dialog.png").toTile());
		dialogImg.horizSizing = Center;
		dialogImg.vertSizing = Center;
		dialogImg.position = new Vector(134, 148);
		dialogImg.extent = new Vector(388, 186);

		var yesButton = new GuiButton(loadButtonImages("data/ui/common/yes"));
		yesButton.position = new Vector(47, 107);
		yesButton.extent = new Vector(88, 52);
		yesButton.vertSizing = Top;
		yesButton.horizSizing = Right;

		var noButton = new GuiButton(loadButtonImages("data/ui/common/no"));
		noButton.position = new Vector(151, 107);
		noButton.extent = new Vector(83, 55);
		noButton.vertSizing = Top;
		noButton.horizSizing = Right;

		var restartButton = new GuiButton(loadButtonImages("data/ui/common/restart"));
		restartButton.position = new Vector(249, 107);
		restartButton.extent = new Vector(103, 56);
		restartButton.vertSizing = Top;
		restartButton.horizSizing = Right;

		dialogImg.addChild(yesButton);
		dialogImg.addChild(noButton);
		dialogImg.addChild(restartButton);

		this.addChild(dialogImg);
	}
}
