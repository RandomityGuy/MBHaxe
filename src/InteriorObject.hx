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

	public function new() {
		super();
	}

	public function init(level:MarbleWorld) {
		this.identifier = this.interiorFile;
		DifBuilder.loadDif(this.interiorFile, cast this);
	}

	public override function setTransform(transform:Matrix) {
		super.setTransform(transform);
		collider.setTransform(transform);
	}
}
