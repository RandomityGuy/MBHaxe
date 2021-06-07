package src;

import src.Util;
import h3d.Quat;
import shapes.PowerUp;
import collision.SphereCollisionEntity;
import src.Sky;
import h3d.scene.Mesh;
import src.InstanceManager;
import h3d.scene.MeshBatch;
import src.DtsObject;
import src.PathedInterior;
import hxd.Key;
import h3d.Vector;
import src.InteriorObject;
import h3d.scene.Scene;
import h3d.scene.CustomObject;
import collision.CollisionWorld;
import src.Marble;

class MarbleWorld {
	public var collisionWorld:CollisionWorld;
	public var instanceManager:InstanceManager;

	public var interiors:Array<InteriorObject> = [];
	public var pathedInteriors:Array<PathedInterior> = [];
	public var marbles:Array<Marble> = [];
	public var dtsObjects:Array<DtsObject> = [];

	var shapeImmunity:Array<DtsObject> = [];
	var shapeOrTriggerInside:Array<DtsObject> = [];

	public var currentTime:Float = 0;
	public var sky:Sky;

	public var scene:Scene;

	public var marble:Marble;
	public var worldOrientation:Quat;
	public var currentUp = new Vector(0, 0, 1);

	var orientationChangeTime = -1e8;
	var oldOrientationQuat = new Quat();

	/** The new target camera orientation quat  */
	public var newOrientationQuat = new Quat();

	public function new(scene:Scene) {
		this.collisionWorld = new CollisionWorld();
		this.scene = scene;
		this.instanceManager = new InstanceManager(scene);
		this.sky = new Sky();
		sky.dmlPath = "data/skies/sky_day.dml";
		sky.init(cast this);
		scene.addChild(sky);
	}

	public function addInterior(obj:InteriorObject) {
		this.interiors.push(obj);
		obj.init(cast this);
		this.collisionWorld.addEntity(obj.collider);
		if (obj.useInstancing)
			this.instanceManager.addObject(obj);
		else
			this.scene.addChild(obj);
	}

	public function addPathedInterior(obj:PathedInterior) {
		this.pathedInteriors.push(obj);
		obj.init(cast this);
		this.collisionWorld.addMovingEntity(obj.collider);
		if (obj.useInstancing)
			this.instanceManager.addObject(obj);
		else
			this.scene.addChild(obj);
	}

	public function addDtsObject(obj:DtsObject) {
		this.dtsObjects.push(obj);
		obj.init(cast this);
		if (obj.useInstancing) {
			this.instanceManager.addObject(obj);
		} else
			this.scene.addChild(obj);
		for (collider in obj.colliders) {
			if (collider != null)
				this.collisionWorld.addEntity(collider);
		}
		this.collisionWorld.addEntity(obj.boundingCollider);
	}

	public function addMarble(marble:Marble) {
		this.marbles.push(marble);
		marble.level = cast this;
		if (marble.controllable) {
			marble.camera.init(cast this);
			marble.init(cast this);
			this.scene.addChild(marble.camera);
			this.marble = marble;
			// Ugly hack
			sky.follow = marble;
		}
		this.collisionWorld.addMovingEntity(marble.collider);
		this.scene.addChild(marble);
	}

	public function update(dt:Float) {
		for (obj in dtsObjects) {
			obj.update(currentTime, dt);
		}
		for (marble in marbles) {
			marble.update(currentTime, dt, collisionWorld, this.pathedInteriors);
		}
		this.instanceManager.update(dt);
		currentTime += dt;
		if (this.marble != null) {
			callCollisionHandlers(marble);
		}
	}

	function callCollisionHandlers(marble:Marble) {
		var contacts = this.collisionWorld.radiusSearch(marble.getAbsPos().getPosition(), marble._radius);
		var newImmunity = [];
		var calledShapes = [];
		var inside = [];

		var contactsphere = new SphereCollisionEntity(marble);
		contactsphere.velocity = new Vector();

		for (contact in contacts) {
			if (contact.go != marble) {
				if (contact.go is DtsObject) {
					var shape:DtsObject = cast contact.go;

					var contacttest = shape.colliders.filter(x -> x != null).map(x -> x.sphereIntersection(contactsphere, 0));
					var contactlist:Array<collision.CollisionInfo> = [];
					for (l in contacttest) {
						contactlist = contactlist.concat(l);
					}

					if (!calledShapes.contains(shape) && !this.shapeImmunity.contains(shape) && contactlist.length != 0) {
						calledShapes.push(shape);
						newImmunity.push(shape);
						shape.onMarbleContact(currentTime);
					}

					shape.onMarbleInside(currentTime);
					if (!this.shapeOrTriggerInside.contains(shape)) {
						this.shapeOrTriggerInside.push(shape);
						shape.onMarbleEnter(currentTime);
					}
					inside.push(shape);
				}
			}
		}

		for (object in shapeOrTriggerInside) {
			if (!inside.contains(object)) {
				this.shapeOrTriggerInside.remove(object);
				object.onMarbleLeave(currentTime);
			}
		}

		this.shapeImmunity = newImmunity;
	}

	public function pickUpPowerUp(powerUp:PowerUp) {
		if (this.marble.heldPowerup == powerUp)
			return false;
		this.marble.heldPowerup = powerUp;
		// 	for (let overlayShape
		// 	of
		// 	this.overlayShapes
		// )
		// 	{
		// 		if (overlayShape.dtsPath.includes("gem"))
		// 			continue;
		// 		// Show the corresponding icon in the HUD
		// 		if (overlayShape.dtsPath == = powerUp.dtsPath)
		// 			this.overlayScene.add(overlayShape.group);
		// 		else
		// 			this.overlayScene.remove(overlayShape.group);
		// 	}
		// 	if (!this.rewinding)
		// 		AudioManager.play(powerUp.sounds[0]);
		return true;
	}

	/** Get the current interpolated orientation quaternion. */
	public function getOrientationQuat(time:Float) {
		var completion = Util.clamp((time - this.orientationChangeTime) / 0.3, 0, 1);
		var q = this.oldOrientationQuat.clone();
		q.slerp(q, this.newOrientationQuat, completion);
		return q;
	}

	public function setUp(vec:Vector, time:Float) {
		this.currentUp = vec;
		var currentQuat = this.getOrientationQuat(time);
		var oldUp = new Vector(0, 0, 1);
		oldUp.transform(currentQuat.toMatrix());

		function getRotQuat(v1:Vector, v2:Vector) {
			function orthogonal(v:Vector) {
				var x = Math.abs(v.x);
				var y = Math.abs(v.y);
				var z = Math.abs(v.z);
				var other = x < y ? (x < z ? new Vector(1, 0, 0) : new Vector(0, 0, 1)) : (y < z ? new Vector(0, 1, 0) : new Vector(0, 0, 1));
				return v.cross(other);
			}

			var u = v1.normalized();
			var v = v2.normalized();
			if (u.multiply(-1).equals(v)) {
				var q = new Quat();
				var o = orthogonal(u).normalized();
				q.x = o.x;
				q.y = o.y;
				q.z = o.z;
				q.w = 0;
				return q;
			}
			var half = u.add(v).normalized();
			var q = new Quat();
			q.w = u.dot(half);
			var vr = u.cross(half);
			q.x = vr.x;
			q.y = vr.y;
			q.z = vr.z;
			return q;
		}

		var quatChange = getRotQuat(oldUp, vec);
		// Instead of calculating the new quat from nothing, calculate it from the last one to guarantee the shortest possible rotation.
		// quatChange.initMoveTo(oldUp, vec);
		quatChange.multiply(quatChange, currentQuat);

		this.newOrientationQuat = quatChange;
		this.oldOrientationQuat = currentQuat;
		this.orientationChangeTime = time;
	}
}
