package src;

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

	public var currentTime:Float = 0;

	var scene:Scene;

	public function new(scene:Scene) {
		this.collisionWorld = new CollisionWorld();
		this.scene = scene;
		this.instanceManager = new InstanceManager(scene);
	}

	public function addInterior(obj:InteriorObject) {
		this.interiors.push(obj);
		this.collisionWorld.addEntity(obj.collider);
		this.scene.addChild(obj);
	}

	public function addPathedInterior(obj:PathedInterior) {
		this.pathedInteriors.push(obj);
		this.collisionWorld.addMovingEntity(obj.collider);
		this.scene.addChild(obj);
		obj.init();
	}

	public function addDtsObject(obj:DtsObject) {
		this.dtsObjects.push(obj);
		obj.init(cast this);
		if (obj.useInstancing) {
			this.instanceManager.addObject(obj);
		} else
			this.scene.addChild(obj);
		// this.instanceManager.addObject(obj);
		for (collider in obj.colliders) {
			if (collider != null)
				this.collisionWorld.addEntity(collider);
		}
	}

	public function addMarble(marble:Marble) {
		this.marbles.push(marble);
		marble.level = cast this;
		if (marble.controllable) {
			this.scene.addChild(marble.camera);
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
	}
}
