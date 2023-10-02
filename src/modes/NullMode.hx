package modes;

import rewind.RewindableState;
import modes.GameMode.ScoreType;
import shapes.Gem;
import h3d.Quat;
import h3d.Vector;
import shapes.StartPad;
import src.MarbleWorld;
import src.Mission;
import src.AudioManager;
import src.ResourceLoader;

class NullMode implements GameMode {
	var level:MarbleWorld;

	public function new(level:MarbleWorld) {
		this.level = level;
	}

	public function getSpawnTransform() {
		// The player is spawned at the last start pad in the mission file.
		var startPad = this.level.dtsObjects.filter(x -> x is StartPad).pop();
		var position:Vector;
		var quat:Quat = new Quat();
		if (startPad != null) {
			// If there's a start pad, start there
			position = startPad.getAbsPos().getPosition();
			quat = startPad.getRotationQuat().clone();
		} else {
			position = new Vector(0, 0, 300);
		}
		position.z += 0.727843;
		return {
			position: position,
			orientation: quat,
			up: new Vector(0, 0, 1)
		};
	}

	public function getRespawnTransform():{up:Vector, position:Vector, orientation:Quat} {
		return null;
	}

	public function missionScan(mission:Mission) {
		// Do nothing
	}

	public function getStartTime() {
		return 0.0;
	}

	public function timeMultiplier() {
		return 1.0;
	}

	public function onRestart() {}

	public function onRespawn() {}

	public function onGemPickup(gem:Gem) {
		this.level.gemCount++;
		var string:String;

		// Show a notification (and play a sound) based on the gems remaining
		if (this.level.gemCount == this.level.totalGems) {
			string = "You have all the gems, head for the finish!";
			AudioManager.playSound(ResourceLoader.getResource('data/sound/gem_all.wav', ResourceLoader.getAudio, @:privateAccess this.level.soundResources));
		} else {
			string = "You picked up a gem. ";

			var remaining = this.level.totalGems - this.level.gemCount;
			if (remaining == 1) {
				string += "Only one gem to go!";
			} else {
				string += '${remaining} gems to go!';
			}

			AudioManager.playSound(ResourceLoader.getResource('data/sound/gem_collect.wav', ResourceLoader.getAudio,
				@:privateAccess this.level.soundResources));
		}

		this.level.displayAlert(string);
		@:privateAccess this.level.playGui.formatGemCounter(this.level.gemCount, this.level.totalGems);
	}

	public function getPreloadFiles() {
		return ['data/sound/gem_all.wav'];
	}

	public function onTimeExpire() {}

	public function getScoreType():ScoreType {
		return Time;
	}

	public function getFinishScore():Float {
		return level.finishTime.gameplayClock;
	}

	public function getRewindState():RewindableState {
		return null;
	}

	public function applyRewindState(state:RewindableState) {}

	public function constructRewindState() {
		return null;
	}
}
