package triggers;

import modes.SoccerMode;
import mis.MissionElement.MissionElementTrigger;
import src.TimeState;
import src.Marble;
import src.MarbleWorld;
import net.Net;

class SoccerGoalTrigger extends Trigger {
	public var team:Int; // 0 = red, 1 = blue

	public function new(element:MissionElementTrigger, level:MarbleWorld) {
		super(element, level);
		team = (element.text != null && element.text.toLowerCase() == "blue") ? 1 : 0;
	}

	override function onMarbleEnter(marble:Marble, time:TimeState) {
		if (!Net.isHost) return;
		if (level.gameMode is SoccerMode) {
			var soccer:SoccerMode = cast level.gameMode;
			soccer.onBallEnterGoal(marble, team);
		}
	}
}
