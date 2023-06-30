package gui;

import gui.GuiControl.MouseState;
import h3d.Vector;
import src.ResourceLoader;
import src.MarbleGame;

class AchievementPopupDlg extends GuiControl {
	var lifetime:Float = 0;
	var onFinish:() -> Void;

	public function new(id:Int) {
		super();
		this.extent = new Vector(640, 480);
		this.position = new Vector();
		this.horizSizing = Width;
		this.vertSizing = Height;

		var popup = new GuiImage(ResourceLoader.getResource('data/ui/achievement/${id}.png', ResourceLoader.getImage, this.imageResources).toTile());
		popup.horizSizing = Center;
		popup.vertSizing = Bottom;
		popup.position = new Vector(70, 465);
		popup.extent = new Vector(477, 90);
		this.addChild(popup);
	}

	override function update(dt:Float, mouseState:MouseState) {
		super.update(dt, mouseState);
		lifetime += dt;
		if (lifetime > 3) {
			MarbleGame.canvas.popDialog(this);
			if (onFinish != null)
				onFinish();
		}
	}
}
