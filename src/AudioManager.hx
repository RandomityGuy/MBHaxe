package src;

import hxd.snd.effect.Spatialization;
import h3d.Vector;
import hxd.res.Sound;
import src.Settings;
import hxd.snd.ChannelGroup;

class AudioManager {
	static var manager:hxd.snd.Manager;
	static var soundChannel:hxd.snd.ChannelGroup;
	static var musicChannel:hxd.snd.ChannelGroup;

	public static function init() {
		AudioManager.manager = hxd.snd.Manager.get();
		AudioManager.soundChannel = new ChannelGroup("sound");
		soundChannel.volume = Settings.optionsSettings.soundVolume;
		AudioManager.musicChannel = new ChannelGroup("music");
		musicChannel.volume = Settings.optionsSettings.musicVolume;
	}

	public static function playSound(sound:Sound, ?position:Vector) {
		AudioManager.manager.play(sound, soundChannel);
		if (position != null) {
			var audioSrc = new Spatialization();
			audioSrc.position = position;
			soundChannel.addEffect(audioSrc);
		}
	}
}
