package collision;

import src.MarbleGame;
import src.TimeState;
import h3d.Matrix;
import src.GameObject;
import src.Marble;
import h3d.col.Ray;
import h3d.Vector;
import h3d.col.Sphere;
import h3d.col.Bounds;

class BoxCollisionEntity extends CollisionEntity {
	var bounds:Bounds;

	var _dbgEntity:h3d.scene.Mesh;

	public function new(bounds:Bounds, go:GameObject) {
		super(go);
		this.bounds = bounds;
		this.generateBoundingBox();
	}

	public override function generateBoundingBox() {
		this.boundingBox = bounds.clone();
		this.boundingBox.transform(this.transform);
		// if (_dbgEntity == null) {
		// 	var cube = new h3d.prim.Cube(this.boundingBox.xSize, this.boundingBox.ySize, this.boundingBox.zSize, true);
		// 	cube.addNormals();
		// 	cube.addUVs();
		// 	_dbgEntity = new h3d.scene.Mesh(cube);
		// 	_dbgEntity.material.mainPass.wireframe = true;
		// 	_dbgEntity.setTransform(transform);
		// 	MarbleGame.instance.scene.addChild(_dbgEntity);
		// } else {
		// 	_dbgEntity.setTransform(transform);
		// }
	}

	public override function setTransform(transform:Matrix) {
		super.setTransform(transform);
		// if (_dbgEntity != null) {
		// 	_dbgEntity.setTransform(transform);
		// }
	}

	public override function rayCast(rayOrigin:Vector, rayDirection:Vector) {
		// TEMP cause bruh
		return [];
	}

	public override function sphereIntersection(collisionEntity:SphereCollisionEntity, timeState:TimeState) {
		return [];
	}
}
