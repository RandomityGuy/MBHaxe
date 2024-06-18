package src;

import gui.MPExitGameDlg;
import gui.GuiControl;
import gui.MPPlayMissionGui;
import gui.MainMenuGui;
#if !js
import gui.ReplayCenterGui;
#end
import gui.ReplayNameDlg;
import gui.ConsoleDlg;
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
import src.Analytics;
import net.Net;
import net.MasterServerClient;
import net.NetCommands;

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

	var exitGameDlg:GuiControl;

	var touchInput:TouchInput;

	var consoleShown:Bool = false;
	var console:ConsoleDlg;

	var _mouseWheelDelta:Float;

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
		scene2d.addEventListener(e -> {
			_mouseWheelDelta = e.wheelDelta;
		});

		Analytics.trackSingle("game-start");
		Analytics.trackPlatformInfo();
	}

	public function update(dt:Float) {
		MasterServerClient.process();
		Net.checkPacketTimeout(dt);
		if (world != null) {
			if (world._disposed) {
				world = null;
				return;
			}
			Debug.update();
			if (Util.isTouchDevice()) {
				touchInput.update();
			}
			if (!paused || world.isMultiplayer) {
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
					console.unfocus();
					canvas.popDialog(console, false);
				}
			}

			var mouseState:MouseState = {
				position: new Vector(canvas.scene2d.mouseX, canvas.scene2d.mouseY),
				wheel: _mouseWheelDelta
			}
			ProfilerUI.measure("canvasUpdate");
			canvas.update(dt, mouseState);
		}
	}

	public function handlePauseGame() {
		if (paused && world._ready) {
			Console.log("Game paused");
			world.setCursorLock(false);
			if (world.isMultiplayer) {
				exitGameDlg = new MPExitGameDlg(() -> {
					canvas.popDialog(exitGameDlg);
					paused = !paused;
					var w = getWorld();
					w.setCursorLock(true);
				}, () -> {
					canvas.popDialog(exitGameDlg);
					quitMission(Net.isClient);
					if (Net.isMP && Net.isClient) {
						Net.disconnect();
					}
				});
			} else {
				exitGameDlg = new ExitGameDlg((sender) -> {
					canvas.popDialog(exitGameDlg);
					var w = getWorld();
					if (w.isRecording) {
						MarbleGame.canvas.pushDialog(new ReplayNameDlg(() -> {
							quitMission();
						}));
					} else {
						quitMission(Net.isClient);
						if (Net.isMP && Net.isClient) {
							Net.disconnect();
						}
					}
				}, (sender) -> {
					canvas.popDialog(exitGameDlg);
					paused = !paused;
					var w = getWorld();
					w.setCursorLock(true);
				}, (sender) -> {
					canvas.popDialog(exitGameDlg);
					var w = getWorld();
					w.restart(w.marble, true);
					// world.setCursorLock(true);
					paused = !paused;
				});
			}
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

	public function getWorld() {
		// So that we don't actually store this somewhere in any closure stack
		return world;
	}

	public function quitMission(weDisconnecting:Bool = false) {
		Console.log("Quitting mission");
		if (Net.isMP) {
			if (Net.isHost) {
				NetCommands.endGame();
			}
		}
		world.setCursorLock(false);
		if (!Settings.levelStatistics.exists(world.mission.path)) {
			Settings.levelStatistics.set(world.mission.path, {
				oobs: 0,
				respawns: 0,
				totalTime: 0,
			});
		}
		var stats = Settings.levelStatistics[world.mission.path];
		Analytics.trackLevelQuit(world.mission.title, world.mission.path, Std.int(world.timeState.timeSinceLoad * 1000), stats.oobs, stats.respawns,
			Settings.optionsSettings.rewindEnabled);
		paused = false;
		if (world.isWatching) {
			#if !js
			canvas.setContent(new ReplayCenterGui());
			#else
			canvas.setContent(new MainMenuGui());
			#end
		} else {
			if (Net.isMP) {
				var lobby = new MPPlayMissionGui(Net.isHost);
				canvas.setContent(lobby);
			} else {
				if (!world.mission.isClaMission && !world.mission.isCustom) {
					PlayMissionGui.currentCategoryStatic = world.mission.type;
				}
				var pmg = new PlayMissionGui();
				PlayMissionGui.currentSelectionStatic = world.mission.index;
				PlayMissionGui.currentGameStatic = world.mission.game;
				canvas.setContent(pmg);
			}
		}
		world.dispose();
		world = null;

		Settings.save();
	}

	public function playMission(mission:Mission, multiplayer:Bool = false) {
		canvas.clearContent();
		if (world != null) {
			world.dispose();
		}
		Analytics.trackLevelPlay(mission.title, mission.path);
		world = new MarbleWorld(scene, scene2d, mission, toRecord, multiplayer);
		world.init();
	}

	public function watchMissionReplay(mission:Mission, replay:Replay) {
		canvas.clearContent();
		Analytics.trackSingle("replay-watch");
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
