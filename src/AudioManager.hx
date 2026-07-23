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
	public static var pitchKeys = ["a", "a_flat", "b", "b_flat", "c", "c_sharp", "d", "e", "e_flat", "f", "f_sharp", "g"];
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
		var sndres = ResourceLoader.getAudio("data/sound/music/Pianoforte.ogg");
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

	/** Resolves the pitch key to use for `soundName` (optionally suffixed with `variantSuffix`,
		e.g. a Hunt-mode gem point value) against whichever song is currently playing, falling
		back to the `"default"` key map when the song is unknown, unmapped, or music is
		inaudible — matching PQ's own `playPitchedSound()` reasoning. */
	public static function resolvePitchKey(soundName:String, ?variantSuffix:String):String {
		var lookupName = soundName + (variantSuffix != null ? variantSuffix : "");
		var songBase = currentMusicName != null ? haxe.io.Path.withoutExtension(currentMusicName) : null;
		var useSongMap = Settings.optionsSettings.musicVolume > 0.01 && songBase != null && PitchedSoundKeys.songs.exists(songBase);
		var songMap = useSongMap ? PitchedSoundKeys.songs.get(songBase) : PitchedSoundKeys.songs.get("default");

		if (songMap.exists(lookupName))
			return songMap.get(lookupName);
		if (songMap.exists(soundName))
			return songMap.get(soundName);

		var defaultMap = PitchedSoundKeys.songs.get("default");
		return defaultMap.exists(lookupName) ? defaultMap.get(lookupName) : defaultMap.get(soundName);
	}

	/** Queues every pre-rendered pitch variant of `soundName` for loading (one file per musical
		key, plus `gotDiamond`'s two extra special variants), so `playPitchedSound` can fetch
		whichever one it ends up needing without an extra load round-trip. */
	public static function preloadPitchedSound(soundName:String, worker:ResourceLoaderWorker) {
		var name = soundName.toLowerCase();
		for (key in pitchKeys)
			worker.loadFile('sound/$name/$key.wav');
		if (name == "gotdiamond") {
			worker.loadFile('sound/$name/a_flat_5.wav');
			worker.loadFile('sound/$name/f_5.wav');
		}
	}

	/** Resolves the file path of the pitch variant that would be played for `soundName`, without
		playing it — for callers that need the `Sound` resource itself (e.g. to store as a
		`PowerUp.pickupSound` played later by other code). */
	public static function getPitchedSoundPath(soundName:String, ?variantSuffix:String):String {
		var key = resolvePitchKey(soundName, variantSuffix);
		return 'data/sound/${soundName.toLowerCase()}/${key.toLowerCase()}.wav';
	}

	/** Plays one of a sound's pre-rendered pitch variants (`data/sound/<soundName>/<key>.wav`),
		matched to the key of whichever song is currently playing — PQ's "pitched sounds" feature. */
	public static function playPitchedSound(soundName:String, resources:Array<Resource<Sound>>, ?variantSuffix:String, ?position:Vector):hxd.snd.Channel {
		var path = getPitchedSoundPath(soundName, variantSuffix);
		var sound = ResourceLoader.getResource(path, ResourceLoader.getAudio, resources);
		return playSound(sound, position);
	}
}
