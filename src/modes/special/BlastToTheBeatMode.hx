package modes.special;

import src.AudioManager;
import src.ResourceLoader;

/** Ported from `BlastToTheBeat.mcs`'s `MissionStartup()`/`punchIt()`. Every path-following object in
	this mission (platforms, checkpoints, items, the end pad) rides the generic `PathNode` chain
	system directly via `nextNode` fields, so nothing mission-specific is needed for any of that -
	the only real mission-specific behavior left is this looping "click track" that keeps the
	platforms' rhythm audible.

	Started from `onRestart` (the actual moment gameplay starts/restarts) rather than
	`onMissionLoad` (which fires during the loading screen, well before the player can hear
	anything meaningfully) - matches real PQ's `punchIt` (`alxStop($bassHandle); $bassHandle =
	alxPlay(...)`), which also stops and restarts the loop from scratch every time it's called, so
	each restart's beat-0 lines up with that restart rather than whatever point the previous
	attempt's loop happened to be at. */
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
