package src;

import collision.SphereCollisionEntity;
import hxd.Key;
import collision.CollisionInfo;
import h3d.Matrix;
import collision.CollisionWorld;
import h3d.col.ObjectCollider;
import h3d.col.Collider.GroupCollider;
import h3d.Vector;
import h3d.scene.CameraController;
import h3d.mat.Material;
import h3d.scene.CustomObject;
import h3d.prim.Sphere;
import h3d.scene.Object;

class Move {
	public var d:Vector;
	public var jump:Bool;
	public var powerup:Bool;

	public function new() {}
}

class Marble extends Object {
	public var camera:CameraController;
	public var controllable:Bool = false;

	public var collider:SphereCollisionEntity;

	public var velocity:Vector;
	public var omega:Vector;

	var gravityDir:Vector = new Vector(0, 0, -1);

	public var _radius = 0.2;

	var _maxRollVelocity = 15;
	var _angularAcceleration = 75;
	var _jumpImpulse = 7.5;
	var _kineticFriction = 0.7;
	var _staticFriction = 1.1;
	var _brakingAcceleration = 30;
	var _gravity = 20;
	var _airAccel = 5;
	var _maxDotSlide = 0.5;
	var _minBounceVel = 0.1;
	var _bounceKineticFriction = 0.2;

	public var _bounceRestitution = 0.5;

	var _bounceYet:Bool;
	var _bounceSpeed:Float;
	var _bouncePos:Vector;
	var _bounceNormal:Vector;
	var _slipAmount:Float;
	var _contactTime:Float;
	var _totalTime:Float;

	public var _mass:Float = 1;

	var contacts:Array<CollisionInfo> = [];
	var queuedContacts:Array<CollisionInfo> = [];

	public function new() {
		super();
		var geom = Sphere.defaultUnitSphere();
		geom.addUVs();
		var obj = new CustomObject(geom, Material.create(), this);
		obj.scale(_radius);

		this.velocity = new Vector();
		this.omega = new Vector();
		this.camera = new CameraController(20);

		this.collider = new SphereCollisionEntity(cast this);
	}

	function findContacts(collisiomWorld:CollisionWorld) {
		this.contacts = queuedContacts;
		var c = collisiomWorld.sphereIntersection(this.collider);
		contacts = contacts.concat(c);
	}

	public function queueCollision(collisionInfo:CollisionInfo) {
		this.queuedContacts.push(collisionInfo);
	}

	function getMarbleAxis() {
		var cammat = Matrix.I();
		var xrot = new Matrix();
		xrot.initRotationX(this.camera.phi);
		var zrot = new Matrix();
		zrot.initRotationZ(this.camera.theta);
		cammat.multiply(xrot, zrot);
		var updir = gravityDir.multiply(-1);
		var motiondir = new Vector(cammat._21, cammat._22, cammat._23);
		var sidedir = motiondir.cross(updir);

		sidedir.normalize();
		motiondir = updir.cross(sidedir);
		return [sidedir, motiondir, updir];
	}

	function getExternalForces(m:Move, dt:Float) {
		var gWorkGravityDir = gravityDir;
		var A = gWorkGravityDir.multiply(this._gravity);
		if (contacts.length == 0) {
			var axes = this.getMarbleAxis();
			var sideDir = axes[0];
			var motionDir = axes[1];
			var upDir = axes[2];
			A = A.add(sideDir.multiply(m.d.x).add(motionDir.multiply(m.d.y)).multiply(this._airAccel));
		}
		return A;
	}

	function computeMoveForces(m:Move) {
		var aControl = new Vector();
		var desiredOmega = new Vector();
		var currentGravityDir = gravityDir;
		var R = currentGravityDir.multiply(-this._radius);
		var rollVelocity = this.omega.cross(R);
		var axes = this.getMarbleAxis();
		var sideDir = axes[0];
		var motionDir = axes[1];
		var upDir = axes[2];
		var currentYVelocity = rollVelocity.dot(motionDir);
		var currentXVelocity = rollVelocity.dot(sideDir);
		var mv = m.d;

		mv = mv.multiply(1.538461565971375);
		var mvlen = mv.length();
		if (mvlen > 1) {
			mv = mv.multiply(1 / mvlen);
		}
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

	function velocityCancel(surfaceSlide:Bool, noBounce:Bool) {
		var SurfaceDotThreshold = 0.001;
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
					var surfaceVel = contacts[i].normal.multiply(surfaceDot);
					this.ReportBounce(contacts[i].point, contacts[i].normal, -surfaceDot);
					if (noBounce) {
						this.velocity = this.velocity.sub(surfaceVel);
					} else if (contacts[i].collider != null) {
						var otherMarble = (cast(contacts[i].collider, SphereCollisionEntity).marble);
						var ourMass = this._mass;
						var theirMass = otherMarble._mass;

						var bounce = Math.max(this._bounceRestitution, otherMarble._bounceRestitution);

						var dp = this.velocity.multiply(ourMass).sub(otherMarble.velocity.multiply(theirMass));
						var normP = contacts[i].normal.multiply(dp.dot(contacts[i].normal));
						normP = normP.multiply(bounce + 1);

						otherMarble.velocity = otherMarble.velocity.add(normP.multiply(1 / theirMass));
						contacts[i].velocity = otherMarble.velocity;
					} else {
						var velocity2 = contacts[i].velocity;
						if (velocity2.length() > 0.0001 && !surfaceSlide && surfaceDot > -this._maxDotSlide * velLen) {
							var vel = this.velocity.clone();
							vel = vel.sub(surfaceVel);
							vel.normalize();
							vel = vel.multiply(velLen);
							this.velocity = vel;
							surfaceSlide = true;
						} else if (surfaceDot > -this._minBounceVel) {
							var vel = this.velocity.clone();
							vel = vel.sub(surfaceVel);
							this.velocity = vel;
						} else {
							var restitution = this._bounceRestitution;
							restitution *= contacts[i].restitution;
							var velocityAdd = surfaceVel.multiply(-(1 + restitution));
							var vAtC = sVel.add(this.omega.cross(contacts[i].normal.multiply(-this._radius)));
							var normalVel = -contacts[i].normal.dot(sVel);
							vAtC = vAtC.sub(contacts[i].normal.multiply(contacts[i].normal.dot(sVel)));
							var vAtCMag = vAtC.length();
							if (vAtCMag != 0) {
								var friction = this._bounceKineticFriction * contacts[i].friction;
								var angVMagnitude = 5 * friction * normalVel / (2 * this._radius);
								if (angVMagnitude > vAtCMag / this._radius) {
									angVMagnitude = vAtCMag / this._radius;
								}
								var vAtCDir = vAtC.multiply(1 / vAtCMag);
								var deltaOmega = contacts[i].normal.cross(vAtCDir).multiply(angVMagnitude);
								this.omega = this.omega.add(deltaOmega);
								this.velocity = this.velocity.sub(deltaOmega.cross(contacts[i].normal.multiply(this._radius)));
							}
							this.velocity = this.velocity.add(velocityAdd);
						}
					}
					done = false;
				}
			}
			looped = true;
			if (itersIn > 6 && noBounce) {
				done = true;
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
				gotOne = true;
			}
			if (gotOne) {
				dir.normalize();
				var soFar = 0.0;
				for (k in 0...contacts.length) {
					if (contacts[k].penetration < this._radius) {
						var timeToSeparate = 0.1;
						var dist = contacts[k].penetration;
						var outVel = this.velocity.add(dir.multiply(soFar)).dot(contacts[k].normal);

						if (timeToSeparate * outVel < dist) {
							soFar += (dist - outVel * timeToSeparate) / timeToSeparate / contacts[k].normal.dot(dir);
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
	}

	function applyContactForces(dt:Float, m:Move, isCentered:Bool, aControl:Vector, desiredOmega:Vector, A:Vector) {
		var a = new Vector();
		this._slipAmount = 0;
		var gWorkGravityDir = new Vector(0, 0, -1);
		var bestSurface = -1;
		var bestNormalForce = 0.0;
		for (i in 0...contacts.length) {
			if (contacts[i].collider == null) {
				var normalForce = -contacts[i].normal.dot(A);
				if (normalForce > bestNormalForce) {
					bestNormalForce = normalForce;
					bestSurface = i;
				}
			}
		}
		var bestContact = (bestSurface != -1) ? contacts[bestSurface] : new CollisionInfo();
		var canJump = bestSurface != -1;
		if (canJump && m.jump) {
			var velDifference = this.velocity.clone().sub(bestContact.velocity);
			var sv = bestContact.normal.dot(velDifference);
			if (sv < 0) {
				sv = 0;
			}
			if (sv < this._jumpImpulse) {
				this.velocity = this.velocity.add(bestContact.normal.clone().multiply((this._jumpImpulse - sv)));
			}
		}
		for (j in 0...contacts.length) {
			var normalForce2 = -contacts[j].normal.dot(A);
			if (normalForce2 > 0 && contacts[j].normal.dot(this.velocity.clone().sub(contacts[j].velocity)) <= 0.0001) {
				A = A.add(contacts[j].normal.multiply(normalForce2));
			}
		}
		if (bestSurface != -1) {
			// TODO: FIX
			// bestContact.velocity - bestContact.normal * Vector3.Dot(bestContact.normal, bestContact.velocity);
			var vAtC = this.velocity.clone().add(this.omega.clone().cross(bestContact.normal.clone().multiply(-this._radius))).sub(bestContact.velocity);
			var vAtCMag = vAtC.length();
			var slipping = false;
			var aFriction = new Vector(0, 0, 0);
			var AFriction = new Vector(0, 0, 0);
			if (vAtCMag != 0) {
				slipping = true;
				var friction = this._kineticFriction * bestContact.friction;
				var angAMagnitude = 5 * friction * bestNormalForce / (2 * this._radius);
				var AMagnitude = bestNormalForce * friction;
				var totalDeltaV = (angAMagnitude * this._radius + AMagnitude) * dt;
				if (totalDeltaV > vAtCMag) {
					var fraction = vAtCMag / totalDeltaV;
					angAMagnitude *= fraction;
					AMagnitude *= fraction;
					slipping = false;
				}
				var vAtCDir = vAtC.clone().multiply(1 / vAtCMag);
				aFriction = bestContact.normal.clone()
					.multiply(-1)
					.cross(vAtCDir.clone().multiply(-1))
					.multiply(angAMagnitude);
				AFriction = vAtCDir.clone().multiply(-AMagnitude);
				this._slipAmount = vAtCMag - totalDeltaV;
			}
			if (!slipping) {
				var R = gWorkGravityDir.clone().multiply(-this._radius);
				var aadd = R.cross(A).multiply(1 / R.lengthSq());
				if (isCentered) {
					var nextOmega = this.omega.add(a.clone().multiply(dt));
					aControl = desiredOmega.clone().sub(nextOmega);
					var aScalar = aControl.length();
					if (aScalar > this._brakingAcceleration) {
						aControl = aControl.multiply(this._brakingAcceleration / aScalar);
					}
				}
				var Aadd = aControl.clone().cross(bestContact.normal.multiply(-this._radius)).multiply(-1);
				var aAtCMag = aadd.clone().cross(bestContact.normal.multiply(-this._radius)).add(Aadd).length();
				var friction2 = this._staticFriction * bestContact.friction;

				if (aAtCMag > friction2 * bestNormalForce) {
					friction2 = this._kineticFriction * bestContact.friction;
					Aadd = Aadd.multiply(friction2 * bestNormalForce / aAtCMag);
				}
				A = A.add(Aadd);
				a = a.add(aadd);
			}
			A = A.add(AFriction);
			a = a.add(aFriction);
		}
		a = a.add(aControl);
		return [A, a];
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

	function advancePhysics(m:Move, dt:Float, collisionWorld:CollisionWorld) {
		this.findContacts(collisionWorld);
		var cmf = this.computeMoveForces(m);
		var isCentered:Bool = cmf.result;
		var aControl = cmf.aControl;
		var desiredOmega = cmf.desiredOmega;
		this.velocityCancel(isCentered, false);
		var A = this.getExternalForces(m, dt);
		var retf = this.applyContactForces(dt, m, isCentered, aControl, desiredOmega, A);
		A = retf[0];
		var a = retf[1];
		this.velocity = this.velocity.add(A.multiply(dt));
		this.omega = this.omega.add(a.multiply(dt));
		this.velocityCancel(isCentered, true);
		this._totalTime += dt;
		if (contacts.length != 0) {
			this._contactTime += dt;
		}
		this.queuedContacts = [];
	}

	public function update(dt:Float, collisionWorld:CollisionWorld) {
		var move = new Move();
		move.d = new Vector();
		if (this.controllable) {
			if (Key.isDown(Key.W)) {
				move.d.x -= 1;
			}
			if (Key.isDown(Key.S)) {
				move.d.x += 1;
			}
			if (Key.isDown(Key.A)) {
				move.d.y += 1;
			}
			if (Key.isDown(Key.D)) {
				move.d.y -= 1;
			}
			if (Key.isDown(Key.SPACE)) {
				move.jump = true;
			}
		}

		var timeRemaining = dt;
		var it = 0;
		do {
			if (timeRemaining <= 0)
				break;

			var timeStep = 0.00800000037997961;
			if (timeRemaining < 0.00800000037997961)
				timeStep = timeRemaining;

			advancePhysics(move, timeStep, collisionWorld);
			var newPos = this.getAbsPos().getPosition().add(this.velocity.multiply(timeStep));
			this.setPosition(newPos.x, newPos.y, newPos.z);
			var tform = this.collider.transform;
			tform.setPosition(new Vector(newPos.x, newPos.y, newPos.z));
			this.collider.setTransform(tform);
			this.collider.velocity = this.velocity;

			timeRemaining -= timeStep;
			it++;
		} while (it <= 10);

		this.camera.target.load(this.getAbsPos().getPosition().toPoint());
	}
}
