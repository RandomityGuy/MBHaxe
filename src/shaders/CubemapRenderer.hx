package shaders;

import h3d.Vector;
import h3d.scene.Scene;
import h3d.Engine;
import h3d.Camera;
import h3d.mat.Texture;

class CubemapRenderer {
	public var cubemap:Texture;

	public var position:Vector;

	var camera:Camera;

	var scene:Scene;

	var nextFaceToRender:Int;

	public function new(scene:Scene) {
		this.scene = scene;
		this.cubemap = new Texture(128, 128, [Cube, Dynamic, Target]);
		this.camera = new Camera(90, 1, 1, 0.02, 100);
		this.position = new Vector();
		this.nextFaceToRender = 0;
	}

	public function render(e:Engine, budget:Float = 1e8) {
		var scenecam = scene.camera;
		scene.camera = camera;

		var start = haxe.Timer.stamp();
		var renderedFaces = 0;

		for (i in 0...6) {
			var index = (nextFaceToRender + i) % 6;

			e.pushTarget(cubemap, index);
			this.camera.setCubeMap(index, position);
			e.clear(0, 1);
			scene.render(e);
			e.popTarget();

			renderedFaces++;
			var time = haxe.Timer.stamp();
			var elapsed = time - start;
			var elapsedPerFace = elapsed / renderedFaces;

			if (elapsedPerFace * (renderedFaces + 1) >= budget)
				break;
		}
		scene.camera = scenecam;

		this.nextFaceToRender += renderedFaces;
		this.nextFaceToRender %= 6;
	}
}
