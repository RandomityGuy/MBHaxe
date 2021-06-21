import mis.MisParser;
import src.ResourceLoader;
import src.Mission;

@:publicFields
class MissionList {
	static var beginnerMissions:Array<Mission>;
	static var intermediateMissions:Array<Mission>;
	static var advancedMissions:Array<Mission>;

	static var _build:Bool = false;

	public function new() {}

	public static function buildMissionList() {
		if (_build)
			return;
		function parseDifficulty(difficulty:String) {
			var difficultyFiles = ResourceLoader.fileSystem.dir("data/missions/" + difficulty);
			var difficultyMissions = [];
			for (file in difficultyFiles) {
				if (file.extension == "mis") {
					var misParser = new MisParser(file.getText());
					var mInfo = misParser.parseMissionInfo();
					var mission = Mission.fromMissionInfo(file.path, mInfo);
					difficultyMissions.push(mission);
				}
			}
			difficultyMissions.sort((a, b) -> Std.parseInt(a.missionInfo.level) - Std.parseInt(b.missionInfo.level));
			return difficultyMissions;
		}

		beginnerMissions = parseDifficulty("beginner");
		intermediateMissions = parseDifficulty("intermediate");
		advancedMissions = parseDifficulty("advanced");

		_build = true;
	}
}
