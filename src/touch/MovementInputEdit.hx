package touch;

import src.Util;
import gui.GuiControl.MouseState;
import h3d.Vector;
import src.Settings;
import gui.GuiGraphics;

class MovementInputEdit extends GuiGraphics {
	public var selected = false;

	public var onClick:(MouseState) -> Void;

	public var onChangeCb:(Vector, Float) -> Void;

	var mousePos:Vector;

	var size:Float;

	var state = 0;

	public function new() {
		var size = Settings.touchSettings.joystickSize;

		this.size = size;

		var g = new h2d.Graphics();
		g.beginFill(0xffffff, 0.4);
		g.drawRoundedRect(0, 0, size * 6, size * 6, size);
		g.endFill();

		super(g);

		this.position = new Vector(Settings.touchSettings.joystickPos[0], Settings.touchSettings.joystickPos[1]);
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

	public override function onMousePress(mouseState:MouseState) {
		onClick(mouseState);
		this.mousePos = mouseState.position;

		var renderRect = getHitTestRect();
		var knobPos = new Vector(renderRect.position.x + renderRect.extent.x / 2, renderRect.position.y + 15);
		if (mouseState.position.sub(knobPos).length() < 15) {
			state = 2;
		} else {
			state = 1;
		}
	}

	public override function onMouseDown(mouseState:MouseState) {
		if (selected) {
			var deltaPos = mouseState.position.sub(this.mousePos);
			this.mousePos = mouseState.position;

			if (state == 1) {
				this.graphics.setPosition(this.graphics.x + deltaPos.x, this.graphics.y + deltaPos.y);
				this.position = this.position.add(deltaPos);

				var joy:GuiGraphics = cast this.children[0];
				joy.graphics.setPosition(joy.graphics.x + deltaPos.x, joy.graphics.y + deltaPos.y);

				onChangeCb(this.position, this.size);
			}
			if (state == 2) {
				var renderRect = getHitTestRect();

				var knobPos = new Vector(renderRect.position.x + renderRect.extent.x / 2, renderRect.position.y + 15);

				var newSize = Util.clamp(Math.abs(mouseState.position.y - (renderRect.position.y + renderRect.extent.y / 2)) / 3, 15,
					70); // Full size is size * 6
				var newPos = new Vector(knobPos.x - newSize * 3, mouseState.position.y);

				var deltaPos = new Vector(renderRect.position.x + 15 + 6.5 - newPos.x, renderRect.position.y + 15 + 6.5 - newPos.y);

				this.size = newSize;
				this.extent = new Vector(size * 6, size * 6);
				this.position = this.position.sub(deltaPos);
				this.graphics.setPosition(this.graphics.x - deltaPos.x, this.graphics.y - deltaPos.y);

				var joystick:GuiGraphics = cast this.children[0];
				joystick.position = new Vector(size * 3, size * 3);
				joystick.extent = new Vector(size, size);
				joystick.graphics.setPosition(this.graphics.x + size * 3, this.graphics.y + size * 3);

				// Redraw lmao
				this.setSelected(false);
				this.setSelected(true);
				// Redraw the joystick
				joystick.graphics.clear();
				joystick.graphics.beginFill(0xffffff, 0.7);
				joystick.graphics.drawCircle(0, 0, size);
				joystick.graphics.endFill();

				onChangeCb(this.position, this.size);
			}
		}
	}

	public override function onMouseRelease(mouseState:MouseState) {
		state = 0;
	}

	public override function getHitTestRect(useScroll:Bool = true) {
		var thisRect = this.getRenderRectangle();

		if (selected) {
			thisRect.position = thisRect.position.add(new Vector(-15 - 6.5, -15 - 6.5));
			thisRect.extent = thisRect.extent.add(new Vector(30 + 13, 30 + 13));
		}

		if (this.parent == null)
			return thisRect;
		else {
			return thisRect.intersect(this.parent.getRenderRectangle());
		}
	}

	public function setSelected(selected:Bool) {
		this.selected = selected;
		if (selected) {
			this.graphics.lineStyle(3, 0xFFFFFF);
			this.graphics.moveTo(-6.5, -6.5);
			this.graphics.lineTo(size * 6 + 6.5, -6.5);
			this.graphics.lineTo(size * 6 + 6.5, size * 6 + 6.5);
			this.graphics.lineTo(-6.5, size * 6 + 6.5);
			this.graphics.lineTo(-6.5, -6.5);

			this.graphics.beginFill(0x8B8B8B);
			this.graphics.lineStyle(0, 0xFFFFFF);
			this.graphics.drawCircle(size * 3, -6.5, 15);
			this.graphics.endFill();
		} else {
			this.graphics.clear();
			this.graphics.beginFill(0xffffff, 0.4);
			this.graphics.drawRoundedRect(0, 0, size * 6, size * 6, size);
			this.graphics.endFill();
		}
	}
}
