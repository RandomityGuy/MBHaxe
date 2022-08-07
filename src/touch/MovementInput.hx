package touch;

import src.Util;
import h2d.col.Point;
import src.Settings;
import h2d.col.Bounds;
import gui.GuiControl;
import h3d.Vector;
import gui.GuiGraphics;

class MovementInput {
	var area:GuiGraphics;

	var added:Bool = false;

	var collider:h2d.Interactive;

	var joystick:GuiGraphics;

	public var pressed = false;

	public var value:Vector = new Vector();

	var touchId = -1;

	public function new() {
		var g = new h2d.Graphics();
		g.beginFill(0xffffff, 0.4);
		g.drawRoundedRect(0, 0, 300, 300, 50);
		g.endFill();

		this.area = new GuiGraphics(g);
		this.area.position = new Vector(100, 40);
		this.area.extent = new Vector(300, 300);
		this.area.vertSizing = Top;

		this.collider = new h2d.Interactive(300, 300, g, h2d.col.Bounds.fromValues(0, 0, 300, 300));

		var g2 = new h2d.Graphics();
		g2.beginFill(0xffffff, 0.7);
		g2.drawCircle(0, 0, 50);
		g2.endFill();

		this.joystick = new GuiGraphics(g2);
		this.joystick.position = new Vector(150, 150);
		this.joystick.extent = new Vector(50, 50);

		this.area.addChild(this.joystick);

		collider.onPush = (e) -> {
			this.area.graphics.alpha = 1;
			this.joystick.graphics.alpha = 1;

			if (!pressed) {
				pressed = true;

				this.touchId = e.touchId;

				// var xPos = Util.clamp(e.relX - this.area.graphics.x, 50, 250);
				// var yPos = Util.clamp(e.relY - this.area.graphics.x, 50, 250);

				// this.value.x = (xPos - 150) / 100;
				// this.value.y = (yPos - 150) / 100;

				// this.joystick.graphics.setPosition(this.area.graphics.x + xPos, this.area.graphics.y + yPos);

				var stopped = false;

				collider.startCapture((emove) -> {
					if (e.touchId != emove.touchId) {
						emove.propagate = true;
						return;
					}
					if (emove.kind == EMove) {
						var xPos = Util.clamp(emove.relX, 50, 250);
						var yPos = Util.clamp(emove.relY, 50, 250);

						this.value.x = (xPos - 150) / 100;
						this.value.y = (yPos - 150) / 100;

						this.joystick.graphics.setPosition(this.area.graphics.x + xPos, this.area.graphics.y + yPos);
					}
					if (emove.kind == ERelease || emove.kind == EReleaseOutside) {
						stopped = true;
						collider.stopCapture();
					}
				}, () -> {
					if (stopped) {
						this.area.graphics.alpha = 0;
						this.joystick.graphics.alpha = 0;

						pressed = false;

						this.value = new Vector(0, 0);
					}
				}, e.touchId);
			}
		}

		this.area.graphics.alpha = 1;
		this.joystick.graphics.alpha = 1;
	}

	public function add(parentGui:GuiControl) {
		parentGui.addChild(this.area);
		added = true;
	}

	public function remove(parentGui:GuiControl) {
		parentGui.removeChild(this.area);
		added = false;
	}

	public function setVisible(enabled:Bool) {
		this.area.graphics.visible = enabled;
	}

	public function dispose() {
		this.area.dispose();
	}
}
