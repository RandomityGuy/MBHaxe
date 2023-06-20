package src;

import src.ResourceLoader;
import hxd.snd.SoundGroup;
import h3d.scene.Scene;
import hxd.snd.effect.Spatialization;
import h3d.Vector;
import hxd.res.Sound;
import src.Settings;
import hxd.snd.ChannelGroup;
import src.Resource;
import src.ResourceLoaderWorker;
import src.Console;

class AudioManager {
	static var manager:hxd.snd.Manager;
	static var soundGroup:hxd.snd.SoundGroup;
	static var musicGroup:hxd.snd.SoundGroup;

	static var currentMusic:hxd.snd.Channel;
	public static var currentMusicName:String;
	public static var currentMusicPaused:Bool = true;

	static var currentMusicResource:Resource<Sound>;

	public static function init() {
		Console.log("Initializing Audio System");
		AudioManager.manager = hxd.snd.Manager.get();
		AudioManager.soundGroup = new SoundGroup("sound");
		soundGroup.volume = Settings.optionsSettings.soundVolume;
		AudioManager.musicGroup = new SoundGroup("music");
		musicGroup.volume = Settings.optionsSettings.musicVolume;
	}

	public static function updateVolumes() {
		soundGroup.volume = Settings.optionsSettings.soundVolume;
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
			#if hl
			audioSrc.referenceDistance = 5;
			#end
			#if js
			audioSrc.referenceDistance = 4.5;
			#end
			ch.addEffect(audioSrc);
		}
		return ch;
	}

	public static function playShell() {
		AudioManager.manager.stopByName("music");
		var sndres = ResourceLoader.getAudio("data/sound/music/Tim Trance.ogg");
		if (sndres == null)
			return;
		sndres.acquire();
		if (currentMusicResource != null)
			currentMusicResource.release();
		currentMusicResource = sndres;
		currentMusic = AudioManager.manager.play(sndres.resource, null, musicGroup);
		currentMusic.loop = true;
	}

	public static function playMusic(music:Sound, musicName:String) {
		AudioManager.manager.stopByName("music");
		if (music == null)
			return;
		AudioManager.currentMusicName = musicName;
		currentMusic = AudioManager.manager.play(music, null, musicGroup);
		currentMusicPaused = false;
		currentMusic.loop = true;
	}

	public static function pauseMusic(paused:Bool) {
		if (currentMusic != null) {
			currentMusic.pause = paused;
			currentMusicPaused = paused;
		}
	}

	public static function stopAllSounds() {
		AudioManager.manager.stopByName("sound");
	}
}
