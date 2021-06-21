package gui;

import h3d.Vector;
import h2d.Scene;
import gui.GuiControl.MouseState;

class Canvas extends GuiControl {
	var scene2d:Scene;

	public function new(scene) {
		super();
		this.scene2d = scene;

		this.position = new Vector();
		this.extent = new Vector(640, 480);
		this.horizSizing = Width;
		this.vertSizing = Height;
	}

	public function setContent(content:GuiControl) {
		this.dispose();
		this.addChild(content);
		this.render(scene2d);
	}

	public override function update(dt:Float, mouseState:MouseState) {
		super.update(dt, mouseState);
	}
}
