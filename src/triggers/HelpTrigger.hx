package triggers;

import src.TimeState;
import src.ResourceLoader;
import src.AudioManager;

class HelpTrigger extends Trigger {
	override function onMarbleEnter(marble:src.Marble, timeState:TimeState) {
		if (marble == this.level.marble) {
			AudioManager.playSound(ResourceLoader.getResource('data/sound/infotutorial.wav', ResourceLoader.getAudio, this.soundResources));
			this.level.displayHelp(this.element.text);
		}
		// this.level.replay.recordMarbleEnter(this);
	}

	public override function init(onFinish:Void->Void) {
		ResourceLoader.load("sound/infotutorial.wav").entry.load(onFinish);
	}
}
