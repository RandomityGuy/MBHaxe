package triggers;

import src.TimeState;

class HelpTrigger extends Trigger {
	override function onMarbleEnter(timeState:TimeState) {
		// AudioManager.play('infotutorial.wav');
		this.level.displayHelp(this.element.text);
		// this.level.replay.recordMarbleEnter(this);
	}
}
