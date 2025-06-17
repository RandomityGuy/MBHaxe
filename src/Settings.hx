package src;

import modes.GameMode.ScoreType;
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
import src.Console;
import src.Renderer;
import net.Uuid;

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
	var frameRateVis:Bool;
	var oobInsults:Bool;
	var marbleIndex:Int;
	var marbleCategoryIndex:Int;
	var marbleSkin:String;
	var marbleModel:String;
	var marbleShader:String;
	var rewindEnabled:Bool;
	var rewindTimescale:Float;
	var reflectionDetail:Int;
	var maxPixelRatio:Float;
	var huntRandom:Bool;
	var fastLoad:Bool;
	var currentView:Int;
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
	var controllerVerticalCenter:Bool;
	var cameraSensitivity:Float;
	var invertYAxis:Bool;
	var respawn:Int;
	var blast:Int;
	var rewind:Int;
	var chat:Int;
	var oobRespawnKeyByPowerup:Bool;
	var moddedController:Bool;
}

typedef TouchSettings = {
	var joystickPos:Array<Float>;
	var joystickSize:Float;
	var jumpButtonPos:Array<Float>;
	var jumpButtonSize:Float;
	var powerupButtonPos:Array<Float>;
	var powerupButtonSize:Float;
	var blastButtonPos:Array<Float>;
	var blastButtonSize:Float;
	var rewindButtonPos:Array<Float>;
	var rewindButtonSize:Float;
	var buttonJoystickMultiplier:Float;
	var hideControls:Bool;
	var dynamicJoystick:Bool;
	var cameraSwipeExtent:Float;
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
	var respawn:Array<String>;
	var blast:Array<String>;
	var rewind:Array<String>;
	var ok:String;
	var back:String;
	var alt1:String;
	var alt2:String;
}

typedef PlayStatistics = {
	var oobs:Int;
	var respawns:Int;
	var totalTime:Float;
	var totalMPScore:Int;
}

class Settings {
	public static var highScores:Map<String, Array<Score>> = [];

	public static var easterEggs:Map<String, Float> = [];

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
		frameRateVis: false,
		oobInsults: true,
		marbleIndex: 0,
		marbleCategoryIndex: 0,
		marbleSkin: "base",
		marbleModel: "data/shapes/balls/marble01.dts",
		marbleShader: "ClassicGlassPureSphere",
		rewindEnabled: false,
		rewindTimescale: 1,
		reflectionDetail: 2,
		maxPixelRatio: 1,
		vsync: false,
		huntRandom: false,
		fastLoad: false,
		currentView: 0
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
		freelook: Key.MOUSE_MIDDLE,
		alwaysFreeLook: true,
		controllerVerticalCenter: true,
		cameraSensitivity: 0.6,
		invertYAxis: false,
		respawn: Key.BACKSPACE,
		blast: Key.MOUSE_RIGHT,
		rewind: Key.R,
		chat: Key.T,
		oobRespawnKeyByPowerup: false,
		moddedController: false
	};

	public static var touchSettings:TouchSettings = {
		joystickPos: [100, 40],
		joystickSize: 50,
		jumpButtonPos: [440, 320],
		jumpButtonSize: 60,
		powerupButtonPos: [440, 180],
		powerupButtonSize: 60,
		blastButtonPos: [300, 240],
		blastButtonSize: 60,
		rewindButtonPos: [300, 100],
		rewindButtonSize: 60,
		buttonJoystickMultiplier: 2.5,
		hideControls: false,
		dynamicJoystick: false,
		cameraSwipeExtent: 10.0
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
		respawn: ["back"],
		blast: ["X", "LB", "RB"],
		rewind: ["Y"],
		ok: "A",
		back: "B",
		alt1: "X",
		alt2: "Y"
	}

	public static var playStatistics:PlayStatistics = {
		oobs: 0,
		respawns: 0,
		totalTime: 0,
		totalMPScore: 0
	}

	public static var levelStatistics:Map<String, PlayStatistics> = [];

	public static var achievementProgression:Int;

	public static var highscoreName = "Player";
	public static var userId = "";

	public static var uiScale = 1.0;

	public static var zoomRatio = 1.0;

	public static var isTouch:Option<Bool> = Option.None;

	#if hl
	#if MACOS_BUNDLE
	public static var settingsDir = Path.join([Sys.getEnv("HOME"), "Library", "Application Support", "MBHaxe-MBU"]);
	#else
	public static var settingsDir = ".";
	#end
	#end
	public static function applySettings() {
		#if hl
		Window.getInstance().resize(optionsSettings.screenWidth, optionsSettings.screenHeight);
		Window.getInstance().displayMode = optionsSettings.isFullScreen ? FullscreenResize : Windowed;
		#end
		AudioManager.updateVolumes();
		#if hl
		Window.getInstance().vsync = optionsSettings.vsync;
		#end
		@:privateAccess cast(MarbleGame.instance.scene.renderer, Renderer).onResize();

		MarbleGame.canvas.render(MarbleGame.canvas.scene2d);
		save();
	}

	public static function saveScore(mapPath:String, score:Score, scoreType:ScoreType = Time) {
		if (highScores.exists(mapPath)) {
			var scoreList = highScores.get(mapPath);
			scoreList.push(score);
			scoreList.sort((a, b) -> a.time == b.time ? 0 : (a.time > b.time ? 1 : -1));
			if (scoreType == Score)
				scoreList.reverse();
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
			stats: playStatistics,
			highscoreName: highscoreName,
			userId: userId,
			marbleIndex: optionsSettings.marbleIndex,
			marbleSkin: optionsSettings.marbleSkin,
			marbleModel: optionsSettings.marbleModel,
			marbleCategoryIndex: optionsSettings.marbleCategoryIndex,
			marbleShader: optionsSettings.marbleShader,
			achievementProgression: achievementProgression
		};
		var scoreCount = 0;
		var eggCount = 0;
		var statCount = 0;
		for (key => value in highScores) {
			scoreCount++;
		}
		for (key => value in easterEggs) {
			eggCount++;
		}
		for (key => value in levelStatistics) {
			statCount++;
		}
		#if hl
		if (scoreCount != 0)
			outputData.highScores = highScores;
		else
			outputData.highScores = {};
		if (eggCount != 0) {
			outputData.easterEggs = easterEggs;
		} else {
			outputData.easterEggs = {};
		}
		if (statCount != 0) {
			outputData.levelStatistics = levelStatistics;
		} else {
			outputData.levelStatistics = {};
		}
		#end
		#if js
		var kvps:Array<Dynamic> = [];
		for (key => value in highScores)
			kvps.push([key, value]);
		var jobj = js.lib.Object.fromEntries(kvps);
		outputData.highScores = jobj;
		kvps = [];
		for (key => value in easterEggs)
			kvps.push([key, value]);
		jobj = js.lib.Object.fromEntries(kvps);
		outputData.easterEggs = jobj;
		kvps = [];
		for (key => value in levelStatistics)
			kvps.push([key, value]);
		jobj = js.lib.Object.fromEntries(kvps);
		outputData.levelStatistics = jobj;
		#end
		var json = Json.stringify(outputData);
		#if (hl && !android)
		if (!FileSystem.exists(settingsDir)) {
			FileSystem.createDirectory(settingsDir);
		}
		File.saveContent(Path.join([settingsDir, "settings.json"]), json);
		Console.log("Saved settings to " + Path.join([settingsDir, "settings.json"]));
		#end
		#if js
		var localStorage = js.Browser.getLocalStorage();
		if (localStorage != null) {
			localStorage.setItem("MBHaxeSettings", json);
		}
		#end
	}

	public static function load() {
		Console.log("Loading settings");
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
			var easterEggData:DynamicAccess<Float> = json.easterEggs;
			if (easterEggData != null) {
				for (key => value in easterEggData) {
					easterEggs.set(key, value);
				}
			}
			optionsSettings = json.options;
			if (optionsSettings.fovX == 0 #if js || optionsSettings.fovX == null #end)
				optionsSettings.fovX = 90;
			if (optionsSettings.rewindEnabled == false #if js || optionsSettings.rewindEnabled == null #end)
				optionsSettings.rewindEnabled = false;
			if (optionsSettings.rewindTimescale == 0 #if js || optionsSettings.rewindTimescale == null #end)
				optionsSettings.rewindTimescale = 1;
			#if js
			if (optionsSettings.reflectionDetail == null)
				optionsSettings.reflectionDetail = 2;
			if (controlsSettings.controllerVerticalCenter == null)
				controlsSettings.controllerVerticalCenter = true;
			if (optionsSettings.huntRandom == null)
				optionsSettings.huntRandom = false;
			if (optionsSettings.fastLoad == null)
				optionsSettings.fastLoad = false;
			if (optionsSettings.currentView == null)
				optionsSettings.currentView = 0;
			#end
			if (optionsSettings.maxPixelRatio == 0 #if js || optionsSettings.maxPixelRatio == null #end)
				optionsSettings.maxPixelRatio = 1;
			controlsSettings = json.controls;
			if (json.touch != null) {
				touchSettings = json.touch;
			}
			if (controlsSettings.rewind == 0) {
				controlsSettings.rewind = Key.R;
			}
			if (controlsSettings.chat == 0) {
				controlsSettings.chat = Key.T;
			}
			if (touchSettings.blastButtonPos == null) {
				touchSettings.blastButtonPos = [300, 240];
				touchSettings.blastButtonSize = 60;
			}
			if (touchSettings.rewindButtonPos == null) {
				touchSettings.rewindButtonPos = [300, 100];
				touchSettings.rewindButtonSize = 60;
			}
			#if js
			if (touchSettings.hideControls == null) {
				touchSettings.hideControls = false;
			}
			if (touchSettings.cameraSwipeExtent == null) {
				touchSettings.cameraSwipeExtent = 10.0;
			}
			if (touchSettings.dynamicJoystick == null) {
				touchSettings.dynamicJoystick = false;
			}
			#end
			if (touchSettings.cameraSwipeExtent == 0) {
				touchSettings.cameraSwipeExtent = 10.0;
			}
			if (json.gamepad != null) {
				gamepadSettings = json.gamepad;
			}
			if (gamepadSettings.respawn == null) {
				gamepadSettings.respawn = ["back"];
			}
			if (gamepadSettings.blast == null) {
				gamepadSettings.blast = ["X", "LB", "RB"];
			}
			if (gamepadSettings.rewind == null) {
				gamepadSettings.rewind = ["Y"];
			}
			if (gamepadSettings.ok == null) {
				gamepadSettings.ok = "A";
			}
			if (gamepadSettings.back == null) {
				gamepadSettings.back = "B";
			}
			if (gamepadSettings.alt1 == null) {
				gamepadSettings.alt1 = "X";
			}
			if (gamepadSettings.alt2 == null) {
				gamepadSettings.alt2 = "Y";
			}
			if (json.stats != null) {
				playStatistics = json.stats;
				#if js
				if (playStatistics.totalMPScore == null)
					playStatistics.totalMPScore = 0;
				#end
			}
			achievementProgression = json.achievementProgression;
			if (json.levelStatistics != null) {
				var levelStatData:DynamicAccess<PlayStatistics> = json.levelStatistics;
				for (key => value in levelStatData) {
					levelStatistics.set(key, value);
				}
			}
			#if js
			if (optionsSettings.marbleIndex == null) {
				optionsSettings.marbleIndex = 0;
				optionsSettings.marbleSkin = "base";
				optionsSettings.marbleModel = "data/shapes/balls/marble01.dts";
			}
			if (optionsSettings.marbleCategoryIndex == null) {
				optionsSettings.marbleCategoryIndex = 0;
			}
			if (optionsSettings.marbleShader == null) {
				optionsSettings.marbleShader = "ClassicGlassPureSphere";
			}
			if (controlsSettings.blast == null) {
				controlsSettings.blast = Key.E;
			}
			if (controlsSettings.rewind == null) {
				controlsSettings.rewind = Key.R;
			}
			if (controlsSettings.chat == null) {
				controlsSettings.chat = Key.T;
			}
			if (controlsSettings.oobRespawnKeyByPowerup == null) {
				controlsSettings.oobRespawnKeyByPowerup = false;
			}
			if (controlsSettings.moddedController == null) {
				controlsSettings.moddedController = false;
			}
			if (optionsSettings.rewindEnabled == null) {
				optionsSettings.rewindEnabled = false;
			}
			if (optionsSettings.rewindTimescale == null) {
				optionsSettings.rewindTimescale = 1;
			}
			if (achievementProgression == null)
				achievementProgression = 0;
			#end
			highscoreName = json.highscoreName;
			if (highscoreName == null) {
				highscoreName = "";
			}
			userId = json.userId;
			if (userId == null || userId == "") {
				userId = Uuid.v4();
			}
		} else {
			Console.warn("Settings file does not exist");
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
		Window.getInstance().displayMode = optionsSettings.isFullScreen ? FullscreenResize : Windowed;
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
			var zoomRatio = (Util.isTouchDevice() && !Util.isTablet()) ? js.Browser.window.screen.height * js.Browser.window.devicePixelRatio / 768 : js.Browser.window.devicePixelRatio; // 768 / js.Browser.window.innerHeight; // js.Browser.window.innerHeight * js.Browser.window.devicePixelRatio / 768;
			if (Util.isIPhone())
				zoomRatio = 1.5;
			if (Util.isIPhone() && js.Browser.window.devicePixelRatio == 2)
				zoomRatio = 1.0;
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

			Console.log("Window resized to " + Settings.optionsSettings.screenWidth + "x" + Settings.optionsSettings.screenHeight + " (Zoom " + zoomRatio +
				")");

			MarbleGame.canvas.scene2d.scaleMode = Zoom(zoomRatio);

			if (MarbleGame.instance.world != null) {
				MarbleGame.instance.world.scene.camera.setFovX(Settings.optionsSettings.fovX,
					Settings.optionsSettings.screenWidth / Settings.optionsSettings.screenHeight);
			}

			#if js
			MarbleGame.canvas.onResize(MarbleGame.canvas.scene2d.width, MarbleGame.canvas.scene2d.height);
			#end
			// Console.log('Window resized to ${wnd.width} x ${wnd.height}, scene ${scene2d.width} x ${scene2d.height}');

			MarbleGame.canvas.render(MarbleGame.canvas.scene2d);
		});
	}
}
