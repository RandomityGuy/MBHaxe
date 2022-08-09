package touch;

import h3d.Vector;
import src.Settings;
import gui.GuiGraphics;

class MovementInputEdit extends GuiGraphics {
	public function new() {
		var size = Settings.touchSettings.joystickSize;

		var g = new h2d.Graphics();
		g.beginFill(0xffffff, 0.4);
		g.drawRoundedRect(0, 0, size * 6, size * 6, size);
		g.endFill();

		super(g);

		this.position = Settings.touchSettings.joystickPos;
		this.extent = new Vector(size * 6, size * 6);
		this.vertSizing = Top;

		var collider = new h2d.Interactive(size * 6, size * 6, g, h2d.col.Bounds.fromValues(0, 0, size * 6, size * 6));

		var g2 = new h2d.Graphics();
		g2.beginFill(0xffffff, 0.7);
		g2.drawCircle(0, 0, size);
		g2.endFill();

		var joystick = new GuiGraphics(g2);
		joystick.position = new Vector(size * 3, size * 3);
		joystick.extent = new Vector(size, size);

		this.addChild(joystick);
	}
}
