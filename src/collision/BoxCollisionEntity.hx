package collision;

import collision.BVHTree.IBVHObject;
import src.MarbleGame;
import src.TimeState;
import h3d.Matrix;
import src.GameObject;
import src.Marble;
import h3d.col.Ray;
import h3d.Vector;
import h3d.col.Sphere;
import h3d.col.Bounds;
import src.Debug;

class BoxCollisionEntity extends CollisionEntity implements IBVHObject {
	var bounds:Bounds;

	public function new(bounds:Bounds, go:GameObject) {
		super(go);
		this.bounds = bounds;
		this.generateBoundingBox();
	}

	public override function generateBoundingBox() {
		this.boundingBox = bounds.clone();
		this.boundingBox.transform(this.transform);
		if (Debug.drawBounds) {
			if (_dbgEntity == null) {
				_dbgEntity = cast this.boundingBox.makeDebugObj();
				_dbgEntity.getMaterials()[0].mainPass.wireframe = true;
				MarbleGame.instance.scene.addChild(_dbgEntity);
			} else {
				_dbgEntity = cast this.boundingBox.makeDebugObj();
				_dbgEntity.getMaterials()[0].mainPass.wireframe = true;
				MarbleGame.instance.scene.addChild(_dbgEntity);
			}
		}
	}

	public override function setTransform(transform:Matrix) {
		super.setTransform(transform);
		if (Debug.drawBounds) {
			if (_dbgEntity != null) {
				_dbgEntity = cast this.boundingBox.makeDebugObj();
				_dbgEntity.getMaterials()[0].mainPass.wireframe = true;
				MarbleGame.instance.scene.addChild(_dbgEntity);
			}
		}
	}

	public override function rayCast(rayOrigin:Vector, rayDirection:Vector, results:Array<octree.IOctreeObject.RayIntersectionData>) {
		// TEMP cause bruh
	}

	public override function sphereIntersection(collisionEntity:SphereCollisionEntity, timeState:TimeState) {
		return [];
	}
}
