package src;

import haxe.io.Path;
import gui.MultiplayerGui;
import net.MasterServerClient;
import gui.MultiplayerLevelSelectGui;
import net.NetCommands;
import net.Net;
import gui.LevelSelectGui;
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
import src.PreviewWorld;

@:publicFields
class MarbleGame {
	static var canvas:Canvas;
	static var instance:MarbleGame;

	static var currentVersion = "1.1.3";

	var world:MarbleWorld;
	var previewWorld:PreviewWorld;

	var scene2d:h2d.Scene;
	var scene:h3d.scene.Scene;

	var paused:Bool;
	var toRecord:Bool = false;
	var recordingName:String;

	var exitGameDlg:ExitGameDlg;

	var touchInput:TouchInput;

	var consoleShown:Bool = false;
	var console:ConsoleDlg;

	var _mouseWheelDelta:Float;
	var _exitingToMenu:Bool = false;

	var fpsLimit:Float = 60;
	var limitingFps:Bool = false;
	var fpsLimitAccum:Float = 0.0;

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
				if (world.finishTime == null && world._ready && @:privateAccess !world.playGui.isChatFocused()) {
					if (js.Browser.document.pointerLockElement != @:privateAccess Window.getInstance().canvas) {
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
			if (world != null && @:privateAccess world.playGui.isChatFocused()) {
				@:privateAccess Window.getInstance().onKeyDown(e);
			}
		});
		js.Browser.window.addEventListener('keyup', (e:js.html.KeyboardEvent) -> {
			var buttonCode = (e.keyCode);
			@:privateAccess Key.keyPressed[buttonCode] = -Key.getFrame();
			if (world != null && @:privateAccess world.playGui.isChatFocused()) {
				@:privateAccess Window.getInstance().onKeyUp(e);
			}
		});
		js.Browser.window.addEventListener('keypress', (e:js.html.KeyboardEvent) -> {
			if (world != null && @:privateAccess world.playGui.isChatFocused()) {
				@:privateAccess Window.getInstance().onKeyPress(e);
			}
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

		if (limitingFps) {
			fpsLimitAccum += dt;
			if (fpsLimitAccum < 1.0 / fpsLimit) {
				return;
			}
			fpsLimitAccum -= (1.0 / fpsLimit);
			dt = 1.0 / fpsLimit;
		}

		if (world != null) {
			if (world._disposed) {
				world = null;
				return;
			}
			Debug.update(dt);
			if (Util.isTouchDevice()) {
				touchInput.update();
			}
			if (!paused || world.isMultiplayer) {
				world.update(dt * Debug.timeScale);
			}
			if (((Key.isPressed(Key.ESCAPE) #if js && paused #end) || Gamepad.isPressed(["start"]))
				&& world.finishTime == null
				&& world._ready) {
				handlePauseGame();
			}
		}
		if (world == null && previewWorld != null) {
			previewWorld.update(dt * Debug.timeScale);
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
				wheel: _mouseWheelDelta,
				handled: false
			}
			ProfilerUI.measure("canvasUpdate", 1);
			canvas.update(dt, mouseState);
		}
	}

	public function showPauseUI() {
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
			@:privateAccess world.playGui.setGuiVisibility(true);
			canvas.popDialog(exitGameDlg);
			paused = !paused;
			var w = getWorld();
			w.setCursorLock(true);
		}, (sender) -> {
			@:privateAccess world.playGui.setGuiVisibility(true);
			canvas.popDialog(exitGameDlg);
			var w = getWorld();
			w.restart(w.marble, true);
			// world.setCursorLock(true);
			paused = !paused;
		});
		canvas.pushDialog(exitGameDlg);
	}

	public function handlePauseGame() {
		if (!paused && world._ready) {
			paused = true;
			Console.log("Game paused");
			world.setCursorLock(false);
			@:privateAccess world.playGui.setGuiVisibility(false);
			AudioManager.playSound(ResourceLoader.getAudio('data/sound/level_text.wav').resource);
			showPauseUI();
		} else {
			if (world._ready) {
				if (canvas.children[0] is ExitGameDlg) {
					paused = false;
					Console.log("Game unpaused");
					if (exitGameDlg != null) {
						canvas.popDialog(exitGameDlg);
						@:privateAccess world.playGui.setGuiVisibility(true);
					}
					world.setCursorLock(true);
				}
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
		var watching = world.isWatching;
		var missionType = world.mission.type;
		var isNotCustom = !world.mission.isClaMission && !world.mission.isCustom;
		var lastMis = Path.withoutExtension(Path.withoutDirectory(world.mission.path));
		world.setCursorLock(false);
		if (!Settings.levelStatistics.exists(world.mission.path)) {
			Settings.levelStatistics.set(world.mission.path, {
				oobs: 0,
				respawns: 0,
				totalTime: 0,
				totalMPScore: 0
			});
		}
		var stats = Settings.levelStatistics[world.mission.path];
		Analytics.trackLevelQuit(world.mission.title, world.mission.path, Std.int(world.timeState.timeSinceLoad * 1000), stats.oobs, stats.respawns,
			Settings.optionsSettings.rewindEnabled);
		world.dispose();
		world = null;
		paused = false;
		if (watching) {
			#if !js
			canvas.setContent(new ReplayCenterGui());
			#else
			canvas.setContent(new MainMenuGui());
			#end
		} else {
			if (Net.isMP) {
				if (weDisconnecting) {
					MarbleGame.instance.setPreviewMission(lastMis, () -> {
						canvas.setContent(new MultiplayerGui());
					});
				} else {
					var lobby = new MultiplayerLevelSelectGui(Net.isHost);
					canvas.setContent(lobby);
				}
			} else {
				var pmg = new LevelSelectGui(LevelSelectGui.currentDifficultyStatic);
				if (_exitingToMenu) {
					_exitingToMenu = false;
					canvas.setContent(new MainMenuGui());
				} else {
					canvas.setContent(pmg);
				}
			}
		}

		Settings.save();
	}

	public function playMission(mission:Mission, multiplayer:Bool = false) {
		canvas.clearContent();
		destroyPreviewWorld();
		if (world != null) {
			world.dispose();
		}
		Analytics.trackLevelPlay(mission.title, mission.path);
		world = new MarbleWorld(scene, scene2d, mission, toRecord, multiplayer);
		world.init();
	}

	public function watchMissionReplay(mission:Mission, replay:Replay) {
		canvas.clearContent();
		destroyPreviewWorld();
		Analytics.trackSingle("replay-watch");
		world = new MarbleWorld(scene, scene2d, mission);
		world.replay = replay;
		world.isWatching = true;
		world.init();
	}

	public function startPreviewWorld(onFinish:() -> Void) {
		previewWorld = new PreviewWorld(scene);
		previewWorld.init(onFinish);
	}

	public function destroyPreviewWorld() {
		previewWorld.destroyAllObjects();
	}

	public function setPreviewMission(misname:String, onFinish:() -> Void, physics:Bool = false) {
		Console.log("Setting preview mission " + misname);
		previewWorld.loadMission(misname, onFinish, physics);
	}

	public function render(e:h3d.Engine) {
		if (world != null && !world._disposed)
			world.render(e);
		if (previewWorld != null && world == null)
			previewWorld.render(e);
		canvas.renderEngine(e);
	}
}
