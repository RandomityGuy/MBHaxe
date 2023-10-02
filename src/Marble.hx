package src;

import collision.CollisionHull;
import dif.Plane;
import shaders.marble.ClassicGlass;
import shaders.marble.ClassicMetal;
import shaders.marble.ClassicMarb3;
import shaders.marble.ClassicMarb2;
import shaders.marble.ClassicGlassPureSphere;
import h3d.mat.MaterialDatabase;
import shaders.MarbleReflection;
import shaders.CubemapRenderer;
import h3d.shader.AlphaMult;
import shaders.DtsTexture;
import collision.gjk.GJK;
import collision.gjk.ConvexHull;
import hxd.snd.effect.Pitch;
import hxd.snd.effect.Spatialization;
import hxd.snd.Channel;
import shapes.TriangleBumper;
import shapes.RoundBumper;
import src.Util;
import src.AudioManager;
import src.Settings;
import h3d.scene.Mesh;
import h3d.col.Bounds;
import collision.CollisionEntity;
import shapes.StartPad;
import src.TimeState;
import src.ParticleSystem.ParticleEmitter;
import src.ParticleSystem.ParticleData;
import src.ParticleSystem.ParticleEmitterOptions;
import src.DtsObject;
import hxd.Cursor;
import shapes.PowerUp;
import src.GameObject;
import src.ForceObject;
import src.MarbleWorld;
import h3d.Quat;
import src.ResourceLoader;
import collision.Collision;
import dif.math.Point3F;
import dif.math.PlaneF;
import collision.CollisionSurface;
import src.PathedInterior;
import collision.SphereCollisionEntity;
import hxd.Key;
import collision.CollisionInfo;
import h3d.Matrix;
import collision.CollisionWorld;
import h3d.col.ObjectCollider;
import h3d.col.Collider.GroupCollider;
import h3d.Vector;
import h3d.mat.Material;
import h3d.prim.Sphere;
import h3d.scene.Object;
import src.MarbleGame;
import src.CameraController;
import src.Resource;
import h3d.mat.Texture;
import collision.CCDCollision.TraceInfo;
import src.ResourceLoaderWorker;
import src.InteriorObject;
import src.Console;
import src.Gamepad;

class Move {
	public var d:Vector;
	public var jump:Bool;
	public var powerup:Bool;

	public function new() {}
}

enum Mode {
	Start;
	Play;
	Finish;
}

final bounceParticleOptions:ParticleEmitterOptions = {
	ejectionPeriod: 80,
	ambientVelocity: new Vector(0, 0, 0.0),
	ejectionVelocity: 3,
	velocityVariance: 0.25,
	emitterLifetime: 250,
	inheritedVelFactor: 0,
	particleOptions: {
		texture: 'particles/star.png',
		blending: Alpha,
		spinSpeed: 90,
		spinRandomMin: -90,
		spinRandomMax: 90,
		lifetime: 500,
		lifetimeVariance: 100,
		dragCoefficient: 1,
		acceleration: -2,
		colors: [new Vector(0.9, 0, 0, 1), new Vector(0.9, 0.9, 0, 1), new Vector(0.9, 0.9, 0, 0)],
		sizes: [0.25, 0.25, 0.25],
		times: [0, 0.75, 1]
	}
};

final trailParticleOptions:ParticleEmitterOptions = {
	ejectionPeriod: 5,
	ejectionVelocity: 0.0,
	velocityVariance: 0.25,
	emitterLifetime: 1e8,
	inheritedVelFactor: 1,
	ambientVelocity: new Vector(),
	particleOptions: {
		texture: 'particles/smoke.png',
		blending: Alpha,
		spinSpeed: 0,
		spinRandomMin: 0,
		spinRandomMax: 0,
		dragCoefficient: 1,
		lifetime: 100,
		lifetimeVariance: 10,
		acceleration: 0,
		colors: [new Vector(1, 1, 0, 0), new Vector(1, 1, 0, 1), new Vector(1, 1, 1, 0)],
		sizes: [0.7, 0.4, 0.1],
		times: [0, 0.15, 1]
	}
};

final blastParticleOptions:ParticleEmitterOptions = {
	ejectionPeriod: 1,
	ambientVelocity: new Vector(0, 0, -0.3),
	ejectionVelocity: 4,
	velocityVariance: 0,
	emitterLifetime: 300,
	inheritedVelFactor: 0,
	particleOptions: {
		texture: 'particles/smoke.png',
		blending: Alpha,
		spinSpeed: 20,
		spinRandomMin: 0,
		spinRandomMax: 0,
		lifetime: 500,
		lifetimeVariance: 100,
		dragCoefficient: 1,
		acceleration: 0,
		colors: [new Vector(0, 1, 1, 0.1), new Vector(0, 1, 1, 0.5), new Vector(0, 1, 1, 0.9)],
		sizes: [0.125, 0.125, 0.125],
		times: [0, 0.4, 1]
	}
}

final blastMaxParticleOptions:ParticleEmitterOptions = {
	ejectionPeriod: 1,
	ambientVelocity: new Vector(0, 0, -0.3),
	ejectionVelocity: 4,
	velocityVariance: 0,
	emitterLifetime: 300,
	inheritedVelFactor: 0,
	particleOptions: {
		texture: 'particles/smoke.png',
		blending: Alpha,
		spinSpeed: 20,
		spinRandomMin: 0,
		spinRandomMax: 0,
		lifetime: 500,
		lifetimeVariance: 100,
		dragCoefficient: 1,
		acceleration: 0,
		colors: [
			new Vector(1, 0.7, 0, 0.1),
			new Vector(1, 0.7, 0, 0.5),
			new Vector(1, 0.7, 0, 0.9)
		],
		sizes: [0.125, 0.125, 0.125],
		times: [0, 0.4, 1]
	}
}

class Marble extends GameObject {
	public var camera:CameraController;
	public var cameraObject:Object;
	public var controllable:Bool = false;

	public var collider:SphereCollisionEntity;

	public var velocity:Vector;
	public var omega:Vector;

	public var level:MarbleWorld;

	public var _radius = 0.2;

	var _prevRadius:Float;

	var _maxRollVelocity:Float = 15;
	var _angularAcceleration:Float = 75;
	var _jumpImpulse = 7.5;
	var _kineticFriction = 0.7;
	var _staticFriction = 1.1;
	var _brakingAcceleration:Float = 30;
	var _gravity:Float = 20;
	var _airAccel:Float = 5;
	var _maxDotSlide = 0.5;
	var _minBounceVel:Float = 0.1;
	var _minBounceSpeed:Float = 3;
	var _minTrailVel:Float = 10;
	var _bounceKineticFriction = 0.2;
	var minVelocityBounceSoft = 2.5;
	var minVelocityBounceHard = 12.0;
	var bounceMinGain = 0.2;

	public var _bounceRestitution = 0.5;

	var _bounceYet:Bool;
	var _bounceSpeed:Float;
	var _bouncePos:Vector;
	var _bounceNormal:Vector;
	var _slipAmount:Float;
	var _contactTime:Float;
	var _totalTime:Float;

	public var _mass:Float = 1;

	public var contacts:Array<CollisionInfo> = [];
	public var bestContact:CollisionInfo;
	public var contactEntities:Array<CollisionEntity> = [];

	var queuedContacts:Array<CollisionInfo> = [];
	var appliedImpulses:Array<{impulse:Vector, contactImpulse:Bool}> = [];

	public var heldPowerup:PowerUp;
	public var lastContactNormal:Vector;

	var forcefield:DtsObject;
	var helicopter:DtsObject;
	var superBounceEnableTime:Float = -1e8;
	var shockAbsorberEnableTime:Float = -1e8;
	var helicopterEnableTime:Float = -1e8;
	var megaMarbleEnableTime:Float = -1e8;

	var teleportEnableTime:Null<Float> = null;
	var teleportDisableTime:Null<Float> = null;
	var bounceEmitDelay:Float = 0;

	var bounceEmitterData:ParticleData;
	var trailEmitterData:ParticleData;
	var blastEmitterData:ParticleData;
	var blastMaxEmitterData:ParticleData;
	var trailEmitterNode:ParticleEmitter;

	var rollSound:Channel;
	var rollMegaSound:Channel;
	var slipSound:Channel;

	var superbounceSound:Channel;
	var shockabsorberSound:Channel;
	var helicopterSound:Channel;
	var playedSounds = [];

	public var mode:Mode = Play;

	public var startPad:StartPad;

	public var prevPos:Vector;

	var cloak:Bool = false;
	var teleporting:Bool = false;
	var isUltra:Bool = false;
	var _firstTick = true;

	public var cubemapRenderer:CubemapRenderer;

	public function new() {
		super();

		this.velocity = new Vector();
		this.omega = new Vector();
		this.camera = new CameraController(cast this);

		this.bounceEmitterData = new ParticleData();
		this.bounceEmitterData.identifier = "MarbleBounceParticle";
		this.bounceEmitterData.texture = ResourceLoader.getResource("data/particles/star.png", ResourceLoader.getTexture, this.textureResources);

		this.trailEmitterData = new ParticleData();
		this.trailEmitterData.identifier = "MarbleTrailParticle";
		this.trailEmitterData.texture = ResourceLoader.getResource("data/particles/smoke.png", ResourceLoader.getTexture, this.textureResources);

		this.blastEmitterData = new ParticleData();
		this.blastEmitterData.identifier = "MarbleBlastParticle";
		this.blastEmitterData.texture = ResourceLoader.getResource("data/particles/smoke.png", ResourceLoader.getTexture, this.textureResources);

		this.blastMaxEmitterData = new ParticleData();
		this.blastMaxEmitterData.identifier = "MarbleBlastMaxParticle";
		this.blastMaxEmitterData.texture = ResourceLoader.getResource("data/particles/smoke.png", ResourceLoader.getTexture, this.textureResources);

		this.rollSound = AudioManager.playSound(ResourceLoader.getResource("data/sound/rolling_hard.wav", ResourceLoader.getAudio, this.soundResources),
			this.getAbsPos().getPosition(), true);
		this.slipSound = AudioManager.playSound(ResourceLoader.getResource("data/sound/sliding.wav", ResourceLoader.getAudio, this.soundResources),
			this.getAbsPos().getPosition(), true);
		this.rollSound.volume = 0;
		this.slipSound.volume = 0;
		this.shockabsorberSound = AudioManager.playSound(ResourceLoader.getResource("data/sound/superbounceactive.wav", ResourceLoader.getAudio,
			this.soundResources), null, true);
		this.shockabsorberSound.pause = true;
		this.superbounceSound = AudioManager.playSound(ResourceLoader.getResource("data/sound/forcefield.wav", ResourceLoader.getAudio, this.soundResources),
			null, true);
		this.superbounceSound.pause = true;
		this.helicopterSound = AudioManager.playSound(ResourceLoader.getResource("data/sound/use_gyrocopter.wav", ResourceLoader.getAudio,
			this.soundResources), null, true);
		this.helicopterSound.pause = true;
	}

	public function init(level:MarbleWorld, onFinish:Void->Void) {
		this.level = level;

		var isUltra = level.mission.game.toLowerCase() == "ultra";

		var marbleDts = new DtsObject();
		Console.log("Marble: " + Settings.optionsSettings.marbleModel + " (" + Settings.optionsSettings.marbleSkin + ")");
		marbleDts.dtsPath = Settings.optionsSettings.marbleModel;
		marbleDts.matNameOverride.set("base.marble", Settings.optionsSettings.marbleSkin + ".marble");
		marbleDts.showSequences = false;
		marbleDts.useInstancing = false;
		marbleDts.init(null, () -> {}); // SYNC
		for (mat in marbleDts.materials) {
			mat.castShadows = true;
			mat.shadows = true;
			mat.receiveShadows = false;
			// mat.mainPass.culling = None;

			if (Settings.optionsSettings.reflectiveMarble) {
				this.cubemapRenderer = new CubemapRenderer(level.scene, level.sky);

				if (Settings.optionsSettings.marbleShader == null
					|| Settings.optionsSettings.marbleShader == "Default"
					|| Settings.optionsSettings.marbleShader == ""
					|| !isUltra) { // Use this shit everywhere except ultra
					mat.mainPass.addShader(new MarbleReflection(this.cubemapRenderer.cubemap));
				} else {
					// Generate tangents for next shaders, only for Ultra
					for (node in marbleDts.graphNodes) {
						for (ch in node.children) {
							var chmesh = cast(ch, Mesh);
							var chpoly = cast(chmesh.primitive, src.Polygon);
							chpoly.addTangents();
						}
					}

					mat.mainPass.removeShader(mat.textureShader);

					if (Settings.optionsSettings.marbleShader == "ClassicGlassPureSphere") {
						var marbleNormal = ResourceLoader.getTexture("data/shapes/balls/pack1/marble01.normal.png").resource;
						var classicGlassShader = new ClassicGlassPureSphere(mat.texture, marbleNormal, this.cubemapRenderer.cubemap, 12,
							new Vector(0.6, 0.6, 0.6, 0.6), this.level.ambient, this.level.dirLight, this.level.dirLightDir, 1);
						mat.mainPass.addShader(classicGlassShader);
					}

					if (Settings.optionsSettings.marbleShader == "ClassicMarb2") {
						var classicMarb2 = new ClassicMarb2(mat.texture, this.cubemapRenderer.cubemap, 12, new Vector(0.6, 0.6, 0.6, 0.6), this.level.ambient,
							this.level.dirLight, this.level.dirLightDir, 1);
						mat.mainPass.addShader(classicMarb2);
					}

					if (Settings.optionsSettings.marbleShader == "ClassicMarb3") {
						var classicMarb3 = new ClassicMarb3(mat.texture, this.cubemapRenderer.cubemap, 12, new Vector(0.6, 0.6, 0.6, 0.6), this.level.ambient,
							this.level.dirLight, this.level.dirLightDir, 1);
						mat.mainPass.addShader(classicMarb3);
					}

					if (Settings.optionsSettings.marbleShader == "ClassicMetal") {
						var marbleNormal = ResourceLoader.getTexture("data/shapes/balls/pack1/marble18.normal.png").resource;
						marbleNormal.wrap = Repeat;
						var classicMetalShader = new ClassicMetal(mat.texture, marbleNormal, this.cubemapRenderer.cubemap, 12, new Vector(0.6, 0.6, 0.6, 0.6),
							this.level.ambient, this.level.dirLight, this.level.dirLightDir, 1);
						mat.mainPass.addShader(classicMetalShader);
					}

					if (Settings.optionsSettings.marbleShader == "ClassicMarbGlass20") {
						var marbleNormal = ResourceLoader.getTexture("data/shapes/balls/pack1/marble20.normal.png").resource;
						marbleNormal.wrap = Repeat;
						var classicGlassShader = new ClassicGlass(mat.texture, marbleNormal, this.cubemapRenderer.cubemap, 12, new Vector(0.6, 0.6, 0.6, 0.6),
							this.level.ambient, this.level.dirLight, this.level.dirLightDir, 1);
						mat.mainPass.addShader(classicGlassShader);
					}

					if (Settings.optionsSettings.marbleShader == "ClassicMarbGlass18") {
						var marbleNormal = ResourceLoader.getTexture("data/shapes/balls/pack1/marble18.normal.png").resource;
						marbleNormal.wrap = Repeat;
						var classicGlassShader = new ClassicGlass(mat.texture, marbleNormal, this.cubemapRenderer.cubemap, 12, new Vector(0.6, 0.6, 0.6, 0.6),
							this.level.ambient, this.level.dirLight, this.level.dirLightDir, 1);
						mat.mainPass.addShader(classicGlassShader);
					}

					var thisprops:Dynamic = mat.getDefaultProps();
					thisprops.light = false; // We will calculate our own lighting
					mat.props = thisprops;
					mat.castShadows = true;
					mat.shadows = true;
					mat.receiveShadows = false;
				}
			}
		}

		// Calculate radius according to marble model (egh)
		var b = marbleDts.getBounds();
		var avgRadius = (b.xSize + b.ySize + b.zSize) / 6;
		if (isUltra) {
			this._radius = 0.3;
			marbleDts.scale(0.3 / avgRadius);
		} else
			this._radius = avgRadius;

		this._prevRadius = this._radius;

		if (isUltra) {
			this.rollMegaSound = AudioManager.playSound(ResourceLoader.getResource("data/sound/mega_roll.wav", ResourceLoader.getAudio, this.soundResources),
				this.getAbsPos().getPosition(), true);
			this.rollMegaSound.volume = 0;
		}

		this.isUltra = isUltra;

		this.collider = new SphereCollisionEntity(cast this);

		this.addChild(marbleDts);

		// var geom = Sphere.defaultUnitSphere();
		// geom.addUVs();
		// var marbleTexture = ResourceLoader.getFileEntry("data/shapes/balls/base.marble.png").toTexture();
		// var marbleMaterial = Material.create(marbleTexture);
		// marbleMaterial.shadows = false;
		// marbleMaterial.castShadows = true;
		// marbleMaterial.mainPass.removeShader(marbleMaterial.textureShader);
		// var dtsShader = new DtsTexture();
		// dtsShader.texture = marbleTexture;
		// dtsShader.currentOpacity = 1;
		// marbleMaterial.mainPass.addShader(dtsShader);
		// var obj = new Mesh(geom, marbleMaterial, this);
		// obj.scale(_radius * 0.1);
		// if (Settings.optionsSettings.reflectiveMarble) {
		// 	this.cubemapRenderer = new CubemapRenderer(level.scene);
		// 	marbleMaterial.mainPass.addShader(new MarbleReflection(this.cubemapRenderer.cubemap));
		// }

		this.forcefield = new DtsObject();
		this.forcefield.dtsPath = "data/shapes/images/glow_bounce.dts";
		this.forcefield.useInstancing = true;
		this.forcefield.identifier = "GlowBounce";
		this.forcefield.showSequences = false;
		this.addChild(this.forcefield);
		this.forcefield.x = 1e8;
		this.forcefield.y = 1e8;
		this.forcefield.z = 1e8;
		this.forcefield.isBoundingBoxCollideable = false;

		this.helicopter = new DtsObject();
		this.helicopter.dtsPath = "data/shapes/images/helicopter.dts";
		this.helicopter.useInstancing = true;
		this.helicopter.identifier = "Helicopter";
		this.helicopter.showSequences = true;
		this.helicopter.isBoundingBoxCollideable = false;
		// this.addChild(this.helicopter);
		this.helicopter.x = 1e8;
		this.helicopter.y = 1e8;
		this.helicopter.z = 1e8;

		var worker = new ResourceLoaderWorker(onFinish);
		worker.addTask(fwd -> level.addDtsObject(this.forcefield, fwd));
		worker.addTask(fwd -> level.addDtsObject(this.helicopter, fwd));
		worker.run();
	}

	function findContacts(collisiomWorld:CollisionWorld, timeState:TimeState) {
		this.contacts = queuedContacts;
		var c = collisiomWorld.sphereIntersection(this.collider, timeState);
		this.contactEntities = c.foundEntities;
		contacts = contacts.concat(c.contacts);
	}

	public function queueCollision(collisionInfo:CollisionInfo) {
		this.queuedContacts.push(collisionInfo);
	}

	public function getMarbleAxis() {
		var motiondir = new Vector(0, -1, 0);
		motiondir.transform(Matrix.R(0, 0, camera.CameraYaw));
		motiondir.transform(level.newOrientationQuat.toMatrix());
		var updir = this.level.currentUp;
		var sidedir = motiondir.cross(updir);

		sidedir.normalize();
		motiondir = updir.cross(sidedir);
		return [sidedir, motiondir, updir];
	}

	function getExternalForces(currentTime:Float, m:Move, dt:Float) {
		if (this.mode == Finish)
			return this.velocity.multiply(-16);
		var gWorkGravityDir = this.level.currentUp.multiply(-1);
		var A = new Vector();
		A = gWorkGravityDir.multiply(this._gravity);
		if (currentTime - this.helicopterEnableTime < 5) {
			A = A.multiply(0.25);
		}
		for (obj in level.forceObjects) {
			var force = cast(obj, ForceObject).getForce(this.getAbsPos().getPosition());
			A = A.add(force.multiply(1 / _mass));
		}
		if (contacts.length != 0 && this.mode != Start) {
			var contactForce = 0.0;
			var contactNormal = new Vector();
			var forceObjectCount = 0;

			var forceObjects = [];

			for (contact in contacts) {
				if (contact.force != 0 && !forceObjects.contains(contact.otherObject)) {
					if (contact.otherObject is RoundBumper) {
						if (!playedSounds.contains("data/sound/bumperding1.wav")) {
							AudioManager.playSound(ResourceLoader.getResource("data/sound/bumperding1.wav", ResourceLoader.getAudio, this.soundResources));
							playedSounds.push("data/sound/bumperding1.wav");
						}
					}
					if (contact.otherObject is TriangleBumper) {
						if (!playedSounds.contains("data/sound/bumper1.wav")) {
							AudioManager.playSound(ResourceLoader.getResource("data/sound/bumper1.wav", ResourceLoader.getAudio, this.soundResources));
							playedSounds.push("data/sound/bumper1.wav");
						}
					}
					forceObjectCount++;
					contactNormal = contactNormal.add(contact.normal);
					contactForce += contact.force;
					forceObjects.push(contact.otherObject);
				}
			}

			if (forceObjectCount != 0) {
				contactNormal.normalize();

				var a = contactForce / this._mass;
				var dot = this.velocity.dot(contactNormal);
				if (a > dot) {
					if (dot > 0)
						a -= dot;

					A = A.add(contactNormal.multiply(a / dt));
				}
			}
		}
		if (contacts.length == 0 && this.mode != Start) {
			var axes = this.getMarbleAxis();
			var sideDir = axes[0];
			var motionDir = axes[1];
			var upDir = axes[2];
			var airAccel = this._airAccel;
			if (currentTime - this.helicopterEnableTime < 5) {
				airAccel *= 2;
			}
			A = A.add(sideDir.multiply(m.d.x).add(motionDir.multiply(m.d.y)).multiply(airAccel));
		}
		return A;
	}

	function computeMoveForces(m:Move, aControl:Vector, desiredOmega:Vector) {
		var currentGravityDir = this.level.currentUp.multiply(-1);
		var R = currentGravityDir.multiply(-this._radius);
		var rollVelocity = this.omega.cross(R);
		var axes = this.getMarbleAxis();
		var sideDir = axes[0];
		var motionDir = axes[1];
		var upDir = axes[2];
		var currentYVelocity = rollVelocity.dot(motionDir);
		var currentXVelocity = rollVelocity.dot(sideDir);
		var mv = m.d;

		// mv = mv.multiply(1.538461565971375);
		// var mvlen = mv.length();
		// if (mvlen > 1) {
		// 	mv = mv.multiply(1 / mvlen);
		// }
		var desiredYVelocity = this._maxRollVelocity * mv.y;
		var desiredXVelocity = this._maxRollVelocity * mv.x;

		if (desiredYVelocity != 0 || desiredXVelocity != 0) {
			if (currentYVelocity > desiredYVelocity && desiredYVelocity > 0) {
				desiredYVelocity = currentYVelocity;
			} else if (currentYVelocity < desiredYVelocity && desiredYVelocity < 0) {
				desiredYVelocity = currentYVelocity;
			}
			if (currentXVelocity > desiredXVelocity && desiredXVelocity > 0) {
				desiredXVelocity = currentXVelocity;
			} else if (currentXVelocity < desiredXVelocity && desiredXVelocity < 0) {
				desiredXVelocity = currentXVelocity;
			}
			var rsq = R.lengthSq();
			var crossP = R.cross(motionDir.multiply(desiredYVelocity).add(sideDir.multiply(desiredXVelocity))).multiply(1 / rsq);
			desiredOmega.set(crossP.x, crossP.y, crossP.z);
			aControl.set(desiredOmega.x - this.omega.x, desiredOmega.y - this.omega.y, desiredOmega.z - this.omega.z);
			var aScalar = aControl.length();
			if (aScalar > this._angularAcceleration) {
				aControl.scale(this._angularAcceleration / aScalar);
			}
			return false;
		}
		return return true;
	}

	function velocityCancel(currentTime:Float, dt:Float, surfaceSlide:Bool, noBounce:Bool, stoppedPaths:Bool, pi:Array<PathedInterior>) {
		var SurfaceDotThreshold = 0.0001;
		var looped = false;
		var itersIn = 0;
		var done:Bool;
		do {
			done = true;
			itersIn++;
			for (i in 0...contacts.length) {
				var sVel = this.velocity.sub(contacts[i].velocity);
				var surfaceDot = contacts[i].normal.dot(sVel);

				if ((!looped && surfaceDot < 0) || surfaceDot < -SurfaceDotThreshold) {
					var velLen = this.velocity.length();
					var surfaceVel = this.contacts[i].normal.multiply(surfaceDot);

					if (!_bounceYet) {
						_bounceYet = true;
						playBoundSound(currentTime, -surfaceDot);
					}

					if (noBounce) {
						this.velocity = this.velocity.sub(surfaceVel);
					} else if (contacts[i].collider != null) {
						var otherMarble:Marble = cast contacts[i].collider.go;

						var ourMass = this._mass;
						var theirMass = otherMarble._mass;

						var bounce = Math.max(this._bounceRestitution, otherMarble._bounceRestitution);

						var dp = this.velocity.multiply(ourMass).sub(otherMarble.velocity.multiply(theirMass));
						var normP = contacts[i].normal.multiply(dp.dot(contacts[i].normal));

						normP = normP.multiply(1 + bounce);

						otherMarble.velocity = otherMarble.velocity.add(normP.multiply(1 / theirMass));
						contacts[i].velocity = otherMarble.velocity;
					} else {
						if (contacts[i].velocity.length() == 0 && !surfaceSlide && surfaceDot > -this._maxDotSlide * velLen) {
							this.velocity = this.velocity.sub(surfaceVel);
							this.velocity.normalize();
							this.velocity = this.velocity.multiply(velLen);
							surfaceSlide = true;
						} else if (surfaceDot >= -this._minBounceVel) {
							this.velocity = this.velocity.sub(surfaceVel);
						} else {
							var restitution = this._bounceRestitution;
							if (currentTime - this.superBounceEnableTime < 5) {
								restitution = 0.9;
							}
							if (currentTime - this.shockAbsorberEnableTime < 5) {
								restitution = 0.01;
							}
							restitution *= contacts[i].restitution;

							var velocityAdd = surfaceVel.multiply(-(1 + restitution));
							var vAtC = sVel.add(this.omega.cross(contacts[i].normal.multiply(-this._radius)));
							var normalVel = -contacts[i].normal.dot(sVel);

							bounceEmitter(sVel.length() * restitution, contacts[i].normal);

							vAtC = vAtC.sub(contacts[i].normal.multiply(contacts[i].normal.dot(sVel)));

							var vAtCMag = vAtC.length();
							if (vAtCMag != 0) {
								var friction = this._bounceKineticFriction * contacts[i].friction;

								var angVMagnitude = friction * 5 * normalVel / (2 * this._radius);
								if (vAtCMag / this._radius < angVMagnitude)
									angVMagnitude = vAtCMag / this._radius;

								var vAtCDir = vAtC.multiply(1 / vAtCMag);

								var deltaOmega = contacts[i].normal.cross(vAtCDir).multiply(angVMagnitude);
								this.omega = this.omega.add(deltaOmega);

								this.velocity = this.velocity.sub(deltaOmega.cross(contacts[i].normal.multiply(_radius)));
							}
							this.velocity = this.velocity.add(velocityAdd);
						}
					}

					done = false;
				}
			}
			looped = true;
			if (itersIn > 6 && !stoppedPaths) {
				stoppedPaths = true;
				if (noBounce)
					done = true;

				for (contact in contacts) {
					contact.velocity.set(0, 0, 0);
				}

				for (interior in pi) {
					interior.setStopped();
				}
			}
		} while (!done && itersIn < 1e4); // Maximum limit pls
			//	if (this.velocity.lengthSq() < 625) {
		var gotOne = false;
		var dir = new Vector(0, 0, 0);
		for (j in 0...contacts.length) {
			var dir2 = dir.add(contacts[j].normal);
			if (dir2.lengthSq() < 0.01) {
				dir2 = dir2.add(contacts[j].normal);
			}
			dir = dir2;
			dir.normalize();
			gotOne = true;
		}
		if (gotOne) {
			dir.normalize();
			var soFar = 0.0;
			for (k in 0...contacts.length) {
				var dist = this._radius - contacts[k].contactDistance;
				var timeToSeparate = 0.1;
				var vel = this.velocity.sub(contacts[k].velocity);
				var outVel = vel.add(dir.multiply(soFar)).dot(contacts[k].normal);
				if (dist > timeToSeparate * outVel) {
					soFar += (dist - outVel * timeToSeparate) / timeToSeparate / contacts[k].normal.dot(dir);
				}
			}
			// if (soFar < -25)
			// 	soFar = -25;
			// if (soFar > 25)
			// 	soFar = 25;
			this.velocity = this.velocity.add(dir.multiply(soFar));
		}
		//	}

		return stoppedPaths;
	}

	function applyContactForces(dt:Float, m:Move, isCentered:Bool, aControl:Vector, desiredOmega:Vector, A:Vector) {
		var a = new Vector();
		this._slipAmount = 0;
		var gWorkGravityDir = this.level.currentUp.multiply(-1);
		var bestSurface = -1;
		var bestNormalForce = 0.0;
		for (i in 0...contacts.length) {
			if (contacts[i].collider == null) {
				contacts[i].normalForce = -contacts[i].normal.dot(A);
				if (contacts[i].normalForce > bestNormalForce) {
					bestNormalForce = contacts[i].normalForce;
					bestSurface = i;
				}
			}
		}
		bestContact = (bestSurface != -1) ? contacts[bestSurface] : null;
		var canJump = bestSurface != -1;
		if (canJump && m.jump) {
			var velDifference = this.velocity.sub(bestContact.velocity);
			var sv = bestContact.normal.dot(velDifference);
			if (sv < 0) {
				sv = 0;
			}
			if (sv < this._jumpImpulse) {
				this.velocity = this.velocity.add(bestContact.normal.multiply((this._jumpImpulse - sv)));
				if (!playedSounds.contains("data/sound/jump.wav")) {
					AudioManager.playSound(ResourceLoader.getResource("data/sound/jump.wav", ResourceLoader.getAudio, this.soundResources));
					playedSounds.push("data/sound/jump.wav");
				}
			}
		}
		for (j in 0...contacts.length) {
			var normalForce2 = -contacts[j].normal.dot(A);
			if (normalForce2 > 0 && contacts[j].normal.dot(this.velocity.sub(contacts[j].velocity)) <= 0.0001) {
				A.set(A.x
					+ contacts[j].normal.x * normalForce2, A.y
					+ contacts[j].normal.y * normalForce2, A.z
					+ contacts[j].normal.z * normalForce2);
			}
		}
		if (bestSurface != -1 && this.mode != Finish) {
			var vAtC = this.velocity.add(this.omega.cross(bestContact.normal.multiply(-this._radius))).sub(bestContact.velocity);
			var vAtCMag = vAtC.length();
			var slipping = false;
			var aFriction = new Vector(0, 0, 0);
			var AFriction = new Vector(0, 0, 0);
			if (vAtCMag != 0) {
				slipping = true;
				var friction = 0.0;
				if (this.mode != Start)
					friction = this._kineticFriction * bestContact.friction;
				var angAMagnitude = 5 * friction * bestNormalForce / (2 * this._radius);
				var AMagnitude = bestNormalForce * friction;
				var totalDeltaV = (angAMagnitude * this._radius + AMagnitude) * dt;
				if (totalDeltaV > vAtCMag) {
					var fraction = vAtCMag / totalDeltaV;
					angAMagnitude *= fraction;
					AMagnitude *= fraction;
					slipping = false;
				}
				var vAtCDir = vAtC.multiply(1 / vAtCMag);
				aFriction = bestContact.normal.multiply(-1).cross(vAtCDir.multiply(-1)).multiply(angAMagnitude);
				AFriction = vAtCDir.multiply(-AMagnitude);
				this._slipAmount = vAtCMag - totalDeltaV;
			}
			if (!slipping) {
				var R = gWorkGravityDir.multiply(-this._radius);
				var aadd = R.cross(A).multiply(1 / R.lengthSq());
				if (isCentered) {
					var nextOmega = this.omega.add(a.multiply(dt));
					aControl = desiredOmega.sub(nextOmega);
					var aScalar = aControl.length();
					if (aScalar > this._brakingAcceleration) {
						aControl = aControl.multiply(this._brakingAcceleration / aScalar);
					}
				}
				var Aadd = aControl.cross(bestContact.normal.multiply(-this._radius)).multiply(-1);
				var aAtCMag = aadd.cross(bestContact.normal.multiply(-this._radius)).add(Aadd).length();
				var friction2 = 0.0;
				if (mode != Start)
					friction2 = this._staticFriction * bestContact.friction;

				if (aAtCMag > friction2 * bestNormalForce) {
					friction2 = 0;
					if (mode != Start)
						friction2 = this._kineticFriction * bestContact.friction;
					Aadd = Aadd.multiply(friction2 * bestNormalForce / aAtCMag);
				}
				A.set(A.x + Aadd.x, A.y + Aadd.y, A.z + Aadd.z);
				a.set(a.x + aadd.x, a.y + aadd.y, a.z + aadd.z);
			}
			A.set(A.x + AFriction.x, A.y + AFriction.y, A.z + AFriction.z);
			a.set(a.x + aFriction.x, a.y + aFriction.y, a.z + aFriction.z);

			lastContactNormal = bestContact.normal;
		}
		a.set(a.x + aControl.x, a.y + aControl.y, a.z + aControl.z);
		if (this.mode == Finish) {
			a.set(); // Zero it out
		}
		return a;
	}

	function bounceEmitter(speed:Float, normal:Vector) {
		if (this.bounceEmitDelay == 0 && this._minBounceSpeed <= speed) {
			this.level.particleManager.createEmitter(bounceParticleOptions, this.bounceEmitterData, this.getAbsPos().getPosition());
			this.bounceEmitDelay = 0.3;
		}
	}

	function trailEmitter() {
		// Trails are bugged
		// var speed = this.velocity.length();
		// if (this._minTrailVel > speed) {
		// 	if (this.trailEmitterNode != null) {
		// 		this.level.particleManager.removeEmitter(this.trailEmitterNode);
		// 		this.trailEmitterNode = null;
		// 	}
		// 	return;
		// }
		// if (this.trailEmitterNode == null)
		// 	this.trailEmitterNode = this.level.particleManager.createEmitter(trailParticleOptions, trailEmitterData, null,
		// 		() -> this.getAbsPos().getPosition());
	}

	function ReportBounce(pos:Vector, normal:Vector, speed:Float) {
		if (this._bounceYet && speed < this._bounceSpeed) {
			return;
		}
		this._bounceYet = true;
		this._bouncePos = pos;
		this._bounceSpeed = speed;
		this._bounceNormal = normal;
	}

	function playBoundSound(time:Float, contactVel:Float) {
		if (minVelocityBounceSoft <= contactVel) {
			var hardBounceSpeed = minVelocityBounceHard;
			var bounceSoundNum = Math.floor(Math.random() * 4);
			var sndList = (time - this.megaMarbleEnableTime < 10) ? [
				"data/sound/mega_bouncehard1.wav",
				"data/sound/mega_bouncehard2.wav",
				"data/sound/mega_bouncehard3.wav",
				"data/sound/mega_bouncehard4.wav"
			] : [
				"data/sound/bouncehard1.wav",
				"data/sound/bouncehard2.wav",
				"data/sound/bouncehard3.wav",
				"data/sound/bouncehard4.wav"
			];

			var snd = ResourceLoader.getResource(sndList[bounceSoundNum], ResourceLoader.getAudio, this.soundResources);
			var gain = bounceMinGain;
			gain = Util.clamp(Math.pow(contactVel / 12, 1.5), 0, 1);

			// if (hardBounceSpeed <= contactVel)
			// 	gain = 1.0;
			// else
			// 	gain = (contactVel - minVelocityBounceSoft) / (hardBounceSpeed - minVelocityBounceSoft) * (1.0 - gain) + gain;

			snd.play(false, Settings.optionsSettings.soundVolume * gain);
		}
	}

	function updateRollSound(time:TimeState, contactPct:Float, slipAmount:Float) {
		var rSpat = rollSound.getEffect(Spatialization);
		rSpat.position = this.getAbsPos().getPosition();

		if (this.rollMegaSound != null) {
			var rmspat = this.rollMegaSound.getEffect(Spatialization);
			rmspat.position = this.getAbsPos().getPosition();
		}

		var sSpat = slipSound.getEffect(Spatialization);
		sSpat.position = this.getAbsPos().getPosition();

		var rollVel = bestContact != null ? this.velocity.sub(bestContact.velocity) : this.velocity;
		var scale = rollVel.length();
		scale /= this._maxRollVelocity;

		var rollVolume = 2 * scale;
		if (rollVolume > 1)
			rollVolume = 1;
		if (contactPct < 0.05)
			rollVolume = rollSound.volume / 5;

		var slipVolume = 0.0;
		if (slipAmount > 1e-4) {
			slipVolume = slipAmount / 5;
			if (slipVolume > 1)
				slipVolume = 1;
			rollVolume = (1 - slipVolume) * rollVolume;
		}

		if (rollVolume < 0)
			rollVolume = 0;
		if (slipVolume < 0)
			slipVolume = 0;

		if (time.currentAttemptTime - this.megaMarbleEnableTime < 10) {
			if (this.rollMegaSound != null) {
				rollMegaSound.volume = rollVolume;
				rollSound.volume = 0;
			}
		} else {
			rollSound.volume = rollVolume;
			if (this.rollMegaSound != null) {
				rollMegaSound.volume = 0;
			}
		}
		slipSound.volume = slipVolume;

		if (rollSound.getEffect(Pitch) == null) {
			rollSound.addEffect(new Pitch());
		}

		if (rollMegaSound != null) {
			if (rollMegaSound.getEffect(Pitch) == null) {
				rollMegaSound.addEffect(new Pitch());
			}
		}

		var pitch = Util.clamp(rollVel.length() / 15, 0, 1) * 0.75 + 0.75;

		// #if js
		// // Apparently audio crashes the whole thing if pitch is less than 0.2
		// if (pitch < 0.2)
		// 	pitch = 0.2;
		// #end
		var rPitch = rollSound.getEffect(Pitch);
		rPitch.value = pitch;

		if (rollMegaSound != null) {
			var rPitch = rollMegaSound.getEffect(Pitch);
			rPitch.value = pitch;
		}
	}

	function testMove(velocity:Vector, position:Vector, deltaT:Float, radius:Float, testPIs:Bool) {
		if (velocity.length() < 0.001) {
			return {
				position: position,
				t: deltaT,
				found: false,
				foundContacts: []
			};
		}
		var searchbox = new Bounds();
		searchbox.addSpherePos(position.x, position.y, position.z, _radius);
		searchbox.addSpherePos(position.x + velocity.x * deltaT, position.y + velocity.y * deltaT, position.z + velocity.z * deltaT, _radius);

		var foundObjs = this.level.collisionWorld.boundingSearch(searchbox);

		var finalT = deltaT;
		var found = false;

		var lastContactPos = new Vector();

		var testTriangles = [];

		var finalContacts = [];

		// for (iter in 0...10) {
		//	var iterationFound = false;
		for (obj in foundObjs) {
			// Its an MP so bruh
			if (!obj.go.isCollideable)
				continue;

			var invMatrix = @:privateAccess obj.invTransform;
			if (obj.go is PathedInterior)
				invMatrix = obj.transform.getInverse();
			var invTform = invMatrix.clone();
			invTform.transpose();
			var localpos = position.clone();
			localpos.transform(invMatrix);

			var relVel = velocity.sub(obj.velocity);
			var relLocalVel = relVel.transformed3x3(invMatrix);

			var invScale = invMatrix.getScale();
			var sphereRadius = new Vector(radius * invScale.x, radius * invScale.y, radius * invScale.z);

			var boundThing = new Bounds();
			boundThing.addSpherePos(localpos.x, localpos.y, localpos.z, radius * 2);
			boundThing.addSpherePos(localpos.x
				+ relLocalVel.x * deltaT * 5, localpos.y
				+ relLocalVel.y * deltaT * 5, localpos.z
				+ relLocalVel.z * deltaT * 5,
				Math.max(Math.max(sphereRadius.x, sphereRadius.y), sphereRadius.z) * 2);

			var currentFinalPos = position.add(relVel.multiply(finalT)); // localpos.add(relLocalVel.multiply(finalT));
			var surfaces = obj.bvh == null ? obj.octree.boundingSearch(boundThing).map(x -> cast x) : obj.bvh.boundingSearch(boundThing);

			for (surf in surfaces) {
				var surface:CollisionSurface = cast surf;

				currentFinalPos = position.add(relVel.multiply(finalT));

				var i = 0;
				while (i < surface.indices.length) {
					var verts = surface.transformTriangle(i, obj.transform, invTform, @:privateAccess obj._transformKey);
					// var v0 = surface.points[surface.indices[i]].transformed(tform);
					// var v = surface.points[surface.indices[i + 1]].transformed(tform);
					// var v2 = surface.points[surface.indices[i + 2]].transformed(tform);
					var v0 = verts.v1;
					var v = verts.v2;
					var v2 = verts.v3;
					// var v0 = surface.points[surface.indices[i]].transformed(obj.transform);
					// var v = surface.points[surface.indices[i + 1]].transformed(obj.transform);
					// var v2 = surface.points[surface.indices[i + 2]].transformed(obj.transform);

					var triangleVerts = [v0, v, v2];

					var surfaceNormal = verts.n; // surface.normals[surface.indices[i]].transformed3x3(obj.transform).normalized();
					if (obj is DtsObject)
						surfaceNormal.multiply(-1);
					var surfaceD = -surfaceNormal.dot(v0);

					// If we're going the wrong direction or not going to touch the plane, ignore...
					if (surfaceNormal.dot(relVel) > -0.001 || surfaceNormal.dot(currentFinalPos) + surfaceD > radius) {
						i += 3;
						continue;
					}

					// var v0T = v0.transformed(obj.transform);
					// var vT = v.transformed(obj.transform);
					// var v2T = v2.transformed(obj.transform);
					// var vN = surfaceNormal.transformed3x3(obj.transform);
					testTriangles.push({
						v: [v0, v, v2],
						n: surfaceNormal,
					});

					// Time until collision with the plane
					var collisionTime = (radius - position.dot(surfaceNormal) - surfaceD) / surfaceNormal.dot(relVel);

					// Are we going to touch the plane during this time step?
					if (collisionTime >= 0.000001 && finalT >= collisionTime) {
						var collisionPoint = position.add(relVel.multiply(collisionTime));
						// var lastPoint = v2;
						// var j = 0;
						// while (j < 3) {
						// 	var testPoint = surface.points[surface.indices[i + j]];
						// 	if (testPoint != lastPoint) {
						// 		var a = surfaceNormal;
						// 		var b = lastPoint.sub(testPoint);
						// 		var planeNorm = b.cross(a);
						// 		var planeD = -planeNorm.dot(testPoint);
						// 		lastPoint = testPoint;
						// 		// if we are on the far side of the edge
						// 		if (planeNorm.dot(collisionPoint) + planeD >= 0.0)
						// 			break;
						// 	}
						// 	j++;
						// }
						// If we're inside the poly, just get the position
						if (Collision.PointInTriangle(collisionPoint, v0, v, v2)) {
							finalT = collisionTime;
							currentFinalPos = position.add(relVel.multiply(finalT));
							found = true;
							// iterationFound = true;
							i += 3;
							// Debug.drawSphere(currentFinalPos, radius);
							continue;
						}
					}
					// We *might* be colliding with an edge

					var lastVert = v2;

					var radSq = radius * radius;
					for (iter in 0...3) {
						var thisVert = triangleVerts[iter];

						var vertDiff = lastVert.sub(thisVert);
						var posDiff = position.sub(thisVert);

						var velRejection = vertDiff.cross(relVel);
						var posRejection = vertDiff.cross(posDiff);

						// Build a quadratic equation to solve for the collision time
						var a = velRejection.lengthSq();
						var b = 2 * posRejection.dot(velRejection);
						var c = (posRejection.lengthSq() - vertDiff.lengthSq() * radSq);

						var discriminant = b * b - (4 * a * c);

						// If it's not quadratic or has no solution, ignore this edge.
						if (a == 0.0 || discriminant < 0.0) {
							lastVert = thisVert;
							continue;
						}

						var oneOverTwoA = 0.5 / a;
						var discriminantSqrt = Math.sqrt(discriminant);

						// Solve using the quadratic formula
						var edgeCollisionTime = (-b + discriminantSqrt) * oneOverTwoA;
						var edgeCollisionTime2 = (-b - discriminantSqrt) * oneOverTwoA;

						// Make sure the 2 times are in ascending order
						if (edgeCollisionTime2 < edgeCollisionTime) {
							var temp = edgeCollisionTime2;
							edgeCollisionTime2 = edgeCollisionTime;
							edgeCollisionTime = temp;
						}

						// If the collision doesn't happen on this time step, ignore this edge.
						if (edgeCollisionTime2 <= 0.0001 || finalT <= edgeCollisionTime) {
							lastVert = thisVert;
							continue;
						}

						// Check if the collision hasn't already happened
						if (edgeCollisionTime >= 0.000001) {
							// if (edgeCollisionTime < 0.000001) {
							// 	edgeCollisionTime = edgeCollisionTime2;
							// }
							// if (edgeCollisionTime < 0.00001)
							// 	continue;
							// if (edgeCollisionTime > finalT)
							// 	continue;

							var edgeLen = vertDiff.length();

							var relativeCollisionPos = position.add(relVel.multiply(edgeCollisionTime)).sub(thisVert);

							var distanceAlongEdge = relativeCollisionPos.dot(vertDiff) / edgeLen;

							// If the collision happens outside the boundaries of the edge, ignore this edge.
							if (-radius > distanceAlongEdge || edgeLen + radius < distanceAlongEdge) {
								lastVert = thisVert;
								continue;
							}

							// If the collision is within the edge, resolve the collision and continue.
							if (distanceAlongEdge >= 0.0 && distanceAlongEdge <= edgeLen) {
								finalT = edgeCollisionTime;
								currentFinalPos = position.add(relVel.multiply(finalT));
								lastContactPos = vertDiff.multiply(distanceAlongEdge / edgeLen).add(thisVert);
								lastVert = thisVert;
								found = true;
								// Debug.drawSphere(currentFinalPos, radius);
								// iterationFound = true;
								continue;
							}
						}

						// This is what happens when we collide with a corner

						a = relVel.lengthSq();

						// Build a quadratic equation to solve for the collision time
						var posVertDiff = position.sub(thisVert);
						b = 2 * posVertDiff.dot(relVel);
						c = posVertDiff.lengthSq() - radSq;
						discriminant = b * b - (4 * a * c);

						// If it's quadratic and has a solution ...
						if (a != 0.0 && discriminant >= 0.0) {
							oneOverTwoA = 0.5 / a;
							discriminantSqrt = Math.sqrt(discriminant);

							// Solve using the quadratic formula
							edgeCollisionTime = (-b + discriminantSqrt) * oneOverTwoA;
							edgeCollisionTime2 = (-b - discriminantSqrt) * oneOverTwoA;

							// Make sure the 2 times are in ascending order
							if (edgeCollisionTime2 < edgeCollisionTime) {
								var temp = edgeCollisionTime2;
								edgeCollisionTime2 = edgeCollisionTime;
								edgeCollisionTime = temp;
							}

							// If the collision doesn't happen on this time step, ignore this corner
							if (edgeCollisionTime2 > 0.0001 && finalT > edgeCollisionTime) {
								// Adjust to make sure very small negative times are counted as zero
								if (edgeCollisionTime <= 0.0 && edgeCollisionTime > -0.0001)
									edgeCollisionTime = 0.0;

								// Check if the collision hasn't already happened
								if (edgeCollisionTime >= 0.000001) {
									// Resolve it and continue
									finalT = edgeCollisionTime;
									currentFinalPos = position.add(relVel.multiply(finalT));
									lastContactPos = thisVert;
									found = true;
									// Debug.drawSphere(currentFinalPos, radius);
									// iterationFound = true;
								}
							}
						}

						// We still need to check the other corner ...
						// Build one last quadratic equation to solve for the collision time
						posVertDiff = position.sub(lastVert);
						b = 2 * posVertDiff.dot(relVel);
						c = posVertDiff.lengthSq() - radSq;
						discriminant = b * b - (4 * a * c);

						// If it's not quadratic or has no solution, then skip this corner
						if (a == 0.0 || discriminant < 0.0) {
							lastVert = thisVert;
							continue;
						}

						oneOverTwoA = 0.5 / a;
						discriminantSqrt = Math.sqrt(discriminant);

						// Solve using the quadratic formula
						edgeCollisionTime = (-b + discriminantSqrt) * oneOverTwoA;
						edgeCollisionTime2 = (-b - discriminantSqrt) * oneOverTwoA;

						// Make sure the 2 times are in ascending order
						if (edgeCollisionTime2 < edgeCollisionTime) {
							var temp = edgeCollisionTime2;
							edgeCollisionTime2 = edgeCollisionTime;
							edgeCollisionTime = temp;
						}

						if (edgeCollisionTime2 <= 0.0001 || finalT <= edgeCollisionTime) {
							lastVert = thisVert;
							continue;
						}

						if (edgeCollisionTime <= 0.0 && edgeCollisionTime > -0.0001)
							edgeCollisionTime = 0;

						if (edgeCollisionTime < 0.000001) {
							lastVert = thisVert;
							continue;
						}

						finalT = edgeCollisionTime;
						currentFinalPos = position.add(relVel.multiply(finalT));
						// Debug.drawSphere(currentFinalPos, radius);

						lastVert = thisVert;
						found = true;
						// iterationFound = true;
					}

					i += 3;
				}
			}
		}

		//	if (!iterationFound)
		//		break;
		// }
		var deltaPosition = velocity.multiply(finalT);
		var finalPosition = position.add(deltaPosition);
		position = finalPosition;

		// for (testTri in testTriangles) {
		// 	var tsi = Collision.TriangleSphereIntersection(testTri.v[0], testTri.v[1], testTri.v[2], testTri.n, finalPosition, radius, testTri.edge,
		// 		testTri.concavity);
		// 	if (tsi.result) {
		// 		var contact = new CollisionInfo();
		// 		contact.point = tsi.point;
		// 		contact.normal = tsi.normal;
		// 		contact.contactDistance = tsi.point.distance(position);
		// 		finalContacts.push(contact);
		// 	}
		// }

		return {
			position: position,
			t: finalT,
			found: found,
			foundContacts: testTriangles
		};
	}

	function nudgeToContacts(position:Vector, radius:Float, foundContacts:Array<{
		v:Array<Vector>,
		n:Vector
	}>) {
		var it = 0;
		var concernedContacts = foundContacts; // PathedInteriors have their own nudge logic
		var prevResolved = 0;
		do {
			var resolved = 0;
			for (testTri in concernedContacts) {
				// Check if we are on wrong side of the triangle
				if (testTri.n.dot(position) - testTri.n.dot(testTri.v[0]) < 0) {
					continue;
				}

				var t1 = testTri.v[1].sub(testTri.v[0]);
				var t2 = testTri.v[2].sub(testTri.v[0]);
				var tarea = Math.abs(t1.cross(t2).length()) / 2.0;

				// Check if our triangle is too small to be collided with
				if (tarea < 0.001) {
					continue;
				}

				// Intersection with plane of testTri and current position
				var t = (testTri.v[0].sub(position)).dot(testTri.n) / testTri.n.lengthSq();
				var intersect = position.add(testTri.n.multiply(t));

				var tsi = Collision.PointInTriangle(intersect, testTri.v[0], testTri.v[1], testTri.v[2]);
				if (tsi) {
					var separatingDistance = position.sub(intersect).normalized();
					var distToContactPlane = intersect.distance(position);
					if (radius - 0.005 - distToContactPlane > 0.0001) {
						// Nudge to the surface of the contact plane
						Debug.drawTriangle(testTri.v[0], testTri.v[1], testTri.v[2]);
						Debug.drawSphere(position, radius);
						position = position.add(separatingDistance.multiply(radius - distToContactPlane - 0.005));
						resolved++;
					}
				}

				// var tsi = Collision.TriangleSphereIntersection(testTri.v[0], testTri.v[1], testTri.v[2], testTri.n, position, radius, testTri.edge,
				// 	testTri.concavity);
				// if (tsi.result) {
				// 	var separatingDistance = position.sub(tsi.point).normalized();
				// 	var distToContactPlane = tsi.point.distance(position);
				// 	if (radius - 0.005 - distToContactPlane > 0.0001) {
				// 		// Nudge to the surface of the contact plane
				// 		Debug.drawTriangle(testTri.v[0], testTri.v[1], testTri.v[2]);
				// 		Debug.drawSphere(position, radius);
				// 		position = position.add(separatingDistance.multiply(radius - distToContactPlane - 0.005));
				// 		resolved++;
				// 	}
				// }

				// var distToContactPlane = position.dot(contact.normal) - contact.point.dot(contact.normal);
			}
			if (resolved == 0 && prevResolved == 0)
				break;
			prevResolved = resolved;
			it++;
		} while (true && it < 10);
		return position;
	}

	function advancePhysics(timeState:TimeState, m:Move, collisionWorld:CollisionWorld, pathedInteriors:Array<PathedInterior>) {
		var timeRemaining = timeState.dt;
		var startTime = timeRemaining;
		var it = 0;

		var piTime = timeRemaining;

		_bounceYet = false;

		var contactTime = 0.0;
		var it = 0;

		var passedTime = timeState.currentAttemptTime;

		var oldPos = this.getAbsPos().getPosition().clone();

		if (this.controllable) {
			for (interior in pathedInteriors) {
				// interior.pushTickState();
				interior.computeNextPathStep(timeRemaining);
			}
		}

		do {
			if (timeRemaining <= 0)
				break;

			var timeStep = 0.004;
			if (timeRemaining < timeStep)
				timeStep = timeRemaining;

			passedTime += timeStep;

			var stoppedPaths = false;
			var tempState = timeState.clone();

			tempState.dt = timeStep;

			it++;

			this.findContacts(collisionWorld, tempState);

			if (this._firstTick) {
				contacts = [];
				this._firstTick = false;
			}

			var aControl = new Vector();
			var desiredOmega = new Vector();
			var isCentered = this.computeMoveForces(m, aControl, desiredOmega);

			stoppedPaths = this.velocityCancel(timeState.currentAttemptTime, timeStep, isCentered, false, stoppedPaths, pathedInteriors);
			var A = this.getExternalForces(timeState.currentAttemptTime, m, timeStep);
			var a = this.applyContactForces(timeStep, m, isCentered, aControl, desiredOmega, A);
			this.velocity.set(this.velocity.x + A.x * timeStep, this.velocity.y + A.y * timeStep, this.velocity.z + A.z * timeStep);
			this.omega.set(this.omega.x + a.x * timeStep, this.omega.y + a.y * timeStep, this.omega.z + a.z * timeStep);
			if (this.mode == Start) {
				// Bruh...
				this.velocity.y = 0;
				this.velocity.x = 0;
			}
			stoppedPaths = this.velocityCancel(timeState.currentAttemptTime, timeStep, isCentered, true, stoppedPaths, pathedInteriors);
			this._totalTime += timeStep;
			if (contacts.length != 0) {
				this._contactTime += timeStep;
			}

			for (impulse in appliedImpulses) {
				this.velocity = this.velocity.add(impulse.impulse);
				if (m.jump && impulse.contactImpulse) {
					this.velocity = this.velocity.add(impulse.impulse.normalized().multiply(this._jumpImpulse));
				}
			}
			appliedImpulses = [];

			velocity.w = 0;

			var pos = this.getAbsPos().getPosition();
			this.prevPos = pos.clone();

			var tdiff = timeStep;

			var finalPosData = testMove(velocity, pos, timeStep, _radius, true); // this.getIntersectionTime(timeStep, velocity);
			if (finalPosData.found) {
				var diff = timeStep - finalPosData.t;
				this.velocity = this.velocity.sub(A.multiply(diff));
				this.omega = this.omega.sub(a.multiply(diff));
				// if (finalPosData.t > 0.00001)
				timeStep = finalPosData.t;
				tdiff = diff;
			}
			var expectedPos = finalPosData.position;
			// var newPos = expectedPos;
			var newPos = nudgeToContacts(expectedPos, _radius, finalPosData.foundContacts);

			if (this.velocity.lengthSq() > 1e-8) {
				var posDiff = newPos.sub(expectedPos);
				if (posDiff.lengthSq() > 1e-8) {
					var velDiffProj = this.velocity.multiply(posDiff.dot(this.velocity) / (this.velocity.lengthSq()));
					var expectedProjPos = expectedPos.add(velDiffProj);
					var updatedTimestep = expectedProjPos.sub(pos).length() / velocity.length();

					var tDiff = updatedTimestep - timeStep;
					if (tDiff > 0) {
						this.velocity = this.velocity.sub(A.multiply(tDiff));
						this.omega = this.omega.sub(a.multiply(tDiff));

						timeStep = updatedTimestep;
					}
				}
			}

			// var intersectT = intersectData.t;
			// if (intersectData.found && intersectT > 0.001) {
			// 	var diff = timeStep - intersectT;
			// 	this.velocity = this.velocity.sub(A.multiply(diff));
			// 	this.omega = this.omega.sub(a.multiply(diff));
			// 	// var mo = new h3d.prim.Sphere();
			// 	// mo.addNormals();
			// 	// mo.scale(_radius);
			// 	// var mCol = new h3d.scene.Mesh(mo);
			// 	// mCol.setPosition(intersectData.position.x, intersectData.position.y, intersectData.position.z);
			// 	// this.level.scene.addChild(mCol);
			// 	timeStep = intersectT;
			// }

			// var posAdd = this.velocity.multiply(timeStep);
			// var expectedPos = pos.add(posAdd);
			// var newPos = nudgeToContacts(expectedPos, _radius);

			// if (mode == Start) {
			// 	var upVec = this.level.currentUp;
			// 	var startpadNormal = startPad.getAbsPos().up();
			// 	this.velocity = upVec.multiply(this.velocity.dot(upVec));
			// 	// Apply contact forces in startPad up direction if upVec is not startpad up, fixes the weird startpad shit in pinball wizard
			// 	if (upVec.dot(startpadNormal) < 0.95) {
			// 		for (contact in contacts) {
			// 			var normF = contact.normal.multiply(contact.normalForce);
			// 			var startpadF = startpadNormal.multiply(normF.dot(startpadNormal));
			// 			var upF = upVec.multiply(normF.dot(upVec));
			// 			this.velocity = this.velocity.add(startpadF.multiply(timeStep / 4));
			// 		}
			// 	}
			// }

			// if (mode == Finish) {
			// 	this.velocity = this.velocity.multiply(0.925);
			// }

			var rot = this.getRotationQuat();
			var quat = new Quat();
			quat.initRotation(omega.x * timeStep, omega.y * timeStep, omega.z * timeStep);
			quat.multiply(quat, rot);
			this.setRotationQuat(quat);

			var totMatrix = quat.toMatrix();
			newPos.w = 1; // Fix shit blowing up
			totMatrix.setPosition(newPos);

			this.setPosition(newPos.x, newPos.y, newPos.z);

			this.collider.setTransform(totMatrix);
			this.collider.velocity = this.velocity;

			if (this.heldPowerup != null && m.powerup && !this.level.outOfBounds) {
				var pTime = timeState.clone();
				pTime.dt = timeStep;
				pTime.currentAttemptTime = passedTime;
				this.heldPowerup.use(pTime);
				this.heldPowerup = null;
				if (this.level.isRecording) {
					this.level.replay.recordPowerupPickup(null);
				}
			}

			if (contacts.length != 0)
				contactTime += timeStep;

			timeRemaining -= timeStep;

			if (this.controllable) {
				for (interior in pathedInteriors) {
					interior.advance(timeStep);
				}
			}

			piTime += timeStep;

			if (tdiff == 0 || it > 10)
				break;
		} while (true);
		if (timeRemaining > 0) {
			// Advance pls
			if (this.controllable) {
				for (interior in pathedInteriors) {
					interior.advance(timeRemaining);
				}
			}
		}
		this.queuedContacts = [];

		var newPos = this.getAbsPos().getPosition().clone();

		if (this.controllable && this.prevPos != null) {
			var tempTimeState = timeState.clone();
			tempTimeState.currentAttemptTime = passedTime;
			this.level.callCollisionHandlers(cast this, tempTimeState, oldPos, newPos);
		}

		this.updateRollSound(timeState, contactTime / timeState.dt, this._slipAmount);
	}

	public function update(timeState:TimeState, collisionWorld:CollisionWorld, pathedInteriors:Array<PathedInterior>) {
		var move = new Move();
		move.d = new Vector();
		if (this.controllable && this.mode != Finish && !MarbleGame.instance.paused && !this.level.isWatching) {
			move.d.x = Gamepad.getAxis(Settings.gamepadSettings.moveYAxis);
			move.d.y = -Gamepad.getAxis(Settings.gamepadSettings.moveXAxis);
			if (Key.isDown(Settings.controlsSettings.forward)) {
				move.d.x -= 1;
			}
			if (Key.isDown(Settings.controlsSettings.backward)) {
				move.d.x += 1;
			}
			if (Key.isDown(Settings.controlsSettings.left)) {
				move.d.y += 1;
			}
			if (Key.isDown(Settings.controlsSettings.right)) {
				move.d.y -= 1;
			}
			if (Key.isDown(Settings.controlsSettings.jump)
				|| MarbleGame.instance.touchInput.jumpButton.pressed
				|| Gamepad.isDown(Settings.gamepadSettings.jump)) {
				move.jump = true;
			}
			if ((!Util.isTouchDevice() && Key.isDown(Settings.controlsSettings.powerup))
				|| (Util.isTouchDevice() && MarbleGame.instance.touchInput.powerupButton.pressed)
				|| Gamepad.isDown(Settings.gamepadSettings.powerup)) {
				move.powerup = true;
			}
			if (MarbleGame.instance.touchInput.movementInput.pressed) {
				move.d.y = -MarbleGame.instance.touchInput.movementInput.value.x;
				move.d.x = MarbleGame.instance.touchInput.movementInput.value.y;
			}
		}

		if (this.level.isWatching) {
			if (this.level.replay.currentPlaybackFrame.marbleStateFlags.has(Jumped))
				move.jump = true;
			if (this.level.replay.currentPlaybackFrame.marbleStateFlags.has(UsedPowerup))
				move.powerup = true;
			move.d = new Vector(this.level.replay.currentPlaybackFrame.marbleX, this.level.replay.currentPlaybackFrame.marbleY, 0);
		} else {
			if (this.level.isRecording) {
				this.level.replay.recordMarbleStateFlags(move.jump, move.powerup, false, false);
				this.level.replay.recordMarbleInput(move.d.x, move.d.y);
			}
		}

		playedSounds = [];
		advancePhysics(timeState, move, collisionWorld, pathedInteriors);

		if (!this.level.isWatching) {
			if (this.level.isRecording) {
				this.level.replay.recordMarbleState(this.getAbsPos().getPosition(), this.velocity, this.getRotationQuat(), this.omega);
			}
		} else {
			var expectedPos = this.level.replay.currentPlaybackFrame.marblePosition.clone();
			var expectedVel = this.level.replay.currentPlaybackFrame.marbleVelocity.clone();
			var expectedOmega = this.level.replay.currentPlaybackFrame.marbleAngularVelocity.clone();

			this.setPosition(expectedPos.x, expectedPos.y, expectedPos.z);
			var tform = this.level.replay.currentPlaybackFrame.marbleOrientation.toMatrix();

			tform.setPosition(new Vector(expectedPos.x, expectedPos.y, expectedPos.z));
			this.collider.setTransform(tform);
			this.velocity = expectedVel;
			this.setRotationQuat(this.level.replay.currentPlaybackFrame.marbleOrientation.clone());
			this.omega = expectedOmega;
		}

		if (this.controllable && !this.level.rewinding) {
			this.camera.update(timeState.currentAttemptTime, timeState.dt);
		}

		updatePowerupStates(timeState.currentAttemptTime, timeState.dt);

		if (this._radius != 0.6666 && timeState.currentAttemptTime - this.megaMarbleEnableTime < 10) {
			this._prevRadius = this._radius;
			this._radius = 0.6666;
			this.collider.radius = 0.6666;
			var marbledts = cast(this.getChildAt(0), DtsObject);
			marbledts.scale(this._radius / this._prevRadius);
		} else if (timeState.currentAttemptTime - this.megaMarbleEnableTime > 10) {
			if (this._radius != this._prevRadius) {
				this._radius = this._prevRadius;
				this.collider.radius = this._radius;
				var marbledts = cast(this.getChildAt(0), DtsObject);
				marbledts.scale(this._prevRadius / 0.6666);
			}
		}

		this.updateTeleporterState(timeState);

		this.trailEmitter();
		if (bounceEmitDelay > 0)
			bounceEmitDelay -= timeState.dt;
		if (bounceEmitDelay < 0)
			bounceEmitDelay = 0;

		// this.camera.target.load(this.getAbsPos().getPosition().toPoint());
	}

	public function updatePowerupStates(currentTime:Float, dt:Float) {
		if (currentTime - this.shockAbsorberEnableTime < 5) {
			this.shockabsorberSound.pause = false;
		} else {
			this.shockabsorberSound.pause = true;
		}
		if (currentTime - this.superBounceEnableTime < 5) {
			this.superbounceSound.pause = false;
		} else {
			this.superbounceSound.pause = true;
		}

		if (currentTime - this.shockAbsorberEnableTime < 5) {
			this.forcefield.setPosition(0, 0, 0);
		} else if (currentTime - this.superBounceEnableTime < 5) {
			this.forcefield.setPosition(0, 0, 0);
		} else {
			this.forcefield.x = 1e8;
			this.forcefield.y = 1e8;
			this.forcefield.z = 1e8;
		}
		if (currentTime - this.helicopterEnableTime < 5) {
			this.helicopter.setPosition(x, y, z);
			this.helicopter.setRotationQuat(this.level.getOrientationQuat(currentTime));
			this.helicopterSound.pause = false;
		} else {
			this.helicopter.setPosition(1e8, 1e8, 1e8);
			this.helicopterSound.pause = true;
		}
	}

	public function useBlast() {
		if (this.level.blastAmount < 0.2 || this.level.game != "ultra")
			return;
		var impulse = this.level.currentUp.multiply(Math.max(Math.sqrt(this.level.blastAmount), this.level.blastAmount) * 10);
		this.applyImpulse(impulse);
		AudioManager.playSound(ResourceLoader.getResource('data/sound/blast.wav', ResourceLoader.getAudio, this.soundResources));
		this.level.particleManager.createEmitter(this.level.blastAmount > 1 ? blastMaxParticleOptions : blastParticleOptions,
			this.level.blastAmount > 1 ? blastMaxEmitterData : blastEmitterData, this.getAbsPos().getPosition(), () -> {
				this.getAbsPos().getPosition().add(this.level.currentUp.multiply(-this._radius * 0.4));
			},
			new Vector(1, 1,
				1).add(new Vector(Math.abs(this.level.currentUp.x), Math.abs(this.level.currentUp.y), Math.abs(this.level.currentUp.z)).multiply(-0.8)));
		this.level.blastAmount = 0;
	}

	public function applyImpulse(impulse:Vector, contactImpulse:Bool = false) {
		this.appliedImpulses.push({impulse: impulse, contactImpulse: contactImpulse});
	}

	public function enableSuperBounce(time:Float) {
		this.superBounceEnableTime = time;
	}

	public function enableShockAbsorber(time:Float) {
		this.shockAbsorberEnableTime = time;
	}

	public function enableHelicopter(time:Float) {
		this.helicopterEnableTime = time;
	}

	public function enableMegaMarble(time:Float) {
		this.megaMarbleEnableTime = time;
	}

	function updateTeleporterState(time:TimeState) {
		var teleportFadeCompletion:Float = 0;

		if (this.teleportEnableTime != null)
			teleportFadeCompletion = Util.clamp((time.currentAttemptTime - this.teleportEnableTime) / 0.5, 0, 1);
		if (this.teleportDisableTime != null)
			teleportFadeCompletion = Util.clamp(1 - (time.currentAttemptTime - this.teleportDisableTime) / 0.5, 0, 1);

		if (teleportFadeCompletion > 0) {
			var ourDts:DtsObject = cast this.children[0];
			ourDts.setOpacity(Util.lerp(1, 0.25, teleportFadeCompletion));
			this.teleporting = true;
		} else {
			if (this.teleporting) {
				var ourDts:DtsObject = cast this.children[0];
				ourDts.setOpacity(1);
				this.teleporting = false;
			}
		}
	}

	public function setCloaking(active:Bool, time:TimeState) {
		this.cloak = active;
		if (this.cloak) {
			var completion = (this.teleportDisableTime != null) ? Util.clamp((time.currentAttemptTime - this.teleportDisableTime) / 0.5, 0, 1) : 1;
			this.teleportEnableTime = time.currentAttemptTime - 0.5 * (1 - completion);
			this.teleportDisableTime = null;
		} else {
			var completion = Util.clamp((time.currentAttemptTime - this.teleportEnableTime) / 0.5, 0, 1);
			this.teleportDisableTime = time.currentAttemptTime - 0.5 * (1 - completion);
			this.teleportEnableTime = null;
		}
	}

	public override function reset() {
		this.velocity = new Vector();
		this.collider.velocity = new Vector();
		this.omega = new Vector();
		this.superBounceEnableTime = Math.NEGATIVE_INFINITY;
		this.shockAbsorberEnableTime = Math.NEGATIVE_INFINITY;
		this.helicopterEnableTime = Math.NEGATIVE_INFINITY;
		this.megaMarbleEnableTime = Math.NEGATIVE_INFINITY;
		this.lastContactNormal = new Vector(0, 0, 1);
		this.contactEntities = [];
		this.cloak = false;
		this._firstTick = true;
		if (this.teleporting) {
			var ourDts:DtsObject = cast this.children[0];
			ourDts.setOpacity(1);
		}
		this.teleporting = false;
		this.teleportDisableTime = null;
		this.teleportEnableTime = null;
		if (this._radius != this._prevRadius) {
			this._radius = this._prevRadius;
			this.collider.radius = this._radius;
			var marbledts = cast(this.getChildAt(0), DtsObject);
			marbledts.scale(this._prevRadius / 0.6666);
		}
	}

	public override function dispose() {
		super.dispose();
		removeChildren();
		camera = null;
		collider = null;
	}
}
