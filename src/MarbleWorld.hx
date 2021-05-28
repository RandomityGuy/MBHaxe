package src;

import hxd.Key;
import h3d.Vector;
import src.InteriorGeometry;
import h3d.scene.Scene;
import h3d.scene.CustomObject;
import collision.CollisionWorld;
import src.Marble;

class MarbleWorld {
	var collisionWorld:CollisionWorld;

	public var interiors:Array<InteriorGeometry> = [];
	public var marbles:Array<Marble> = [];

	var scene:Scene;

	public function new(scene:Scene) {
		this.collisionWorld = new CollisionWorld();
		this.scene = scene;
	}

	public function addInterior(obj:InteriorGeometry) {
		this.interiors.push(obj);
		this.collisionWorld.addEntity(obj.collider);
		this.scene.addChild(obj);
	}

	public function addMarble(marble:Marble) {
		this.marbles.push(marble);
		if (marble.controllable) {
			this.scene.addChild(marble.camera);
		}
		this.collisionWorld.addMovingEntity(marble.collider);
		this.scene.addChild(marble);
	}

	public function update(dt:Float) {
		for (marble in marbles) {
			marble.update(dt, collisionWorld);
		}
	}
}
