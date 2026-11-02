package modes;

import net.Net;

/**
 * Standard gem hunt, but players are split into red/blue teams.
 */
class TeamHuntMode extends HuntMode implements TeamsMode {
	public function new(level:src.MarbleWorld) {
		super(level, false);
	}

	public function getTeamCount():Int {
		return 2;
	}

	public function getTeamName(team:Int):String {
		return TeamInfo.getName(team);
	}

	public function getTeamColor(team:Int):Int {
		return TeamInfo.getColor(team);
	}

	public function getTeamScore(team:Int):Int {
		if (@:privateAccess level.playGui == null)
			return 0;
		var total = 0;
		for (player in @:privateAccess level.playGui.playerList) {
			if (Net.getTeamId(player.id) == team)
				total += player.score;
		}
		return total;
	}

	public function showsIndividualScores():Bool {
		return true;
	}
}
