package src;

import src.ResourceLoader;
import hxd.snd.SoundGroup;
import h3d.scene.Scene;
import hxd.snd.effect.Spatialization;
import h3d.Vector;
import hxd.res.Sound;
import src.Settings;
import hxd.snd.ChannelGroup;

class AudioManager {
	static var manager:hxd.snd.Manager;
	static var soundGroup:hxd.snd.SoundGroup;
	static var musicGroup:hxd.snd.SoundGroup;

	public static function init() {
		AudioManager.manager = hxd.snd.Manager.get();
		AudioManager.soundGroup = new SoundGroup("sound");
		soundGroup.volume = Settings.optionsSettings.soundVolume;
		AudioManager.musicGroup = new SoundGroup("music");
		musicGroup.volume = Settings.optionsSettings.musicVolume;
	}

	public static function update(scene3d:Scene) {
		manager.listener.syncCamera(scene3d.camera);
	}

	public static function playSound(sound:Sound, ?position:Vector, ?loop:Bool = false) {
		var ch = AudioManager.manager.play(sound, null, soundGroup);
		ch.loop = loop;
		if (position != null) {
			var audioSrc = new Spatialization();
			audioSrc.position = position;
			ch.addEffect(audioSrc);
		}
		return ch;
	}

	public static function playShell() {
		AudioManager.manager.stopByName("music");
		var snd = ResourceLoader.getAudio("data/sound/shell.ogg");
		var ch = AudioManager.manager.play(snd, null, musicGroup);
		ch.loop = true;
	}

	public static function playMusic(music:Sound) {
		AudioManager.manager.stopByName("music");
		var ch = AudioManager.manager.play(music, null, musicGroup);
		ch.loop = true;
	}

	public static function stopAllSounds() {
		AudioManager.manager.stopByName("sound");
	}
}
