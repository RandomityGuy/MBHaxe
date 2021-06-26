package src;

import haxe.DynamicAccess;
import sys.io.File;
import src.ResourceLoader;
import haxe.Json;

typedef Score = {
	var name:String;
	var time:Float;
}

class Settings {
	public static var highScores:Map<String, Array<Score>> = [];

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
}
