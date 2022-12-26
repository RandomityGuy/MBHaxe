package gui;

import h2d.Bitmap;
import h3d.Vector;
import src.Settings;
import gui.GuiControl.MouseState;
import h2d.Interactive;
import h2d.Scene;
import h2d.Tile;
import h2d.Graphics;
import src.MarbleGame;
import src.Util;

class GuiConsoleScrollCtrl extends GuiControl {
	public var scrollY:Float = 0;

	var maxScrollY:Float;

	var scrollBarY:Graphics;
	var scrollTrack:Bitmap;

	var scrollTopTile:Tile;
	var scrollBottomTile:Tile;
	var scrollFillTile:Tile;

	var scrollTopPressedTile:Tile;
	var scrollBottomPressedTile:Tile;
	var scrollFillPressedTile:Tile;

	var scrollTrackTile:Tile;

	var clickInteractive:Interactive;

	var pressed:Bool = false;
	var dirty:Bool = true;
	var prevMousePos:Vector;

	var scrollUpButton:GuiButton;
	var scrollDownButton:GuiButton;

	public function new(scrollBar:Tile) {
		super();
		this.scrollTopTile = scrollBar.sub(0, 37, 18, 8);
		this.scrollBottomTile = scrollBar.sub(0, 55, 18, 8);
		this.scrollFillTile = scrollBar.sub(0, 46, 18, 1);
		this.scrollTopPressedTile = scrollBar.sub(19, 37, 18, 8);
		this.scrollBottomPressedTile = scrollBar.sub(19, 46, 18, 8);
		this.scrollFillPressedTile = scrollBar.sub(19, 55, 18, 1);
		this.scrollTrackTile = scrollBar.sub(0, 64, 18, 1);
		var scrollUpTile = scrollBar.sub(0, 1, 18, 17);
		var scrollDownTile = scrollBar.sub(0, 19, 18, 17);
		var scrollUpPressedTile = scrollBar.sub(19, 1, 18, 17);
		var scrollDownPressedTile = scrollBar.sub(19, 19, 18, 17);
		var scrollUpDisabledTile = scrollBar.sub(38, 1, 18, 17);
		var scrollDownDisabledTile = scrollBar.sub(38, 19, 18, 17);

		scrollUpButton = new GuiButton([scrollUpTile, scrollUpTile, scrollUpPressedTile, scrollUpDisabledTile]);
		scrollUpButton.position = new Vector(0, 0);
		scrollUpButton.extent = new Vector(18, 17);
		scrollUpButton.horizSizing = Right;
		scrollUpButton.pressedAction = (e) -> {
			this.scrollY -= 10;
			this.updateScrollVisual();
		}
		this.addChild(scrollUpButton);

		scrollDownButton = new GuiButton([scrollDownTile, scrollDownTile, scrollDownPressedTile, scrollDownDisabledTile]);
		scrollDownButton.position = new Vector(0, 0);
		scrollDownButton.extent = new Vector(18, 17);
		scrollDownButton.horizSizing = Right;
		scrollDownButton.pressedAction = (e) -> {
			this.scrollY += 10;
			this.updateScrollVisual();
		}
		this.addChild(scrollDownButton);

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
		this.scrollTrack = new Bitmap(scrollTrackTile);
	}

	public function setScrollMax(max:Float) {
		this.scrollY = 0;
		this.maxScrollY = max;
		this.dirty = true;
		this.updateScrollVisual();
	}

	public override function getRenderRectangle():Rect {
		var rrec = super.getRenderRectangle();
		rrec.scroll.y = scrollY * this.maxScrollY / (rrec.extent.y - 34 * Settings.uiScale);
		return rrec;
	}

	public override function render(scene2d:Scene) {
		this.dirty = true;

		scrollUpButton.position = new Vector(this.extent.x - 18, 0);
		scrollDownButton.position = new Vector(this.extent.x - 18, this.extent.y - 17);

		if (scene2d.contains(scrollTrack))
			scene2d.removeChild(scrollTrack);

		if (scene2d.contains(scrollBarY))
			scene2d.removeChild(scrollBarY);

		if (scene2d.contains(clickInteractive))
			scene2d.removeChild(clickInteractive);

		scene2d.addChild(scrollTrack);
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

		this.scrollTrack.setPosition(renderRect.position.x + renderRect.extent.x - 18 * Settings.uiScale, renderRect.position.y);

		var scrollExtentY = renderRect.extent.y - 34 * Settings.uiScale;

		var scrollBarYSize = (scrollExtentY * scrollExtentY / (maxScrollY * Settings.uiScale - 34 * Settings.uiScale));

		this.scrollTrack.scaleY = renderRect.extent.y;

		this.scrollY = Util.clamp(scrollY, 0, scrollExtentY - scrollBarYSize * Settings.uiScale);

		this.scrollBarY.setPosition(renderRect.position.x
			+ renderRect.extent.x
			- 18 * Settings.uiScale,
			18 * Settings.uiScale
			+ renderRect.position.y
			+ scrollY);

		this.clickInteractive.setPosition(renderRect.position.x + renderRect.extent.x - 18 * Settings.uiScale, 18 * Settings.uiScale + renderRect.position.y);

		this.clickInteractive.height = scrollExtentY;

		if (this.dirty) {
			if (scrollBarYSize > scrollExtentY) {
				scrollBarYSize = scrollExtentY;
				scrollBarY.clear();
				return;
			}

			scrollBarY.clear();

			scrollBarY.tileWrap = true;

			scrollBarY.drawTile(0, 0, pressed ? scrollTopPressedTile : scrollTopTile);

			// :skull:
			for (i in 0...cast(scrollBarYSize - 12)) {
				scrollBarY.drawTile(0, i + 8, pressed ? scrollFillPressedTile : scrollFillTile);
			}

			scrollBarY.drawTile(0, scrollBarYSize - 8, pressed ? scrollBottomPressedTile : scrollBottomTile);

			this.dirty = false;
		}

		for (c in this.children) {
			c.onScroll(0, scrollY * (this.maxScrollY - 34 * Settings.uiScale) / scrollExtentY);
		}
	}

	public override function dispose() {
		super.dispose();
		this.scrollBarY.remove();
		this.scrollTrack.remove();
		this.clickInteractive.remove();
	}

	public function setScrollPercentage(f:Float) {
		var renderRect = this.getRenderRectangle();
		var scrollExtentY = renderRect.extent.y - 34 * Settings.uiScale;
		var scrollBarYSize = (scrollExtentY * scrollExtentY / (maxScrollY * Settings.uiScale - 34 * Settings.uiScale));

		this.scrollY = Util.lerp(0, scrollExtentY - scrollBarYSize * Settings.uiScale, f);
		updateScrollVisual();
	}

	public override function onRemove() {
		super.onRemove();
		if (MarbleGame.canvas.scene2d.contains(scrollTrack)) {
			MarbleGame.canvas.scene2d.removeChild(scrollTrack); // Refresh "layer"
		}
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
