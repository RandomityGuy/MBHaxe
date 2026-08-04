package triggers;

import src.TimeState;
import src.Marble;
import src.MarbleWorld;
import src.DtsObject;
import src.PathedInterior;
import mis.MissionElement.MissionElementTrigger;

class SecretAreaTrigger extends Trigger {
	public function new(element:MissionElementTrigger, level:MarbleWorld) {
		super(element, level);
	}

	override function onMarbleEnter(marble:Marble, timeState:TimeState) {
		var line:String;
		if (this.level.gemCount == this.level.totalGems) {
			if (timeState.gameplayClock < this.level.mission.qualifyTime) {
				var catapult = this.level.namedGameObjects.get("secretcatapult");
				if (catapult != null)
					cast(catapult, PathedInterior).setTargetTime(timeState, -1);

				var gravityItem = this.level.namedGameObjects.get("secretgravityitem1");
				if (gravityItem != null)
					cast(gravityItem, DtsObject).setHide(false);

				line = "A new challenge awaits you, step aboard!";
			} else {
				line = "Sorry, next time be quicker!";
			}
		} else {
			line = "Sorry, keep searching...";
		}
		this.level.displayAlert(line);
	}
}
