package gui;

import format.abc.Data.ABCData;
import h2d.Flow;
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
	Height;
}

enum VertSizing {
	Bottom;
	Height;
	Top;
	Center;
	Relative;
	Width;
}

typedef MouseState = {
	var position:Vector;
	var ?button:Int;
	var ?wheel:Float;
	var handled:Bool;
}

@:publicFields
class GuiControl {
	var horizSizing:HorizSizing = Right;
	var vertSizing:VertSizing = Bottom;

	var position:Vector;
	var extent:Vector;
	var xScale:Float = 1;
	var yScale:Float = 1;

	var children:Array<GuiControl> = [];

	var parent:GuiControl;

	var _entered:Bool = false;
	var _skipNextEvent:Bool = false;
	var _mousePos:Vector = null;

	var imageResources:Array<Resource<Image>> = [];
	var textureResources:Array<Resource<Texture>> = [];
	var soundResources:Array<Resource<Sound>> = [];

	var _disposed = false;

	var _flow:Flow;

	var _manualScroll = false;

	// var _border:h2d.Graphics = null;

	public function new() {}

	public function render(scene2d:Scene, ?parent:Flow) {
		if (this._flow == null) {
			this._flow = new Flow(parent != null ? parent : scene2d);
			// this._flow.debug = true;
		}
		// if (_border == null) {
		// 	_border = new h2d.Graphics(scene2d);
		// }
		if (parent == null) {
			if (scene2d.contains(this._flow)) {
				scene2d.removeChild(this._flow);
			}
			scene2d.addChild(this._flow);
		} else {
			if (parent.contains(this._flow)) {
				parent.removeChild(this._flow);
			}
			parent.addChild(this._flow);
		}
		var rrect = getRenderRectangle();
		this._flow.maxWidth = cast rrect.extent.x;
		this._flow.maxHeight = cast rrect.extent.y;
		this._flow.borderWidth = cast rrect.extent.x;
		this._flow.borderHeight = cast rrect.extent.y;
		this._flow.borderRight = cast rrect.extent.x;
		this._flow.borderBottom = cast rrect.extent.y;
		this._flow.overflow = Hidden;
		this._flow.multiline = true;
		if (parent != null) {
			var props = parent.getProperties(this._flow);
			props.isAbsolute = true;
			var off = this.getOffsetFromParent();
			this._flow.setPosition(off.x, off.y);
		}
		for (c in children) {
			c.render(scene2d, this._flow);
		}
		this._skipNextEvent = true;
	}

	public function update(dt:Float, mouseState:MouseState) {
		if (!_skipNextEvent) {
			var hitTestRect = getHitTestRect(!_manualScroll);
			// _border.clear();
			// _border.lineStyle(2, 0x0000FF);
			// _border.drawRect(hitTestRect.position.x, hitTestRect.position.y, hitTestRect.extent.x, hitTestRect.extent.y);
			if (hitTestRect.inRect(mouseState.position)) {
				if (Key.isPressed(Key.MOUSE_LEFT)) {
					mouseState.button = Key.MOUSE_LEFT;
					this.onMousePress(mouseState);
					if (mouseState.handled)
						return;
				}
				if (Key.isPressed(Key.MOUSE_RIGHT)) {
					mouseState.button = Key.MOUSE_RIGHT;
					this.onMousePress(mouseState);
					if (mouseState.handled)
						return;
				}
				if (Key.isReleased(Key.MOUSE_LEFT)) {
					mouseState.button = Key.MOUSE_LEFT;
					this.onMouseRelease(mouseState);
					if (mouseState.handled)
						return;
				}
				if (Key.isReleased(Key.MOUSE_RIGHT)) {
					mouseState.button = Key.MOUSE_RIGHT;
					this.onMouseRelease(mouseState);
					if (mouseState.handled)
						return;
				}
				if (Key.isDown(Key.MOUSE_LEFT)) {
					mouseState.button = Key.MOUSE_LEFT;
					this.onMouseDown(mouseState);
					if (mouseState.handled)
						return;
				}
				if (Key.isDown(Key.MOUSE_RIGHT)) {
					mouseState.button = Key.MOUSE_RIGHT;
					this.onMouseDown(mouseState);
					if (mouseState.handled)
						return;
				}

				if (!_entered) {
					_entered = true;
					this.onMouseEnter(mouseState);
					if (mouseState.handled)
						return;
				}
				if (_entered) {
					if (this._mousePos != null) {
						if (!this._mousePos.equals(mouseState.position)) {
							this.onMouseMove(mouseState);
							this._mousePos = mouseState.position.clone();
							if (mouseState.handled)
								return;
						}
					} else {
						this._mousePos = mouseState.position.clone();
						this.onMouseMove(mouseState);
						if (mouseState.handled)
							return;
					}
				}
			} else {
				if (_entered) {
					_entered = false;
					this.onMouseLeave(mouseState);
					if (mouseState.handled)
						return;
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
			rect.position = parentRect.position.add(new Vector(this.position.x * uiScaleFactor * xScale, this.position.y * uiScaleFactor * yScale));
		}

		var scaleFactor = 1.0 / Window.getInstance().windowToPixelRatio;
		#if (js || android)
		scaleFactor = 1 / Settings.zoomRatio; // 768 / js.Browser.window.innerHeight * js.Browser.window.devicePixelRatio; // 0.5; // 768 / js.Browser.window.innerHeight; // js.Browser.window.innerHeight * js.Browser.window.devicePixelRatio / 768;
		#end

		if (this.horizSizing == HorizSizing.Width) {
			if (this.parent != null)
				rect.extent.x = parentRect.extent.x * (this.extent.x / parent.extent.x);
			else
				rect.extent.x = Window.getInstance().width * scaleFactor;
		}

		if (this.horizSizing == HorizSizing.Height) {
			if (this.parent != null)
				rect.extent.x = parentRect.extent.y * (this.extent.y / parent.extent.y);
			else
				rect.extent.x = Window.getInstance().height * scaleFactor;
		}

		if (this.vertSizing == VertSizing.Height) {
			if (this.parent != null)
				rect.extent.y = parentRect.extent.y * (this.extent.y / parent.extent.y);
			else
				rect.extent.y = Window.getInstance().height * scaleFactor;
		}

		if (this.vertSizing == VertSizing.Width) {
			if (this.parent != null)
				rect.extent.y = parentRect.extent.x * (this.extent.x / parent.extent.x);
			else
				rect.extent.y = Window.getInstance().width * scaleFactor;
		}

		if (this.horizSizing == HorizSizing.Center) {
			if (this.parent != null) {
				rect.position.x = parentRect.position.x + parentRect.extent.x / 2 - (rect.extent.x * uiScaleFactor * xScale) / 2;
				rect.extent.x *= uiScaleFactor * xScale;
			}
		}
		if (this.vertSizing == VertSizing.Center) {
			if (this.parent != null) {
				rect.position.y = parentRect.position.y + parentRect.extent.y / 2 - (rect.extent.y * uiScaleFactor * yScale) / 2;
				rect.extent.y *= uiScaleFactor * yScale;
			}
		}
		if (this.horizSizing == HorizSizing.Right) {
			if (this.parent != null) {
				rect.position.x = parentRect.position.x + this.position.x * uiScaleFactor * xScale;
				rect.extent.x *= uiScaleFactor * xScale;
			}
		}
		if (this.vertSizing == VertSizing.Bottom) {
			if (this.parent != null) {
				rect.position.y = parentRect.position.y + this.position.y * uiScaleFactor * yScale;
				rect.extent.y *= uiScaleFactor * yScale;
			}
		}
		if (this.horizSizing == HorizSizing.Left) {
			if (this.parent != null) {
				rect.position.x = parentRect.position.x + parentRect.extent.x - (parent.extent.x - this.position.x) * uiScaleFactor * xScale;
				rect.extent.x *= uiScaleFactor * xScale;
			}
		}
		if (this.vertSizing == VertSizing.Top) {
			if (this.parent != null) {
				rect.position.y = parentRect.position.y + parentRect.extent.y - (parent.extent.y - this.position.y) * uiScaleFactor * yScale;
				rect.extent.y *= uiScaleFactor * yScale;
			}
		}
		if (this.parent != null) {
			rect.scroll.x = parentRect.scroll.x;
			rect.scroll.y = parentRect.scroll.y;
		}
		return rect;
	}

	public function getHitTestRect(useScroll:Bool = true) {
		var thisRect = this.getRenderRectangle();
		if (useScroll)
			thisRect.position.y -= thisRect.scroll.y;
		if (this.parent == null)
			return thisRect;
		else {
			var parRect = this.parent.getRenderRectangle();
			// parRect.position.y -= parRect.scroll.y;
			var rr = thisRect.intersect(parRect);
			if (useScroll) {
				thisRect.position.y -= thisRect.scroll.y;
				rr.scroll.y = thisRect.scroll.y;
			}
			return rr;
		}
	}

	public function getOffsetFromParent() {
		var rect = new Rect(this.position, this.extent);
		var parentRect:Rect = null;

		var uiScaleFactor = Settings.uiScale;

		var offset = this.position.clone();
		offset.x *= uiScaleFactor * xScale;
		offset.y *= uiScaleFactor * yScale;

		if (this.parent != null) {
			parentRect = this.parent.getRenderRectangle();
			offset = this.position.multiply(uiScaleFactor);
			offset.x *= xScale;
			offset.y *= yScale;
		}

		var scaleFactor = 1.0 / Window.getInstance().windowToPixelRatio;
		#if (js || android)
		scaleFactor = 1 / Settings.zoomRatio; // 768 / js.Browser.window.innerHeight * js.Browser.window.devicePixelRatio; // 0.5; // 768 / js.Browser.window.innerHeight; // js.Browser.window.innerHeight * js.Browser.window.devicePixelRatio / 768;
		#end

		if (this.horizSizing == HorizSizing.Center) {
			if (this.parent != null) {
				offset.x = parentRect.extent.x / 2 - (rect.extent.x * uiScaleFactor * xScale) / 2;
			}
		}
		if (this.vertSizing == VertSizing.Center) {
			if (this.parent != null) {
				offset.y = parentRect.extent.y / 2 - (rect.extent.y * uiScaleFactor * yScale) / 2;
			}
		}
		if (this.horizSizing == HorizSizing.Right) {
			if (this.parent != null) {
				offset.x = this.position.x * uiScaleFactor * xScale;
			}
		}
		if (this.vertSizing == VertSizing.Bottom) {
			if (this.parent != null) {
				offset.y = this.position.y * uiScaleFactor * yScale;
			}
		}
		if (this.horizSizing == HorizSizing.Left) {
			if (this.parent != null) {
				offset.x = parentRect.extent.x - (parent.extent.x - this.position.x) * uiScaleFactor * xScale;
			}
		}
		if (this.vertSizing == VertSizing.Top) {
			if (this.parent != null) {
				offset.y = parentRect.extent.y - (parent.extent.y - this.position.y) * uiScaleFactor * yScale;
			}
		}
		offset.x = Math.floor(offset.x);
		offset.y = Math.floor(offset.y);
		return offset;
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
		this._flow.remove();
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

		_disposed = true;
	}

	public function onMouseDown(mouseState:MouseState) {}

	public function onMousePress(mouseState:MouseState) {}

	public function onMouseRelease(mouseState:MouseState) {}

	public function onMouseEnter(mouseState:MouseState) {}

	public function onMouseLeave(mouseState:MouseState) {}

	public function onMouseMove(mouseState:MouseState) {}

	public function onScroll(scrollX:Float, scrollY:Float) {}

	public function onRemove() {
		this._flow.remove();
		for (c in this.children) {
			c.onRemove();
		}
	}

	public function renderEngine(engine:h3d.Engine) {
		for (c in this.children) {
			c.renderEngine(engine);
		}
	}

	public function onResize(width:Int, height:Int) {
		for (c in this.children) {
			c.onResize(width, height);
		}
	}
}
