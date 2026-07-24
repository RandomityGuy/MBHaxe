package shapes;

import h3d.Vector;
import h3d.mat.BlendMode;
import src.DtsObject;
import src.TimeState;
import src.MarbleWorld;
import src.Marble;
import src.AudioManager;
import src.ResourceLoader;
import src.ResourceLoaderWorker;
import collision.CollisionInfo;
import src.ParticleSystem.ParticleData;
import src.ParticleSystem.ParticleEmitterOptions;
import mis.MissionElement.MissionElementStaticShape;

/** PQ's ambient "mist"/"shine" gleam around an ice shard (`server/scripts/particles/
	IceShardMistEmitter.cs`/`IceShardShineEmitter.cs`) - runs forever (the shard itself is never
	removed in this port - see `IceShard.hx`'s class doc). */
/** Ported from `IceShardMistEmitter.cs`. Note the source has a misspelled duplicate
	`dragCoeffiecient = "1"` at the bottom of `IceShardMistParticle` (and a bogus
	`dragCoefficient = "5.71219"` on the *emitter*, which has no drag field at all in the real
	engine) - both are dead/no-op fields since they don't match the real `dragCoefficient` name;
	the correctly-spelled `dragCoefficient = "9.21569"` earlier in the particle block is the one
	that actually takes effect. */
final iceShardMistOptions:ParticleEmitterOptions = {
	ejectionPeriod: 294,
	periodVariance: 78,
	ambientVelocity: new Vector(0, 0, 0),
	ejectionVelocity: 0,
	velocityVariance: 0,
	emitterLifetime: 1e9,
	ejectionOffset: 0.392157,
	thetaMin: 0,
	thetaMax: 148.235,
	phiReferenceVel: 0,
	phiVariance: 360,
	inheritedVelFactor: 0,
	particleOptions: {
		texture: 'particles/smoke_blur32.png',
		blending: BlendMode.Alpha,
		spinSpeed: 10,
		spinRandomMin: -90,
		spinRandomMax: 0.5,
		lifetime: 1400,
		lifetimeVariance: 96,
		dragCoefficient: 9.21569,
		constantAcceleration: 0,
		gravityCoefficient: -0.0980392,
		windCoefficient: 0,
		colors: [
			new Vector(0.843137, 0.833333, 0.843137, 0),
			new Vector(0.784314, 0.813725, 0.882353, 0.686275),
			new Vector(0.843137, 0.862745, 0.892157, 0.264706),
			new Vector(0.892157, 0.911765, 0.980392, 0)
		],
		sizes: [0.83, 0.83, 1.08, 1.08],
		times: [0, 0.28, 0.73, 1]
	}
};

/** Ported from `IceShardShineEmitter.cs`. Same misspelled-duplicate situation as the mist particle
	above - the real `dragCoefficient` is `10`, not the dead `dragCoeffiecient = "0.1"` an earlier
	pass of this port had mistakenly picked up. */
final iceShardShineOptions:ParticleEmitterOptions = {
	ejectionPeriod: 275,
	periodVariance: 274,
	ambientVelocity: new Vector(0, 0, 0),
	ejectionVelocity: 3.92157,
	velocityVariance: 2.44098,
	emitterLifetime: 1e9,
	ejectionOffset: 0,
	thetaMin: 0,
	thetaMax: 180,
	phiReferenceVel: 0,
	phiVariance: 360,
	inheritedVelFactor: 0,
	particleOptions: {
		texture: 'particles/glint2.png',
		blending: BlendMode.Add,
		spinSpeed: 0,
		spinRandomMin: 0,
		spinRandomMax: 0,
		lifetime: 1500,
		lifetimeVariance: 100,
		dragCoefficient: 10,
		constantAcceleration: 0,
		gravityCoefficient: 0,
		windCoefficient: 0,
		colors: [
			new Vector(0.852941, 0.911765, 1, 0),
			new Vector(0.862745, 0.901961, 1, 0),
			new Vector(0.862745, 0.892157, 1, 1),
			new Vector(0.862745, 0.892157, 1, 0)
		],
		sizes: [0.15, 0, 0.15, 0],
		times: [0, 0.78, 0.88, 1]
	}
};

/** Ported from PQ's `IceShard1`/`IceShard2`/`IceShard::onCollision` (`server/scripts/hazards.cs`).
	Touching a shard freezes the marble for `FREEZE_TIME` seconds (see `Marble.freeze`/`unfreeze`),
	with an `INVULN_TIME`-second grace period after unfreezing before it can refreeze. PQ's version
	also lets a marble that's currently on fire ("fireball") melt through the shard instead of
	freezing (`%marble._fireballActive` / `iceCollision`) - that's the Fireball powerup, not ported
	yet, so shards always freeze here regardless of marble state; shards are also never destroyed
	(that only happens via the fireball-melts-it path in PQ). */
class IceShard extends DtsObject {
	public static inline final FREEZE_TIME = 2.0;
	public static inline final INVULN_TIME = 1.0;

	var freezeSound:hxd.res.Sound;
	var crackSound:hxd.res.Sound;
	var element:MissionElementStaticShape;
	var gotoTargetTriggered:Bool = false;

	public function new(element:MissionElementStaticShape) {
		super();
		this.element = element;
		var isShard2 = element.datablock.toLowerCase() == "iceshard2";
		this.dtsPath = isShard2 ? "data/shapes_pq/gameplay/hazards/ice_shard_2.dts" : "data/shapes_pq/gameplay/hazards/ice_shard.dts";
		this.isCollideable = true;
		this.identifier = "IceShard" + this.dtsPath;
		this.enableCollideCallbacks = true;

		var skinField = element.fields.get("skin");
		if (skinField != null && skinField[0] != "")
			this.skinOverride = skinField[0];
	}

	public override function init(level:MarbleWorld, onFinish:Void->Void) {
		super.init(level, () -> {
			var mistData = new ParticleData();
			mistData.identifier = "iceShardMist";
			mistData.texture = ResourceLoader.getResource("data/particles/smoke_blur32.png", ResourceLoader.getTexture, this.textureResources);

			var shineData = new ParticleData();
			shineData.identifier = "iceShardShine";
			shineData.texture = ResourceLoader.getResource("data/particles/glint2.png", ResourceLoader.getTexture, this.textureResources);

			this.level.particleManager.createEmitter(iceShardMistOptions, mistData, null, () -> this.getAbsPos().getPosition());
			this.level.particleManager.createEmitter(iceShardShineOptions, shineData, null, () -> this.getAbsPos().getPosition());

			var worker = new ResourceLoaderWorker(onFinish);
			worker.addTask(fwd -> ResourceLoader.load("sound/ice_freeze.wav").entry.load(() -> {
				this.freezeSound = ResourceLoader.getResource("data/sound/ice_freeze.wav", ResourceLoader.getAudio, this.soundResources);
				fwd();
			}));
			worker.addTask(fwd -> ResourceLoader.load("sound/ice_crack.wav").entry.load(() -> {
				this.crackSound = ResourceLoader.getResource("data/sound/ice_crack.wav", ResourceLoader.getAudio, this.soundResources);
				fwd();
			}));
			worker.run();
		});
	}

	public override function reset() {
		super.reset();

		this.gotoTargetTriggered = false;
	}

	public function playFreezeSound(marble:Marble) {
		if (marble == this.level.marble && this.freezeSound != null)
			AudioManager.playSound(this.freezeSound);
	}

	public function playCrackSound(marble:Marble) {
		if (marble == this.level.marble && this.crackSound != null)
			AudioManager.playSound(this.crackSound);
	}

	override function onMarbleContact(marble:Marble, timeState:TimeState, ?contact:CollisionInfo) {
		super.onMarbleContact(marble, timeState, contact);
		if (!marble.isFrozen && marble.lastFreezeTime + FREEZE_TIME + INVULN_TIME < timeState.currentAttemptTime)
			marble.freeze(this, timeState);

		this.runGotoTarget(marble, timeState);
	}

	/** `gotoTarget` isn't a core PQ engine feature - it's a per-mission script override some PQ
		levels inject (`package IceShardGoToTarget { function IceShard::onCollision(...) }`, e.g.
		`UnseasonablyCold.mcs`) that bolts PathTrigger-style object/path movement, PathedInterior
		target-time setting, and a help-bubble message onto specific ice shard instances. Since
		arbitrary embedded script can't be interpreted generically, this one pattern is baked in as
		a built-in IceShard capability instead - active only when the `gotoTarget` field is set. */
	function runGotoTarget(marble:Marble, timeState:TimeState) {
		var gotoTargetField = this.element.fields.get("gototarget");
		if (gotoTargetField == null || !mis.MisParser.parseBoolean(gotoTargetField[0]))
			return;

		var triggerOnceField = this.element.fields.get("triggeronce");
		var triggerOnce = triggerOnceField == null || mis.MisParser.parseBoolean(triggerOnceField[0]);
		if (triggerOnce && this.gotoTargetTriggered)
			return;
		this.gotoTargetTriggered = true;

		triggers.PathTrigger.runObjectPathChain(this.element.fields, this.level);

		var i = 1;
		while (true) {
			var interiorField = this.element.fields.get("pathedinterior" + i);
			var interiorName = interiorField != null ? interiorField[0] : null;
			if (interiorName == null || interiorName == "")
				break;
			var target = this.level.namedGameObjects.get(interiorName);
			if (target == null || !(target is src.PathedInterior))
				break;

			var targetTimeField = this.element.fields.get("targettime" + i);
			var targetTime = targetTimeField != null ? mis.MisParser.parseNumber(targetTimeField[0]) : 999999;
			if (targetTime > 0)
				targetTime /= 1000;
			(cast target : src.PathedInterior).setTargetTime(timeState, targetTime);
			i++;
		}

		var textField = this.element.fields.get("text");
		if (textField != null && textField[0] != "") {
			var extendedField = this.element.fields.get("extended");
			var extended = extendedField != null && mis.MisParser.parseBoolean(extendedField[0]);
			if (extended)
				this.level.displayHelp(textField[0]);
			else
				this.level.displayAlert(textField[0]);
		}
	}
}
