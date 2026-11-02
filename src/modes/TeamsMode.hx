package modes;

/**
 * Implemented by game modes that use teams
 */
interface TeamsMode {
	public function getTeamCount():Int;
	public function getTeamName(team:Int):String;
	public function getTeamColor(team:Int):Int;
	public function getTeamScore(team:Int):Int;

	// Whether the scoreboard should still display each player's individual score below the team total.
	public function showsIndividualScores():Bool;
}
