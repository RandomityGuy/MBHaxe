package;

import src.MarbleWorld;
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

	var world:MarbleWorld;

	override function init() {
		super.init();

		this.fileSystem = new LocalFileSystem(".", null);

		var loader = new Loader(fileSystem);

		world = new MarbleWorld(s3d);

		var db = DifBuilder.loadDif("interiors/beginner/beginner_finish.dif", loader);
		world.addInterior(db);

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

		var marble2 = new Marble();
		world.addMarble(marble2);
		marble2.setPosition(0, 5, 5);

		var marble = new Marble();
		marble.controllable = true;
		world.addMarble(marble);
		marble.setPosition(0, 0, 5);
		// marble.setPosition(-10, -5, 5);
	}

	override function update(dt:Float) {
		super.update(dt);
		world.update(dt);
	}

	static function main() {
		new Main();
	}
}
