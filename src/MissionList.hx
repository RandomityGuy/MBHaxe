import haxe.Json;
import mis.MisParser;
import src.ResourceLoader;
import src.Mission;

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
					mission.game = game;
					missions.set(file.path, mission);
					difficultyMissions.push(mission);
				}
			}
			difficultyMissions.sort((a, b) -> Std.parseInt(a.missionInfo.level) - Std.parseInt(b.missionInfo.level));

			for (i in 0...difficultyMissions.length - 1) {
				@:privateAccess difficultyMissions[i].next = difficultyMissions[i + 1];
			}
			return difficultyMissions;
		}

		var goldMissions:Map<String, Array<Mission>> = [];
		var platinumMissions:Map<String, Array<Mission>> = [];

		goldMissions.set("beginner", parseDifficulty("gold", "missions_mbg", "beginner"));
		goldMissions.set("intermediate", parseDifficulty("gold", "missions_mbg", "intermediate"));
		goldMissions.set("advanced", parseDifficulty("gold", "missions_mbg", "advanced"));

		platinumMissions.set("beginner", parseDifficulty("platinum", "missions_mbp", "beginner"));
		platinumMissions.set("intermediate", parseDifficulty("platinum", "missions_mbp", "intermediate"));
		platinumMissions.set("advanced", parseDifficulty("platinum", "missions_mbp", "advanced"));
		platinumMissions.set("expert", parseDifficulty("platinum", "missions_mbp", "expert"));

		customMissions = parseDifficulty("custom", "missions", "custom");

		@:privateAccess goldMissions["beginner"][goldMissions["beginner"].length - 1].next = goldMissions["intermediate"][0];
		@:privateAccess goldMissions["intermediate"][goldMissions["intermediate"].length - 1].next = goldMissions["advanced"][0];
		@:privateAccess goldMissions["advanced"][goldMissions["advanced"].length - 1].next = goldMissions["beginner"][0];
		@:privateAccess platinumMissions["beginner"][platinumMissions["beginner"].length - 1].next = platinumMissions["intermediate"][0];
		@:privateAccess platinumMissions["intermediate"][platinumMissions["intermediate"].length - 1].next = platinumMissions["advanced"][0];
		@:privateAccess platinumMissions["advanced"][platinumMissions["advanced"].length - 1].next = platinumMissions["expert"][0];
		@:privateAccess platinumMissions["expert"][platinumMissions["expert"].length - 1].next = platinumMissions["beginner"][0];

		missionList.set("gold", goldMissions);
		missionList.set("platinum", platinumMissions);

		// parseCLAList();

		_build = true;
	}

	static function parseCLAList() {
		var claJson:Array<Dynamic> = Json.parse(ResourceLoader.fileSystem.get("data/cla_list.json").getText());

		for (missionData in claJson) {
			var mission = new Mission();
			mission.id = missionData.id;
			mission.artist = missionData.artist;
			mission.title = missionData.name;
			mission.description = missionData.desc;
			mission.qualifyTime = missionData.time;
			mission.goldTime = missionData.goldTime;
			mission.path = missionData.baseName;
			mission.isClaMission = true;

			customMissions.push(mission);
		}
	}
}
