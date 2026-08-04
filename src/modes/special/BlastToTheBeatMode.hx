package modes.special;

import src.AudioManager;
import src.ResourceLoader;

class BlastToTheBeatMode extends NullMode {
	var channel:hxd.snd.Channel;

	public override function getPreloadFiles():Array<String> {
		return ['data/sound/bass_punch.wav'];
	}

	public override function onRestart() {
		super.onRestart();
		if (this.channel != null)
			this.channel.stop();
		var sound = ResourceLoader.getResource('data/sound/bass_punch.wav', ResourceLoader.getAudio, @:privateAccess this.level.soundResources);
		this.channel = AudioManager.playSound(sound, null, true);
	}
}
