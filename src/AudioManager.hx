package src;

import h3d.scene.Scene;
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

	public static function update(scene3d:Scene) {
		manager.listener.syncCamera(scene3d.camera);
	}

	public static function playSound(sound:Sound, ?position:Vector, ?loop:Bool = false) {
		var ch = AudioManager.manager.play(sound, soundChannel);
		ch.loop = loop;
		if (position != null) {
			var audioSrc = new Spatialization();
			audioSrc.position = position;
			ch.addEffect(audioSrc);
		}
		return ch;
	}

	public static function stopAllSounds() {
		manager.stopByName("sound");
	}
}
