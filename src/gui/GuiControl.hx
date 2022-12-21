package gui;

import hxd.res.Image;
import h2d.Graphics;
import hxd.Key;
import h2d.Scene;
import h2d.col.Bounds;
import hxd.Window;
import h3d.Vector;
import src.Resource;
import hxd.res.Sound;
import h3d.mat.Texture;
import src.Settings;

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
	var _skipNextEvent:Bool = false;
	var _mousePos:Vector = null;

	var imageResources:Array<Resource<Image>> = [];
	var textureResources:Array<Resource<Texture>> = [];
	var soundResources:Array<Resource<Sound>> = [];

	public function new() {}

	public function render(scene2d:Scene) {
		for (c in children) {
			c.render(scene2d);
		}
		this._skipNextEvent = true;
	}

	public function update(dt:Float, mouseState:MouseState) {
		if (!_skipNextEvent) {
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
				if (_entered) {
					if (this._mousePos != null) {
						if (!this._mousePos.equals(mouseState.position)) {
							this.onMouseMove(mouseState);
							this._mousePos = mouseState.position.clone();
						}
					} else {
						this._mousePos = mouseState.position.clone();
						this.onMouseMove(mouseState);
					}
				}
			} else {
				if (_entered) {
					_entered = false;
					this.onMouseLeave(mouseState);
				}
			}
		} else {
			_skipNextEvent = false;
		}
		for (c in children) {
			c.update(dt, mouseState);
		}
	}

	public function getRenderRectangle() {
		var rect = new Rect(this.position, this.extent);
		var parentRect:Rect = null;

		var uiScaleFactor = Settings.uiScale;

		if (this.parent != null) {
			parentRect = this.parent.getRenderRectangle();
			rect.position = parentRect.position.add(this.position.multiply(uiScaleFactor));
		}

		var scaleFactor = 1.0;
		#if (js || android)
		scaleFactor = 1 / Settings.zoomRatio; // 768 / js.Browser.window.innerHeight * js.Browser.window.devicePixelRatio; // 0.5; // 768 / js.Browser.window.innerHeight; // js.Browser.window.innerHeight * js.Browser.window.devicePixelRatio / 768;
		#end

		if (this.horizSizing == HorizSizing.Width) {
			if (this.parent != null)
				rect.extent.x = parentRect.extent.x * (this.extent.x / parent.extent.x);
			else
				rect.extent.x = Window.getInstance().width * scaleFactor;
		}
		if (this.vertSizing == VertSizing.Height) {
			if (this.parent != null)
				rect.extent.y = parentRect.extent.y * (this.extent.y / parent.extent.y);
			else
				rect.extent.y = Window.getInstance().height * scaleFactor;
		}

		if (this.horizSizing == HorizSizing.Center) {
			if (this.parent != null) {
				rect.position.x = parentRect.position.x + parentRect.extent.x / 2 - (rect.extent.x * uiScaleFactor) / 2;
				rect.extent.x *= uiScaleFactor;
			}
		}
		if (this.vertSizing == VertSizing.Center) {
			if (this.parent != null) {
				rect.position.y = parentRect.position.y + parentRect.extent.y / 2 - (rect.extent.y * uiScaleFactor) / 2;
				rect.extent.y *= uiScaleFactor;
			}
		}
		if (this.horizSizing == HorizSizing.Right) {
			if (this.parent != null) {
				rect.position.x = parentRect.position.x + this.position.x * uiScaleFactor;
				rect.extent.x *= uiScaleFactor;
			}
		}
		if (this.vertSizing == VertSizing.Bottom) {
			if (this.parent != null) {
				rect.position.y = parentRect.position.y + this.position.y * uiScaleFactor;
				rect.extent.y *= uiScaleFactor;
			}
		}
		if (this.horizSizing == HorizSizing.Left) {
			if (this.parent != null) {
				rect.position.x = parentRect.position.x + parentRect.extent.x - (parent.extent.x - this.position.x * uiScaleFactor);
				rect.extent.x *= uiScaleFactor;
			}
		}
		if (this.vertSizing == VertSizing.Top) {
			if (this.parent != null) {
				rect.position.y = parentRect.position.y + parentRect.extent.y - (parent.extent.y - this.position.y * uiScaleFactor);
				rect.extent.y *= uiScaleFactor;
			}
		}
		if (this.parent != null) {
			rect.scroll.x = parentRect.scroll.x;
			rect.scroll.y = parentRect.scroll.y;
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

	public function guiToScreen(point:Vector) {
		var rect = this.getRenderRectangle();
		return rect.position.add(point);
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

		for (textureResource in textureResources) {
			textureResource.release();
		}
		for (imageResource in imageResources) {
			imageResource.release();
		}
		for (audioResource in soundResources) {
			audioResource.release();
		}
	}

	public function onMouseDown(mouseState:MouseState) {}

	public function onMousePress(mouseState:MouseState) {}

	public function onMouseRelease(mouseState:MouseState) {}

	public function onMouseEnter(mouseState:MouseState) {}

	public function onMouseLeave(mouseState:MouseState) {}

	public function onMouseMove(mouseState:MouseState) {}

	public function onScroll(scrollX:Float, scrollY:Float) {}

	public function onRemove() {
		for (c in this.children) {
			c.onRemove();
		}
	}

	public function renderEngine(engine:h3d.Engine) {
		for (c in this.children) {
			c.renderEngine(engine);
		}
	}
}
