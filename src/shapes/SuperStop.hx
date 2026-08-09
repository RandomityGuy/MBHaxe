package shapes;

import h3d.Vector;
import src.ResourceLoader;
import mis.MissionElement.MissionElementItem;
import src.TimeState;
import src.DtsObject;
import src.MarbleWorld;
import src.AudioManager;

class SuperStop extends PowerUp {
	public function new(element:MissionElementItem) {
		super(element);
		var datablockLower = element.datablock.toLowerCase();
		this.dtsPath = "data/shapes/items/superstop.dts";
		this.isCollideable = false;
		this.isTSStatic = false;
		this.identifier = "SuperStop";
		this.pickUpName = "Super Stop PowerUp";
		this.radarIndex = 0;
	}

	public function pickUp(marble:src.Marble):Bool {
		return this.level.pickUpPowerUp(marble, this);
	}

	public override function init(level:MarbleWorld, onFinish:Void->Void) {
		super.init(level, () -> {
			ResourceLoader.load("sound/pusuperstopvoice.wav").entry.load(() -> {
				this.pickupSound = ResourceLoader.getResource("data/sound/pusuperstopvoice.wav", ResourceLoader.getAudio, this.soundResources);
				ResourceLoader.load("sound/dosuperstop.wav").entry.load(onFinish);
			});
		});
	}

	public function use(marble:src.Marble, timeState:TimeState) {
		if (level.marble == marble && @:privateAccess !marble.isNetUpdate)
			AudioManager.playSound(ResourceLoader.getResource("data/sound/dosuperstop.wav", ResourceLoader.getAudio, this.soundResources));
		marble.velocity.load(new Vector(0, 0, 0));
		this.level.deselectPowerUp(marble);
		return true;
	}
}
