package triggers;

import src.TimeState;
import src.Marble;
import src.MarbleWorld;
import src.DtsObject;
import src.PathedInterior;
import mis.MissionElement.MissionElementTrigger;

/** Ported from `BagOfSecrets.mcs`'s `secretAreaTrigger::onEnterTrigger` - a one-off mission-specific
	`TriggerData` (its own datablock, not a generic trigger type) that reveals a shortcut back to the
	normal play area once the player has every gem and is still under the level's par time
	(`MissionInfo.time` -> `Mission.qualifyTime`). Looks its target objects up by name via
	`level.namedGameObjects` rather than routing through the mission's `BagOfSecretsMode`, since
	nothing else needs to know about them - that mode only handles the initial hide/park-at-load
	half (`missionStartup()`). */
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
