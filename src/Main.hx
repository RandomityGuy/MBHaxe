package;

import src.Mission;
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

		var ltr = File.getContent("data/missions/beginner/finale.mis");
		var mfp = new MisParser(ltr);
		var mis = mfp.parse();

		var mission = new Mission();
		mission.root = mis.root;

		world = new MarbleWorld(s3d, s2d, mission);

		var dirlight = new DirLight(new Vector(0.5, 0.5, -0.5), s3d);
		dirlight.enableSpecular = true;
		s3d.lightSystem.ambientLight.set(0.3, 0.3, 0.3);

		world.init();

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
