package src;

import haxe.io.BytesInput;
import haxe.zip.Reader;
import hxd.res.Image;
import haxe.Json;
import src.Mission;
import src.Http;
import src.ResourceLoader;
import src.Console;
import src.MarbleGame;

class Marbleland {
	public static var pqMissions:Array<Mission> = [];
	public static var missions:Map<Int, Mission> = [];

	public static function init() {
		Http.get('https://marbleland.vaniverse.io/api/level/list', (b) -> {
			parseMissionList(b.toString());
			Console.log('Loaded platinumquest customs: ${pqMissions.length}');
			// Load the marbleland level from JS
			#if js
			var urlParams = new js.html.URLSearchParams(js.Browser.window.location.search);
			var playParam = urlParams.get("play");
			if (playParam != null) {
				var intParam = Std.parseInt(playParam);
				if (intParam != null) {
					var mission = missions.get(intParam);
					if (mission != null) {
						MarbleGame.instance.playMission(mission);
					}
				}
			}
			#end
		}, (e) -> {
			Console.log('Error getting custom list from marbleland.');
		});
	}

	static function parseMissionList(s:String) {
		var claJson:Array<Dynamic> = Json.parse(s);

		for (missionData in claJson) {
			// filter
			if (missionData.datablockCompatibility != "pq") // lets allow playing ONLY pq levels in this port, the rest of the levels, just play the other game
				continue;

			if (missionData.hasCustomCode)
				continue;

			var isMultiplayer = missionData.gameType == 'multi';
			if (isMultiplayer)
				continue;

			var mission = new Mission();
			mission.id = missionData.id;
			mission.path = 'missions/' + missionData.baseName;
			#if (hl && !android)
			mission.path = 'data/' + mission.path;
			#end
			mission.path = mission.path.toLowerCase();
			mission.title = missionData.name;
			mission.artist = missionData.artist != null ? missionData.artist : "Unknown Author";
			mission.description = missionData.desc != null ? missionData.desc : "";
			mission.qualifyTime = (missionData.qualifyingTime != null && missionData.qualifyingTime != 0) ? missionData.qualifyingTime / 1000 : Math.POSITIVE_INFINITY;
			mission.goldTime = missionData.goldTime != null ? missionData.goldTime / 1000 : 0;
			mission.goldScore = missionData.goldScore != null ? missionData.goldScore : 0;
			if (missionData.platinumScore != null)
				mission.goldScore = missionData.platinumScore;
			mission.game = missionData.modification;
			if (mission.game == null)
				mission.game = "platinumquest";
			if (missionData.modification != 'gold' && missionData.modification != 'ultra')
				mission.goldTime = missionData.platinumTime != null ? missionData.platinumTime / 1000 : mission.goldTime;
			mission.ultimateTime = missionData.ultimateTime != null ? missionData.ultimateTime / 1000 : 0;
			mission.awesomeTime = missionData.awesomeTime != null ? missionData.awesomeTime / 1000 : 0;
			mission.ultimateScore = missionData.ultimateScore != null ? missionData.ultimateScore : 0;
			mission.awesomeScore = missionData.awesomeScore != null ? missionData.awesomeScore : 0;
			mission.hasEgg = missionData.hasEgg;
			mission.isClaMission = true;
			mission.addedAt = missionData.addedAt;
			mission.curationScore = missionData.curationScore != null ? missionData.curationScore : 0;
			mission.gameMode = missionData.gameMode;
			if (mission.gameMode != null)
				mission.gameMode = mission.gameMode.toLowerCase();

			pqMissions.push(mission);

			missions.set(mission.id, mission);
		}

		// sort according to name
		pqMissions.sort((x, y) -> x.title > y.title ? 1 : (x.title < y.title ? -1 : 0));
		for (i in 0...pqMissions.length - 1) {
			@:privateAccess pqMissions[i].next = pqMissions[i + 1];
			pqMissions[i].index = i;
		}
	}

	public static function getMissionImage(id:Int, cb:Image->Void) {
		return Http.get('https://marbleland.vaniverse.io/api/level/${id}/image?width=258&height=194', (imageBytes) -> {
			var res = new Image(new hxd.fs.BytesFileSystem.BytesFileEntry('${id}.png', imageBytes));
			cb(res);
		}, (e) -> {
			cb(null);
		});
	}

	public static function getMissionPreview(id:Int, cb:Image->Void) {
		return Http.get('https://marbleland.vaniverse.io/api/level/${id}/prev-image?width=1280&height=720', (imageBytes) -> {
			var res = new Image(new hxd.fs.BytesFileSystem.BytesFileEntry('${id}.png', imageBytes));
			cb(res);
		}, (e) -> {
			cb(null);
		});
	}

	public static function getMissionInfo(id:Int, cb:Dynamic->Void) {
		return Http.get('https://marbleland.vaniverse.io/api/level/${id}/mission-info', (infoBytes) -> {
			var res = Json.parse(infoBytes.toString());
			cb(res);
		}, (e) -> {
			cb(null);
		});
	}

	public static function download(id:Int, cb:Array<haxe.zip.Entry>->Void) {
		Http.get('https://marbleland.vaniverse.io/api/level/${id}/zip?assuming=none', (zipData -> {
			var reader = new Reader(new BytesInput(zipData));
			var entries:Array<haxe.zip.Entry> = null;
			try {
				entries = [for (x in reader.read()) x];
			} catch (e) {}
			cb(entries);
		}), (e) -> {
			cb(null);
		});
	}

	public static function getMissionList(sortMode:String):Array<Mission> {
		switch (sortMode) {
			case "relevant":
				var filtered = pqMissions.filter(x -> x.curationScore > -2);
				filtered.sort((x, y) -> x.addedAt > y.addedAt ? -1 : (x.addedAt < y.addedAt ? 1 : 0));
				return filtered;
			case "all":
				var copy = pqMissions.copy();
				copy.sort((x, y) -> x.addedAt > y.addedAt ? -1 : (x.addedAt < y.addedAt ? 1 : 0));
				return copy;
			case "alphabetical":
				return pqMissions;
		}
		return pqMissions;
	}
}
