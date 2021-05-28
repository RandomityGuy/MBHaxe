package;

import collision.CollisionWorld;
import src.Marble;
import hxd.res.Loader;
import hxd.fs.LocalFileSystem;
import hxd.fs.FileSystem;
import src.DifBuilder;
import h3d.Vector;
import h3d.scene.fwd.DirLight;
import h3d.mat.Material;
import h3d.prim.Cube;
import h3d.scene.*;

class Main extends hxd.App {
	var scene:Scene;
	var fileSystem:FileSystem;

	var marble:Marble;
	var marble2:Marble;
	var collisionWorld:CollisionWorld;

	override function init() {
		super.init();

		this.fileSystem = new LocalFileSystem(".", null);

		var loader = new Loader(fileSystem);

		var cube = new Cube();
		cube.addUVs();
		cube.addNormals();

		this.collisionWorld = new CollisionWorld();

		var db = DifBuilder.loadDif("interiors/beginner/beginner_finish.dif", loader);
		collisionWorld.addEntity(db.collider);

		var mat = Material.create();
		var difbounds = new CustomObject(cube, mat, s3d);
		var bound = db.collider.boundingBox;
		var oct = collisionWorld.octree;
		difbounds.setPosition(oct.root.min.x, oct.root.min.y, oct.root.min.z);

		var difbounds2 = new CustomObject(cube, mat, s3d);
		difbounds2.setPosition(oct.root.min.x + oct.root.size, oct.root.min.y + oct.root.size, oct.root.min.z + oct.root.size);

		var difbounds3 = new CustomObject(cube, mat, s3d);
		difbounds3.setPosition(bound.xMin, bound.yMin, bound.zMin);
		var difbounds4 = new CustomObject(cube, mat, s3d);
		difbounds4.setPosition(bound.xMax, bound.yMax, bound.zMax);

		// for (surf in db.collider.surfaces) {
		// 	var surfmin = new CustomObject(cube, mat, s3d);
		// 	var bound = surf.boundingBox;
		// 	surfmin.setPosition(bound.xMin, bound.yMin, bound.zMin);

		// 	var surfmax = new CustomObject(cube, mat, s3d);
		// 	surfmax.setPosition(bound.xMax, bound.yMax, bound.zMax);
		// }

		s3d.addChild(db);

		// var mat = Material.create();
		// var so = new CustomObject(cube, mat);
		// so.setPosition(0, 0, 0);
		// s3d.addChild(so);

		var dirlight = new DirLight(new Vector(0.5, 0.5, -0.5), s3d);
		dirlight.enableSpecular = true;
		s3d.lightSystem.ambientLight.set(0.3, 0.3, 0.3);

		// s3d.camera.

		marble = new Marble();
		marble.controllable = true;
		s3d.addChild(marble);
		marble.setPosition(0, 0, 5);

		marble2 = new Marble();
		s3d.addChild(marble2);
		marble2.setPosition(0, 5, 5);
		// marble.setPosition(-10, -5, 5);
		s3d.addChild(marble.camera);

		collisionWorld.addMovingEntity(marble.collider);
		collisionWorld.addMovingEntity(marble2.collider);
	}

	override function update(dt:Float) {
		super.update(dt);
		marble.update(dt, this.collisionWorld);
		marble2.update(dt, this.collisionWorld);
	}

	static function main() {
		new Main();
	}
}
