package shapes;

import mis.MissionElement.MissionElementItem;
import src.TimeState;
import src.Marble;
import src.MarbleWorld;
import mis.MisParser;

class FireballItem extends PowerUp {
	var activeTime:Float;

	public function new(element:MissionElementItem) {
		super(element);
		this.dtsPath = "data/shapes_pq/gameplay/powerups/fireball.dts";
		this.identifier = "FireballItem";
		this.pickUpName = "Fireball PowerUp";

		var activeTimeField = element.fields.get("activetime");
		this.activeTime = activeTimeField != null && activeTimeField[0] != "" ? MisParser.parseNumber(activeTimeField[0]) / 1000 : 7;
	}

	public function pickUp(marble:Marble):Bool {
		if (marble.fireball && marble.fireballTime >= this.activeTime)
			return false;
		marble.activateFireball(this.activeTime);
		return true;
	}

	public function use(marble:Marble, timeState:TimeState):Bool {
		return true;
	}
}
