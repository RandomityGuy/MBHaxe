package src;

import haxe.Json;
import mis.MisParser;
import src.ResourceLoader;
import src.Mission;
import src.Console;
import src.MissionList;

@:publicFields
class MissionList {
	static var missionList:Map<String, Map<String, Array<Mission>>>;
	static var customMissions:Array<Mission>;

	static var missions:Map<String, Mission>;

	static var _build:Bool = false;

	public function new() {}

	public static function buildMissionList() {
		if (_build)
			return;

		missions = new Map<String, Mission>();
		missionList = [];

		function parseDifficulty(game:String, mispath:String, difficulty:String) {
			#if (hl && !android)
			var difficultyFiles = ResourceLoader.fileSystem.dir('data/${mispath}/' + difficulty);
			#end
			#if (js || android)
			var difficultyFiles = ResourceLoader.fileSystem.dir('${mispath}/' + difficulty);
			#end
			var difficultyMissions = [];
			for (file in difficultyFiles) {
				if (file.extension == "mis" || file.extension == "mcs") {
					var mInfo = file.extension == "mcs" ? new mis.McsParser(file.getText()).getMissionInfo() : new MisParser(file.getText()).parseMissionInfo();
					var mission = Mission.fromMissionInfo(file.path, mInfo);
					if (game != "custom")
						mission.game = game;
					else if (mInfo.game != null && mInfo.game != "")
						mission.game = mInfo.game.toLowerCase();
					else
						mission.game = game; // Last case scenario
					if (game == "custom")
						mission.isCustom = true;
					// do egg thing
					if (StringTools.contains(file.getText().toLowerCase(), 'datablock = "easteregg"')) { // Ew
						mission.hasEgg = true;
					}
					missions.set(file.path, mission);
					difficultyMissions.push(mission);
				}
			}
			difficultyMissions.sort((a, b) -> Std.parseInt(a.missionInfo.level) - Std.parseInt(b.missionInfo.level));

			for (i in 0...difficultyMissions.length) {
				difficultyMissions[i].index = i;
			}

			for (i in 0...difficultyMissions.length - 1) {
				@:privateAccess difficultyMissions[i].next = difficultyMissions[i + 1];
			}
			return difficultyMissions;
		}

		var platinumMissions:Map<String, Array<Mission>> = [];
		platinumMissions.set("tutorial", parseDifficulty("platinum", "missions_pq", "tutorial"));
		platinumMissions.set("beginner", parseDifficulty("platinum", "missions_pq", "beginner"));
		platinumMissions.set("intermediate", parseDifficulty("platinum", "missions_pq", "intermediate"));
		platinumMissions.set("advanced", parseDifficulty("platinum", "missions_pq", "advanced"));
		platinumMissions.set("expert", parseDifficulty("platinum", "missions_pq", "expert"));
		platinumMissions.set("bonus", parseDifficulty("platinum", "missions_pq", "bonus"));

		customMissions = parseDifficulty("custom", "missions", "custom");

		@:privateAccess platinumMissions["tutorial"][platinumMissions["tutorial"].length - 1].next = platinumMissions["beginner"][0];
		@:privateAccess platinumMissions["beginner"][platinumMissions["beginner"].length - 1].next = platinumMissions["intermediate"][0];
		@:privateAccess platinumMissions["intermediate"][platinumMissions["intermediate"].length - 1].next = platinumMissions["advanced"][0];
		@:privateAccess platinumMissions["advanced"][platinumMissions["advanced"].length - 1].next = platinumMissions["expert"][0];
		@:privateAccess platinumMissions["expert"][platinumMissions["expert"].length - 1].next = platinumMissions["bonus"][0];
		@:privateAccess platinumMissions["bonus"][platinumMissions["bonus"].length - 1].next = platinumMissions["tutorial"][0];

		// Hypercube uses MBG logic
		missionList.set("platinum", platinumMissions);

		Console.log("Loaded MissionList");
		Console.log("Platinum Tutorial: " + platinumMissions["tutorial"].length);
		Console.log("Platinum Beginner: " + platinumMissions["beginner"].length);
		Console.log("Platinum Intermediate: " + platinumMissions["intermediate"].length);
		Console.log("Platinum Advanced: " + platinumMissions["advanced"].length);
		Console.log("Platinum Expert: " + platinumMissions["expert"].length);
		Console.log("Platinum Bonus: " + platinumMissions["bonus"].length);
		Console.log("Custom: " + customMissions.length);

		// parseCLAList();

		_build = true;
	}
}
