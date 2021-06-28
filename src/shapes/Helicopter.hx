package shapes;

import mis.MissionElement.MissionElementItem;
import src.TimeState;
import src.DtsObject;

class Helicopter extends PowerUp {
	public function new(element:MissionElementItem) {
		super(element);
		this.dtsPath = "data/shapes/images/helicopter.dts";
		this.isCollideable = false;
		this.isTSStatic = false;
		this.showSequences = false;
		this.identifier = "Helicopter";
		this.pickUpName = "Gyrocopter PowerUp";
	}

	public function pickUp():Bool {
		return this.level.pickUpPowerUp(this);
	}

	public function use(timeState:TimeState) {
		var marble = this.level.marble;
		marble.enableHelicopter(timeState.currentAttemptTime);
		// marble.body.addLinearVelocity(this.level.currentUp.scale(20)); // Simply add to vertical velocity
		// if (!this.level.rewinding)
		//	AudioManager.play(this.sounds[1]);
		// this.level.particles.createEmitter(superJumpParticleOptions, null, () => Util.vecOimoToThree(marble.body.getPosition()));
		this.level.deselectPowerUp();
	}
}
