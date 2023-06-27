package src;

import collision.CollisionWorld;
import src.MarbleWorld;
import src.DifBuilder;
import h3d.Matrix;
import collision.CollisionEntity;
import src.GameObject;
import h3d.scene.Object;

class InteriorObject extends GameObject {
	public var collider:CollisionEntity;
	public var interiorFile:String;
	public var useInstancing = true;
	public var level:MarbleWorld;
	public var collisionWorld:CollisionWorld;

	public function new() {
		super();
		this.isCollideable = true;
	}

	public function init(level:MarbleWorld, onFinish:Void->Void) {
		this.identifier = this.interiorFile;
		this.level = level;
		if (this.level != null)
			this.collisionWorld = this.level.collisionWorld;
		DifBuilder.loadDif(this.interiorFile, cast this, onFinish, -1, this.isCollideable);
	}

	public override function setTransform(transform:Matrix) {
		super.setTransform(transform);
		if (this.isCollideable) {
			collider.setTransform(transform);
			collisionWorld.updateTransform(this.collider);
		}
	}
}
