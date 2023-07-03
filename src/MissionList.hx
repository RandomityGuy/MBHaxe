package src;

import haxe.Json;
import mis.MisParser;
import src.ResourceLoader;
import src.Mission;
import src.Console;

@:publicFields
class MissionList {
	static var missionList:Map<String, Map<String, Array<Mission>>>;
	static var customMissions:Array<Mission>;

	static var missions:Map<String, Mission>;
	static var missionsFilenameLookup:Map<String, Mission>;

	static var _build:Bool = false;

	public function new() {}

	public static function buildMissionList() {
		if (_build)
			return;

		missions = new Map<String, Mission>();
		missionsFilenameLookup = new Map<String, Mission>();
		missionList = [];

		function parseDifficulty(game:String, mispath:String, difficulty:String, difficultyIndex:Int) {
			#if (hl && !android)
			var difficultyFiles = ResourceLoader.fileSystem.dir('data/${mispath}/' + difficulty);
			#end
			#if (js || android)
			var difficultyFiles = ResourceLoader.fileSystem.dir('${mispath}/' + difficulty);
			#end
			var difficultyMissions = [];
			for (file in difficultyFiles) {
				if (file.isDirectory)
					for (sfile in file) {
						if (sfile.extension == "mis") {
							var misParser = new MisParser(sfile.getText());
							var mInfo = misParser.parseMissionInfo();
							var mission = Mission.fromMissionInfo(sfile.path, mInfo);
							if (game != "custom")
								mission.game = game;
							else if (mInfo.game != null && mInfo.game != "")
								mission.game = mInfo.game.toLowerCase();
							else
								mission.game = game; // Last case scenario
							if (game == "custom")
								mission.isCustom = true;
							// do egg thing
							if (StringTools.contains(sfile.getText().toLowerCase(), 'datablock = "easteregg"')) { // Ew
								mission.hasEgg = true;
							}
							mission.difficultyIndex = difficultyIndex;
							missions.set(sfile.path, mission);
							missionsFilenameLookup.set(sfile.name.toLowerCase(), mission);
							difficultyMissions.push(mission);
						}
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

		var ultraMissions:Map<String, Array<Mission>> = [];

		ultraMissions.set("beginner", parseDifficulty("ultra", "missions", "beginner", 0));
		ultraMissions.set("intermediate", parseDifficulty("ultra", "missions", "intermediate", 1));
		ultraMissions.set("advanced", parseDifficulty("ultra", "missions", "advanced", 2));
		ultraMissions.set("multiplayer", parseDifficulty("ultra", "missions", "multiplayer", 3));

		@:privateAccess ultraMissions["beginner"][ultraMissions["beginner"].length - 1].next = ultraMissions["intermediate"][0];
		@:privateAccess ultraMissions["intermediate"][ultraMissions["intermediate"].length - 1].next = ultraMissions["advanced"][0];
		@:privateAccess ultraMissions["advanced"][ultraMissions["advanced"].length - 1].next = ultraMissions["beginner"][0];

		@:privateAccess ultraMissions["multiplayer"][ultraMissions["multiplayer"].length - 1].next = ultraMissions["multiplayer"][0];

		missionList.set("ultra", ultraMissions);

		// parseCLAList();

		_build = true;
	}
}
