package shapes;

import h3d.Vector;
import h3d.Quat;
import h3d.Matrix;
import h3d.mat.BlendMode;
import src.DtsObject;
import src.Marble;
import src.MarbleWorld;
import src.TimeState;
import src.AudioManager;
import src.ResourceLoader;
import src.ResourceLoaderWorker;
import src.ParticleSystem.ParticleData;
import src.ParticleSystem.ParticleEmitterOptions;
import collision.CollisionInfo;
import mis.MissionElement.MissionElementStaticShape;

/** Ported from `server/scripts/cannon.cs`'s `CannonSmokeEmitter`/`CannonSmoke` - one of the two
	one-shot "point emission" bursts `CannonExplosion` (the `explosion` datablock field every
	`DefaultCannon`-family cannon has) spawns via Torque's native "shape entered Destroyed damage
	state" explosion system (`Cannon::explode`'s `setDamageState("Destroyed")`) - that native
	trigger has no equivalent in this port, so these are spawned explicitly from `Cannon.explode`
	instead. See `cannonVolumeOptions` below for `CannonExplosion`'s third emitter (the
	`particleEmitter`/`particleDensity`/`particleRadius` "volume particles"). */
final cannonSmokeOptions:ParticleEmitterOptions = {
	ejectionPeriod: 10,
	periodVariance: 0,
	ambientVelocity: new Vector(0, 0, 0),
	ejectionVelocity: 4,
	velocityVariance: 0.5,
	emitterLifetime: 250,
	ejectionOffset: 0,
	thetaMin: 0,
	thetaMax: 180,
	phiReferenceVel: 0,
	phiVariance: 360,
	inheritedVelFactor: 0.25,
	particleOptions: {
		texture: 'particles/smoke.png',
		blending: BlendMode.Alpha,
		spinSpeed: 0,
		spinRandomMin: -80,
		spinRandomMax: 80,
		lifetime: 1200,
		lifetimeVariance: 300,
		dragCoefficient: 0,
		constantAcceleration: -0.8,
		gravityCoefficient: 0,
		windCoefficient: 0,
		colors: [
			new Vector(0.56, 0.36, 0.26, 1),
			new Vector(0.2, 0.2, 0.2, 1),
			new Vector(0, 0, 0, 0)
		],
		sizes: [1, 1.5, 2],
		times: [0, 0.5, 1]
	}
};

/** Ported from `server/scripts/cannon.cs`'s `CannonSparkEmitter`/`CannonSparks` - the other
	`CannonExplosion` point-emission burst, see `cannonSmokeOptions`'s doc comment. */
final cannonSparkOptions:ParticleEmitterOptions = {
	ejectionPeriod: 3,
	periodVariance: 0,
	ambientVelocity: new Vector(0, 0, 0),
	ejectionVelocity: 13,
	velocityVariance: 6.75,
	emitterLifetime: 100,
	ejectionOffset: 0,
	thetaMin: 0,
	thetaMax: 180,
	phiReferenceVel: 0,
	phiVariance: 360,
	inheritedVelFactor: 0.2,
	particleOptions: {
		texture: 'particles/spark.png',
		blending: BlendMode.Add,
		spinSpeed: 0,
		spinRandomMin: 0,
		spinRandomMax: 0,
		lifetime: 500,
		lifetimeVariance: 350,
		dragCoefficient: 1,
		constantAcceleration: 0,
		gravityCoefficient: 0,
		windCoefficient: 0,
		colors: [
			new Vector(0.6, 0.4, 0.3, 1),
			new Vector(0.6, 0.4, 0.3, 1),
			new Vector(1, 0.4, 0.3, 0)
		],
		sizes: [0.5, 0.25, 0.25],
		times: [0, 0.5, 1]
	}
};

/** Ported from `server/scripts/cannon.cs`'s `CannonParticle`/`CannonEmitter`, as driven by
	`CannonExplosion`'s `particleEmitter = CannonEmitter`, `particleDensity = 80`,
	`particleRadius = 1` fields - real source's `Explosion::explode` spawns these via
	`ParticleEmitter::emitParticles(pos, normal, radius, vel, density)`, a *radius-distributed*
	one-shot spawn mode `game/fx/particleEngine.cc` implements natively (`density` particles, each
	given its own random starting position within a sphere of `radius` around `pos`) that this
	codebase's `ParticleManager` has no equivalent API for. Emulated instead with the existing
	per-particle `spawnOffset` hook (`ParticleEmitterOptions.spawnOffset`, added to each particle's
	base spawn position - see `ParticleEmitter.emit`) returning a uniformly-random point inside a
	unit sphere, and an `emitterLifetime` long enough (`density * ejectionPeriod`) that roughly
	`particleDensity` particles spawn over the burst at the datablock's own `ejectionPeriodMS`,
	approximating "spawn `density` particles at once" as "spawn them in a very short continuous
	burst" instead - not instantaneous like the real engine, but visually equivalent for a puff this
	brief. */
final cannonVolumeOptions:ParticleEmitterOptions = {
	ejectionPeriod: 7,
	periodVariance: 0,
	ambientVelocity: new Vector(0, 0, 0),
	ejectionVelocity: 2,
	velocityVariance: 1,
	emitterLifetime: 80 * 7,
	ejectionOffset: 0,
	thetaMin: 0,
	thetaMax: 60,
	phiReferenceVel: 0,
	phiVariance: 360,
	inheritedVelFactor: 0.2,
	spawnOffset: () -> {
		var dir = new Vector(Math.random() * 2 - 1, Math.random() * 2 - 1, Math.random() * 2 - 1);
		if (dir.lengthSq() < 0.0001)
			dir.set(0, 0, 1);
		dir.normalize();
		// Cube-root the radial fraction so points end up uniformly distributed by *volume*, not
		// bunched up near the center (a plain `Math.random() * radius` would do the latter).
		var radius = Math.pow(Math.random(), 1 / 3) * 1;
		return dir.multiply(radius);
	},
	particleOptions: {
		texture: 'particles/smoke.png',
		blending: BlendMode.Add,
		spinSpeed: 0,
		spinRandomMin: 0,
		spinRandomMax: 0,
		lifetime: 1000,
		lifetimeVariance: 150,
		dragCoefficient: 2,
		constantAcceleration: 0,
		gravityCoefficient: 0.2,
		windCoefficient: 0,
		colors: [new Vector(0.56, 0.36, 0.26, 1), new Vector(0.56, 0.36, 0.26, 0)],
		sizes: [0.5, 1],
		times: [0, 1]
	}
};

/** Ported from `DefaultCannon`/`Cannon_Low/Mid/High/Custom` (`server/scripts/cannon.cs`) + the
	per-frame aim/fire logic in `client/scripts/cannon.cs` (that half lives in
	`CameraController.updateCannonCamera`, since real PQ keeps cannon aim tightly coupled to the
	camera's own live yaw/pitch state - see that function's doc comment).

	Rotation math note: rather than re-deriving Torque's own axis-angle rotation chains (a real risk
	of subtle sign/handedness bugs, as the DTS billboard-facing feature ran into earlier this port),
	`computeAimDirection`/`buildLookRotation` instead reuse two already-confirmed-correct primitives
	from elsewhere in this exact codebase: the world-direction formula `CameraController.update()`
	uses to turn its own `CameraYaw`/`CameraPitch` into a look direction, and the billboard port's
	direction-to-look-rotation construction. This makes "the cannon fires exactly where the camera
	is looking" true by construction. Still worth confirming in-game that yaw/pitch *bounds*
	(`pitchBoundHigh`/`Low`, `yawBoundLeft`/`Right`) clamp in the intuitively-correct direction -
	their sign relationship was worked out from the real source's own field-doc comments, not
	tested empirically. */
class Cannon extends DtsObject {
	public var useCharge:Bool;
	public var chargeTime:Float; // seconds
	public var force:Float;

	// Degrees, matching the mission field's own authored unit - only converted to radians at the
	// point of use (matches real source's `mDegToRad` calls at each use site, not at parse time).
	public var pitch:Float;
	public var yaw:Float;
	public var pitchBoundHigh:Float;
	public var pitchBoundLow:Float;
	public var yawBoundLeft:Float;
	public var yawBoundRight:Float;
	public var yawLimit:Bool;

	public var instant:Bool;
	public var instantDelayTime:Float; // seconds
	public var useBase:Bool;
	public var lockTime:Float; // seconds
	public var lockCam:Bool;
	public var basename:String;

	// Parsed for forward-compatibility with a later HUD/aim-assist pass (per direct instruction to
	// keep this port clean enough to add that later) - not read anywhere yet.
	public var showReticle:Bool;
	public var showAim:Bool;
	public var aimSize:Float;

	public var base:CannonBase = null;

	/** The cannon's original placed transform (`_baseTrans`) - captured once, lazily, the first
		time `resetCannon` runs (which is guaranteed to be after the mission's real placement
		transform has actually been applied - see `MarbleWorld.addPlaceableShape`/`restart`'s
		ordering, capturing this any earlier would see the shape's pre-placement default
		transform). */
	public var baseTransform:Matrix = null;

	public var lastYaw:Float = 0;
	public var lastPitch:Float = 0;

	var explodeSound:hxd.res.Sound;
	var explodeForceSound:hxd.res.Sound;
	var smokeData:ParticleData;
	var sparkData:ParticleData;

	/** `-1e8` sentinel = not currently disabled (per
		[No Null Primitives](feedback_no_null_primitives.md)). */
	var explodeReenableTime:Float = -1e8;

	public function new(element:MissionElementStaticShape, presetForce:Float = -1) {
		super();
		this.dtsPath = "data/shapes_pq/gameplay/cannon/cannon.dts";
		this.identifier = "Cannon";
		this.isCollideable = true;

		var fields = element.fields;
		function getStr(name:String, def:String):String {
			var f = fields.get(name);
			return f != null && f[0] != "" ? f[0] : def;
		}
		function getNum(name:String, def:Float):Float {
			var f = fields.get(name);
			return f != null && f[0] != "" ? mis.MisParser.parseNumber(f[0]) : def;
		}
		function getBool(name:String, def:Bool):Bool {
			var f = fields.get(name);
			return f != null && f[0] != "" ? mis.MisParser.parseBoolean(f[0]) : def;
		}

		this.useCharge = getBool("usecharge", false);
		this.chargeTime = getNum("chargetime", 2000) / 1000;
		this.force = presetForce >= 0 ? presetForce : getNum("force", 30);
		this.pitch = getNum("pitch", 0);
		this.yaw = getNum("yaw", 0);
		this.pitchBoundHigh = getNum("pitchboundhigh", 80);
		this.pitchBoundLow = getNum("pitchboundlow", -30);
		this.yawBoundLeft = getNum("yawboundleft", 70);
		this.yawBoundRight = getNum("yawboundright", 70);
		this.yawLimit = getBool("yawlimit", true);
		this.instant = getBool("instant", false);
		this.instantDelayTime = getNum("instantdelaytime", 0) / 1000;
		this.useBase = getBool("usebase", true);
		this.lockTime = getNum("locktime", 0) / 1000;
		this.lockCam = getBool("lockcam", false);
		this.basename = getStr("basename", "");
		this.showReticle = getBool("showreticle", false);
		this.showAim = getBool("showaim", true);
		this.aimSize = getNum("aimsize", 0.25);

		// Instant cannons always render orange regardless of variant skin, matching
		// `Cannon::initFields`'s `if (%obj.instant == 1) %obj.setSkinName("orange");`.
		this.skinOverride = this.instant ? "orange" : switch (element.datablock.toLowerCase()) {
			case "cannon_low": "green";
			case "cannon_mid": "blue";
			case "cannon_high": "red";
			default: "white";
		}
		this.identifier += this.skinOverride;
	}

	/** Deliberately does NOT call `resetCannon()` here - `init()`'s own `onFinish` runs well
		*before* this shape's actual placement transform is ever applied (`MarbleWorld.
		addPlaceableShape` calls `addDtsObject(shape, outerCallback)`, which runs `shape.init(level,
		innerCallback)` - `innerCallback` is this function's `onFinish` parameter, and it completes
		*before* `addDtsObject` returns control to `outerCallback`, which is the thing that actually
		calls `shape.setTransform(mat)` - capturing `baseTransform` this early would read the
		object's pre-placement default transform, not its real mission position). The first
		`resetCannon()` call instead comes from `MarbleWorld.restart()`'s unconditional `for (shape
		in dtsObjects) shape.reset();` pass, which only ever runs once the *entire* mission has
		finished loading (every object's real placement transform already applied) - see `reset()`
		below. */
	public override function init(level:MarbleWorld, onFinish:Void->Void) {
		super.init(level, () -> {
			this.level.cannons.push(this);
			var worker = new ResourceLoaderWorker(onFinish);
			worker.addTask(fwd -> ResourceLoader.load("sound/explode1_tweaked.wav").entry.load(() -> {
				this.explodeSound = ResourceLoader.getResource("data/sound/explode1_tweaked.wav", ResourceLoader.getAudio, this.soundResources);
				fwd();
			}));
			worker.addTask(fwd -> ResourceLoader.load("sound/CannonLaunch.wav").entry.load(() -> {
				this.explodeForceSound = ResourceLoader.getResource("data/sound/CannonLaunch.wav", ResourceLoader.getAudio, this.soundResources);
				fwd();
			}));
			this.smokeData = new ParticleData();
			this.smokeData.identifier = "cannonSmoke";
			this.smokeData.texture = ResourceLoader.getResource("data/particles/smoke.png", ResourceLoader.getTexture, this.textureResources);
			this.sparkData = new ParticleData();
			this.sparkData.identifier = "cannonSpark";
			this.sparkData.texture = ResourceLoader.getResource("data/particles/spark.png", ResourceLoader.getTexture, this.textureResources);
			worker.run();
		});
	}

	public override function update(timeState:TimeState) {
		super.update(timeState);
		if (!this.isCollideable && timeState.currentAttemptTime >= this.explodeReenableTime)
			this.isCollideable = true;
	}

	public override function onMarbleContact(marble:Marble, timeState:TimeState, ?contact:CollisionInfo) {
		super.onMarbleContact(marble, timeState, contact);
		marble.enterCannon(this, timeState);
	}

	/** Builds a world-space direction from `yaw`/`pitch`, using the same spherical parameterization
		confirmed correct by `hide`'s own `CannonPropertyProvider.updateCannonParams` (the level
		editor's live yaw/pitch readout for a placed cannon - `hide`'s rotation handling is
		confirmed correct, it's the actual source of truth the game's own Torque<->Heaps coordinate
		conversion should agree with). That function derives yaw/pitch FROM a direction via
		`yaw = atan2(dir.x, dir.y)`, `pitch = atan2(dir.z, sqrt(dir.x^2+dir.y^2))`, applied to the
		object's rotation *after* negating its quaternion's `x`/`w` (converting engine-space
		rotation to file/Torque-space rotation before reading it as yaw/pitch). This is that
		formula's algebraic inverse (direction FROM yaw/pitch) with the matching *vector*-space
		conversion applied instead of the quaternion one: this codebase's established rule is that
		crossing between file/Torque space and engine space negates a plain position/direction
		vector's **X component only** (see the coordinate-system note in the engine architecture
		reference - `pos.x = -pos.x`, never Y or Z) - a quaternion's conversion (negate `x` AND `w`)
		is a different-looking operation on different data, not the same rule restated. Negating
		both X and Y (an earlier, wrong attempt at this fix) satisfied the first bug report it was
		checked against (`Verticality.mcs`) but broke a different cannon in `HavingABlast.mcs`
		(yaw=0 facing backwards) - negating X only satisfies both. */
	function computeAimDirection(yawRad:Float, pitchRad:Float):Vector {
		var dir = new Vector(-Math.cos(pitchRad) * Math.sin(yawRad), Math.cos(pitchRad) * Math.cos(yawRad), Math.sin(pitchRad));
		var orientationQuat = this.level.getOrientationQuat(this.level.timeState.currentAttemptTime);
		dir.transform(orientationQuat.toMatrix());
		return dir;
	}

	/** Builds a rotation whose local +Y axis (this codebase's established mesh "forward" - see the
		DTS billboard port) points along `dir`, ported directly from `DtsObject.hx`'s confirmed-
		working billboard-facing rotation construction (same axisY/axisX/axisZ derivation). */
	function buildLookRotation(dir:Vector, up:Vector):Quat {
		var faceDir = dir.normalized();
		var worldUp = up.clone();
		if (Math.abs(faceDir.dot(worldUp)) > 0.9999)
			worldUp = new Vector(1, 0, 0);
		var axisX = faceDir.cross(worldUp);
		axisX.normalize();
		var axisZ = axisX.cross(faceDir);
		axisZ.normalize();

		var mat = new Matrix();
		mat._11 = axisX.x;
		mat._12 = axisX.y;
		mat._13 = axisX.z;
		mat._14 = 0;
		mat._21 = faceDir.x;
		mat._22 = faceDir.y;
		mat._23 = faceDir.z;
		mat._24 = 0;
		mat._31 = axisZ.x;
		mat._32 = axisZ.y;
		mat._33 = axisZ.z;
		mat._34 = 0;
		mat._41 = 0;
		mat._42 = 0;
		mat._43 = 0;
		mat._44 = 1;

		var q = new Quat();
		q.initRotateMatrix(mat);
		return q;
	}

	/** The aimed body's local +Y axis in world space - see `buildLookRotation`'s doc comment. Takes
		`yaw`/`pitch` in the cannon's own *authored* (file/`hide`) convention - use
		`computeFireDirectionFromCamera` instead for anything driven by the live camera. */
	public function computeFireDirection(yawRad:Float, pitchRad:Float):Vector {
		return this.computeAimDirection(yawRad, pitchRad);
	}

	/** Builds a world direction the *same way this engine's own orbit camera does*
		(`CameraController.update()`'s `directionVector` construction: rotate `(1,0,0)` by pitch
		around Y, then by yaw around Z, then the level's gravity-orientation quat) - NOT the same
		axis convention as `computeAimDirection` above. That function treats local **Y** as the
		zero-yaw forward axis (matching `hide`'s tool, for the cannon's own *authored* `yaw`/`pitch`
		fields); the live camera treats local **X** as the zero-yaw forward axis. Conflating the two
		(feeding live `CameraYaw`/`CameraPitch` into `computeAimDirection`) is a 90-degree axis
		mismatch, not just a sign difference - confirmed as the root cause of a real "camera points
		90 degrees off after firing" bug report. Use this (and `computeFireDirectionFromCamera`/
		`updateAimFromCamera` below) for anything driven by live `CameraYaw`/`CameraPitch`; use
		`computeAimDirection`/`computeFireDirection`/`updateAim` for the cannon's own authored
		resting `yaw`/`pitch` fields (`resetCannon`, the base auto-create fallback, instant-cannon
		firing). No pitch sign flip is needed here (unlike calls into the file-convention
		functions) - `cameraPitch` is used exactly as the orbit camera itself uses it. */
	function computeCameraDirection(cameraYaw:Float, cameraPitch:Float):Vector {
		var dir = new Vector(1, 0, 0);
		var q = new Quat();
		q.initRotateAxis(0, 1, 0, cameraPitch);
		dir.transform(q.toMatrix());
		q.initRotateAxis(0, 0, 1, cameraYaw);
		dir.transform(q.toMatrix());
		var orientationQuat = this.level.getOrientationQuat(this.level.timeState.currentAttemptTime);
		dir.transform(orientationQuat.toMatrix());
		return dir;
	}

	/** Camera-convention counterpart to `computeFireDirection` - see `computeCameraDirection`'s doc
		comment. */
	public function computeFireDirectionFromCamera(cameraYaw:Float, cameraPitch:Float):Vector {
		return this.computeCameraDirection(cameraYaw, cameraPitch);
	}

	/** Ported from `updateCannonView`'s per-frame base/body transform update - sets the base to
		yaw only, the body to yaw+pitch, both positioned at the cannon's original placement. Called
		once by `resetCannon` (with the cannon's own authored `yaw`/`pitch` fields, file convention)
		to establish the resting pose - see `updateAimFromCamera` for the live-camera-driven
		counterpart called every frame while a marble is actually aiming this cannon. */
	public function updateAim(yawRad:Float, pitchRad:Float) {
		var basePos = this.baseTransform.getPosition();
		var worldUp = new Vector(0, 0, 1);
		worldUp.transform(this.level.getOrientationQuat(this.level.timeState.currentAttemptTime).toMatrix());

		if (this.base != null) {
			var baseDir = this.computeAimDirection(yawRad, 0);
			var baseMat = new Matrix();
			this.buildLookRotation(baseDir, worldUp).toMatrix(baseMat);
			baseMat.setPosition(basePos);
			this.base.setTransform(baseMat);
		}

		var bodyDir = this.computeAimDirection(yawRad, pitchRad);
		var bodyMat = new Matrix();
		this.buildLookRotation(bodyDir, worldUp).toMatrix(bodyMat);
		bodyMat.setPosition(basePos);
		this.setTransform(bodyMat);

		this.lastYaw = yawRad;
		this.lastPitch = pitchRad;
	}

	/** Camera-convention counterpart to `updateAim` - see `computeCameraDirection`'s doc comment.
		`lastYaw`/`lastPitch` are still stored in file/`hide` convention regardless of which of the
		two `updateAim*` methods last ran, so `Marble.enterCannon`'s snap-to-last-aim logic only
		needs one conversion formula either way; the `- Math.PI / 2` here is that same axis-mismatch
		correction applied in reverse (see `Marble.enterCannon`'s doc comment for the forward
		direction of this conversion). */
	public function updateAimFromCamera(cameraYaw:Float, cameraPitch:Float) {
		var basePos = this.baseTransform.getPosition();
		var worldUp = new Vector(0, 0, 1);
		worldUp.transform(this.level.getOrientationQuat(this.level.timeState.currentAttemptTime).toMatrix());

		if (this.base != null) {
			var baseDir = this.computeCameraDirection(cameraYaw, 0);
			var baseMat = new Matrix();
			this.buildLookRotation(baseDir, worldUp).toMatrix(baseMat);
			baseMat.setPosition(basePos);
			this.base.setTransform(baseMat);
		}

		var bodyDir = this.computeCameraDirection(cameraYaw, cameraPitch);
		var bodyMat = new Matrix();
		this.buildLookRotation(bodyDir, worldUp).toMatrix(bodyMat);
		bodyMat.setPosition(basePos);
		this.setTransform(bodyMat);

		this.lastYaw = cameraYaw - Math.PI / 2;
		this.lastPitch = -cameraPitch;
	}

	/** `MarbleWorld.restart` already calls `.reset()` on every `dtsObjects` entry (including this
		one) - overriding the normal hook here means `resetCannons()`'s real-source behavior (reset
		every cannon on mission load AND every restart) falls out for free with no `MarbleWorld.hx`
		changes needed. */
	public override function reset() {
		super.reset();
		this.resetCannon();
	}

	/** Ported from `Cannon::reset`/`clientCmdResetCannons` - called once (lazily, the first time)
		to capture `baseTransform` and resolve/create the base, and every time thereafter (mission
		restart, `MarbleWorld.restart`) to snap the aim back to the authored default `yaw`/`pitch`. */
	function resetCannon() {
		if (this.baseTransform == null) {
			// `getTransform()` (immediate local transform), not `getAbsPos()` - the latter is only
			// refreshed by the scene graph's own sync/render pass, which hasn't necessarily run yet
			// this soon after placement (this runs from `MarbleWorld.restart()`'s initial pass right
			// after mission load), so it can still read stale/default (origin) data. Matches
			// `GameObject.moveOnPath`'s identical `pathInitialTransform = this.getTransform().clone()`
			// - same hazard, same fix, already established elsewhere in this codebase. Safe to treat
			// local == absolute here since a `Cannon` is always a top-level scene object.
			this.baseTransform = this.getTransform().clone();
			resolveOrCreateBase();
		}
		this.updateAim(this.yaw * Math.PI / 180, this.pitch * Math.PI / 180);
	}

	function resolveOrCreateBase() {
		if (!this.useBase)
			return;
		if (this.basename != "") {
			var existing = this.level.namedGameObjects.get(this.basename);
			if (existing != null && (existing is CannonBase)) {
				this.base = cast existing;
				this.base.cannon = this;
				return;
			}
		}
		var base = new CannonBase();
		base.cannon = this;
		this.level.addDtsObject(base, () -> {
			// `this.base` is only assigned once the DTS has actually finished loading - calling
			// `setTransform` on it any earlier (e.g. from `resetCannon`'s `updateAim` call, which
			// runs synchronously right after this function returns) would hit fields `DtsObject.
			// init()` hasn't set up yet. `resetCannon`'s one synchronous `updateAim` call this
			// misses is caught up here instead, using the aim it last computed.
			this.base = base;
			this.updateAim(this.yaw * Math.PI / 180, this.pitch * Math.PI / 180);
		});
	}

	/** Ported from `Explosion::explode`/`Explosion::onAdd` (`game/fx/explosion.cc`) - each of
		`CannonExplosion`'s own `emitter[0]/emitter[1]` (spawned at the exact explosion center) is
		mirrored by its two `subExplosion[0]/[1]` entries (`CannonSubExplosion1`/`2`), which are
		themselves `ExplosionData`s with the *same* `emitter[0]/emitter[1]` pair (`CannonSmokeEmitter`/
		`CannonSparkEmitter`) but their own `offset = 1.0` - `Explosion::onAdd`'s offset handling
		nudges a sub-explosion to a random point within 1 unit of center (`randVec.set(rand(-1,1),
		rand(0,1), rand(-1,1)).normalize() * offset`, then rotated into the parent explosion's normal
		frame - simplified here to a plain world-space offset since a cannon's explosion normal is
		always world-up, making that rotation a near no-op). Net effect: three overlapping
		smoke+spark bursts (one dead-center, two scattered nearby) instead of one, matching the
		fuller-looking real effect. */
	function spawnExplosionBurst(pos:Vector) {
		this.level.particleManager.createEmitter(cannonSmokeOptions, this.smokeData, pos);
		this.level.particleManager.createEmitter(cannonSparkOptions, this.sparkData, pos);
	}

	/** Ported from `Cannon::explode` - plays the launch/explode sound (a louder, distinct one for
		`force >= 200`) and briefly disables collision so the marble can't immediately re-trigger
		entry while still overlapping the barrel right after firing (`setDamageState("Destroyed")`
		.. `schedule(1000, "setDamageState", "Enabled")`, converted to a plain elapsed-time check
		per [No Schedules](feedback_no_schedules.md) - see `update()`). Also spawns the
		`CannonExplosion` particle bursts (see `spawnExplosionBurst`'s doc comment) - real source
		gets these for free from Torque's native "shape entered Destroyed damage state" explosion
		system, which has no equivalent here, so they're spawned explicitly instead. */
	public function explode(timeState:TimeState) {
		var pos = this.getAbsPos().getPosition();
		if (this.force >= 200) {
			if (this.explodeForceSound != null)
				AudioManager.playSound(this.explodeForceSound, pos);
		} else {
			if (this.explodeSound != null)
				AudioManager.playSound(this.explodeSound, pos);
		}
		this.spawnExplosionBurst(pos);
		for (i in 0...2) {
			var randVec = new Vector(Math.random() * 2 - 1, Math.random(), Math.random() * 2 - 1);
			if (randVec.lengthSq() > 0.0001)
				randVec.normalize();
			this.spawnExplosionBurst(pos.add(randVec));
		}
		// `CannonExplosion`'s third emitter - the radius-distributed "volume particles" (see
		// `cannonVolumeOptions`'s doc comment). Reuses `smokeData` (same "smoke" texture the point-
		// emission bursts already loaded) rather than a separate `ParticleData` - blending is a
		// per-emitter `ParticleOptions` setting, not tied to the shared `ParticleData`/texture.
		this.level.particleManager.createEmitter(cannonVolumeOptions, this.smokeData, pos);
		this.isCollideable = false;
		this.explodeReenableTime = timeState.currentAttemptTime + 1;
	}
}
