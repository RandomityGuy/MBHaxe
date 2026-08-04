package triggers;

import src.Marble;
import src.TimeState;
import mis.MissionElement.MissionElementTrigger;
import src.MarbleWorld;
import modes.GameMode.GameModeFactory;
import modes.TwoDMode;

class StopTDTrigger extends Trigger {
	public function new(element:MissionElementTrigger, level:MarbleWorld) {
		super(element, level);
	}

	override function onMarbleEnter(marble:Marble, time:TimeState) {
		var twoD = GameModeFactory.findMode(this.level.gameMode, TwoDMode);
		if (twoD != null)
			twoD.deactivate();
	}
}
