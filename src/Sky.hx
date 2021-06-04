package src;

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
		var sky = new h3d.prim.Sphere(300, 128, 128);
		sky.addNormals();
		var skyMesh = new h3d.scene.Mesh(sky, this);
		skyMesh.material.mainPass.culling = Front;
		skyMesh.material.mainPass.addShader(new h3d.shader.CubeMap(texture));
		skyMesh.material.shadows = false;
		skyMesh.culled = false;
	}

	function createSkyboxCubeTextured(dmlPath:String) {
		if (ResourceLoader.fileSystem.exists(dmlPath)) {
			var dmlFile = File.getContent(dmlPath);
			var dmlDirectory = Path.directory(dmlPath);
			var lines = dmlFile.split('\n').map(x -> x.toLowerCase());
			var skyboxImages = [];

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

			Util.rotateImage(skyboxImages[0], Math.PI / 2);

			var cubemaptexture = new Texture(maxheight, maxwidth, [Cube]);
			for (i in 0...6) {
				cubemaptexture.uploadBitmap(skyboxImages[skyboxIndices[i]], 0, i);
			}
			return cubemaptexture;
		}
		return null;
	}
}
