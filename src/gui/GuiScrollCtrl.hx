package gui;

import h3d.Vector;
import src.Settings;
import gui.GuiControl.MouseState;
import h2d.Interactive;
import h2d.Scene;
import h2d.Tile;
import h2d.Graphics;
import src.MarbleGame;
import src.Util;

class GuiScrollCtrl extends GuiControl {
	public var scrollY:Float = 0;

	var maxScrollY:Float;

	var scrollBarY:Graphics;

	var scrollTopTile:Tile;
	var scrollBottomTile:Tile;
	var scrollFillTile:Tile;

	var scrollTopPressedTile:Tile;
	var scrollBottomPressedTile:Tile;
	var scrollFillPressedTile:Tile;

	var clickInteractive:Interactive;

	var pressed:Bool = false;
	var dirty:Bool = true;
	var prevMousePos:Vector;

	public function new(scrollBar:Tile) {
		super();
		this.scrollTopTile = scrollBar.sub(0, 4, 10, 6);
		this.scrollBottomTile = scrollBar.sub(0, 13, 10, 6);
		this.scrollFillTile = scrollBar.sub(0, 11, 10, 1);
		this.scrollTopPressedTile = scrollBar.sub(11, 4, 10, 6);
		this.scrollBottomPressedTile = scrollBar.sub(11, 13, 10, 6);
		this.scrollFillPressedTile = scrollBar.sub(11, 11, 10, 1);
		this.scrollBarY = new Graphics();
		this.scrollBarY.scale(Settings.uiScale);
		this.clickInteractive = new Interactive(10 * Settings.uiScale, 1);
		this.clickInteractive.onPush = (e) -> {
			if (!this.pressed) {
				this.pressed = true;
				this.dirty = true;
				this.updateScrollVisual();

				var prevEY:Null<Float> = null;

				this.clickInteractive.startCapture(e2 -> {
					if (e2.kind == ERelease) {
						this.clickInteractive.stopCapture();
					}
					if (e2.kind == EMove) {
						if (prevEY == null) {
							prevEY = e2.relY;
						} else {
							this.scrollY += (e2.relY - prevEY);
							prevEY = e2.relY;
							this.updateScrollVisual();
						}
					}
				}, () -> {
					if (this.pressed) {
						this.pressed = false;
						this.dirty = true;
						this.updateScrollVisual();
					}
				});
			}
		};
	}

	public function setScrollMax(max:Float) {
		this.scrollY = 0;
		this.maxScrollY = max;
		this.dirty = true;
		this.updateScrollVisual();
	}

	public override function getRenderRectangle():Rect {
		var rrec = super.getRenderRectangle();
		rrec.scroll.y = scrollY * this.maxScrollY / rrec.extent.y;
		return rrec;
	}

	public override function render(scene2d:Scene) {
		this.dirty = true;

		if (scene2d.contains(scrollBarY))
			scene2d.removeChild(scrollBarY);

		if (scene2d.contains(clickInteractive))
			scene2d.removeChild(clickInteractive);

		scene2d.addChild(scrollBarY);
		scene2d.addChild(clickInteractive);

		updateScrollVisual();

		super.render(scene2d);
	}

	public function updateScrollVisual() {
		var renderRect = this.getRenderRectangle();

		if (maxScrollY < renderRect.extent.y) {
			scrollBarY.clear();
			return;
		}

		var scrollBarYSize = renderRect.extent.y * renderRect.extent.y / (maxScrollY * Settings.uiScale);

		this.scrollY = Util.clamp(scrollY, 0, renderRect.extent.y - scrollBarYSize * Settings.uiScale);

		this.scrollBarY.setPosition(renderRect.position.x + renderRect.extent.x - 10 * Settings.uiScale, renderRect.position.y + scrollY);

		this.clickInteractive.setPosition(renderRect.position.x + renderRect.extent.x - 10 * Settings.uiScale, renderRect.position.y);

		this.clickInteractive.height = renderRect.extent.y;

		if (this.dirty) {
			if (scrollBarYSize > renderRect.extent.y) {
				scrollBarYSize = renderRect.extent.y;
				scrollBarY.clear();
				return;
			}

			scrollBarY.clear();
			scrollBarY.drawTile(0, 0, pressed ? scrollTopPressedTile : scrollTopTile);

			// :skull:
			for (i in 0...cast(scrollBarYSize - 12)) {
				scrollBarY.drawTile(0, i + 6, pressed ? scrollFillPressedTile : scrollFillTile);
			}

			scrollBarY.drawTile(0, scrollBarYSize - 6, pressed ? scrollBottomPressedTile : scrollBottomTile);

			this.dirty = false;
		}

		for (c in this.children) {
			c.onScroll(0, scrollY * this.maxScrollY / renderRect.extent.y);
		}
	}

	public override function dispose() {
		super.dispose();
		this.scrollBarY.remove();
	}

	public override function onRemove() {
		super.onRemove();
		if (MarbleGame.canvas.scene2d.contains(scrollBarY)) {
			MarbleGame.canvas.scene2d.removeChild(scrollBarY); // Refresh "layer"
		}
		if (MarbleGame.canvas.scene2d.contains(clickInteractive)) {
			MarbleGame.canvas.scene2d.removeChild(clickInteractive); // Refresh "layer"
		}
	}

	public override function onMousePress(mouseState:MouseState) {
		if (Util.isTouchDevice()) {
			this.pressed = true;
			this.dirty = true;
			this.updateScrollVisual();
			this.prevMousePos = mouseState.position;
		}
	}

	public override function onMouseRelease(mouseState:MouseState) {
		if (Util.isTouchDevice()) {
			this.pressed = false;
			this.dirty = true;
			this.updateScrollVisual();
		}
	}

	public override function onMouseMove(mouseState:MouseState) {
		if (Util.isTouchDevice()) {
			super.onMouseMove(mouseState);
			if (this.pressed) {
				var dy = mouseState.position.y - this.prevMousePos.y;
				this.scrollY -= dy;
				this.prevMousePos = mouseState.position;
				this.updateScrollVisual();
			}
		}
	}

	// public override function onMouseDown(mouseState:MouseState) {
	// 	var renderRect = this.getHitTestRect();
	// 	if (mouseState.position.x >= renderRect.position.x + renderRect.extent.x - 10) {
	// 		this.scrollY = mouseState.position.y - renderRect.position.y;
	// 		this.updateScrollVisual();
	// 	}
	// 	super.onMouseDown(mouseState);
	// }
}
