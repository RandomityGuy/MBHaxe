package src;

import haxe.io.BytesInput;
import haxe.zip.Reader;
import hxd.res.Image;
import hxd.BitmapData;
import haxe.Json;
import src.Mission;
import src.Http;
import src.ResourceLoader;

class Marbleland {
	public static var goldMissions = [];
	public static var ultraMissions = [];
	public static var platinumMissions = [];

	public static function init() {
		Http.get('https://raw.githubusercontent.com/Vanilagy/MarbleBlast/master/src/assets/customs_gold.json', (b) -> {
			parseMissionList(b.toString(), "gold");
		}, (e) -> {});
		Http.get('https://raw.githubusercontent.com/Vanilagy/MarbleBlast/master/src/assets/customs_ultra.json', (b) -> {
			parseMissionList(b.toString(), "ultra");
		}, (e) -> {});
		Http.get('https://raw.githubusercontent.com/Vanilagy/MarbleBlast/master/src/assets/customs_platinum.json', (b) -> {
			parseMissionList(b.toString(), "platinum");
		}, (e) -> {});
	}

	static function parseMissionList(s:String, game:String) {
		var claJson:Array<Dynamic> = Json.parse(s);

		for (missionData in claJson) {
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
			mission.qualifyTime = missionData.qualifyingTime != null ? missionData.qualifyingTime / 1000 : Math.POSITIVE_INFINITY;
			mission.goldTime = missionData.goldTime != null ? missionData.goldTime / 1000 : 0;
			mission.game = missionData.modification;
			if (missionData.modification == 'platinum')
				mission.goldTime = missionData.platinumTime != null ? missionData.platinumTime / 1000 : mission.goldTime;
			mission.ultimateTime = missionData.ultimateTime != null ? missionData.ultimateTime / 1000 : 0;
			mission.hasEgg = missionData.hasEgg;
			mission.isClaMission = true;

			switch (game) {
				case 'gold':
					goldMissions.push(mission);
				case 'ultra':
					ultraMissions.push(mission);
				case 'platinum':
					platinumMissions.push(mission);
			}
		}
	}

	public static function getMissionImage(id:Int, cb:Image->Void) {
		Http.get('https://marbleland.vani.ga/api/level/${id}/image?width=258&height=194', (imageBytes) -> {
			var res = new Image(new hxd.fs.BytesFileSystem.BytesFileEntry('${id}.png', imageBytes));
			cb(res);
		}, (e) -> {
			cb(null);
		});
	}

	public static function download(id:Int, cb:Array<haxe.zip.Entry>->Void) {
		Http.get('https://marbleblast.vani.ga/api/custom/${id}.zip', (zipData -> {
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
