package triggers;

import src.TimeState;
import src.Marble;
import src.Console;

class UsePowerupTrigger extends Trigger {
	override function onMarbleEnter(marble:Marble, timeState:TimeState) {
		if (marble != this.level.marble)
			return;

		var powerupField = this.element.fields.get("powerup");
		var powerup = powerupField != null ? powerupField[0] : "SuperJumpItem";
		var name = powerup.toLowerCase();

		if (StringTools.startsWith(name, "superjumpitem") || StringTools.startsWith(name, "customsuperjumpitem"))
			marble.velocity.load(marble.velocity.add(marble.currentUp.multiply(20)));
		else if (StringTools.startsWith(name, "superbounceitem"))
			marble.enableSuperBounce(timeState);
		else if (StringTools.startsWith(name, "shockabsorberitem"))
			marble.enableShockAbsorber(timeState);
		else if (StringTools.startsWith(name, "helicopteritem"))
			marble.enableHelicopter(timeState, StringTools.endsWith(name, "_pq"));
		else if (StringTools.startsWith(name, "timetravelitem") || StringTools.startsWith(name, "sundialitem"))
			this.level.addBonusTime(5);
		else if (StringTools.startsWith(name, "timepenaltyitem"))
			this.level.addBonusTime(-5);
		else
			Console.warn('UsePowerupTrigger: unsupported powerup "$powerup"');
	}
}
