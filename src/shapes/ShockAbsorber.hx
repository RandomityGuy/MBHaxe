package shapes;

import src.ResourceLoader;
import mis.MissionElement.MissionElementItem;
import src.TimeState;
import src.DtsObject;
import src.MarbleWorld;

class ShockAbsorber extends PowerUp {
	public function new(element:MissionElementItem) {
		super(element);
		var datablockLower = element.datablock.toLowerCase();
		this.dtsPath = switch (datablockLower) {
			case "shockabsorberitem_pq": "data/shapes_pq/gameplay/powerups/pillow.dts";
			case "shockabsorberitem_mbu": "data/shapes_mbu/items/shockabsorber.dts";
			default: "data/shapes/items/shockabsorber.dts";
		}
		this.isCollideable = false;
		this.isTSStatic = false;
		// Instancing batches by `identifier`, and the PQ variant uses a different mesh - keep the
		// dtsPath in the identifier so it doesn't get batched with the vanilla mesh.
		this.identifier = "ShockAbsorber" + this.dtsPath;
		this.pickUpName = "Shock Absorber PowerUp";
		this.radarIndex = 27;
	}

	public override function init(level:MarbleWorld, onFinish:Void->Void) {
		super.init(level, () -> {
			ResourceLoader.load("sound/pushockabsorbervoice.wav").entry.load(() -> {
				this.pickupSound = ResourceLoader.getResource("data/sound/pushockabsorbervoice.wav", ResourceLoader.getAudio, this.soundResources);
				onFinish();
			});
		});
	}

	public function pickUp(marble:src.Marble):Bool {
		return this.level.pickUpPowerUp(marble, this);
	}

	public function use(marble:src.Marble, timeState:TimeState) {
		marble.enableShockAbsorber(timeState);
		this.level.deselectPowerUp(marble);
		return true;
	}
}
