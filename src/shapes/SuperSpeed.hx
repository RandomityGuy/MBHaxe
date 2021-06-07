package shapes;

import h3d.Quat;
import h3d.Vector;
import src.DtsObject;

class SuperSpeed extends PowerUp {
	public function new() {
		super();
		this.dtsPath = "data/shapes/items/superspeed.dts";
		this.isCollideable = false;
		this.isTSStatic = false;
		this.identifier = "SuperSpeed";
		this.useInstancing = true;
	}

	public function pickUp():Bool {
		return this.level.pickUpPowerUp(this);
	}

	public function use(time:Float) {
		var marble = this.level.marble;
		var movementVector = marble.getMarbleAxis()[0];

		// Okay, so super speed directionality is a bit strange. In general, the direction is based on the normal vector of the last surface you had contact with.

		// var quat = level.newOrientationQuat;
		// movementVector.applyQuaternion(quat);

		var quat2 = new Quat();
		// Determine the necessary rotation to rotate the up vector to the contact normal.
		quat2.initMoveTo(marble.gravityDir.multiply(-1), marble.lastContactNormal);
		movementVector.transform(quat2.toMatrix());
		marble.velocity = marble.velocity.add(movementVector.multiply(-24.7));

		// marble.body.addLinearVelocity(Util.vecThreeToOimo(movementVector).scale(24.7)); // Whirligig's determined value
		// marble.body.addLinearVelocity(this.level.currentUp.scale(20)); // Simply add to vertical velocity
		// if (!this.level.rewinding)
		//	AudioManager.play(this.sounds[1]);
		// this.level.particles.createEmitter(superJumpParticleOptions, null, () => Util.vecOimoToThree(marble.body.getPosition()));
		// this.level.deselectPowerUp();
	}
}
