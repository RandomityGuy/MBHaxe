package shapes;

import h3d.Vector;
import src.DtsObject;

class AntiGravity extends PowerUp {
	public function new() {
		super();
		this.dtsPath = "data/shapes/items/antigravity.dts";
		this.isCollideable = false;
		this.isTSStatic = false;
		this.identifier = "AntiGravity";
		this.autoUse = true;
	}

	public function pickUp():Bool {
		var direction = new Vector(0, 0, -1);
		direction.transform(this.getRotationQuat().toMatrix());
		return !direction.equals(this.level.currentUp);
	}

	public function use(time:Float) {
		var direction = new Vector(0, 0, -1);
		direction.transform(this.getRotationQuat().toMatrix());
		this.level.setUp(direction, time);
		// marble.body.addLinearVelocity(this.level.currentUp.scale(20)); // Simply add to vertical velocity
		// if (!this.level.rewinding)
		//	AudioManager.play(this.sounds[1]);
		// this.level.particles.createEmitter(superJumpParticleOptions, null, () => Util.vecOimoToThree(marble.body.getPosition()));
		// this.level.deselectPowerUp();
	}
}
