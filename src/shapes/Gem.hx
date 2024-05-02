package shapes;

import h3d.shader.pbr.PropsValues;
import src.MarbleWorld;
import mis.MissionElement.MissionElementItem;
import src.TimeState;
import src.DtsObject;
import src.ResourceLoaderWorker;
import src.ResourceLoader;
import src.Marble;

class Gem extends DtsObject {
	public var pickedUp:Bool;

	public var netIndex:Int;
	public var pickUpClient:Int = -1;

	var gemColor:String;

	public var radarColor:Int;

	public function new(element:MissionElementItem) {
		super();
		dtsPath = "data/shapes/items/gem.dts";
		ambientRotate = true;
		isCollideable = false;
		this.isBoundingBoxCollideable = true;
		pickedUp = false;
		useInstancing = true;
		this.sharedNodeTransforms = true;
		showSequences = false; // Gems actually have an animation for the little shiny thing, but the actual game ignores that. I get it, it was annoying as hell.

		var GEM_COLORS = ["red"];
		var color = element.datablock.substring("GemItem".length);
		if (color.length == 0)
			color = GEM_COLORS[Math.floor(Math.random() * GEM_COLORS.length)];
		this.identifier = "Gem" + color;
		this.matNameOverride.set('base.gem', color + ".gem");
		gemColor = color + ".gem";
		radarColor = switch (color) {
			case "blue":
				0x0000E6;
			case "yellow":
				0xE6FF00;
			default:
				0xE60000;
		}
	}

	public override function init(level:MarbleWorld, onFinish:Void->Void) {
		super.init(level, () -> {
			var worker = new ResourceLoaderWorker(onFinish);
			worker.loadFile('sound/gem_collect.wav');
			worker.run();
		});
	}

	public override function setHide(hide:Bool) {
		if (hide) {
			this.pickedUp = true;
			this.setOpacity(0);
		} else {
			this.pickedUp = false;
			this.setOpacity(1);
		}
	}

	override function onMarbleInside(marble:Marble, timeState:TimeState) {
		super.onMarbleInside(marble, timeState);
		if (this.pickedUp || this.level.rewinding)
			return;
		this.pickedUp = true;
		this.setOpacity(0); // Hide the gem
		this.level.pickUpGem(marble, this);
		// this.level.replay.recordMarbleInside(this);
	}

	override function reset() {
		this.pickedUp = false;
		this.pickUpClient = -1;
		this.setOpacity(1);
	}

	override function getPreloadMaterials(dts:dts.DtsFile) {
		var mats = super.getPreloadMaterials(dts);
		switch (gemColor) {
			case "yellow":
				mats.push('data/shapes/items/yellow.gem.png');
				mats.push("data/skies/gemCubemapUp2.png");
			case "blue":
				mats.push('data/shapes/items/blue.gem.png');
				mats.push("data/skies/gemCubemapUp3.png");
			default:
				mats.push('data/shapes/items/red.gem.png');
				mats.push("data/skies/gemCubemapUp.png");
		}

		return mats;
	}

	override function postProcessMaterial(matName:String, material:h3d.mat.Material) {
		if (matName == "red.gem") {
			var diffuseTex = ResourceLoader.getTexture('data/shapes/items/red.gem.png').resource;
			diffuseTex.wrap = Repeat;
			diffuseTex.mipMap = Nearest;

			var cubemapTex = new h3d.mat.Texture(64, 64, [Cube]);
			var cubemapFace = ResourceLoader.getImage('data/skies/gemCubemapUp.png').resource;
			for (i in 0...6) {
				cubemapTex.uploadPixels(cubemapFace.getPixels(), 0, i);
			}
			var shader = new shaders.DefaultCubemapNormalNoSpecMaterial(diffuseTex, 1, cubemapTex);
			var dtsTex = material.mainPass.getShader(shaders.DtsTexture);
			dtsTex.passThrough = true;
			material.mainPass.removeShader(material.textureShader);
			material.mainPass.addShader(shader);
			var thisprops:Dynamic = material.getDefaultProps();
			thisprops.light = false; // We will calculate our own lighting
			material.props = thisprops;
			material.shadows = false;
			material.receiveShadows = true;
		}
		if (matName == "yellow.gem") {
			var diffuseTex = ResourceLoader.getTexture('data/shapes/items/yellow.gem.png').resource;
			diffuseTex.wrap = Repeat;
			diffuseTex.mipMap = Nearest;

			var cubemapTex = new h3d.mat.Texture(64, 64, [Cube]);
			var cubemapFace = ResourceLoader.getImage('data/skies/gemCubemapUp2.png').resource;
			for (i in 0...6) {
				cubemapTex.uploadPixels(cubemapFace.getPixels(), 0, i);
			}
			var shader = new shaders.DefaultCubemapNormalNoSpecMaterial(diffuseTex, 1, cubemapTex);
			var dtsTex = material.mainPass.getShader(shaders.DtsTexture);
			dtsTex.passThrough = true;
			material.mainPass.removeShader(material.textureShader);
			material.mainPass.addShader(shader);
			var thisprops:Dynamic = material.getDefaultProps();
			thisprops.light = false; // We will calculate our own lighting
			material.props = thisprops;
			material.shadows = false;
			material.receiveShadows = true;
		}
		if (matName == "blue.gem") {
			var diffuseTex = ResourceLoader.getTexture('data/shapes/items/blue.gem.png').resource;
			diffuseTex.wrap = Repeat;
			diffuseTex.mipMap = Nearest;

			var cubemapTex = new h3d.mat.Texture(64, 64, [Cube]);
			var cubemapFace = ResourceLoader.getImage('data/skies/gemCubemapUp3.png').resource;
			for (i in 0...6) {
				cubemapTex.uploadPixels(cubemapFace.getPixels(), 0, i);
			}
			var shader = new shaders.DefaultCubemapNormalNoSpecMaterial(diffuseTex, 1, cubemapTex);
			var dtsTex = material.mainPass.getShader(shaders.DtsTexture);
			dtsTex.passThrough = true;
			material.mainPass.removeShader(material.textureShader);
			material.mainPass.addShader(shader);
			var thisprops:Dynamic = material.getDefaultProps();
			thisprops.light = false; // We will calculate our own lighting
			material.props = thisprops;
			material.shadows = false;
			material.receiveShadows = true;
		}
	}
}
