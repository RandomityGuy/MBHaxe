package src;

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

	public function new() {
		super();
		this.isCollideable = true;
	}

	public function init(level:MarbleWorld, onFinish:Void->Void) {
		this.identifier = this.interiorFile;
		this.level = level;
		DifBuilder.loadDif(this.interiorFile, cast this, onFinish);
	}

	public override function setTransform(transform:Matrix) {
		super.setTransform(transform);
		collider.setTransform(transform);
		this.level.collisionWorld.updateTransform(this.collider);
	}
}
