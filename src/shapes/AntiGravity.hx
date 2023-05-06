package shapes;

import src.ResourceLoader;
import mis.MissionElement.MissionElementItem;
import src.TimeState;
import h3d.Vector;
import src.DtsObject;
import src.MarbleWorld;

class AntiGravity extends PowerUp {
	public function new(element:MissionElementItem, norespawn:Bool = false) {
		super(element);
		this.dtsPath = "data/shapes/items/antigravity.dts";
		this.isCollideable = false;
		this.isTSStatic = false;
		this.identifier = "AntiGravity";
		this.pickUpName = "Gravity Defier";
		this.autoUse = true;
		if (norespawn)
			this.cooldownDuration = Math.NEGATIVE_INFINITY;
	}

	public function pickUp():Bool {
		var direction = new Vector(0, 0, -1);
		direction.transform(this.getRotationQuat().toMatrix());
		return !direction.equals(this.level.currentUp);
	}

	public function use(timeState:TimeState) {
		if (!this.level.rewinding) {
			var direction = new Vector(0, 0, -1);
			direction.transform(this.getRotationQuat().toMatrix());
			this.level.setUp(direction, timeState);
		}
		// marble.body.addLinearVelocity(this.level.currentUp.scale(20)); // Simply add to vertical velocity
		// if (!this.level.rewinding)
		//	AudioManager.play(this.sounds[1]);
		// this.level.particles.createEmitter(superJumpParticleOptions, null, () => Util.vecOimoToThree(marble.body.getPosition()));
		// this.level.deselectPowerUp();
	}

	public override function init(level:MarbleWorld, onFinish:Void->Void) {
		super.init(level, () -> {
			ResourceLoader.load("sound/gravitychange.wav").entry.load(() -> {
				this.pickupSound = ResourceLoader.getResource("data/sound/gravitychange.wav", ResourceLoader.getAudio, this.soundResources);
				onFinish();
			});
		});
	}
}
