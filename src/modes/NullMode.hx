package modes;

import src.Marble;
import modes.GameMode.ScoreType;
import shapes.Gem;
import h3d.Quat;
import h3d.Vector;
import shapes.StartPad;
import src.MarbleWorld;
import src.Mission;
import src.AudioManager;
import src.ResourceLoader;
import src.Console;

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
			position.z += 3;
		} else {
			position = new Vector(0, 0, 300);
		}
		return {
			position: position,
			orientation: quat,
			up: new Vector(0, 0, 1)
		};
	}

	public function getRespawnTransform(marble:Marble):{up:Vector, position:Vector, orientation:Quat} {
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

	public function onRestart() {
		this.level.schedule(0.5, () -> {
			// setCenterText('ready');
			Console.log("State Ready");
			AudioManager.playSound(ResourceLoader.getResource('data/sound/ready.wav', ResourceLoader.getAudio, @:privateAccess this.level.soundResources));
			return 0;
		});
		this.level.schedule(2, () -> {
			// setCenterText('set');
			Console.log("State Set");
			AudioManager.playSound(ResourceLoader.getResource('data/sound/set.wav', ResourceLoader.getAudio, @:privateAccess this.level.soundResources));
			return 0;
		});
		this.level.schedule(3.5, () -> {
			// setCenterText('go');
			Console.log("State Go");
			AudioManager.playSound(ResourceLoader.getResource('data/sound/go.wav', ResourceLoader.getAudio, @:privateAccess this.level.soundResources));
			Console.log("State Play");
			return 0;
		});
	}

	public function onRespawn(marble:Marble) {}

	public function onGemPickup(marble:Marble, gem:Gem) {
		this.level.gemCount++;
		var string:String;

		// Show a notification (and play a sound) based on the gems remaining
		if (this.level.gemCount == this.level.totalGems) {
			string = "You have all the diamonds, head for the finish!";
			// if (!this.rewinding)
			AudioManager.playSound(ResourceLoader.getResource('data/sound/gotallgems.wav', ResourceLoader.getAudio, @:privateAccess this.level.soundResources));

			// Some levels with this package end immediately upon collection of all gems
			// if (this.mission.misFile.activatedPackages.includes('endWithTheGems')) {
			// 	let
			// 	completionOfImpact = this.physics.computeCompletionOfImpactWithBody(gem.bodies[0], 2); // Get the exact point of impact
			// 	this.touchFinish(completionOfImpact);
			// }
		} else {
			string = "You picked up a diamond.  ";

			var remaining = this.level.totalGems - this.level.gemCount;
			if (remaining == 1) {
				string += "Only one diamond to go!";
			} else {
				string += '${remaining} diamonds to go!';
			}

			// if (!this.rewinding)
			AudioManager.playSound(ResourceLoader.getResource('data/sound/gotgem.wav', ResourceLoader.getAudio, @:privateAccess this.level.soundResources));
		}

		this.level.displayAlert(string);
		@:privateAccess this.level.playGui.formatGemCounter(this.level.gemCount, this.level.totalGems);
	}

	public function getPreloadFiles() {
		return [];
	}

	public function onTimeExpire() {}

	public function getScoreType():ScoreType {
		return Time;
	}

	public function getFinishScore():Float {
		return level.finishTime.gameplayClock;
	}

	// public function getRewindState():RewindableState {
	// 	return null;
	// }
	// public function applyRewindState(state:RewindableState) {}
	// public function constructRewindState() {
	// 	return null;
	// }

	public function onClientRestart() {}

	public function onMissionLoad() {}

	public function update(t:src.TimeState) {}
}
