package src;

import h3d.scene.pbr.Environment;
import src.Util;
import src.MarbleWorld;
import hxd.BitmapData;
import h3d.shader.CubeMap;
import h3d.mat.Texture;
import haxe.io.Path;
import sys.io.File;
import src.ResourceLoader;
import h3d.scene.Object;

class Sky extends Object {
	public var dmlPath:String;

	public function new() {
		super();
	}

	public function init(level:MarbleWorld) {
		var texture = createSkyboxCubeTextured(this.dmlPath);
		var sky = new h3d.prim.Sphere(1, 128, 128);
		sky.addNormals();
		sky.addUVs();
		var skyMesh = new h3d.scene.Mesh(sky, this);
		skyMesh.material.mainPass.culling = Front;
		skyMesh.material.mainPass.setPassName("overlay");
		skyMesh.scale(200);
		var env = new Environment(texture);
		env.compute();
		var renderer = cast(level.scene.renderer, h3d.scene.pbr.Renderer);
		// renderer.env = env;
		skyMesh.material.mainPass.addShader(new h3d.shader.pbr.CubeLod(texture));
		skyMesh.material.shadows = false;
	}

	function createSkyboxCubeTextured(dmlPath:String) {
		if (ResourceLoader.fileSystem.exists(dmlPath)) {
			var dmlFile = File.getContent(dmlPath);
			var dmlDirectory = Path.directory(dmlPath);
			var lines = dmlFile.split('\n').map(x -> x.toLowerCase());
			var skyboxImages = [];

			// 5: bottom, to be rotated/flipped
			// 0: front
			var skyboxIndices = [3, 1, 2, 0, 4, 5];

			for (i in 0...6) {
				var line = lines[i];
				var filenames = ResourceLoader.getFullNamesOf(dmlDirectory + '/' + line);
				if (filenames.length == 0) {
					skyboxImages.push(new BitmapData(128, 128));
				} else {
					var image = ResourceLoader.getImage(filenames[0]).toBitmap();
					skyboxImages.push(image);
				}
			}
			var maxwidth = 0;
			var maxheight = 0;
			for (texture in skyboxImages) {
				if (texture.height > maxheight)
					maxheight = texture.height;
				if (texture.width > maxwidth)
					maxwidth = texture.width;
			}

			Util.flipImage(skyboxImages[0], true, false);
			Util.flipImage(skyboxImages[4], true, false);
			Util.rotateImage(skyboxImages[5], Math.PI);
			Util.flipImage(skyboxImages[5], true, false);
			Util.rotateImage(skyboxImages[1], -Math.PI / 2);
			Util.flipImage(skyboxImages[1], true, false);
			Util.rotateImage(skyboxImages[2], Math.PI);
			Util.flipImage(skyboxImages[2], true, false);
			Util.rotateImage(skyboxImages[3], Math.PI / 2);
			Util.flipImage(skyboxImages[3], true, false);

			var cubemaptexture = new Texture(maxheight, maxwidth, [Cube]);
			for (i in 0...6) {
				cubemaptexture.uploadBitmap(skyboxImages[skyboxIndices[i]], 0, i);
			}
			return cubemaptexture;
		}
		return null;
	}
}
