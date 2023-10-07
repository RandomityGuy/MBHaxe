package src;

import haxe.io.BytesInput;
import haxe.zip.Reader;
import hxd.res.Image;
import haxe.Json;
import src.Mission;
import src.Http;
import src.ResourceLoader;
import src.Console;

class Marbleland {
	public static var goldMissions = [];
	public static var ultraMissions = [];
	public static var platinumMissions = [];
	public static var missions:Map<Int, Mission> = [];

	public static function init() {
		Http.get('https://marbleland.vaniverse.io/api/level/list', (b) -> {
			parseMissionList(b.toString());
			Console.log('Loaded gold customs: ${goldMissions.length}');
			Console.log('Loaded ultra customs: ${ultraMissions.length}');
			Console.log('Loaded platinum customs: ${platinumMissions.length}');
		}, (e) -> {
			Console.log('Error getting custom list from marbleland.');
		});
	}

	static function parseMissionList(s:String) {
		var claJson:Array<Dynamic> = Json.parse(s);
		var platDupes = new Map();

		for (missionData in claJson) {
			// filter
			if (missionData.datablockCompatibility != 'mbw' && missionData.datablockCompatibility != 'mbg')
				continue;
			if (!['gold', 'platinum', 'ultra', 'platinumquest'].contains(missionData.modification))
				continue;
			if (missionData.gameMode != null && missionData.gameMode != 'null')
				continue;
			if (missionData.gameType != 'single')
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
			if (missionData.modification == 'platinumquest')
				missionData.modification = 'platinum'; // play PQ levels compatible with web pls
			mission.game = missionData.modification;
			if (missionData.modification == 'platinum')
				mission.goldTime = missionData.platinumTime != null ? missionData.platinumTime / 1000 : mission.goldTime;
			mission.ultimateTime = missionData.ultimateTime != null ? missionData.ultimateTime / 1000 : 0;
			mission.hasEgg = missionData.hasEgg;
			mission.isClaMission = true;
			mission.addedAt = missionData.addedAt;

			var game = missionData.modification;

			if (game == 'platinum') {
				if (platDupes.exists(mission.title + mission.description))
					continue;
				else
					platDupes.set(mission.title + mission.description, true);
			}

			switch (game) {
				case 'gold':
					goldMissions.push(mission);
				case 'ultra':
					ultraMissions.push(mission);
				case 'platinum':
					platinumMissions.push(mission);
			}

			missions.set(mission.id, mission);
		}

		// sort according to name
		goldMissions.sort((x, y) -> x.title > y.title ? 1 : (x.title < y.title ? -1 : 0));
		for (i in 0...goldMissions.length - 1) {
			@:privateAccess goldMissions[i].next = goldMissions[i + 1];
			goldMissions[i].index = i;
		}
		@:privateAccess goldMissions[goldMissions.length - 1].next = goldMissions[0];
		goldMissions[goldMissions.length - 1].index = goldMissions.length - 1;
		platinumMissions.sort((x, y) -> x.title > y.title ? 1 : (x.title < y.title ? -1 : 0));
		for (i in 0...platinumMissions.length - 1) {
			@:privateAccess platinumMissions[i].next = platinumMissions[i + 1];
			platinumMissions[i].index = i;
		}
		@:privateAccess platinumMissions[platinumMissions.length - 1].next = platinumMissions[0];
		platinumMissions[platinumMissions.length - 1].index = platinumMissions.length - 1;
		ultraMissions.sort((x, y) -> x.title > y.title ? 1 : (x.title < y.title ? -1 : 0));
		for (i in 0...ultraMissions.length - 1) {
			@:privateAccess ultraMissions[i].next = ultraMissions[i + 1];
			ultraMissions[i].index = i;
		}
		@:privateAccess ultraMissions[ultraMissions.length - 1].next = ultraMissions[0];
		ultraMissions[ultraMissions.length - 1].index = ultraMissions.length - 1;
	}

	public static function getMissionImage(id:Int, cb:Image->Void) {
		return Http.get('https://marbleland.vaniverse.io/api/level/${id}/image?width=258&height=194', (imageBytes) -> {
			var res = new Image(new hxd.fs.BytesFileSystem.BytesFileEntry('${id}.png', imageBytes));
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
}
