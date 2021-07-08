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

	var world:MarbleWorld;

	var scene2d:h2d.Scene;
	var scene:h3d.scene.Scene;

	var paused:Bool;

	var exitGameDlg:ExitGameDlg;

	public function new(scene2d:h2d.Scene, scene:h3d.scene.Scene) {
		canvas = new Canvas(scene2d, cast this);
		this.scene = scene;
		this.scene2d = scene2d;

		#if js
		js.Browser.document.addEventListener('pointerlockchange', () -> {
			if (!paused && world != null) {
				if (world.finishTime == null) {
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
			if (Key.isPressed(Key.ESCAPE) && world.finishTime == null) {
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
		if (paused) {
			world.setCursorLock(false);
			exitGameDlg = new ExitGameDlg((sender) -> {
				canvas.popDialog(exitGameDlg);
				paused = !paused;
				world.dispose();
				world = null;
				canvas.setContent(new PlayMissionGui());
			}, (sender) -> {
				canvas.popDialog(exitGameDlg);
				paused = !paused;
				world.setCursorLock(true);
			}, (sender) -> {
				canvas.popDialog(exitGameDlg);
				world.restart();
				world.setCursorLock(true);
				paused = !paused;
			});
			canvas.pushDialog(exitGameDlg);
		} else {
			canvas.popDialog(exitGameDlg);
			world.setCursorLock(true);
		}
	}

	public function playMission(mission:Mission) {
		var musicFileName = [
			'data/sound/groovepolice.ogg',
			'data/sound/classic vibe.ogg',
			'data/sound/beach party.ogg'
		][(mission.index + 1) % 3];
		AudioManager.playMusic(ResourceLoader.getAudio(musicFileName));
		canvas.clearContent();
		mission.load();
		world = new MarbleWorld(scene, scene2d, mission);
		world.init();
		world.start();
	}

	public function render(e:h3d.Engine) {
		if (world != null && !world._disposed)
			world.render(e);
		canvas.renderEngine(e);
	}
}
