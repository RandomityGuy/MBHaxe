package shapes;

import src.DtsObject;

class AntiGravity extends PowerUp {
	public function new() {
		super();
		this.dtsPath = "data/shapes/items/antigravity.dts";
		this.isCollideable = false;
		this.isTSStatic = false;
		this.identifier = "AntiGravity";
	}

	public function pickUp():Bool {
		return this.level.pickUpPowerUp(this);
	}

	public function use(time:Float) {
		var marble = this.level.marble;
		// marble.body.addLinearVelocity(this.level.currentUp.scale(20)); // Simply add to vertical velocity
		// if (!this.level.rewinding)
		//	AudioManager.play(this.sounds[1]);
		// this.level.particles.createEmitter(superJumpParticleOptions, null, () => Util.vecOimoToThree(marble.body.getPosition()));
		// this.level.deselectPowerUp();
	}
}
