package;

import gui.MainMenuGui;
import hxd.res.DefaultFont;
import h2d.Text;
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

	var mmg:MainMenuGui;

	var fpsCounter:Text;

	override function init() {
		super.init();

		var ltr = File.getContent("data/missions/advanced/airwalk.mis");
		var mfp = new MisParser(ltr);
		var mis = mfp.parse();

		var mission = new Mission();
		mission.root = mis.root;

		mmg = new MainMenuGui();
		mmg.init(s2d);

		// world = new MarbleWorld(s3d, s2d, mission);

		// world.init();
		// world.start();

		fpsCounter = new Text(DefaultFont.get(), s2d);
		fpsCounter.y = 40;
		fpsCounter.color = new Vector(1, 1, 1, 1);
	}

	override function update(dt:Float) {
		super.update(dt);
		mmg.update(dt);
		// world.update(dt);
		fpsCounter.text = 'FPS: ${this.engine.fps}';
	}

	override function render(e:h3d.Engine) {
		// this.world.render(e);
		super.render(e);
	}

	static function main() {
		h3d.mat.PbrMaterialSetup.set();
		new Main();
	}
}
