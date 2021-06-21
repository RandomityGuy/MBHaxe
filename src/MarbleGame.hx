package src;

import gui.ExitGameDlg;
import hxd.Key;
import src.Mission;
import h3d.Vector;
import gui.GuiControl.MouseState;
import hxd.Window;
import src.MarbleWorld;
import gui.Canvas;

@:publicFields
class MarbleGame {
	var canvas:Canvas;
	var world:MarbleWorld;

	var scene2d:h2d.Scene;
	var scene:h3d.scene.Scene;

	var paused:Bool;

	var exitGameDlg:ExitGameDlg;

	public function new(scene2d:h2d.Scene, scene:h3d.scene.Scene) {
		this.canvas = new Canvas(scene2d, cast this);
		this.scene = scene;
		this.scene2d = scene2d;
	}

	public function update(dt:Float) {
		if (world != null) {
			if (!paused) {
				world.update(dt);
			}
			if (Key.isPressed(Key.ESCAPE)) {
				paused = !paused;
				if (paused) {
					exitGameDlg = new ExitGameDlg();
					canvas.pushDialog(exitGameDlg);
				} else {
					canvas.popDialog(exitGameDlg);
				}
			}
		}
		if (canvas != null) {
			var wnd = Window.getInstance();
			var mouseState:MouseState = {
				position: new Vector(wnd.mouseX, wnd.mouseY)
			}
			canvas.update(dt, mouseState);
		}
	}

	public function playMission(mission:Mission) {
		this.canvas.clearContent();
		mission.load();
		world = new MarbleWorld(scene, scene2d, mission);
		world.init();
		world.start();
	}

	public function render(e:h3d.Engine) {
		if (world != null)
			world.render(e);
	}
}
