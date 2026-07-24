package triggers;

import src.Marble;
import src.TimeState;
import mis.MissionElement.MissionElementTrigger;
import src.MarbleWorld;
import modes.GameMode.GameModeFactory;
import modes.TwoDMode;

/** Ported from PQ's `StopTDTrigger` datablock (`modes/2d.cs`) - unconditionally force-stops 2D
	mode on marble-enter, regardless of `KeepEffectOnLeave` on whatever activated it. */
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
