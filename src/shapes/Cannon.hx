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
import src.Util;
import src.ParticleSystem.ParticleData;
import src.ParticleSystem.ParticleEmitterOptions;
import collision.CollisionInfo;
import mis.MissionElement.MissionElementStaticShape;

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

class Cannon extends DtsObject {
	public var useCharge:Bool;
	public var chargeTime:Float; // seconds
	public var force:Float;

	// Degrees
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

	public var showReticle:Bool;
	public var showAim:Bool;
	public var aimSize:Float;

	public var base:CannonBase = null;

	// Original transform
	public var baseTransform:Matrix = null;

	var savedScaleX:Float = 1;

	var savedScaleY:Float = 1;
	var savedScaleZ:Float = 1;

	// The base's scale
	var savedBaseScaleX:Float = 1;

	var savedBaseScaleY:Float = 1;
	var savedBaseScaleZ:Float = 1;

	public var lastYaw:Float = 0;
	public var lastPitch:Float = 0;

	var explodeSound:hxd.res.Sound;
	var explodeForceSound:hxd.res.Sound;
	var smokeData:ParticleData;
	var sparkData:ParticleData;

	var aimGraphics:h3d.scene.Graphics;

	var aimPositions:Array<Vector>;

	var aimDirs:Array<Vector>;

	var lastAimAppliedYaw:Float = 1e8;

	var lastAimAppliedPitch:Float = 1e8;
	var lastAimAppliedForceFraction:Float = 1e8;

	static inline var AIM_STEP_COUNT = 125;

	var aimVisualizationValid:Bool = false;

	var explodeReenableTime:Float = -1e8;

	public function new(element:MissionElementStaticShape, presetForce:Float = -1) {
		super();
		this.dtsPath = "data/shapes_pq/gameplay/cannon/cannon.dts";
		this.identifier = "Cannon";
		this.isCollideable = true;

		var fields = element.fields;
		function getStr(name:String, def:String):String {
			var f = fields.get(name);
			return f != null && f[0] != "" ? f[0].toLowerCase() : def;
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

		this.skinOverride = this.instant ? "orange" : switch (element.datablock.toLowerCase()) {
			case "cannon_low": "green";
			case "cannon_mid": "blue";
			case "cannon_high": "red";
			default: "white";
		}
		this.identifier += this.skinOverride;
	}

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

	inline function computeAimDirection(yawRad:Float, pitchRad:Float):Vector {
		var dir = new Vector(-Math.cos(pitchRad) * Math.sin(yawRad), Math.cos(pitchRad) * Math.cos(yawRad), Math.sin(pitchRad));
		var orientationQuat = this.level.getOrientationQuat(this.level.timeState.currentAttemptTime);
		// if (!this.level.marble.currentUp.equals(new Vector(0, 0, -1)))
		// 	dir.transform(orientationQuat.toMatrix());
		return dir;
	}

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

	public inline function computeFireDirection(yawRad:Float, pitchRad:Float):Vector {
		return this.computeAimDirection(yawRad, pitchRad);
	}

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

	public inline function computeFireDirectionFromCamera(cameraYaw:Float, cameraPitch:Float):Vector {
		return this.computeCameraDirection(cameraYaw, cameraPitch);
	}

	public function updateAim(yawRad:Float, pitchRad:Float) {
		var basePos = this.baseTransform.getPosition();
		var worldUp = new Vector(0, 0, 1);
		worldUp.transform(this.level.getOrientationQuat(this.level.timeState.currentAttemptTime).toMatrix());

		if (this.base != null) {
			var baseDir = this.computeAimDirection(yawRad, 0);
			var baseMat = new Matrix();
			this.buildLookRotation(baseDir, worldUp).toMatrix(baseMat);
			baseMat.scale(this.savedBaseScaleX, this.savedBaseScaleY, this.savedBaseScaleZ);
			baseMat.setPosition(basePos);
			this.base.setTransform(baseMat);
		}

		var bodyDir = this.computeAimDirection(yawRad, pitchRad);
		var bodyMat = new Matrix();
		this.buildLookRotation(bodyDir, worldUp).toMatrix(bodyMat);
		bodyMat.scale(this.savedScaleX, this.savedScaleY, this.savedScaleZ);
		bodyMat.setPosition(basePos);
		this.setTransform(bodyMat);

		this.lastYaw = yawRad;
		this.lastPitch = pitchRad;
	}

	public function updateAimFromCamera(cameraYaw:Float, cameraPitch:Float) {
		var basePos = this.baseTransform.getPosition();
		var worldUp = new Vector(0, 0, 1);
		worldUp.transform(this.level.getOrientationQuat(this.level.timeState.currentAttemptTime).toMatrix());

		if (this.base != null) {
			var baseDir = this.computeCameraDirection(cameraYaw, 0);
			var baseMat = new Matrix();
			this.buildLookRotation(baseDir, worldUp).toMatrix(baseMat);
			baseMat.scale(this.savedBaseScaleX, this.savedBaseScaleY, this.savedBaseScaleZ);
			baseMat.setPosition(basePos);
			this.base.setTransform(baseMat);
		}

		var bodyDir = this.computeCameraDirection(cameraYaw, cameraPitch);
		var bodyMat = new Matrix();
		this.buildLookRotation(bodyDir, worldUp).toMatrix(bodyMat);
		bodyMat.scale(this.savedScaleX, this.savedScaleY, this.savedScaleZ);
		bodyMat.setPosition(basePos);
		this.setTransform(bodyMat);

		this.lastYaw = cameraYaw - Math.PI / 2;
		this.lastPitch = -cameraPitch;
	}

	public override function reset() {
		super.reset();
		this.resetCannon();
	}

	function resetCannon() {
		if (this.baseTransform == null) {
			this.baseTransform = this.getTransform().clone();
			this.savedScaleX = this.scaleX;
			this.savedScaleY = this.scaleY;
			this.savedScaleZ = this.scaleZ;
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
				this.savedBaseScaleX = this.base.scaleX;
				this.savedBaseScaleY = this.base.scaleY;
				this.savedBaseScaleZ = this.base.scaleZ;
				return;
			}
		}
		this.savedBaseScaleX = this.savedScaleX;
		this.savedBaseScaleY = this.savedScaleY;
		this.savedBaseScaleZ = this.savedScaleZ;
		var base = new CannonBase();
		base.cannon = this;
		this.level.addDtsObject(base, () -> {
			this.base = base;
			this.updateAim(this.yaw * Math.PI / 180, this.pitch * Math.PI / 180);
		});
	}

	function spawnExplosionBurst(pos:Vector) {
		this.level.particleManager.createEmitter(cannonSmokeOptions, this.smokeData, pos);
		this.level.particleManager.createEmitter(cannonSparkOptions, this.sparkData, pos);
	}

	function drawAimRing(pos:Vector, normal:Vector, radius:Float, segments:Int) {
		var n = normal.lengthSq() > 0.0001 ? normal.normalized() : new Vector(0, 0, 1);
		var reference = Math.abs(n.dot(new Vector(0, 0, 1))) > 0.999 ? new Vector(1, 0, 0) : new Vector(0, 0, 1);
		var axisX = n.cross(reference).normalized();
		var axisY = axisX.cross(n).normalized();
		for (i in 0...segments + 1) {
			var theta = i / segments * Math.PI * 2;
			var p = pos.add(axisX.multiply(Math.cos(theta) * radius)).add(axisY.multiply(Math.sin(theta) * radius));
			if (i == 0)
				this.aimGraphics.moveTo(p.x, p.y, p.z);
			else
				this.aimGraphics.lineTo(p.x, p.y, p.z);
		}
	}

	public function hideAimVisualization() {
		if (this.aimGraphics != null)
			this.aimGraphics.clear();
		this.aimVisualizationValid = false;
	}

	public function updateAimVisualization(cameraYaw:Float, cameraPitch:Float, forceFraction:Float) {
		if (!this.showAim || this.aimSize <= 0 || (this.useCharge && forceFraction < 0.25)) {
			this.hideAimVisualization();
			return;
		}

		if (this.aimVisualizationValid
			&& Math.abs(cameraYaw - this.lastAimAppliedYaw) < 0.001
			&& Math.abs(cameraPitch - this.lastAimAppliedPitch) < 0.001
			&& Math.abs(forceFraction - this.lastAimAppliedForceFraction) < 0.005)
			return;
		this.lastAimAppliedYaw = cameraYaw;
		this.lastAimAppliedPitch = cameraPitch;
		this.lastAimAppliedForceFraction = forceFraction;
		this.aimVisualizationValid = true;

		if (this.aimGraphics == null)
			this.aimGraphics = new h3d.scene.Graphics(this.level.scene);
		if (this.aimPositions == null) {
			this.aimPositions = [for (i in 0...AIM_STEP_COUNT) new Vector()];
			this.aimDirs = [for (i in 0...AIM_STEP_COUNT) new Vector()];
		}
		this.aimGraphics.clear();

		var force = this.force * (this.useCharge ? forceFraction : 1);
		var initPos = this.baseTransform.getPosition();
		var vel = this.computeCameraDirection(cameraYaw, cameraPitch).multiply(force);
		var gravity = this.level.marble.currentUp.multiply(-this.level.marble.cannonBeforeGravity);

		var timeStep = Util.clamp(force * 0.001, 0.02, 0.2);
		var hitPos:Vector = null;
		var hitNormal:Vector = null;
		var stepCount = AIM_STEP_COUNT;

		for (i in 0...AIM_STEP_COUNT) {
			var start = initPos.add(vel.multiply(i * timeStep)).add(gravity.multiply(0.5 * Math.pow(i * timeStep, 2)));
			var end = initPos.add(vel.multiply((i + 1) * timeStep)).add(gravity.multiply(0.5 * Math.pow((i + 1) * timeStep, 2)));

			var segVec = end.sub(start);
			var segLen = segVec.length();
			if (segLen > 0.0001) {
				var results = this.level.collisionWorld.rayCast(start, segVec.multiply(1 / segLen), segLen);
				var closest:octree.IOctreeObject.RayIntersectionData = null;
				var closestDist = 1e8;
				for (r in results) {
					var d = start.distance(r.point);
					if (d < closestDist) {
						closestDist = d;
						closest = r;
					}
				}
				if (closest != null) {
					end = closest.point;
					hitPos = closest.point;
					hitNormal = closest.normal;
				}
			}

			this.aimPositions[i].load(end);
			this.aimDirs[i].load(end.sub(start));
			if (hitPos != null) {
				stepCount = i;
				break;
			}
		}

		// 12 rings spread
		var circleCount = 12;
		for (i in 0...circleCount) {
			var index = Std.int(i * stepCount / circleCount);
			if (index >= AIM_STEP_COUNT)
				index = AIM_STEP_COUNT - 1;
			if (index < 0)
				continue;
			var progress = Util.clamp(i / circleCount, 0, 1);
			var color = 0xFF0000 | (Std.int(progress * 255) << 8);
			this.aimGraphics.lineStyle(2, color);
			this.drawAimRing(this.aimPositions[index], this.aimDirs[index], this.aimSize, 20);
		}
		if (hitPos != null) {
			this.aimGraphics.lineStyle(2, 0x00FF00);
			this.drawAimRing(hitPos, hitNormal, this.aimSize, 20);
		}
	}

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
		this.level.particleManager.createEmitter(cannonVolumeOptions, this.smokeData, pos);
		this.isCollideable = false;
		this.explodeReenableTime = timeState.currentAttemptTime + 1;
	}
}
