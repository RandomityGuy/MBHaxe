package triggers;

import src.TimeState;
import src.ResourceLoader;
import src.AudioManager;

class HelpTrigger extends Trigger {
	override function onMarbleEnter(timeState:TimeState) {
		AudioManager.playSound(ResourceLoader.getAudio('data/sound/infotutorial.wav'));
		this.level.displayHelp(this.element.text);
		// this.level.replay.recordMarbleEnter(this);
	}
}
