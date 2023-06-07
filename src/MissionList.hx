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
				var subfiles = ResourceLoader.fileSystem.dir(file.path);
				for (file in subfiles) {
					if (file.extension == "mis") {
						var misParser = new MisParser(file.getText());
						var mInfo = misParser.parseMissionInfo();
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

		ultraMissions.set("beginner", parseDifficulty("ultra", "missions", "beginner"));
		ultraMissions.set("intermediate", parseDifficulty("ultra", "missions", "intermediate"));
		ultraMissions.set("advanced", parseDifficulty("ultra", "missions", "advanced"));

		@:privateAccess ultraMissions["beginner"][ultraMissions["beginner"].length - 1].next = ultraMissions["intermediate"][0];
		@:privateAccess ultraMissions["intermediate"][ultraMissions["intermediate"].length - 1].next = ultraMissions["advanced"][0];
		@:privateAccess ultraMissions["advanced"][ultraMissions["advanced"].length - 1].next = ultraMissions["beginner"][0];

		missionList.set("ultra", ultraMissions);

		// parseCLAList();

		_build = true;
	}
}
