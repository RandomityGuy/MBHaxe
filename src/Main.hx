package;

import mis.MisParser;
import sys.io.File;
import shapes.EndPad;
import shapes.LandMine;
import shapes.StartPad;
import shapes.TriangleBumper;
import shapes.RoundBumper;
import shapes.Oilslick;
import gui.PlayGui;
import shapes.Helicopter;
import shapes.ShockAbsorber;
import shapes.SuperBounce;
import shapes.SuperSpeed;
import shapes.SignFinish;
import shapes.Trapdoor;
import shapes.AntiGravity;
import shapes.SuperJump;
import h3d.prim.Polygon;
import src.ResourceLoader;
import src.GameObject;
import shapes.Tornado;
import shapes.DuctFan;
import dts.DtsFile;
import src.InteriorObject;
import h3d.Quat;
import src.PathedInteriorMarker;
import src.PathedInterior;
import src.MarbleWorld;
import collision.CollisionWorld;
import src.Marble;
import src.DifBuilder;
import h3d.Vector;
import h3d.scene.fwd.DirLight;
import h3d.mat.Material;
import h3d.prim.Cube;
import h3d.scene.*;
import src.DtsObject;

class Main extends hxd.App {
	var scene:Scene;

	var world:MarbleWorld;
	var dtsObj:DtsObject;

	override function init() {
		super.init();

		dtsObj = new SuperSpeed();
		dtsObj.x = -3;

		world = new MarbleWorld(s3d, s2d);

		var db = new InteriorObject();
		db.interiorFile = "data/interiors/beginner/beginner_finish.dif";
		world.addInterior(db);
		var tform = db.getTransform();
		tform.setPosition(new Vector(0, 0, 0));
		db.setTransform(tform);

		var ltr = File.getContent("data/missions/beginner/finale.mis");
		var mfp = new MisParser(ltr);
		var mis = mfp.parse();

		// var pi = new PathedInterior();
		// DifBuilder.loadDif("data/interiors/addon/smallplatform.dif", loader, pi);
		// var pim = pi.getTransform();
		// pim.setPosition(new Vector(5, 0, 0));
		// pi.setTransform(pim);

		// var cube = new Polygon([new h3d.col.Point(0, 0, 0), new h3d.col.Point(0, 0, 1), new h3d.col.Point(0, 1, 0)]);
		// cube.addNormals();
		// cube.addUVs();
		// var tex = ResourceLoader.loader.load("data/interiors/arrow_cool1.jpg").toTexture();
		// var mat = Material.create(tex);
		// var mesh = new Mesh(cube, mat);
		// var go = new GameObject();
		// go.identifier = "lol";
		// go.addChild(mesh);
		// world.instanceManager.addObject(go);

		// var m1 = new PathedInteriorMarker();
		// m1.msToNext = 5;
		// m1.position = new Vector(0, 0, 0);
		// m1.smoothingType = "";
		// m1.rotation = new Quat();

		// var m2 = new PathedInteriorMarker();
		// m2.msToNext = 3;
		// m2.position = new Vector(0, 0, 5);
		// m2.smoothingType = "";
		// m2.rotation = new Quat();

		// var m3 = new PathedInteriorMarker();
		// m3.msToNext = 5;
		// m3.position = new Vector(0, 0, 0);
		// m3.smoothingType = "";
		// m3.rotation = new Quat();

		// pi.markerData = [m1, m2, m3];

		// world.addPathedInterior(pi);

		world.addDtsObject(dtsObj);

		var sj = new SuperJump();
		sj.x = 3;
		world.addDtsObject(sj);

		var sj2 = new SuperJump();
		sj2.x = 3;
		sj2.z = 2;
		world.addDtsObject(sj2);

		var sb = new SuperBounce();
		sb.y = 3;
		world.addDtsObject(sb);

		var sh = new ShockAbsorber();
		sh.y = -3;
		world.addDtsObject(sh);

		var he = new Helicopter();
		world.addDtsObject(he);
		sj.setTransform(sj.getTransform());

		var ag = new AntiGravity();
		ag.y = 6;
		world.addDtsObject(ag);

		var os = new Oilslick();
		os.x = 5;
		os.z = 0.1;
		world.addDtsObject(os);

		var tdoor = new Trapdoor();
		tdoor.x = -5;
		tdoor.z = 1;
		world.addDtsObject(tdoor);

		var rb = new RoundBumper();
		rb.x = -5;
		rb.y = 2;
		world.addDtsObject(rb);

		var tb = new TriangleBumper();
		tb.x = -5;
		tb.y = 4;
		world.addDtsObject(tb);

		var spad = new StartPad();
		spad.x = 5;
		spad.y = 3;
		world.addDtsObject(spad);

		var lm = new LandMine();
		lm.x = 7;
		world.addDtsObject(lm);

		var epad = new EndPad();
		epad.x = 5;
		epad.x = -3;
		world.addDtsObject(epad);

		// var le:ParticleEmitterOptions = {

		// 	ejectionPeriod: 0.01,
		// 	ambientVelocity: new Vector(0, 0, 0),
		// 	ejectionVelocity: 0.5,
		// 	velocityVariance: 0.25,
		// 	emitterLifetime: 1e8,
		// 	inheritedVelFactor: 0.2,
		// 	particleOptions: {
		// 		texture: 'particles/smoke.png',
		// 		blending: Add,
		// 		spinSpeed: 40,
		// 		spinRandomMin: -90,
		// 		spinRandomMax: 90,
		// 		lifetime: 1,
		// 		lifetimeVariance: 0.15,
		// 		dragCoefficient: 0.8,
		// 		acceleration: 0,
		// 		colors: [new Vector(0.56, 0.36, 0.26, 1), new Vector(0.56, 0.36, 0.26, 0)],
		// 		sizes: [0.5, 1],
		// 		times: [0, 1]
		// 	}
		// };

		// var p1 = new ParticleData();
		// p1.identifier = "testparticle";
		// p1.texture = ResourceLoader.getTexture("data/particles/smoke.png");

		// // var emitter = new ParticleEmitter(le, p1, world.particleManager); // var p = new Particle();
		// world.particleManager.createEmitter(le, p1, new Vector());

		// p.position = new Vector();
		// p.color = new Vector(255, 255, 255);
		// p.rotation = Math.PI;
		// p.scale = 5;

		// world.particleManager.addParticle(p1, p);

		// for (i in 0...10) {

		// 	for (j in 0...10) {
		// 		var trapdoor = new Tornado();
		// 		trapdoor.x = i * 2;
		// 		trapdoor.y = j * 2;
		// 		world.addDtsObject(trapdoor);
		// 	}
		// }

		// for (surf in db.collider.surfaces) {
		// 	var surfmin = new CustomObject(cube, mat, s3d);
		// 	var bound = surf.boundingBox;
		// 	surfmin.setPosition(bound.xMin, bound.yMin, bound.zMin);

		// 	var surfmax = new CustomObject(cube, mat, s3d);
		// 	surfmax.setPosition(bound.xMax, bound.yMax, bound.zMax);
		// }

		// var mat = Material.create();
		// var so = new CustomObject(cube, mat);
		// so.setPosition(0, 0, 0);
		// s3d.addChild(so);

		var dirlight = new DirLight(new Vector(0.5, 0.5, -0.5), s3d);
		dirlight.enableSpecular = true;
		s3d.lightSystem.ambientLight.set(0.3, 0.3, 0.3);

		// s3d.camera.

		var marble = new Marble();
		marble.controllable = true;
		world.addMarble(marble);
		marble.setPosition(5, 0, 5);

		// var marble2 = new Marble();
		// world.addMarble(marble2);
		// marble2.setPosition(5, 0, 5);
		// marble.setPosition(-10, -5, 5);
	}

	override function update(dt:Float) {
		super.update(dt);
		world.update(dt);
	}

	override function render(e:h3d.Engine) {
		this.world.render(e);
		super.render(e);
	}

	static function main() {
		h3d.mat.PbrMaterialSetup.set();
		new Main();
	}
}
