package src;

import src.MarbleGame;
import hxd.Window;
import haxe.DynamicAccess;
import sys.io.File;
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
		musicVolume: 0,
		soundVolume: 0
	};

	public static function applySettings() {
		Window.getInstance().resize(optionsSettings.screenWidth, optionsSettings.screenHeight);
		Window.getInstance().displayMode = optionsSettings.isFullScreen ? FullscreenResize : Windowed;

		MarbleGame.canvas.render(MarbleGame.canvas.scene2d);
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
		var outputData = {
			highScores: highScores
		};
		var json = Json.stringify(outputData);
		File.saveContent("settings.json", json);
	}

	public static function load() {
		if (ResourceLoader.fileSystem.exists("settings.json")) {
			var json = Json.parse(ResourceLoader.fileSystem.get("settings.json").getText());
			var highScoreData:DynamicAccess<Array<Score>> = json.highScores;
			for (key => value in highScoreData) {
				highScores.set(key, value);
			}
		}
	}

	public static function init() {
		load();
		Window.getInstance().resize(optionsSettings.screenWidth, optionsSettings.screenHeight);
		Window.getInstance().displayMode = optionsSettings.isFullScreen ? FullscreenResize : Windowed;
		Window.getInstance().addResizeEvent(() -> {
			var wnd = Window.getInstance();
			Settings.optionsSettings.screenWidth = wnd.width;
			Settings.optionsSettings.screenHeight = wnd.height;
			MarbleGame.canvas.render(MarbleGame.canvas.scene2d);
		});
	}
}
