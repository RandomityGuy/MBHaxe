package src;

import h3d.Vector;
import haxe.ds.Option;
import gui.Canvas;
import src.AudioManager;
import hxd.Key;
import src.MarbleGame;
import hxd.Window;
import haxe.DynamicAccess;
#if hl
import sys.io.File;
import sys.FileSystem;
import haxe.io.Path;
#end
import src.ResourceLoader;
import haxe.Json;
import src.Util;

typedef Score = {
	var name:String;
	var time:Float;
}

typedef OptionsSettings = {
	var screenWidth:Int;
	var screenHeight:Int;
	var isFullScreen:Bool;
	var videoDriver:Int;
	var colorDepth:Int;
	var shadows:Bool;
	var musicVolume:Float;
	var soundVolume:Float;
	var vsync:Bool;
	var fovX:Int;
	var rewindEnabled:Bool;
	var rewindTimescale:Float;
}

typedef ControlsSettings = {
	var forward:Int;
	var backward:Int;
	var left:Int;
	var right:Int;
	var camForward:Int;
	var camBackward:Int;
	var camLeft:Int;
	var camRight:Int;
	var jump:Int;
	var powerup:Int;
	var freelook:Int;
	var alwaysFreeLook:Bool;
	var cameraSensitivity:Float;
	var invertYAxis:Bool;
	var rewind:Int;
	var respawn:Int;
}

typedef TouchSettings = {
	var joystickPos:Array<Float>;
	var joystickSize:Float;
	var jumpButtonPos:Array<Float>;
	var jumpButtonSize:Float;
	var powerupButtonPos:Array<Float>;
	var powerupButtonSize:Float;
	var rewindButtonPos:Array<Float>;
	var rewindButtonSize:Float;
	var buttonJoystickMultiplier:Float;
}

typedef GamepadSettings = {
	var moveXAxis:String;
	var moveYAxis:String;
	var cameraXAxis:String;
	var cameraYAxis:String;
	var jump:Array<String>;
	var powerup:Array<String>;
	var cameraSensitivity:Float;
	var invertXAxis:Bool;
	var invertYAxis:Bool;
	var axisDeadzone:Float;
	var rewind:Array<String>;
}

class Settings {
	public static var highScores:Map<String, Array<Score>> = [];

	public static var optionsSettings:OptionsSettings = {
		screenWidth: 1280,
		screenHeight: 720,
		isFullScreen: false,
		videoDriver: 0,
		colorDepth: 1,
		shadows: false,
		musicVolume: 1,
		soundVolume: 0.7,
		fovX: 90,
		rewindEnabled: false,
		rewindTimescale: 1,
		vsync: #if js true #end
		#if hl
		false
		#end
	};

	public static var controlsSettings:ControlsSettings = {
		forward: Key.W,
		backward: Key.S,
		left: Key.A,
		right: Key.D,
		camForward: Key.UP,
		camBackward: Key.DOWN,
		camLeft: Key.LEFT,
		camRight: Key.RIGHT,
		jump: Key.SPACE,
		powerup: Key.MOUSE_LEFT,
		freelook: Key.MOUSE_RIGHT,
		alwaysFreeLook: true,
		cameraSensitivity: 0.6,
		invertYAxis: false,
		rewind: Key.R,
		respawn: Key.T,
	};

	public static var touchSettings:TouchSettings = {
		joystickPos: [100, 40],
		joystickSize: 50,
		jumpButtonPos: [440, 320],
		jumpButtonSize: 60,
		powerupButtonPos: [440, 180],
		powerupButtonSize: 60,
		rewindButtonPos: [380, 240],
		rewindButtonSize: 60,
		buttonJoystickMultiplier: 2.5
	}

	public static var gamepadSettings:GamepadSettings = {
		moveXAxis: "analogX",
		moveYAxis: "analogY",
		cameraXAxis: "ranalogX",
		cameraYAxis: "ranalogY",
		jump: ["A", "LT"],
		powerup: ["B", "RT"],
		cameraSensitivity: 1.0,
		invertXAxis: false,
		invertYAxis: false,
		axisDeadzone: 0.15,
		rewind: ["Y"],
	}

	public static var progression = [24, 24, 52];
	public static var highscoreName = "";

	public static var uiScale = 1.0;

	public static var zoomRatio = 1.0;

	public static var isTouch:Option<Bool> = Option.None;

	#if hl
	#if MACOS_BUNDLE
	public static var settingsDir = Path.join([Sys.getEnv("HOME"), "Library", "Application Support", "MBHaxe-MBG"]);
	#else
	public static var settingsDir = ".";
	#end
	#end
	public static function applySettings() {
		#if hl
		Window.getInstance().resize(optionsSettings.screenWidth, optionsSettings.screenHeight);
		Window.getInstance().displayMode = optionsSettings.isFullScreen ? Borderless : Windowed;
		#end
		AudioManager.updateVolumes();

		MarbleGame.canvas.render(MarbleGame.canvas.scene2d);
		save();
	}

	public static function saveScore(mapPath:String, score:Score) {
		if (highScores.exists(mapPath)) {
			var scoreList = highScores.get(mapPath);
			scoreList.push(score);
			scoreList.sort((a, b) -> a.time == b.time ? 0 : (a.time > b.time ? 1 : -1));
		} else {
			highScores.set(mapPath, [score]);
		}
		save();
	}

	public static function getScores(mapPath:String) {
		if (highScores.exists(mapPath)) {
			return highScores.get(mapPath).copy();
		} else {
			return [];
		}
	}

	public static function save() {
		var outputData:Dynamic = {
			options: optionsSettings,
			controls: controlsSettings,
			touch: touchSettings,
			gamepad: gamepadSettings,
			progression: progression,
			highscoreName: highscoreName
		};
		var scoreCount = 0;
		for (key => value in highScores) {
			scoreCount++;
		}
		#if hl
		if (scoreCount != 0)
			outputData.highScores = highScores;
		else
			outputData.highScores = {};
		#end
		#if js
		var kvps:Array<Dynamic> = [];
		for (key => value in highScores)
			kvps.push([key, value]);
		var jobj = js.lib.Object.fromEntries(kvps);
		outputData.highScores = jobj;
		#end
		var json = Json.stringify(outputData);
		#if (hl && !android)
		if (!FileSystem.exists(settingsDir)) {
			FileSystem.createDirectory(settingsDir);
		}
		File.saveContent(Path.join([settingsDir, "settings.json"]), json);
		#end
		#if js
		var localStorage = js.Browser.getLocalStorage();
		if (localStorage != null) {
			localStorage.setItem("MBHaxeSettings", json);
		}
		#end
	}

	public static function load() {
		var settingsExists = false;
		#if hl
		settingsExists = FileSystem.exists(Path.join([settingsDir, "settings.json"]));
		#end
		#if js
		var localStorage = js.Browser.getLocalStorage();
		if (localStorage != null) {
			settingsExists = localStorage.getItem("MBHaxeSettings") != null;
		}
		#end

		if (settingsExists) {
			#if hl
			var json = Json.parse(File.getContent(Path.join([settingsDir, "settings.json"])));
			#end
			#if js
			var json = Json.parse(localStorage.getItem("MBHaxeSettings"));
			#end
			var highScoreData:DynamicAccess<Array<Score>> = json.highScores;
			for (key => value in highScoreData) {
				highScores.set(key, value);
			}
			optionsSettings = json.options;
			if (optionsSettings.fovX == 0 #if js || optionsSettings.fovX == null #end)
				optionsSettings.fovX = 90;
			if (optionsSettings.rewindEnabled == false #if js || optionsSettings.rewindEnabled == null #end)
				optionsSettings.rewindEnabled = false;
			if (optionsSettings.rewindTimescale == 0 #if js || optionsSettings.rewindTimescale == null #end)
				optionsSettings.rewindTimescale = 1;
			controlsSettings = json.controls;
			if (json.touch != null) {
				touchSettings = json.touch;
			}
			if (controlsSettings.rewind == 0) {
				controlsSettings.rewind = Key.R;
			}
			if (controlsSettings.respawn == 0) {
				controlsSettings.respawn = Key.T;
			}
			if (touchSettings.rewindButtonPos == null) {
				touchSettings.rewindButtonPos = [380, 240];
				touchSettings.rewindButtonSize = 60;
			}
			if (json.gamepad != null) {
				gamepadSettings = json.gamepad;
			}
			if (gamepadSettings.rewind == null) {
				gamepadSettings.rewind = ["Y"];
			}
			#if js
			if (controlsSettings.rewind == null) {
				controlsSettings.rewind = Key.R;
			}
			if (controlsSettings.respawn == null) {
				controlsSettings.respawn = Key.T;
			}
			if (optionsSettings.rewindEnabled == null) {
				optionsSettings.rewindEnabled = false;
			}
			if (optionsSettings.rewindTimescale == null) {
				optionsSettings.rewindTimescale = 1;
			}
			#end
			progression = json.progression;
			highscoreName = json.highscoreName;
		} else {
			save();
		}
		#if hl
		Window.getInstance().vsync = optionsSettings.vsync;
		#end
	}

	public static function init() {
		load();
		#if hl
		Window.getInstance().resize(optionsSettings.screenWidth, optionsSettings.screenHeight);
		Window.getInstance().displayMode = optionsSettings.isFullScreen ? Borderless : Windowed;
		uiScale = 1 / Window.getInstance().windowToPixelRatio;
		#end
		#if js
		Window.getInstance().propagateKeyEvents = true;
		#end
		// @:privateAccess Window.getInstance().window.center();
		Window.getInstance().addResizeEvent(() -> {
			var wnd = Window.getInstance();
			var zoomRatio = Window.getInstance().windowToPixelRatio;
			#if js
			var zoomRatio = (Util.isTouchDevice() && !Util.isTablet()) ? js.Browser.window.screen.height * js.Browser.window.devicePixelRatio / 600 : js.Browser.window.devicePixelRatio; // 768 / js.Browser.window.innerHeight; // js.Browser.window.innerHeight * js.Browser.window.devicePixelRatio / 768;
			if (Util.isIPhone())
				zoomRatio = 2;
			Settings.zoomRatio = zoomRatio;
			#end
			#if android
			var zoomRatio = Window.getInstance().height / 600;
			Settings.zoomRatio = zoomRatio;
			#end
			#if hl
			Settings.optionsSettings.screenWidth = cast wnd.width;
			Settings.optionsSettings.screenHeight = cast wnd.height;
			#end
			#if js
			Settings.optionsSettings.screenWidth = cast Math.max(js.Browser.window.screen.width,
				js.Browser.window.screen.height); // 1024; // cast(js.Browser.window.innerWidth / js.Browser.window.innerHeight) * 768; // cast js.Browser.window.innerWidth * js.Browser.window.devicePixelRatio * 0.5;
			Settings.optionsSettings.screenHeight = cast Math.min(js.Browser.window.screen.width,
				js.Browser.window.screen.height); // 768; // cast js.Browser.window.innerHeight * js.Browser.window.devicePixelRatio * 0.5;

			var canvasElement = js.Browser.document.getElementById("webgl");
			canvasElement.style.width = "100%";
			canvasElement.style.height = "100%";
			#end

			MarbleGame.canvas.scene2d.scaleMode = Zoom(zoomRatio);

			if (MarbleGame.instance.world != null) {
				MarbleGame.instance.world.scene.camera.setFovX(Settings.optionsSettings.fovX,
					Settings.optionsSettings.screenWidth / Settings.optionsSettings.screenHeight);
			}

			MarbleGame.canvas.render(MarbleGame.canvas.scene2d);
		});
	}
}
