package src;

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

	function findContacts(collisiomWorld:CollisionWorld, dt:Float) {
		this.contacts = queuedContacts;
		var c = collisiomWorld.sphereIntersection(this.collider, dt);
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
					if (contacts[k].contactDistance < this._radius) {
						var timeToSeparate = 0.1;
						var dist = this._radius - contacts[k].contactDistance; // contacts[k].penetration;
						var normal = contacts[k].normal;
						var unk = normal.multiply(soFar);
						var tickle = this.velocity.sub(contacts[k].velocity);
						var plop = unk.add(tickle);
						var outVel = plop.dot(normal);
						var cancan = timeToSeparate * outVel;

						if (dist > cancan) {
							var bla = contacts[k].normal;
							var bFac = (dist - cancan) / timeToSeparate;
							soFar += bFac / bla.dot(dir);
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
				contacts[i].normalForce = -contacts[i].normal.dot(A);
				if (contacts[i].normalForce > bestNormalForce) {
					bestNormalForce = contacts[i].normalForce;
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

	function testMove(velocity:Vector, position:Vector, deltaT:Float, radius:Float, testPIs:Bool, collisionWorld:CollisionWorld) {
		var velLen = velocity.length();
		if (velLen < 0.001)
			return deltaT;

		var velocityDir = velocity.normalized();

		var deltaPosition = velocity.multiply(deltaT);
		var finalPosition = position.add(deltaPosition);

		var expandedcollider = new SphereCollisionEntity(cast this);
		expandedcollider.transform = Matrix.T(position.x, position.y, position.z);
		expandedcollider.radius = this.getAbsPos().getPosition().distance(position) + radius;

		var foundObjs = collisionWorld.radiusSearch(position, expandedcollider.radius);

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
			if (obj.velocity.length() != 0) { // Its an MP so bruh

				var invMatrix = obj.transform.clone();
				invMatrix.invert();
				var localpos = position.clone();
				localpos.transform(invMatrix);
				var surfaces = obj.octree.radiusSearch(localpos, expandedcollider.radius);

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
		}

		position = finalPosition;

		var contacted = false;
		if (deltaT > finalT) {
			contacted = true;
		}

		return finalT;
	}

	function getIntersectionTime(dt:Float, velocity:Vector, pathedInteriors:Array<PathedInterior>, collisionWorld:CollisionWorld) {
		var expandedcollider = new SphereCollisionEntity(cast this);
		var position = this.getAbsPos().getPosition();
		expandedcollider.transform = Matrix.T(position.x, position.y, position.z);
		expandedcollider.radius = this.getAbsPos().getPosition().distance(position) + _radius;

		var foundObjs = collisionWorld.radiusSearch(position, expandedcollider.radius);

		function toDifPoint(vec:Vector) {
			return new Point3F(vec.x, vec.y, vec.z);
		}

		var intersectT = 10e8;

		for (obj in foundObjs) {
			if (obj.velocity.length() > 0) {
				var radius = _radius;

				var invMatrix = obj.transform.clone();
				invMatrix.invert();
				var localpos = position.clone();
				localpos.transform(invMatrix);
				var surfaces = obj.octree.radiusSearch(localpos, radius * 1.1);

				var tform = obj.transform.clone();
				var velDir = obj.velocity.normalized();
				// tform.setPosition(tform.getPosition().add(velDir.multiply(_radius)));
				tform.setPosition(tform.getPosition().add(obj.velocity.multiply(dt)).sub(velDir.multiply(_radius)));

				var contacts = [];

				for (surf in surfaces) {
					var surface:CollisionSurface = cast surf;

					var i = 0;
					while (i < surface.indices.length) {
						var v0 = surface.points[surface.indices[i]].transformed(tform);
						var v = surface.points[surface.indices[i + 1]].transformed(tform);
						var v2 = surface.points[surface.indices[i + 2]].transformed(tform);

						var polyPlane = PlaneF.ThreePoints(toDifPoint(v0), toDifPoint(v), toDifPoint(v2));

						var surfacenormal = surface.normals[surface.indices[i]].transformed3x3(obj.transform);

						var t = (-position.dot(surfacenormal) - polyPlane.d) / velocity.dot(surfacenormal);

						var pt = position.add(velocity.multiply(t));

						if (Collision.PointInTriangle(pt, v0, v, v2)) {
							if (t > 0 && t < intersectT) {
								intersectT = t;
							}
						}

						i += 3;
					}
				}
			}
		}

		return intersectT;
	}

	function advancePhysics(currentTime:Float, dt:Float, m:Move, collisionWorld:CollisionWorld, pathedInteriors:Array<PathedInterior>) {
		var timeRemaining = dt;
		var it = 0;

		var piTime = currentTime;
		do {
			if (timeRemaining <= 0)
				break;

			var timeStep = 0.00800000037997961;
			if (timeRemaining < 0.00800000037997961)
				timeStep = timeRemaining;

			this.findContacts(collisionWorld, timeStep);
			var cmf = this.computeMoveForces(m);
			var isCentered:Bool = cmf.result;
			var aControl = cmf.aControl;
			var desiredOmega = cmf.desiredOmega;
			this.velocityCancel(isCentered, false);
			var A = this.getExternalForces(m, timeStep);
			var retf = this.applyContactForces(timeStep, m, isCentered, aControl, desiredOmega, A);
			A = retf[0];
			var a = retf[1];
			this.velocity = this.velocity.add(A.multiply(timeStep));
			this.omega = this.omega.add(a.multiply(timeStep));
			this.velocityCancel(isCentered, true);
			this._totalTime += timeStep;
			if (contacts.length != 0) {
				this._contactTime += timeStep;
			}

			var intersectT = this.getIntersectionTime(timeStep, velocity, pathedInteriors, collisionWorld);

			if (intersectT < timeStep) {
				var diff = timeStep - intersectT;
				this.velocity = this.velocity.sub(A.multiply(diff));
				this.omega = this.omega.sub(a.multiply(diff));
				timeStep = intersectT;
			}

			piTime += timeStep;
			if (this.controllable) {
				for (interior in pathedInteriors) {
					interior.update(piTime, timeStep);
				}
			}

			var pos = this.getAbsPos().getPosition();

			var newPos = pos.add(this.velocity.multiply(timeStep));
			this.setPosition(newPos.x, newPos.y, newPos.z);
			var tform = this.collider.transform;
			tform.setPosition(new Vector(newPos.x, newPos.y, newPos.z));
			this.collider.setTransform(tform);
			this.collider.velocity = this.velocity;

			timeRemaining -= timeStep;
			it++;
		} while (it <= 10);
		this.queuedContacts = [];
	}

	public function update(currentTime:Float, dt:Float, collisionWorld:CollisionWorld, pathedInteriors:Array<PathedInterior>) {
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

		advancePhysics(currentTime, dt, move, collisionWorld, pathedInteriors);

		// var timeRemaining = dt;
		// var it = 0;

		// var piTime = currentTime;

		// var pos = this.getAbsPos().getPosition();
		// do {
		// 	if (timeRemaining <= 0)
		// 		break;

		// 	var timeStep = 0.00800000037997961;
		// 	if (timeRemaining < 0.00800000037997961)
		// 		timeStep = timeRemaining;

		// 	var externalForces = getExternalForces(move, timeStep);

		// 	advancePhysics(move, timeStep, collisionWorld);

		// 	var intersectT = this.getIntersectionTime(timeStep, velocity, pathedInteriors, collisionWorld);

		// 	if (intersectT < timeStep) {
		// 		timeStep = intersectT;
		// 	}

		// 	piTime += timeStep;

		// 	if (this.controllable) {
		// 		for (interior in pathedInteriors) {
		// 			// interior.rollBack();
		// 			interior.update(piTime, timeStep);
		// 		}
		// 	}

		// 	var pos = this.getAbsPos().getPosition();

		// 	var newPos = pos.add(this.velocity.multiply(timeStep));
		// 	this.setPosition(newPos.x, newPos.y, newPos.z);
		// 	var tform = this.collider.transform;
		// 	tform.setPosition(new Vector(newPos.x, newPos.y, newPos.z));
		// 	this.collider.setTransform(tform);
		// 	this.collider.velocity = this.velocity;

		// 	// if (intersectT != timeStep && intersectT != 10e8) {
		// 	// 	// this.velocity = this.velocity.sub(externalForces.multiply(timeStep - intersectT));
		// 	// 	// this.omega
		// 	// 	if (intersectT > timeStep) {
		// 	// 		trace("Bruh");
		// 	// 	}
		// 	// 	timeStep = intersectT;
		// 	// }

		// 	timeRemaining -= timeStep;
		// 	it++;
		// } while (it <= 10);

		this.camera.target.load(this.getAbsPos().getPosition().toPoint());
	}
}
