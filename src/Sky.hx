package src;

import hxd.Pixels;
import shaders.Skybox;
import h3d.shader.pbr.PropsValues;
import h3d.shader.AmbientLight;
import h3d.scene.pbr.Environment;
import src.Util;
import src.MarbleWorld;
import hxd.BitmapData;
import h3d.shader.CubeMap;
import h3d.mat.Texture;
import haxe.io.Path;
import src.ResourceLoader;
import h3d.scene.Object;
import src.Resource;
import hxd.res.Image;
import src.ResourceLoaderWorker;

class Sky extends Object {
	public var dmlPath:String;

	var imageResources:Array<Resource<Image>> = [];

	public function new() {
		super();
	}

	public function init(level:MarbleWorld, onFinish:Void->Void) {
		createSkyboxCubeTextured(this.dmlPath, texture -> {
			var sky = new h3d.prim.Sphere(1, 128, 128);
			sky.addNormals();
			sky.addUVs();
			var skyMesh = new h3d.scene.Mesh(sky, this);
			skyMesh.material.mainPass.culling = Front;
			// This is such a hack
			// skyMesh.material.mainPass.addShader(new h3d.shader.pbr.PropsValues(1, 0, 0, 1));
			skyMesh.material.mainPass.enableLights = false;
			skyMesh.material.shadows = false;
			skyMesh.material.blendMode = None;
			// var pbrprops = skyMesh.material.mainPass.getShader(PropsValues);
			// pbrprops.emissiveValue = 1;
			// pbrprops.roughnessValue = 0;`
			// pbrprops.occlusionValue = 0;
			// pbrprops.metalnessValue = 1;

			skyMesh.scale(3500);
			// var env = new Environment(texture);
			// env.compute();
			// var renderer = cast(level.scene.renderer, h3d.scene.pbr.Renderer);
			var shad = new Skybox(texture);
			skyMesh.material.mainPass.addShader(shad);
			skyMesh.material.mainPass.depthWrite = false;
			onFinish();
		});
		// skyMesh.material.shadows = false;
	}

	public function dispose() {
		for (imageResource in imageResources) {
			imageResource.release();
		}
	}

	function createSkyboxCubeTextured(dmlPath:String, onFinish:Texture->Void) {
		#if (js || android)
		dmlPath = StringTools.replace(dmlPath, "data/", "");
		#end
		if (ResourceLoader.fileSystem.exists(dmlPath)) {
			var dmlFileEntry = ResourceLoader.fileSystem.get(dmlPath);
			dmlFileEntry.load(() -> {
				var dmlFile = dmlFileEntry.getText();
				var dmlDirectory = Path.directory(dmlPath);
				var lines = dmlFile.split('\n').map(x -> x.toLowerCase());
				var skyboxImages = [];

				// 5: bottom, to be rotated/flipped
				// 0: front
				var skyboxIndices = [3, 1, 2, 0, 4, 5];

				var filestoload = [];
				for (i in 0...6) {
					var line = StringTools.trim(lines[i]);
					var filenames = ResourceLoader.getFullNamesOf(dmlDirectory + '/' + line);
					if (filenames.length != 0) {
						filestoload.push(filenames[0]);
					}
				}

				var worker = new ResourceLoaderWorker(() -> {
					for (i in 0...6) {
						var line = StringTools.trim(lines[i]);
						var filenames = ResourceLoader.getFullNamesOf(dmlDirectory + '/' + line);
						if (filenames.length == 0) {
							var pixels = Texture.fromColor(0).capturePixels(0, 0);
							skyboxImages.push(pixels);
							// var tex = new h3d.mat.Texture();
							// skyboxImages.push(new BitmapData(128, 128));
						} else {
							var image = ResourceLoader.getResource(filenames[0], ResourceLoader.getImage, this.imageResources).toBitmap();
							var pixels = image.getPixels();
							skyboxImages.push(pixels);
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
						cubemaptexture.uploadPixels(skyboxImages[skyboxIndices[i]], 0, i);
					}
					onFinish(cubemaptexture);
				});

				for (file in filestoload) {
					worker.loadFile(file);
				}
				worker.run();
			});
		} else {
			onFinish(null);
		}
	}
}
