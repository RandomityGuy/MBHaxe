package src;

import gui.MainMenuGui;
#if !js
import gui.ReplayCenterGui;
#end
import gui.ReplayNameDlg;
import gui.ConsoleDlg;
import gui.MessageBoxOkDlg;
import src.Replay;
import touch.TouchInput;
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
import src.JSPlatform;
import gui.Canvas;
import src.Util;
import src.ProfilerUI;
import src.Settings;
import src.Console;
import src.Debug;
import src.Gamepad;

@:publicFields
class MarbleGame {
	static var canvas:Canvas;

	static var instance:MarbleGame;

	var world:MarbleWorld;

	var scene2d:h2d.Scene;
	var scene:h3d.scene.Scene;

	var paused:Bool;
	var toRecord:Bool = false;
	var recordingName:String;

	var exitGameDlg:ExitGameDlg;

	var touchInput:TouchInput;

	var consoleShown:Bool = false;
	var console:ConsoleDlg;

	public function new(scene2d:h2d.Scene, scene:h3d.scene.Scene) {
		Console.log("Initializing the game...");
		canvas = new Canvas(scene2d, cast this);
		this.scene = scene;
		this.scene2d = scene2d;
		MarbleGame.instance = this;
		this.touchInput = new TouchInput();

		#if js
		// Pause shit
		if (Util.isTouchDevice())
			this.touchInput.registerTouchInput();

		js.Browser.document.addEventListener('pointerlockchange', () -> {
			if (!paused && world != null) {
				if (world.finishTime == null && world._ready) {
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
		var canvas = js.Browser.document.getElementById("webgl");
		var pointercontainer = js.Browser.document.querySelector("#pointercontainer");
		pointercontainer.addEventListener('mousedown', (e:js.html.MouseEvent) -> {
			var buttonCode = switch (e.button) {
				case 1: 2;
				case 2: 1;
				case x: x;
			};
			@:privateAccess Key.keyPressed[buttonCode] = Key.getFrame();
			@:privateAccess Window.getInstance().onMouseDown(e);
		});
		pointercontainer.addEventListener('mouseup', (e:js.html.MouseEvent) -> {
			var buttonCode = switch (e.button) {
				case 1: 2;
				case 2: 1;
				case x: x;
			};
			@:privateAccess Key.keyPressed[buttonCode] = -Key.getFrame();
			@:privateAccess Window.getInstance().onMouseUp(e);
		});
		canvas.addEventListener('mousedown', (e:js.html.MouseEvent) -> {
			var buttonCode = switch (e.button) {
				case 1: 2;
				case 2: 1;
				case x: x;
			};
			@:privateAccess Key.keyPressed[buttonCode] = Key.getFrame();
		});
		canvas.addEventListener('mouseup', (e:js.html.MouseEvent) -> {
			var buttonCode = switch (e.button) {
				case 1: 2;
				case 2: 1;
				case x: x;
			};
			@:privateAccess Key.keyPressed[buttonCode] = -Key.getFrame();
		});
		pointercontainer.addEventListener('keypress', (e:js.html.KeyboardEvent) -> {
			@:privateAccess Window.getInstance().onKeyPress(e);
		});
		pointercontainer.addEventListener('keydown', (e:js.html.KeyboardEvent) -> {
			var buttonCode = (e.keyCode);
			@:privateAccess Key.keyPressed[buttonCode] = Key.getFrame();
			@:privateAccess Window.getInstance().onKeyDown(e);
		});
		pointercontainer.addEventListener('keyup', (e:js.html.KeyboardEvent) -> {
			var buttonCode = (e.keyCode);
			@:privateAccess Key.keyPressed[buttonCode] = -Key.getFrame();
			@:privateAccess Window.getInstance().onKeyUp(e);
		});
		js.Browser.window.addEventListener('keydown', (e:js.html.KeyboardEvent) -> {
			var buttonCode = (e.keyCode);
			@:privateAccess Key.keyPressed[buttonCode] = Key.getFrame();
		});
		js.Browser.window.addEventListener('keyup', (e:js.html.KeyboardEvent) -> {
			var buttonCode = (e.keyCode);
			@:privateAccess Key.keyPressed[buttonCode] = -Key.getFrame();
		});

		pointercontainer.addEventListener('touchstart', (e:js.html.TouchEvent) -> {
			@:privateAccess Key.keyPressed[Key.MOUSE_LEFT] = Key.getFrame();
			@:privateAccess scene2d.window.curMouseX = e.touches[0].clientX;
			@:privateAccess scene2d.window.curMouseY = e.touches[0].clientY;
		});

		pointercontainer.addEventListener('touchend', (e:js.html.TouchEvent) -> {
			// @:privateAccess Key.keyPressed[Key.MOUSE_LEFT] = -Key.getFrame();
		});

		pointercontainer.addEventListener('touchmove', (e:js.html.TouchEvent) -> {
			@:privateAccess scene2d.window.curMouseX = e.touches[0].clientX;
			@:privateAccess scene2d.window.curMouseY = e.touches[0].clientY;
		});

		js.Browser.window.addEventListener('contextmenu', (e) -> e.preventDefault()); // Disable right click context menu for good

		js.Browser.window.addEventListener('beforeunload', (e) -> {
			// Ask the user if they're sure about closing the tab if they're currently in game
			if (world != null) {
				e.preventDefault();
				e.returnValue = '';
			}
		});
		JSPlatform.initFullscreenEnforcer();

		Window.getInstance().removeEventTarget(@:privateAccess Key.onEvent);
		#end
	}

	public function update(dt:Float) {
		if (world != null) {
			if (world._disposed) {
				world = null;
				return;
			}
			Debug.update();
			if (Util.isTouchDevice()) {
				touchInput.update();
			}
			if (!paused) {
				world.update(dt * Debug.timeScale);
			}
			if (((Key.isPressed(Key.ESCAPE) #if js && paused #end) || Gamepad.isPressed(["start"]))
				&& world.finishTime == null
				&& world._ready) {
				paused = !paused;
				handlePauseGame();
			}
		}
		if (canvas != null) {
			if (Key.isPressed(Key.QWERTY_TILDE)) {
				consoleShown = !consoleShown;
				if (consoleShown) {
					if (console == null || @:privateAccess console._disposed)
						console = new ConsoleDlg();
					@:privateAccess console.isShowing = true;
					canvas.pushDialog(console);
				} else {
					@:privateAccess console.isShowing = false;
					canvas.popDialog(console, false);
				}
			}

			var mouseState:MouseState = {
				position: new Vector(canvas.scene2d.mouseX, canvas.scene2d.mouseY)
			}
			ProfilerUI.measure("canvasUpdate");
			canvas.update(dt, mouseState);
		}
	}

	public function handlePauseGame() {
		if (paused && world._ready) {
			Console.log("Game paused");
			world.setCursorLock(false);
			exitGameDlg = new ExitGameDlg((sender) -> {
				canvas.popDialog(exitGameDlg);
				if (world.isRecording) {
					MarbleGame.canvas.pushDialog(new ReplayNameDlg(() -> {
						quitMission();
					}));
				} else {
					quitMission();
				}
			}, (sender) -> {
				canvas.popDialog(exitGameDlg);
				paused = !paused;
				world.setCursorLock(true);
			}, (sender) -> {
				canvas.popDialog(exitGameDlg);
				world.restart(true);
				// world.setCursorLock(true);
				paused = !paused;
			});
			canvas.pushDialog(exitGameDlg);
		} else {
			if (world._ready) {
				Console.log("Game unpaused");
				if (exitGameDlg != null)
					canvas.popDialog(exitGameDlg);
				world.setCursorLock(true);
			}
		}
	}

	public function quitMission() {
		Console.log("Quitting mission");
		world.setCursorLock(false);
		paused = false;
		if (world.isWatching) {
			#if !js
			canvas.setContent(new ReplayCenterGui());
			#else
			canvas.setContent(new MainMenuGui());
			#end
		} else {
			if (!world.mission.isClaMission) {
				PlayMissionGui.currentCategoryStatic = world.mission.type;
			}
			var pmg = new PlayMissionGui();
			PlayMissionGui.currentSelectionStatic = world.mission.index;
			PlayMissionGui.currentGameStatic = world.mission.game;
			canvas.setContent(pmg);
		}
		world.dispose();
		world = null;

		Settings.save();
	}

	public function playMission(mission:Mission) {
		canvas.clearContent();
		if (world != null) {
			world.dispose();
		}
		world = new MarbleWorld(scene, scene2d, mission, toRecord);
		world.init();
	}

	public function watchMissionReplay(mission:Mission, replay:Replay) {
		canvas.clearContent();
		world = new MarbleWorld(scene, scene2d, mission);
		world.replay = replay;
		world.isWatching = true;
		world.init();
	}

	public function render(e:h3d.Engine) {
		if (world != null && !world._disposed)
			world.render(e);
		canvas.renderEngine(e);
	}
}
