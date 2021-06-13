package src;

import src.GameObject;
import triggers.Trigger;
import src.Mission;
import src.TimeState;
import gui.PlayGui;
import src.ParticleSystem.ParticleManager;
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

class MarbleWorld extends Scheduler {
	public var collisionWorld:CollisionWorld;
	public var instanceManager:InstanceManager;
	public var particleManager:ParticleManager;

	var playGui:PlayGui;

	public var interiors:Array<InteriorObject> = [];
	public var pathedInteriors:Array<PathedInterior> = [];
	public var marbles:Array<Marble> = [];
	public var dtsObjects:Array<DtsObject> = [];

	var shapeImmunity:Array<DtsObject> = [];
	var shapeOrTriggerInside:Array<GameObject> = [];

	public var timeState:TimeState = new TimeState();
	public var bonusTime:Float = 0;
	public var sky:Sky;

	public var scene:Scene;
	public var mission:Mission;

	public var marble:Marble;
	public var worldOrientation:Quat;
	public var currentUp = new Vector(0, 0, 1);
	public var outOfBounds:Bool = false;
	public var outOfBoundsTime:TimeState;
	public var finishTime:TimeState;

	var helpTextTimeState:Float = -1e8;
	var alertTextTimeState:Float = -1e8;

	var orientationChangeTime = -1e8;
	var oldOrientationQuat = new Quat();

	/** The new target camera orientation quat  */
	public var newOrientationQuat = new Quat();

	public function new(scene:Scene, scene2d:h2d.Scene) {
		this.collisionWorld = new CollisionWorld();
		this.scene = scene;
		this.playGui = new PlayGui();
		this.instanceManager = new InstanceManager(scene);
		this.particleManager = new ParticleManager(cast this);
		this.sky = new Sky();
		sky.dmlPath = "data/skies/sky_day.dml";
		sky.init(cast this);
		playGui.init(scene2d);
		scene.addChild(sky);
	}

	public function start() {
		restart();
		for (interior in this.interiors)
			interior.onLevelStart();
		for (shape in this.dtsObjects)
			shape.onLevelStart();
	}

	public function restart() {
		this.timeState.currentAttemptTime = 0;
		this.timeState.gameplayClock = 0;
		this.bonusTime = 0;
		this.outOfBounds = false;
		this.marble.camera.CameraPitch = 0.45;

		for (shape in dtsObjects)
			shape.reset();
		for (interior in this.interiors)
			interior.reset();

		this.currentUp = new Vector(0, 0, 1);
		this.orientationChangeTime = -1e8;
		this.oldOrientationQuat = new Quat();
		this.newOrientationQuat = new Quat();
		this.deselectPowerUp();

		this.clearSchedule();
	}

	public function updateGameState() {
		if (this.timeState.currentAttemptTime < 0.5) {
			this.playGui.setCenterText('none');
		}
		if ((this.timeState.currentAttemptTime >= 0.5) && (this.timeState.currentAttemptTime < 2)) {
			this.playGui.setCenterText('ready');
		}
		if ((this.timeState.currentAttemptTime >= 2) && (this.timeState.currentAttemptTime < 3.5)) {
			this.playGui.setCenterText('set');
		}
		if ((this.timeState.currentAttemptTime >= 3.5) && (this.timeState.currentAttemptTime < 5.5)) {
			this.playGui.setCenterText('go');
		}
		if (this.timeState.currentAttemptTime >= 5.5) {
			this.playGui.setCenterText('none');
		}
		if (this.outOfBounds) {
			this.playGui.setCenterText('outofbounds');
		}
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
		this.updateTimer(dt);
		this.tickSchedule(timeState.currentAttemptTime);
		this.updateGameState();
		for (obj in dtsObjects) {
			obj.update(timeState);
		}
		for (marble in marbles) {
			marble.update(timeState, collisionWorld, this.pathedInteriors);
		}
		this.instanceManager.update(dt);
		this.particleManager.update(1000 * timeState.timeSinceLoad, dt);
		this.playGui.update(timeState);

		if (this.marble != null) {
			callCollisionHandlers(marble);
		}
		this.updateTexts();
	}

	public function render(e:h3d.Engine) {
		this.playGui.render(e);
	}

	public function updateTimer(dt:Float) {
		this.timeState.dt = dt;
		this.timeState.currentAttemptTime += dt;
		this.timeState.timeSinceLoad += dt;
		if (this.bonusTime != 0) {
			this.bonusTime -= dt;
			if (this.bonusTime < 0) {
				this.timeState.gameplayClock -= this.bonusTime;
				this.bonusTime = 0;
			}
		} else {
			this.timeState.gameplayClock += dt;
		}
		playGui.formatTimer(this.timeState.gameplayClock);
	}

	function updateTexts() {
		var helpTextTime = this.helpTextTimeState;
		var alertTextTime = this.alertTextTimeState;
		var helpTextCompletion = Math.pow(Util.clamp((this.timeState.currentAttemptTime - helpTextTime - 3), 0, 1), 2);
		var alertTextCompletion = Math.pow(Util.clamp((this.timeState.currentAttemptTime - alertTextTime - 3), 0, 1), 2);
		this.playGui.setHelpTextOpacity(1 - helpTextCompletion);
		this.playGui.setAlertTextOpacity(1 - alertTextCompletion);
	}

	public function displayAlert(text:String) {
		this.playGui.setAlertText(text);
		this.alertTextTimeState = this.timeState.currentAttemptTime;
	}

	public function displayHelp(text:String) {
		this.playGui.setHelpText(text);
		this.helpTextTimeState = this.timeState.currentAttemptTime;

		// TODO FIX
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

					var contacttest = shape.colliders.filter(x -> x != null).map(x -> x.sphereIntersection(contactsphere, timeState));
					var contactlist:Array<collision.CollisionInfo> = [];
					for (l in contacttest) {
						contactlist = contactlist.concat(l);
					}

					if (!calledShapes.contains(shape) && !this.shapeImmunity.contains(shape) && contactlist.length != 0) {
						calledShapes.push(shape);
						newImmunity.push(shape);
						shape.onMarbleContact(timeState);
					}

					shape.onMarbleInside(timeState);
					if (!this.shapeOrTriggerInside.contains(contact.go)) {
						this.shapeOrTriggerInside.push(contact.go);
						shape.onMarbleEnter(timeState);
					}
					inside.push(contact.go);
				}
				if (contact.go is Trigger) {
					var trigger:Trigger = cast contact.go;
					var contacttest = trigger.collider.sphereIntersection(contactsphere, timeState);
					if (contacttest.length != 0) {
						trigger.onMarbleContact(timeState);
					}

					trigger.onMarbleInside(timeState);
					if (!this.shapeOrTriggerInside.contains(contact.go)) {
						this.shapeOrTriggerInside.push(contact.go);
						trigger.onMarbleEnter(timeState);
					}
					inside.push(contact.go);
				}
			}
		}

		for (object in shapeOrTriggerInside) {
			if (!inside.contains(object)) {
				this.shapeOrTriggerInside.remove(object);
				object.onMarbleLeave(timeState);
			}
		}

		this.shapeImmunity = newImmunity;
	}

	public function pickUpPowerUp(powerUp:PowerUp) {
		if (this.marble.heldPowerup == powerUp)
			return false;
		this.marble.heldPowerup = powerUp;
		this.playGui.setPowerupImage(powerUp.identifier);
		return true;
	}

	public function deselectPowerUp() {
		this.playGui.setPowerupImage("");
	}

	/** Get the current interpolated orientation quaternion. */
	public function getOrientationQuat(time:Float) {
		var completion = Util.clamp((time - this.orientationChangeTime) / 0.3, 0, 1);
		var q = this.oldOrientationQuat.clone();
		q.slerp(q, this.newOrientationQuat, completion);
		return q;
	}

	public function setUp(vec:Vector, timeState:TimeState) {
		this.currentUp = vec;
		var currentQuat = this.getOrientationQuat(timeState.currentAttemptTime);
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
		this.orientationChangeTime = timeState.currentAttemptTime;
	}

	public function goOutOfBounds() {
		if (this.outOfBounds || this.finishTime != null)
			return;
		// this.updateCamera(this.timeState); // Update the camera at the point of OOB-ing
		this.outOfBounds = true;
		this.outOfBoundsTime = this.timeState.clone();
		// this.oobCameraPosition = camera.position.clone();
		playGui.setCenterText('outofbounds');
		// AudioManager.play('whoosh.wav');
		// if (this.replay.mode != = 'playback')
		this.schedule(this.timeState.currentAttemptTime + 2, () -> this.restart());
	}
}

typedef ScheduleInfo = {
	var id:Float;
	var stringId:String;
	var time:Float;
	var callBack:Void->Any;
}

abstract class Scheduler {
	var scheduled:Array<ScheduleInfo> = [];

	public function tickSchedule(time:Float) {
		for (item in this.scheduled) {
			if (time >= item.time) {
				this.scheduled.remove(item);
				item.callBack();
			}
		}
	}

	public function schedule(time:Float, callback:Void->Any, stringId:String = null) {
		var id = Math.random();
		this.scheduled.push({
			id: id,
			stringId: '${id}',
			time: time,
			callBack: callback
		});
		return id;
	}

	/** Cancels a schedule */
	public function cancel(id:Float) {
		var idx = this.scheduled.filter((val) -> {
			return val.id == id;
		});
		if (idx.length == 0)
			return;
		this.scheduled.remove(idx[0]);
	}

	public function clearSchedule() {
		this.scheduled = [];
	}

	public function clearScheduleId(id:String) {
		var idx = this.scheduled.filter((val) -> {
			return val.stringId == id;
		});
		if (idx.length == 0)
			return;
		this.scheduled.remove(idx[0]);
	}
}
