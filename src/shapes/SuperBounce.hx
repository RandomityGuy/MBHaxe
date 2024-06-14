package shapes;

import src.ResourceLoader;
import mis.MissionElement.MissionElementItem;
import src.TimeState;
import src.DtsObject;
import src.MarbleWorld;

class SuperBounce extends PowerUp {
	public function new(element:MissionElementItem) {
		super(element);
		this.dtsPath = "data/shapes/items/superbounce.dts";
		this.isCollideable = false;
		this.isTSStatic = false;
		this.identifier = "SuperBounce";
		this.pickUpName = "Marble Recoil PowerUp";
	}

	public function pickUp(marble:src.Marble):Bool {
		return this.level.pickUpPowerUp(marble, this);
	}

	public override function init(level:MarbleWorld, onFinish:Void->Void) {
		super.init(level, () -> {
			ResourceLoader.load("sound/pusuperbouncevoice.wav").entry.load(() -> {
				this.pickupSound = ResourceLoader.getResource("data/sound/pusuperbouncevoice.wav", ResourceLoader.getAudio, this.soundResources);
				onFinish();
			});
		});
	}

	public function use(marble:src.Marble, timeState:TimeState) {
		marble.enableSuperBounce(timeState);
		// marble.body.addLinearVelocity(this.level.currentUp.scale(20)); // Simply add to vertical velocity
		// if (!this.level.rewinding)
		//	AudioManager.play(this.sounds[1]);
		// this.level.particles.createEmitter(superJumpParticleOptions, null, () => Util.vecOimoToThree(marble.body.getPosition()));
		this.level.deselectPowerUp(marble);
	}
}
