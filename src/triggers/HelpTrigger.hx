package triggers;

import src.TimeState;
import src.ResourceLoader;
import src.AudioManager;
import src.Marble;

class HelpTrigger extends Trigger {
	override function onMarbleEnter(marble:Marble, timeState:TimeState) {
		AudioManager.playSound(ResourceLoader.getResource('data/sound/infotutorial.wav', ResourceLoader.getAudio, this.soundResources));
		if (this.element.text != null && this.element.text != "")
			this.level.displayHelp(this.element.text);
		// this.level.replay.recordMarbleEnter(this);
	}

	public override function init(onFinish:Void->Void) {
		ResourceLoader.load("sound/infotutorial.wav").entry.load(onFinish);
	}
}
