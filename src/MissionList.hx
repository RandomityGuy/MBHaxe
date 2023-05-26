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
			difficultyMissions.sort((a, b) -> Std.parseInt(a.missionInfo.level) - Std.parseInt(b.missionInfo.level));

			for (i in 0...difficultyMissions.length) {
				difficultyMissions[i].index = i;
			}

			for (i in 0...difficultyMissions.length - 1) {
				@:privateAccess difficultyMissions[i].next = difficultyMissions[i + 1];
			}
			return difficultyMissions;
		}

		var goldMissions:Map<String, Array<Mission>> = [];
		var platinumMissions:Map<String, Array<Mission>> = [];
		var ultraMissions:Map<String, Array<Mission>> = [];

		goldMissions.set("beginner", parseDifficulty("gold", "missions_mbg", "beginner"));
		goldMissions.set("intermediate", parseDifficulty("gold", "missions_mbg", "intermediate"));
		goldMissions.set("advanced", parseDifficulty("gold", "missions_mbg", "advanced"));

		platinumMissions.set("beginner", parseDifficulty("platinum", "missions_mbp", "beginner"));
		platinumMissions.set("intermediate", parseDifficulty("platinum", "missions_mbp", "intermediate"));
		platinumMissions.set("advanced", parseDifficulty("platinum", "missions_mbp", "advanced"));
		platinumMissions.set("expert", parseDifficulty("platinum", "missions_mbp", "expert"));

		ultraMissions.set("beginner", parseDifficulty("ultra", "missions_mbu", "beginner"));
		ultraMissions.set("intermediate", parseDifficulty("ultra", "missions_mbu", "intermediate"));
		ultraMissions.set("advanced", parseDifficulty("ultra", "missions_mbu", "advanced"));

		customMissions = parseDifficulty("custom", "missions", "custom");

		@:privateAccess goldMissions["beginner"][goldMissions["beginner"].length - 1].next = goldMissions["intermediate"][0];
		@:privateAccess goldMissions["intermediate"][goldMissions["intermediate"].length - 1].next = goldMissions["advanced"][0];
		@:privateAccess goldMissions["advanced"][goldMissions["advanced"].length - 1].next = goldMissions["beginner"][0];
		@:privateAccess platinumMissions["beginner"][platinumMissions["beginner"].length - 1].next = platinumMissions["intermediate"][0];
		@:privateAccess platinumMissions["intermediate"][platinumMissions["intermediate"].length - 1].next = platinumMissions["advanced"][0];
		@:privateAccess platinumMissions["advanced"][platinumMissions["advanced"].length - 1].next = platinumMissions["expert"][0];
		@:privateAccess platinumMissions["expert"][platinumMissions["expert"].length - 1].next = platinumMissions["beginner"][0];
		@:privateAccess ultraMissions["beginner"][ultraMissions["beginner"].length - 1].next = ultraMissions["intermediate"][0];
		@:privateAccess ultraMissions["intermediate"][ultraMissions["intermediate"].length - 1].next = ultraMissions["advanced"][0];
		@:privateAccess ultraMissions["advanced"][ultraMissions["advanced"].length - 1].next = ultraMissions["beginner"][0];

		// Hypercube uses MBG logic
		ultraMissions["advanced"][ultraMissions["advanced"].length - 1].game = "gold";

		missionList.set("gold", goldMissions);
		missionList.set("platinum", platinumMissions);
		missionList.set("ultra", ultraMissions);

		Console.log("Loaded MissionList");
		Console.log("Gold Beginner: " + goldMissions["beginner"].length);
		Console.log("Gold Intermediate: " + goldMissions["intermediate"].length);
		Console.log("Gold Advanced: " + goldMissions["advanced"].length);
		Console.log("Platinum Beginner: " + platinumMissions["beginner"].length);
		Console.log("Platinum Intermediate: " + platinumMissions["intermediate"].length);
		Console.log("Platinum Advanced: " + platinumMissions["advanced"].length);
		Console.log("Platinum Expert: " + platinumMissions["expert"].length);
		Console.log("Ultra Beginner: " + ultraMissions["beginner"].length);
		Console.log("Ultra Intermediate: " + ultraMissions["intermediate"].length);
		Console.log("Ultra Advanced: " + ultraMissions["advanced"].length);
		Console.log("Custom: " + customMissions.length);

		// parseCLAList();

		_build = true;
	}
}
