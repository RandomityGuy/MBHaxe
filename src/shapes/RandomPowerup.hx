package shapes;

import src.ResourceLoaderWorker;
import src.ResourceLoader;
import mis.MissionElement.MissionElementItem;
import src.TimeState;
import mis.MisParser;
import src.MarbleWorld;

class RandomPowerup extends PowerUp {
	var wasTimeTravel:Bool;

	public function new(element:MissionElementItem) {
		super(element);
		this.dtsPath = "data/shapes/items/random.dts";
		this.isCollideable = false;
		this.isTSStatic = false;
		this.identifier = "RandomPowerup";
		this.useInstancing = true;
		this.autoUse = true;
		this.wasTimeTravel = false;
	}

	public override function init(level:MarbleWorld, onFinish:Void->Void) {
		super.init(level, () -> {
			var sounds = [
				"sound/pugyrocoptervoice.wav",
				"sound/pushockabsorbervoice.wav",
				"sound/pusuperbouncevoice.wav",
				"sound/pusuperjumpvoice.wav",
				"sound/pusuperspeedvoice.wav",
				"sound/dosuperspeed.wav",
				"sound/dosuperjump.wav",
				"sound/putimetravelvoice.wav",
				"sound/timetravelactive.wav"
			];
			var rlw = new ResourceLoaderWorker(onFinish);
			for (sound in sounds) {
				rlw.loadFile(sound);
			}
			rlw.run();
		});
	}

	public function pickUp():Bool {
		while (true) {
			var r = Std.random(6);
			if (this.level.isWatching)
				r = this.level.replay.getRandomGenState();
			var pow:PowerUp = null;
			switch (r) {
				case 0:
					pow = new TimeTravel(this.element);
					this.pickupSound = ResourceLoader.getResource("data/sound/putimetravelvoice.wav", ResourceLoader.getAudio, this.soundResources);
					wasTimeTravel = true;
				case 1:
					pow = new SuperJump(this.element);
					this.pickupSound = ResourceLoader.getResource("data/sound/pusuperjumpvoice.wav", ResourceLoader.getAudio, this.soundResources);
				case 2:
					pow = new SuperSpeed(this.element);
					this.pickupSound = ResourceLoader.getResource("data/sound/pusuperspeedvoice.wav", ResourceLoader.getAudio, this.soundResources);
				case 3:
					pow = new ShockAbsorber(this.element);
					this.pickupSound = ResourceLoader.getResource("data/sound/pushockabsorbervoice.wav", ResourceLoader.getAudio, this.soundResources);
				case 4:
					pow = new SuperBounce(this.element);
					this.pickupSound = ResourceLoader.getResource("data/sound/pusuperbouncevoice.wav", ResourceLoader.getAudio, this.soundResources);
				case 5:
					pow = new Helicopter(this.element);
					this.pickupSound = ResourceLoader.getResource("data/sound/pugyrocoptervoice.wav", ResourceLoader.getAudio, this.soundResources);
			}
			pow.level = this.level;

			if (pow.pickUp()) {
				this.cooldownDuration = pow.cooldownDuration;
				this.pickUpName = pow.pickUpName;
				if (this.level.isRecording)
					this.level.replay.recordRandomGenState(r);
				return true;
			}
		}
		return true;
	}

	public function use(time:TimeState) {
		if (this.wasTimeTravel)
			this.level.addBonusTime(5);
	}
}
