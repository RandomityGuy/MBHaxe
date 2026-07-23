package shapes;

import src.ResourceLoader;
import mis.MissionElement.MissionElementItem;
import src.TimeState;
import src.DtsObject;
import src.AudioManager;
import src.MarbleWorld;
import src.Marble;

class Helicopter extends PowerUp {
	public function new(element:MissionElementItem) {
		super(element);
		this.dtsPath = StringTools.endsWith(element.datablock, "_PQ") ? "data/shapes_pq/gameplay/powerups/gyrocopter.dts" : "data/shapes/images/helicopter.dts";
		this.isCollideable = false;
		this.isTSStatic = false;
		this.showSequences = false;
		// Instancing batches by `identifier`, and the PQ variant uses a different mesh - keep the
		// dtsPath in the identifier so it doesn't get batched with the vanilla mesh.
		this.identifier = "Helicopter" + this.dtsPath;
		this.pickUpName = "Helicopter PowerUp";
	}

	public override function init(level:MarbleWorld, onFinish:Void->Void) {
		super.init(level, () -> {
			ResourceLoader.load("sound/pugyrocoptervoice.wav").entry.load(() -> {
				this.pickupSound = ResourceLoader.getResource("data/sound/pugyrocoptervoice.wav", ResourceLoader.getAudio, this.soundResources);
				onFinish();
			});
		});
	}

	public function pickUp(marble:Marble):Bool {
		return this.level.pickUpPowerUp(marble, this);
	}

	public function use(marble:Marble, timeState:TimeState) {
		marble.enableHelicopter(timeState, StringTools.endsWith(dtsPath, "gyrocopter.dts"));
		this.level.deselectPowerUp(marble);
		return true;
	}
}
