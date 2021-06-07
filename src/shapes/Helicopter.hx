package shapes;

import src.DtsObject;

class Helicopter extends PowerUp {
	public function new() {
		super();
		this.dtsPath = "data/shapes/images/helicopter.dts";
		this.isCollideable = false;
		this.isTSStatic = false;
		this.showSequences = false;
		this.identifier = "Helicopter";
	}

	public function pickUp():Bool {
		return this.level.pickUpPowerUp(this);
	}

	public function use(time:Float) {
		var marble = this.level.marble;
		marble.enableHelicopter(time);
		// marble.body.addLinearVelocity(this.level.currentUp.scale(20)); // Simply add to vertical velocity
		// if (!this.level.rewinding)
		//	AudioManager.play(this.sounds[1]);
		// this.level.particles.createEmitter(superJumpParticleOptions, null, () => Util.vecOimoToThree(marble.body.getPosition()));
		// this.level.deselectPowerUp();
	}
}
