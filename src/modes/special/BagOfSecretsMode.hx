package modes.special;

import src.DtsObject;
import src.PathedInterior;

/** Ported from `BagOfSecrets.mcs`'s `missionStartup()` - hides the secret shortcut's reward items
	and parks its `secretCatapult` at the start of its path until `triggers.SecretAreaTrigger`
	(the mission's own `secretAreaTrigger` datablock) reveals them. */
class BagOfSecretsMode extends QuotaMode {
	public override function onMissionLoad() {
		super.onMissionLoad();
		var gravityItem = this.level.namedGameObjects.get("secretgravityitem1");
		if (gravityItem != null)
			cast(gravityItem, DtsObject).setHide(true);

		var timeTravel = this.level.namedGameObjects.get("topareatimetravel");
		if (timeTravel != null)
			cast(timeTravel, DtsObject).setHide(true);

		var catapult = this.level.namedGameObjects.get("secretcatapult");
		if (catapult != null)
			cast(catapult, PathedInterior).setTargetTime(this.level.timeState, 0);
	}
}
