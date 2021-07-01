package gui;

import h2d.Graphics;
import hxd.Key;
import h2d.Scene;
import h2d.col.Bounds;
import hxd.Window;
import h3d.Vector;

enum HorizSizing {
	Right;
	Width;
	Left;
	Center;
	Relative;
}

enum VertSizing {
	Bottom;
	Height;
	Top;
	Center;
	Relative;
}

typedef MouseState = {
	var position:Vector;
	var ?button:Int;
}

@:publicFields
class GuiControl {
	var horizSizing:HorizSizing = Right;
	var vertSizing:VertSizing = Bottom;

	var position:Vector;
	var extent:Vector;

	var children:Array<GuiControl> = [];

	var parent:GuiControl;

	var _entered:Bool = false;

	public function new() {}

	public function render(scene2d:Scene) {
		for (c in children) {
			c.render(scene2d);
		}
	}

	public function update(dt:Float, mouseState:MouseState) {
		var hitTestRect = getHitTestRect();
		if (hitTestRect.inRect(mouseState.position)) {
			if (Key.isPressed(Key.MOUSE_LEFT)) {
				mouseState.button = Key.MOUSE_LEFT;
				this.onMousePress(mouseState);
			}
			if (Key.isPressed(Key.MOUSE_RIGHT)) {
				mouseState.button = Key.MOUSE_RIGHT;
				this.onMousePress(mouseState);
			}
			if (Key.isReleased(Key.MOUSE_LEFT)) {
				mouseState.button = Key.MOUSE_LEFT;
				this.onMouseRelease(mouseState);
			}
			if (Key.isReleased(Key.MOUSE_RIGHT)) {
				mouseState.button = Key.MOUSE_RIGHT;
				this.onMouseRelease(mouseState);
			}
			if (Key.isDown(Key.MOUSE_LEFT)) {
				mouseState.button = Key.MOUSE_LEFT;
				this.onMouseDown(mouseState);
			}
			if (Key.isDown(Key.MOUSE_RIGHT)) {
				mouseState.button = Key.MOUSE_RIGHT;
				this.onMouseDown(mouseState);
			}

			if (!_entered) {
				_entered = true;
				this.onMouseEnter(mouseState);
			}
		} else {
			if (_entered) {
				_entered = false;
				this.onMouseLeave(mouseState);
			}
		}
		for (c in children) {
			c.update(dt, mouseState);
		}
	}

	public function getRenderRectangle() {
		var rect = new Rect(this.position, this.extent);
		var parentRect:Rect = null;
		if (this.parent != null) {
			parentRect = this.parent.getRenderRectangle();
			rect.position = parentRect.position.add(this.position);
		}
		if (this.horizSizing == HorizSizing.Width) {
			if (this.parent != null)
				rect.extent.x = parentRect.extent.x * (this.extent.x / parent.extent.x);
			else
				rect.extent.x = Window.getInstance().width;
		}
		if (this.vertSizing == VertSizing.Height) {
			if (this.parent != null)
				rect.extent.y = parentRect.extent.y * (this.extent.y / parent.extent.y);
			else
				rect.extent.y = Window.getInstance().height;
		}

		if (this.horizSizing == HorizSizing.Center) {
			if (this.parent != null) {
				rect.position.x = parentRect.position.x + parentRect.extent.x / 2 - rect.extent.x / 2;
			}
		}
		if (this.vertSizing == VertSizing.Center) {
			if (this.parent != null) {
				rect.position.y = parentRect.position.y + parentRect.extent.y / 2 - rect.extent.y / 2;
			}
		}
		if (this.horizSizing == HorizSizing.Right) {
			if (this.parent != null) {
				rect.position.x = parentRect.position.x + this.position.x;
			}
		}
		if (this.vertSizing == VertSizing.Bottom) {
			if (this.parent != null) {
				rect.position.y = parentRect.position.y + this.position.y;
			}
		}
		if (this.horizSizing == HorizSizing.Left) {
			if (this.parent != null) {
				rect.position.x = parentRect.position.x + parentRect.extent.x - (parent.extent.x - this.position.x);
			}
		}
		if (this.vertSizing == VertSizing.Top) {
			if (this.parent != null) {
				rect.position.y = parentRect.position.y + parentRect.extent.y - (parent.extent.y - this.position.y);
			}
		}
		return rect;
	}

	public function getHitTestRect() {
		var thisRect = this.getRenderRectangle();
		if (this.parent == null)
			return thisRect;
		else {
			return thisRect.intersect(this.parent.getRenderRectangle());
		}
	}

	public function addChild(ctrl:GuiControl) {
		this.children.push(ctrl);
		ctrl.parent = this;
	}

	public function removeChild(ctrl:GuiControl) {
		this.children.remove(ctrl);
		ctrl.parent = null;
		ctrl.onRemove();
	}

	public function removeChildren() {
		for (c in this.children) {
			c.parent = null;
			c.onRemove();
		}
		this.children = [];
	}

	public function dispose() {
		for (c in this.children) {
			c.dispose();
		}
		this.children = [];
	}

	public function onMouseDown(mouseState:MouseState) {}

	public function onMousePress(mouseState:MouseState) {}

	public function onMouseRelease(mouseState:MouseState) {}

	public function onMouseEnter(mouseState:MouseState) {}

	public function onMouseLeave(mouseState:MouseState) {}

	public function onRemove() {
		for (c in this.children) {
			c.onRemove();
		}
	}
}
