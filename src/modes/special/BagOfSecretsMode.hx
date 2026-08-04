package modes.special;

import src.DtsObject;
import src.PathedInterior;

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
