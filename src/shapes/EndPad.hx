package shapes;

import src.MarbleGame;
import collision.gjk.Cylinder;
import src.AudioManager;
import h3d.Quat;
import h3d.mat.Material;
import h3d.scene.Mesh;
import h3d.prim.Polygon;
import h3d.col.Bounds;
import h2d.col.Matrix;
import collision.gjk.ConvexHull;
import src.TimeState;
import collision.CollisionInfo;
import src.Util;
import src.ResourceLoader;
import src.ParticleSystem.ParticleData;
import src.MarbleWorld;
import src.DtsObject;
import src.MarbleWorld.Scheduler;
import src.ParticleSystem.ParticleEmitter;
import src.ParticleSystem.ParticleEmitterOptions;
import h3d.Vector;
import src.Resource;
import h3d.mat.Texture;

class EndPad extends DtsObject {
	var finishCollider:ConvexHull;
	var finishBounds:Bounds;
	var inFinish:Bool = false;

	public function new() {
		super();
		this.dtsPath = "data/shapes/pads/endarea.dts";
		this.isCollideable = true;
		this.identifier = "EndPad";
		this.useInstancing = false;
	}

	public override function init(level:MarbleWorld, onFinish:Void->Void) {
		super.init(level, onFinish);
	}

	function generateCollider() {
		var height = 4.8;
		var radius = 1.7;
		var vertices = [];

		for (i in 0...2) {
			for (j in 0...64) {
				var angle = j / 64 * Math.PI * 2;
				var x = Math.cos(angle);
				var z = Math.sin(angle);

				vertices.push(new Vector(x * radius * this.scaleX, (i != 0 ? 4.8 : 0) * 1, z * radius * this.scaleY));
			}
		}
		// var m = new h3d.prim.Cylinder(64, radius, height);
		// m.addNormals();
		// m.addUVs();
		// var cmesh = new h3d.scene.Mesh(m);
		// cmesh.setTransform(this.getAbsPos());
		// MarbleGame.instance.scene.addChild(cmesh);
		finishCollider = new ConvexHull(vertices);
		// finishCollider = new Cylinder();
		// finishCollider.p1 = this.getAbsPos().getPosition();
		// finishCollider.p2 = finishCollider.p1.clone();
		// var vertDir = this.getAbsPos().up();
		// finishCollider.p2 = finishCollider.p2.add(vertDir.multiply(height));
		// finishCollider.radius = radius;

		finishBounds = new Bounds();
		for (vert in vertices)
			finishBounds.addPoint(vert.toPoint());

		var rotQuat = new Quat();
		rotQuat.initRotation(0, Math.PI / 2, 0);
		var rotMat = rotQuat.toMatrix();

		var tform = this.getAbsPos().clone();
		tform.prependRotation(Math.PI / 2, 0, 0);

		finishCollider.transform = tform;

		finishBounds.transform(tform);

		// var polygon = new Polygon(vertices.map(x -> x.toPoint()));
		// polygon.addNormals();
		// polygon.addUVs();
		// var collidermesh = new Mesh(polygon, Material.create(), this.level.scene);
		// collidermesh.setTransform(tform);
	}

	override function update(timeState:TimeState) {
		super.update(timeState);
	}

	override function postProcessMaterial(matName:String, material:h3d.mat.Material) {
		if (matName == "abyss2") {
			var glowpass = material.mainPass.clone();
			glowpass.setPassName("glow");
			glowpass.depthTest = LessEqual;
			glowpass.enableLights = false;
			material.addPass(glowpass);

			material.mainPass.setPassName("glowPre");
			material.mainPass.enableLights = false;

			var rotshader = new shaders.UVRotAnim(0.5, 0.5, 1);
			material.mainPass.addShader(rotshader);

			var thisprops:Dynamic = material.getDefaultProps();
			thisprops.light = false; // We will calculate our own lighting
			material.props = thisprops;
			material.shadows = false;
		}

		if (matName == "ringtex") {
			var diffuseTex = ResourceLoader.getTexture("data/shapes/pads/ringtex.png").resource;
			diffuseTex.wrap = Repeat;
			diffuseTex.mipMap = Nearest;
			var shader = new shaders.DefaultNormalMaterial(diffuseTex, 14, new h3d.Vector(0.3, 0.3, 0.3, 7), 1);
			shader.doGammaRamp = false;
			var dtsshader = material.mainPass.getShader(shaders.DtsTexture);
			if (dtsshader != null)
				material.mainPass.removeShader(dtsshader);
			// var dtsTex = material.mainPass.getShader(shaders.DtsTexture);
			// dtsTex.passThrough = true;
			material.mainPass.removeShader(material.textureShader);
			material.mainPass.addShader(shader);
			var thisprops:Dynamic = material.getDefaultProps();
			thisprops.light = false; // We will calculate our own lighting
			material.props = thisprops;
			material.shadows = false;
			material.receiveShadows = true;
		}

		if (matName == "misty") {
			var diffuseTex = ResourceLoader.getTexture("data/shapes/pads/misty.png").resource;
			diffuseTex.wrap = Repeat;
			diffuseTex.mipMap = Nearest;

			var trivialShader = new shaders.TrivialMaterial(diffuseTex);
			var scrollShader = new h3d.shader.UVScroll(0, 0.25);

			var glowpass = material.mainPass.clone();
			glowpass.addShader(trivialShader);
			glowpass.addShader(scrollShader);
			var dtsshader = glowpass.getShader(shaders.DtsTexture);
			if (dtsshader != null)
				glowpass.removeShader(dtsshader);
			glowpass.setPassName("glow");
			glowpass.depthTest = LessEqual;
			glowpass.depthWrite = false;
			glowpass.enableLights = false;
			glowpass.blendSrc = SrcAlpha;
			glowpass.blendDst = OneMinusSrcAlpha;
			material.addPass(glowpass);

			material.mainPass.setPassName("glowPreNoRender");
			material.mainPass.addShader(trivialShader);
			dtsshader = material.mainPass.getShader(shaders.DtsTexture);
			if (dtsshader != null)
				material.mainPass.removeShader(dtsshader);
			material.mainPass.enableLights = false;

			// var thisprops:Dynamic = material.getDefaultProps();
			// thisprops.light = false; // We will calculate our own lighting
			// material.props = thisprops;
			// material.shadows = false;
			// material.blendMode = Alpha;
			// material.mainPass.depthWrite = false;
			// material.mainPass.blendSrc = SrcAlpha;
			// material.mainPass.blendDst = OneMinusSrcAlpha;
		}
	}
}
