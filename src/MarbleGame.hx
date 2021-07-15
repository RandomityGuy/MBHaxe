package src;

import src.ResourceLoader;
import src.AudioManager;
import gui.PlayMissionGui;
import gui.ExitGameDlg;
import hxd.Key;
import src.Mission;
import h3d.Vector;
import gui.GuiControl.MouseState;
import hxd.Window;
import src.MarbleWorld;
import gui.Canvas;

@:publicFields
class MarbleGame {
	static var canvas:Canvas;

	static var instance:MarbleGame;

	var world:MarbleWorld;

	var scene2d:h2d.Scene;
	var scene:h3d.scene.Scene;

	var paused:Bool;

	var exitGameDlg:ExitGameDlg;

	public function new(scene2d:h2d.Scene, scene:h3d.scene.Scene) {
		canvas = new Canvas(scene2d, cast this);
		this.scene = scene;
		this.scene2d = scene2d;
		MarbleGame.instance = this;

		#if js
		// Pause shit
		js.Browser.document.addEventListener('pointerlockchange', () -> {
			if (!paused && world != null) {
				if (world.finishTime == null && world._ready) {
					trace(js.Browser.document.pointerLockElement);
					trace(@:privateAccess Window.getInstance().canvas);
					if (js.Browser.document.pointerLockElement != @:privateAccess Window.getInstance().canvas) {
						paused = true;
						handlePauseGame();
						// Focus the shit again
						var jsCanvas = @:privateAccess Window.getInstance().canvas;
						@:privateAccess Window.getInstance().lockCallback = null; // Fix cursorlock position shit
						jsCanvas.focus();
						// js.Browser.document.exitPointerLock();
					}
				}
			}
		});
		// Resize shit
		js.Browser.window.addEventListener('resize', () -> {
			var canvasElement = js.Browser.document.getElementById("webgl");
			canvasElement.style.width = "100%";
			canvasElement.style.height = "100%";
		});
		#end
	}

	public function update(dt:Float) {
		if (world != null) {
			if (world._disposed) {
				world = null;
				return;
			}
			if (!paused) {
				world.update(dt);
			}
			if (Key.isPressed(Key.ESCAPE) && world.finishTime == null && world._ready) {
				#if hl
				paused = !paused;
				handlePauseGame();
				#end
				#if js
				if (paused)
					paused = false;
				handlePauseGame();
				#end
			}
		}
		if (canvas != null) {
			var wnd = Window.getInstance();
			var mouseState:MouseState = {
				position: new Vector(wnd.mouseX, wnd.mouseY)
			}
			canvas.update(dt, mouseState);
		}
	}

	public function handlePauseGame() {
		if (paused && world._ready) {
			world.setCursorLock(false);
			exitGameDlg = new ExitGameDlg((sender) -> {
				canvas.popDialog(exitGameDlg);
				quitMission();
			}, (sender) -> {
				canvas.popDialog(exitGameDlg);
				paused = !paused;
				world.setCursorLock(true);
			}, (sender) -> {
				canvas.popDialog(exitGameDlg);
				world.restart();
				// world.setCursorLock(true);
				paused = !paused;
			});
			canvas.pushDialog(exitGameDlg);
		} else {
			if (world._ready) {
				if (exitGameDlg != null)
					canvas.popDialog(exitGameDlg);
				world.setCursorLock(true);
			}
		}
	}

	public function quitMission() {
		world.setCursorLock(false);
		paused = false;
		var pmg = new PlayMissionGui();
		PlayMissionGui.currentSelectionStatic = world.mission.index;
		world.dispose();
		world = null;
		canvas.setContent(pmg);
	}

	public function playMission(mission:Mission) {
		canvas.clearContent();
		world = new MarbleWorld(scene, scene2d, mission);
		world.init();
	}

	public function render(e:h3d.Engine) {
		if (world != null && !world._disposed)
			world.render(e);
		canvas.renderEngine(e);
	}
}
