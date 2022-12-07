package shapes;

import src.ResourceLoaderWorker;
import src.MarbleWorld;
import src.ResourceLoader;
import src.TimeState;
import mis.MissionElement.MissionElementItem;
import src.AudioManager;

class MegaMarble extends PowerUp {
	public function new(element:MissionElementItem) {
		super(element);
		this.dtsPath = "data/shapes/items/megamarble.dts";
		this.isCollideable = false;
		this.isTSStatic = false;
		this.showSequences = true;
		this.identifier = "MegaMarble";
		this.pickUpName = "Mega Marble PowerUp";
	}

	public override function init(level:MarbleWorld, onFinish:Void->Void) {
		super.init(level, () -> {
			ResourceLoader.load("sound/pumegamarblevoice.wav").entry.load(() -> {
				var worker = new ResourceLoaderWorker(onFinish);
				worker.loadFile("sound/mega_bouncehard1.wav");
				worker.loadFile("sound/mega_bouncehard2.wav");
				worker.loadFile("sound/mega_bouncehard3.wav");
				worker.loadFile("sound/mega_bouncehard4.wav");
				worker.loadFile("sound/mega_roll.wav");
				worker.loadFile("sound/dosuperjump.wav");
				this.pickupSound = ResourceLoader.getResource("data/sound/pumegamarblevoice.wav", ResourceLoader.getAudio, this.soundResources);
				worker.run();
			});
		});
	}

	public function pickUp():Bool {
		return this.level.pickUpPowerUp(this);
	}

	public function use(timeState:TimeState) {
		this.level.marble.enableMegaMarble(timeState.currentAttemptTime);
		this.level.deselectPowerUp();
		AudioManager.playSound(ResourceLoader.getResource('data/sound/dosuperjump.wav', ResourceLoader.getAudio, this.soundResources));
	}
}
