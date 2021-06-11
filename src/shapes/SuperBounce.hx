package shapes;

import src.TimeState;
import src.DtsObject;

class SuperBounce extends PowerUp {
	public function new() {
		super();
		this.dtsPath = "data/shapes/items/superbounce.dts";
		this.isCollideable = false;
		this.isTSStatic = false;
		this.identifier = "SuperBounce";
		this.pickUpName = "Super Bounce PowerUp";
	}

	public function pickUp():Bool {
		return this.level.pickUpPowerUp(this);
	}

	public function use(timeState:TimeState) {
		var marble = this.level.marble;
		marble.enableSuperBounce(timeState.currentAttemptTime);
		// marble.body.addLinearVelocity(this.level.currentUp.scale(20)); // Simply add to vertical velocity
		// if (!this.level.rewinding)
		//	AudioManager.play(this.sounds[1]);
		// this.level.particles.createEmitter(superJumpParticleOptions, null, () => Util.vecOimoToThree(marble.body.getPosition()));
		this.level.deselectPowerUp();
	}
}
