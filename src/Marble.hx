package src;

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
		sizes: [0.4, 0.4, 0.1],
		times: [0, 0.15, 1]
	}
};

class Marble extends GameObject {
	public var camera:CameraController;
	public var cameraObject:Object;
	public var controllable:Bool = false;

	public var collider:SphereCollisionEntity;

	public var velocity:Vector;
	public var omega:Vector;

	public var level:MarbleWorld;

	public var _radius = 0.2;

	var _maxRollVelocity = 15;
	var _angularAcceleration = 75;
	var _jumpImpulse = 7.5;
	var _kineticFriction = 0.7;
	var _staticFriction = 1.1;
	var _brakingAcceleration = 30;
	var _gravity = 20;
	var _airAccel:Float = 5;
	var _maxDotSlide = 0.5;
	var _minBounceVel = 3;
	var _minTrailVel = 10;
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
	var appliedImpulses:Array<Vector> = [];

	public var heldPowerup:PowerUp;
	public var lastContactNormal:Vector;

	var forcefield:DtsObject;
	var helicopter:DtsObject;
	var superBounceEnableTime:Float = -1e8;
	var shockAbsorberEnableTime:Float = -1e8;
	var helicopterEnableTime:Float = -1e8;

	var bounceEmitDelay:Float = 0;

	var bounceEmitterData:ParticleData;
	var trailEmitterData:ParticleData;
	var trailEmitterNode:ParticleEmitter;

	var rollSound:Channel;
	var slipSound:Channel;

	var superbounceSound:Channel;
	var shockabsorberSound:Channel;
	var helicopterSound:Channel;
	var playedSounds = [];

	public var mode:Mode = Play;

	public var startPad:StartPad;

	public var prevPos:Vector;

	public function new() {
		super();
		var geom = Sphere.defaultUnitSphere();
		geom.addUVs();
		var marbleTexture = ResourceLoader.getFileEntry("data/shapes/balls/base.marble.png").toTexture();
		var marbleMaterial = Material.create(marbleTexture);
		marbleMaterial.shadows = false;
		marbleMaterial.castShadows = true;
		var obj = new Mesh(geom, marbleMaterial, this);
		obj.scale(_radius);

		this.velocity = new Vector();
		this.omega = new Vector();
		this.camera = new CameraController(cast this);

		this.collider = new SphereCollisionEntity(cast this);

		this.bounceEmitterData = new ParticleData();
		this.bounceEmitterData.identifier = "MarbleBounceParticle";
		this.bounceEmitterData.texture = ResourceLoader.getResource("data/particles/star.png", ResourceLoader.getTexture, this.textureResources);

		this.trailEmitterData = new ParticleData();
		this.trailEmitterData.identifier = "MarbleTrailParticle";
		this.trailEmitterData.texture = ResourceLoader.getResource("data/particles/smoke.png", ResourceLoader.getTexture, this.textureResources);

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

	public function init(level:MarbleWorld) {
		this.level = level;
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
		level.addDtsObject(this.forcefield);

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
		level.addDtsObject(this.helicopter);
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
		var gWorkGravityDir = this.level.currentUp.multiply(-1);
		var A = new Vector();
		if (this.mode != Finish)
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
		if (contacts.length == 0) {
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

	function computeMoveForces(m:Move) {
		var aControl = new Vector();
		var desiredOmega = new Vector();
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
			desiredOmega = R.cross(motionDir.multiply(desiredYVelocity).add(sideDir.multiply(desiredXVelocity))).multiply(1 / rsq);
			aControl = desiredOmega.sub(this.omega);
			var aScalar = aControl.length();
			if (aScalar > this._angularAcceleration) {
				aControl = aControl.multiply(this._angularAcceleration / aScalar);
			}
			return {result: false, aControl: aControl, desiredOmega: desiredOmega};
		}
		return {result: true, aControl: aControl, desiredOmega: desiredOmega};
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
						playBoundSound(-surfaceDot);
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
								restitution = 0;
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
					contact.velocity = new Vector();
				}

				for (interior in pi) {
					interior.setStopped();
				}
			}
		} while (!done);
		if (this.velocity.lengthSq() < 625) {
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
					if (dist >= 0) {
						var f1 = this.velocity.sub(contacts[k].velocity).add(dir.multiply(soFar)).dot(contacts[k].normal);
						var f2 = timeToSeparate * f1;
						if (f2 < dist) {
							var f3 = (dist - f2) / timeToSeparate;
							soFar += f3 / contacts[k].normal.dot(dir);
						}
					}
				}
				if (soFar < -25)
					soFar = -25;
				if (soFar > 25)
					soFar = 25;
				this.velocity = this.velocity.add(dir.multiply(soFar));
			}
		}

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
				A = A.add(contacts[j].normal.multiply(normalForce2));
			}
		}
		if (bestSurface != -1) {
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
					aControl = desiredOmega.clone().sub(nextOmega);
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
				A = A.add(Aadd);
				a = a.add(aadd);
			}
			A = A.add(AFriction);
			a = a.add(aFriction);

			lastContactNormal = bestContact.normal;
		}
		a = a.add(aControl);
		return [A, a];
	}

	function bounceEmitter(speed:Float, normal:Vector) {
		if (this.bounceEmitDelay == 0 && this._minBounceVel <= speed) {
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

	function playBoundSound(contactVel:Float) {
		if (minVelocityBounceSoft <= contactVel) {
			var hardBounceSpeed = minVelocityBounceHard;
			var bounceSoundNum = Math.floor(Math.random() * 4);
			var sndList = [
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

	function updateRollSound(contactPct:Float, slipAmount:Float) {
		var rSpat = rollSound.getEffect(Spatialization);
		rSpat.position = this.getAbsPos().getPosition();

		var sSpat = slipSound.getEffect(Spatialization);
		sSpat.position = this.getAbsPos().getPosition();

		var rollVel = bestContact != null ? this.velocity.sub(bestContact.velocity) : this.velocity;
		var scale = rollVel.length();
		scale /= this._maxRollVelocity;

		var rollVolume = 2 * scale;
		if (rollVolume > 1)
			rollVolume = 1;
		if (contactPct < 0.05)
			rollVolume = 0;

		var slipVolume = 0.0;
		if (slipAmount > 0) {
			slipVolume = slipAmount / 5;
			if (slipVolume > 1)
				slipVolume = 1;
			rollVolume = (1 - slipVolume) * rollVolume;
		}

		if (rollVolume < 0)
			rollVolume = 0;
		if (slipVolume < 0)
			slipVolume = 0;

		rollSound.volume = rollVolume;
		slipSound.volume = slipVolume;

		if (rollSound.getEffect(Pitch) == null) {
			rollSound.addEffect(new Pitch());
		}

		var pitch = Util.clamp(rollVel.length() / 15, 0, 1) * 0.75 + 0.75;

		// #if js
		// // Apparently audio crashes the whole thing if pitch is less than 0.2
		// if (pitch < 0.2)
		// 	pitch = 0.2;
		// #end
		var rPitch = rollSound.getEffect(Pitch);
		rPitch.value = pitch;
	}

	function testMove(velocity:Vector, position:Vector, deltaT:Float, radius:Float, testPIs:Bool):{position:Vector, t:Float} {
		var velLen = velocity.length();
		if (velLen < 0.001)
			return {position: position, t: deltaT};

		var velocityDir = velocity.normalized();

		var deltaPosition = velocity.multiply(deltaT);
		var finalPosition = position.add(deltaPosition);

		var searchbox = new Bounds();
		searchbox.addSpherePos(this.x, this.y, this.z, _radius);
		searchbox.addSpherePos(this.x + velocity.x * deltaT * 2, this.y + velocity.y * deltaT * 2, this.z + velocity.z * deltaT * 2, _radius);

		var foundObjs = this.level.collisionWorld.boundingSearch(searchbox);

		var finalT = deltaT;
		var marbleCollisionTime = finalT;
		var marbleCollisionNormal = new Vector(0, 0, 1);

		var lastContactPos = new Vector();

		function toDifPoint(vec:Vector) {
			return new Point3F(vec.x, vec.y, vec.z);
		}
		function fromDifPoint(vec:Point3F) {
			return new Vector(vec.x, vec.y, vec.z);
		}

		var contactPoly:{v0:Vector, v:Vector, v2:Vector};

		for (obj in foundObjs) {
			// Its an MP so bruh

			var invMatrix = @:privateAccess obj.invTransform;
			if (obj.go is PathedInterior)
				invMatrix = obj.transform.getInverse();
			var localpos = position.clone();
			localpos.transform(invMatrix);

			var relLocalVel = velocity.sub(obj.velocity);
			relLocalVel.transform3x3(invMatrix);

			var boundThing = new Bounds();
			boundThing.addSpherePos(localpos.x, localpos.y, localpos.z, radius * 1.1);
			boundThing.addSpherePos(localpos.x
				+ relLocalVel.x * deltaT * 2, localpos.y
				+ relLocalVel.y * deltaT * 2, localpos.z
				+ relLocalVel.z * deltaT * 2,
				radius * 1.1);

			var surfaces = obj.octree.boundingSearch(boundThing);

			for (surf in surfaces) {
				var surface:CollisionSurface = cast surf;

				var i = 0;
				while (i < surface.indices.length) {
					var v0 = surface.points[surface.indices[i]].transformed(obj.transform);
					var v = surface.points[surface.indices[i + 1]].transformed(obj.transform);
					var v2 = surface.points[surface.indices[i + 2]].transformed(obj.transform);

					var polyPlane = PlaneF.ThreePoints(toDifPoint(v0), toDifPoint(v), toDifPoint(v2));

					// If we're going the wrong direction or not going to touch the plane, ignore...
					if (!(polyPlane.getNormal().dot(toDifPoint(velocityDir)) > -0.001
						|| polyPlane.getNormal().dot(toDifPoint(finalPosition)) + polyPlane.d > radius)) {
						// Time until collision with the plane
						var collisionTime = (radius
							- (polyPlane.getNormal().dot(toDifPoint(position)) + polyPlane.d)) / polyPlane.getNormal().dot(toDifPoint(velocity));

						// Are we going to touch the plane during this time step?
						if (collisionTime >= 0.0 && finalT >= collisionTime) {
							var lastVertIndex = surface.indices[surface.indices.length - 1];
							var lastVert = surface.points[lastVertIndex];

							var collisionPos = velocity.multiply(collisionTime).add(position);

							var isOnEdge:Bool = false;

							for (i in 0...surface.indices.length) {
								{
									var thisVert = surface.points[surface.indices[i]];
									if (thisVert != lastVert) {
										var edgePlane = PlaneF.ThreePoints(toDifPoint(thisVert).add(polyPlane.getNormal()), toDifPoint(thisVert),
											toDifPoint(lastVert));
										lastVert = thisVert;

										// if we are on the far side of the edge
										if (edgePlane.getNormal().dot(toDifPoint(collisionPos)) + edgePlane.d < 0.0)
											break;
									}
								}

								isOnEdge = i != surface.indices.length;
							}

							// If we're inside the poly, just get the position
							if (!isOnEdge) {
								finalT = collisionTime;
								finalPosition = collisionPos;
								lastContactPos = fromDifPoint(polyPlane.project(toDifPoint(collisionPos)));
								contactPoly = {v0: v0, v: v, v2: v2};
								i += 3;
								continue;
							}
						}

						// We *might* be colliding with an edge

						var lastVert = surface.points[surface.indices[surface.indices.length - 1]];

						if (surface.indices.length == 0) {
							i += 3;
							continue;
						}
						var radSq = radius * radius;
						for (iter in 0...surface.indices.length) {
							var thisVert = surface.points[surface.indices[i]];

							var vertDiff = lastVert.sub(thisVert);
							var posDiff = position.sub(thisVert);

							var velRejection = vertDiff.cross(velocity);
							var posRejection = vertDiff.cross(posDiff);

							// Build a quadratic equation to solve for the collision time
							var a = velRejection.lengthSq();
							var halfB = posRejection.dot(velRejection);
							var b = halfB + halfB;

							var discriminant = b * b - (posRejection.lengthSq() - vertDiff.lengthSq() * radSq) * (a * 4.0);

							// If it's not quadratic or has no solution, ignore this edge.
							if (a == 0.0 || discriminant < 0.0) {
								lastVert = thisVert;
								continue;
							}

							var oneOverTwoA = 0.5 / a;
							var discriminantSqrt = Math.sqrt(discriminant);

							// Solve using the quadratic formula
							var edgeCollisionTime = (discriminantSqrt - b) * oneOverTwoA;
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
							if (edgeCollisionTime >= 0.0) {
								var edgeLen = vertDiff.length();

								var relativeCollisionPos = velocity.multiply(edgeCollisionTime).add(position).sub(thisVert);

								var distanceAlongEdge = relativeCollisionPos.dot(vertDiff) / edgeLen;

								// If the collision happens outside the boundaries of the edge, ignore this edge.
								if (-radius > distanceAlongEdge || edgeLen + radius < distanceAlongEdge) {
									lastVert = thisVert;
									continue;
								}

								// If the collision is within the edge, resolve the collision and continue.
								if (distanceAlongEdge >= 0.0 && distanceAlongEdge <= edgeLen) {
									finalT = edgeCollisionTime;
									finalPosition = velocity.multiply(edgeCollisionTime).add(position);

									lastContactPos = vertDiff.multiply(distanceAlongEdge / edgeLen).add(thisVert);
									contactPoly = {v0: v0, v: v, v2: v2};

									lastVert = thisVert;
									continue;
								}
							}

							// This is what happens when we collide with a corner

							var speedSq = velocity.lengthSq();

							// Build a quadratic equation to solve for the collision time
							var posVertDiff = position.sub(thisVert);
							var halfCornerB = posVertDiff.dot(velocity);
							var cornerB = halfCornerB + halfCornerB;

							var fourA = speedSq * 4.0;

							var cornerDiscriminant = cornerB * cornerB - (posVertDiff.lengthSq() - radSq) * fourA;

							// If it's quadratic and has a solution ...
							if (speedSq != 0.0 && cornerDiscriminant >= 0.0) {
								var oneOver2A = 0.5 / speedSq;
								var cornerDiscriminantSqrt = Math.sqrt(cornerDiscriminant);

								// Solve using the quadratic formula
								var cornerCollisionTime = (cornerDiscriminantSqrt - cornerB) * oneOver2A;
								var cornerCollisionTime2 = (-cornerB - cornerDiscriminantSqrt) * oneOver2A;

								// Make sure the 2 times are in ascending order
								if (cornerCollisionTime2 < cornerCollisionTime) {
									var temp = cornerCollisionTime2;
									cornerCollisionTime2 = cornerCollisionTime;
									cornerCollisionTime = temp;
								}

								// If the collision doesn't happen on this time step, ignore this corner
								if (cornerCollisionTime2 > 0.0001 && finalT > cornerCollisionTime) {
									// Adjust to make sure very small negative times are counted as zero
									if (cornerCollisionTime <= 0.0 && cornerCollisionTime > -0.0001)
										cornerCollisionTime = 0.0;

									// Check if the collision hasn't already happened
									if (cornerCollisionTime >= 0.0) {
										// Resolve it and continue
										finalT = cornerCollisionTime;
										contactPoly = {v0: v0, v: v, v2: v2};
										finalPosition = velocity.multiply(cornerCollisionTime).add(position);
										lastContactPos = thisVert;
									}
								}
							}

							// We still need to check the other corner ...
							// Build one last quadratic equation to solve for the collision time
							var lastVertDiff = position.sub(lastVert);
							var lastCornerHalfB = lastVertDiff.dot(velocity);
							var lastCornerB = lastCornerHalfB + lastCornerHalfB;
							var lastCornerDiscriminant = lastCornerB * lastCornerB - (lastVertDiff.lengthSq() - radSq) * fourA;

							// If it's not quadratic or has no solution, then skip this corner
							if (speedSq == 0.0 || lastCornerDiscriminant < 0.0) {
								lastVert = thisVert;
								continue;
							}

							var lastCornerOneOver2A = 0.5 / speedSq;
							var lastCornerDiscriminantSqrt = Math.sqrt(lastCornerDiscriminant);

							// Solve using the quadratic formula
							var lastCornerCollisionTime = (lastCornerDiscriminantSqrt - lastCornerB) * lastCornerOneOver2A;
							var lastCornerCollisionTime2 = (-lastCornerB - lastCornerDiscriminantSqrt) * lastCornerOneOver2A;

							// Make sure the 2 times are in ascending order
							if (lastCornerCollisionTime2 < lastCornerCollisionTime) {
								var temp = lastCornerCollisionTime2;
								lastCornerCollisionTime2 = lastCornerCollisionTime;
								lastCornerCollisionTime = temp;
							}

							// If the collision doesn't happen on this time step, ignore this corner
							if (lastCornerCollisionTime2 <= 0.0001 || finalT <= lastCornerCollisionTime) {
								lastVert = thisVert;
								continue;
							}

							// Adjust to make sure very small negative times are counted as zero
							if (lastCornerCollisionTime <= 0.0 && lastCornerCollisionTime > -0.0001)
								lastCornerCollisionTime = 0.0;

							// Check if the collision hasn't already happened
							if (lastCornerCollisionTime < 0.0) {
								lastVert = thisVert;
								continue;
							}

							// Resolve it and continue
							finalT = lastCornerCollisionTime;
							finalPosition = velocity.multiply(lastCornerCollisionTime).add(position);
							lastContactPos = lastVert;
							contactPoly = {v0: v0, v: v, v2: v2};

							lastVert = thisVert;
						}
					}

					i += 3;
				}
			}
		}

		position = finalPosition;

		return {position: position, t: finalT};
	}

	function getIntersectionTime(dt:Float, velocity:Vector) {
		var searchbox = new Bounds();
		searchbox.addSpherePos(this.x, this.y, this.z, _radius);
		searchbox.addSpherePos(this.x + velocity.x * dt * 2, this.y + velocity.y * dt * 2, this.z + velocity.z * dt * 2, _radius);

		var position = this.getAbsPos().getPosition();

		var foundObjs = this.level.collisionWorld.boundingSearch(searchbox);
		// var foundObjs = this.contactEntities;

		function toDifPoint(vec:Vector) {
			return new Point3F(vec.x, vec.y, vec.z);
		}

		var maxIntersectDist = 0.0;
		var contactNorm = new Vector();
		var contactPt = null;

		var traceinfo = new TraceInfo();

		traceinfo.resetTrace(position.clone(), position.add(velocity.multiply(dt)), this._radius);

		var foundTriangles = [];

		for (obj in foundObjs) {
			var radius = _radius;

			var invMatrix = @:privateAccess obj.invTransform;
			if (obj.go is PathedInterior)
				invMatrix = obj.transform.getInverse();
			var localpos = position.clone();
			localpos.transform(invMatrix);

			var relLocalVel = velocity.sub(obj.velocity);
			relLocalVel.transform3x3(invMatrix);

			var boundThing = new Bounds();
			boundThing.addSpherePos(localpos.x, localpos.y, localpos.z, radius * 1.1);
			boundThing.addSpherePos(localpos.x + relLocalVel.x * dt * 2, localpos.y + relLocalVel.y * dt * 2, localpos.z + relLocalVel.z * dt * 2,
				radius * 1.1);

			var surfaces = obj.octree.boundingSearch(boundThing);

			var tform = obj.transform.clone();

			var relVelocity = velocity.sub(obj.velocity);

			// tform.setPosition(tform.getPosition().add(velDir.multiply(_radius)));
			// tform.setPosition(tform.getPosition().add(obj.velocity.multiply(dt)));

			var contacts = [];

			for (surf in surfaces) {
				var surface:CollisionSurface = cast surf;

				var i = 0;
				while (i < surface.indices.length) {
					var v0 = surface.points[surface.indices[i]].transformed(tform);
					var v = surface.points[surface.indices[i + 1]].transformed(tform);
					var v2 = surface.points[surface.indices[i + 2]].transformed(tform);

					var surfacenormal = surface.normals[surface.indices[i]].transformed3x3(obj.transform);

					foundTriangles.push(v0);
					foundTriangles.push(v);
					foundTriangles.push(v2);
					// foundTriangles.push(surfacenormal);

					traceinfo.resetTrace(position.clone(), position.add(relVelocity.multiply(dt)), this._radius);
					traceinfo.traceSphereTriangle(v2, v, v0);

					if (traceinfo.collision) {
						var tcolpos = traceinfo.getTraceEndpoint();
						var closest = Collision.ClosestPtPointTriangle(tcolpos, _radius, v2.add(obj.velocity.multiply(traceinfo.t)),
							v.add(obj.velocity.multiply(traceinfo.t)), v0.add(obj.velocity.multiply(traceinfo.t)), surfacenormal);
						if (closest != null) {
							var dist = tcolpos.sub(closest);
							var distlen = dist.length();
							if (maxIntersectDist < distlen && distlen < _radius) {
								maxIntersectDist = distlen;
								contactNorm = dist.normalized();
								contactPt = closest;
							}
						}
					}

					// var closest = Collision.IntersectTriangleCapsule(position, position.add(relVelocity.multiply(dt)), _radius, v0, v, v2, surfacenormal);
					// var closest = Collision.IntersectTriangleSphere(v0, v, v2, surfacenormal, position, radius);

					// if (closest != null) {
					// This is some ballpark approximation, very bruh
					// var radiusDir = relVelocity.normalized().multiply(radius);
					// var t = (-position.add(radiusDir).dot(surfacenormal) + v0.dot(surfacenormal)) / relVelocity.dot(surfacenormal);

					// var pt = position.add(radiusDir).add(relVelocity.multiply(t));

					// if (Collision.PointInTriangle(pt, v0, v, v2)) {
					// 	if (t > 0 && t < intersectT) {
					// 		intersectT = t;
					// 	}
					// }
					// }

					i += 3;
				}
			}
		}

		if (maxIntersectDist > 0) {
			var finalPos = contactPt.add(contactNorm.multiply(_radius));

			// Nudge the finalPos to the surface of the object

			var chull = new ConvexHull(foundTriangles);
			var sph = new collision.gjk.Sphere();
			sph.position = finalPos;
			sph.radius = _radius;

			var pt = GJK.gjk(sph, chull);

			while (pt != null) {
				if (pt.lengthSq() < 0.0001) {
					break;
				}
				trace('Separating Vector Len: ${pt.length()}');
				finalPos = finalPos.sub(pt);
				sph.position = finalPos;
				pt = GJK.gjk(sph, chull);
			}

			// if (pt != null) {
			// 	finalPos = finalPos.sub(pt);
			// 	sph.position = finalPos;
			// 	pt = GJK.gjk(sph, chull);
			// 	if (pt != null) {
			// 		trace("?????");
			// 	}
			// 	trace('Separating Vector Len: ${pt.length()}');
			// }

			// var colpos = finalPos;
			// var msh = new h3d.prim.Sphere();
			// var prim = new h3d.scene.Mesh(msh);
			// msh.addNormals();
			// prim.setTransform(Matrix.T(colpos.x, colpos.y, colpos.z));
			// prim.setScale(this._radius);
			// this.level.scene.addChild(prim);

			var intersectT = finalPos.sub(position).length() / velocity.length();
			return intersectT;
		}

		return 10e8;
	}

	function advancePhysics(timeState:TimeState, m:Move, collisionWorld:CollisionWorld, pathedInteriors:Array<PathedInterior>) {
		var timeRemaining = timeState.dt;
		var it = 0;

		var piTime = timeState.currentAttemptTime;

		// if (this.controllable) {
		// 	for (interior in pathedInteriors) {
		// 		// interior.pushTickState();
		// 		interior.recomputeVelocity(piTime + 0.032, 0.032);
		// 	}
		// }

		_bounceYet = false;

		var contactTime = 0.0;
		var it = 0;

		do {
			if (timeRemaining <= 0)
				break;

			var timeStep = 0.004;
			if (timeRemaining < timeStep)
				timeStep = timeRemaining;

			if (this.controllable) {
				for (interior in pathedInteriors) {
					interior.pushTickState();
					interior.recomputeVelocity(piTime + timeStep * 4, timeStep * 4);
				}
			}

			var intersectData = testMove(velocity, this.getAbsPos().getPosition(), timeStep, _radius, true); // this.getIntersectionTime(timeStep, velocity);
			var intersectT = intersectData.t;

			if (intersectT < timeStep && intersectT >= 0.0001) {
				// trace('CCD AT t = ${intersectT}');
				// intersectT *= 0.8; // We uh tick the shit to not actually at the contact time cause bruh
				// intersectT /= 2;
				var diff = timeStep - intersectT;
				// this.velocity = this.velocity.sub(A.multiply(diff));
				// this.omega = this.omega.sub(a.multiply(diff));
				timeStep = intersectT;
				// this.setPosition(intersectData.position.x, intersectData.position.y, intersectData.position.z);
			}

			var tempState = timeState.clone();
			tempState.dt = timeStep;

			it++;

			this.findContacts(collisionWorld, tempState);
			var cmf = this.computeMoveForces(m);
			var isCentered:Bool = cmf.result;
			var aControl = cmf.aControl;
			var desiredOmega = cmf.desiredOmega;
			var stoppedPaths = false;
			stoppedPaths = this.velocityCancel(timeState.currentAttemptTime, timeStep, isCentered, false, stoppedPaths, pathedInteriors);
			var A = this.getExternalForces(timeState.currentAttemptTime, m, timeStep);
			var retf = this.applyContactForces(timeStep, m, isCentered, aControl, desiredOmega, A);
			A = retf[0];
			var a = retf[1];
			this.velocity = this.velocity.add(A.multiply(timeStep));
			this.omega = this.omega.add(a.multiply(timeStep));
			stoppedPaths = this.velocityCancel(timeState.currentAttemptTime, timeStep, isCentered, true, stoppedPaths, pathedInteriors);
			this._totalTime += timeStep;
			if (contacts.length != 0) {
				this._contactTime += timeStep;
			}

			for (impulse in appliedImpulses) {
				this.velocity = this.velocity.add(impulse);
			}
			appliedImpulses = [];

			piTime += timeStep;
			if (this.controllable) {
				for (interior in pathedInteriors) {
					interior.popTickState();
					interior.setStopped(stoppedPaths);
					var piDT = timeState.clone();
					piDT.currentAttemptTime = piTime;
					piDT.dt = timeStep;
					interior.update(piDT);
				}
			}

			var pos = this.getAbsPos().getPosition();
			this.prevPos = pos.clone();

			if (mode == Start) {
				var upVec = this.level.currentUp;
				var startpadNormal = startPad.getAbsPos().up();
				this.velocity = upVec.multiply(this.velocity.dot(upVec));
				// Apply contact forces in startPad up direction if upVec is not startpad up, fixes the weird startpad shit in pinball wizard
				if (upVec.dot(startpadNormal) < 0.95) {
					for (contact in contacts) {
						var normF = contact.normal.multiply(contact.normalForce);
						var startpadF = startpadNormal.multiply(normF.dot(startpadNormal));
						var upF = upVec.multiply(normF.dot(upVec));
						this.velocity = this.velocity.add(startpadF.multiply(timeStep / 4));
					}
				}
			}

			if (mode == Finish) {
				this.velocity = this.velocity.multiply(0.925);
			}

			var newPos = pos.add(this.velocity.multiply(timeStep));
			var rot = this.getRotationQuat();
			var quat = new Quat();
			quat.initRotation(omega.x * timeStep, omega.y * timeStep, omega.z * timeStep);
			quat.multiply(quat, rot);
			this.setRotationQuat(quat);

			this.setPosition(newPos.x, newPos.y, newPos.z);

			var tform = this.collider.transform;
			tform.setPosition(new Vector(newPos.x, newPos.y, newPos.z));
			this.collider.setTransform(tform);
			this.collider.velocity = this.velocity;

			if (this.heldPowerup != null && m.powerup && !this.level.outOfBounds) {
				var pTime = timeState.clone();
				pTime.dt = timeStep;
				pTime.currentAttemptTime = piTime;
				this.heldPowerup.use(pTime);
				this.heldPowerup = null;
			}

			if (this.controllable && this.prevPos != null) {
				var tempTimeState = timeState.clone();
				tempState.currentAttemptTime = piTime;
				tempState.dt = timeStep;
				this.level.callCollisionHandlers(cast this, tempTimeState);
			}

			if (contacts.length != 0)
				contactTime += timeStep;

			timeRemaining -= timeStep;
		} while (true);
		this.queuedContacts = [];

		this.updateRollSound(contactTime / timeState.dt, this._slipAmount);
	}

	public function update(timeState:TimeState, collisionWorld:CollisionWorld, pathedInteriors:Array<PathedInterior>) {
		var move = new Move();
		move.d = new Vector();
		if (this.controllable && this.mode != Finish && !MarbleGame.instance.paused) {
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
			if (Key.isDown(Settings.controlsSettings.jump) || MarbleGame.instance.touchInput.jumpButton.pressed) {
				move.jump = true;
			}
			if (Key.isDown(Settings.controlsSettings.powerup) || MarbleGame.instance.touchInput.powerupButton.pressed) {
				move.powerup = true;
			}
		}

		playedSounds = [];
		advancePhysics(timeState, move, collisionWorld, pathedInteriors);

		if (this.controllable) {
			this.camera.update(timeState.currentAttemptTime, timeState.dt);
		}

		updatePowerupStates(timeState.currentAttemptTime, timeState.dt);

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

	public function applyImpulse(impulse:Vector) {
		this.appliedImpulses.push(impulse);
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

	public override function reset() {
		this.velocity = new Vector();
		this.collider.velocity = new Vector();
		this.omega = new Vector();
		this.superBounceEnableTime = Math.NEGATIVE_INFINITY;
		this.shockAbsorberEnableTime = Math.NEGATIVE_INFINITY;
		this.helicopterEnableTime = Math.NEGATIVE_INFINITY;
		this.lastContactNormal = new Vector(0, 0, 1);
	}
}
