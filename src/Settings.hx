package src;

import gui.Canvas;
import src.AudioManager;
import hxd.Key;
import src.MarbleGame;
import hxd.Window;
import haxe.DynamicAccess;
#if hl
import sys.io.File;
#end
import src.ResourceLoader;
import haxe.Json;

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
	var fov:Int;
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
		fov: 60,
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
		invertYAxis: false
	};

	public static var progression = [0, 0, 0];
	public static var highscoreName = "";

	public static function applySettings() {
		Window.getInstance().resize(optionsSettings.screenWidth, optionsSettings.screenHeight);
		Window.getInstance().displayMode = optionsSettings.isFullScreen ? FullscreenResize : Windowed;
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
		#if hl
		File.saveContent("settings.json", json);
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
		settingsExists = ResourceLoader.fileSystem.exists("settings.json");
		#end
		#if js
		var localStorage = js.Browser.getLocalStorage();
		if (localStorage != null) {
			settingsExists = localStorage.getItem("MBHaxeSettings") != null;
		}
		#end

		if (settingsExists) {
			#if hl
			var json = Json.parse(ResourceLoader.fileSystem.get("settings.json").getText());
			#end
			#if js
			var json = Json.parse(localStorage.getItem("MBHaxeSettings"));
			#end
			var highScoreData:DynamicAccess<Array<Score>> = json.highScores;
			for (key => value in highScoreData) {
				highScores.set(key, value);
			}
			optionsSettings = json.options;
			if (optionsSettings.fov == 0 #if js || optionsSettings.fov == null #end)
				optionsSettings.fov = 60;
			controlsSettings = json.controls;
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
		Window.getInstance().displayMode = optionsSettings.isFullScreen ? FullscreenResize : Windowed;
		#end
		#if js
		Window.getInstance().propagateKeyEvents = true;
		#end
		// @:privateAccess Window.getInstance().window.center();
		Window.getInstance().addResizeEvent(() -> {
			var wnd = Window.getInstance();
			var zoomRatio = 1.0;
			#if js
			zoomRatio = js.Browser.window.devicePixelRatio;
			#end
			Settings.optionsSettings.screenWidth = cast wnd.width / zoomRatio;
			Settings.optionsSettings.screenHeight = cast wnd.height / zoomRatio;

			MarbleGame.canvas.scene2d.scaleMode = Zoom(zoomRatio);

			MarbleGame.canvas.render(MarbleGame.canvas.scene2d);
		});
	}
}
