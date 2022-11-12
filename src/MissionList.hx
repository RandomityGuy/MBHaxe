import haxe.Json;
import mis.MisParser;
import src.ResourceLoader;
import src.Mission;

@:publicFields
class MissionList {
	static var beginnerMissions:Array<Mission>;
	static var intermediateMissions:Array<Mission>;
	static var advancedMissions:Array<Mission>;
	static var customMissions:Array<Mission>;

	static var missions:Map<String, Mission>;

	static var _build:Bool = false;

	public function new() {}

	public static function buildMissionList() {
		if (_build)
			return;

		missions = new Map<String, Mission>();

		function parseDifficulty(difficulty:String) {
			#if (hl && !android)
			var difficultyFiles = ResourceLoader.fileSystem.dir("data/missions/" + difficulty);
			#end
			#if (js || android)
			var difficultyFiles = ResourceLoader.fileSystem.dir("missions/" + difficulty);
			#end
			var difficultyMissions = [];
			for (file in difficultyFiles) {
				if (file.extension == "mis") {
					var misParser = new MisParser(file.getText());
					var mInfo = misParser.parseMissionInfo();
					var mission = Mission.fromMissionInfo(file.path, mInfo);
					missions.set(file.path, mission);
					difficultyMissions.push(mission);
				}
			}
			difficultyMissions.sort((a, b) -> Std.parseInt(a.missionInfo.level) - Std.parseInt(b.missionInfo.level));
			return difficultyMissions;
		}

		beginnerMissions = parseDifficulty("beginner");
		intermediateMissions = parseDifficulty("intermediate");
		advancedMissions = parseDifficulty("advanced");
		customMissions = parseDifficulty("expert");

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
