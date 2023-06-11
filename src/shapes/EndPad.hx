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
	var fireworks:Array<Firework> = [];

	var finishCollider:ConvexHull;
	var finishBounds:Bounds;
	var inFinish:Bool = false;

	public function new() {
		super();
		this.dtsPath = "data/shapes/pads/endarea.dts";
		this.isCollideable = true;
		this.identifier = "EndPad";
		this.useInstancing = true;
	}

	public override function init(level:MarbleWorld, onFinish:Void->Void) {
		super.init(level, () -> {
			ResourceLoader.load("sound/firewrks.wav").entry.load(onFinish);
		});
	}

	// override function onMarbleContact(timeState:TimeState, ?contact:CollisionInfo) {
	// 	if (!isEntered) {
	// 		isEntered = true;
	// 		spawnFirework(timeState);
	// 	}
	// }

	function spawnFirework(time:TimeState) {
		var firework = new Firework(this.getAbsPos().getPosition(), time.timeSinceLoad, this.level);
		this.fireworks.push(firework);
		AudioManager.playSound(ResourceLoader.getResource("data/sound/firewrks.wav", ResourceLoader.getAudio, this.soundResources),
			this.getAbsPos().getPosition());
		// AudioManager.play(this.sounds[0], 1, AudioManager.soundGain, this.worldPosition);
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

		for (firework in this.fireworks) {
			firework.tick(timeState.timeSinceLoad);
			if (timeState.timeSinceLoad - firework.spawnTime >= 10)
				this.fireworks.remove(firework);
			// We can safely remove the firework
		}
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

		if (matName == "misty") {
			var diffuseTex = ResourceLoader.getTexture("data/shapes/pads/misty.png").resource;
			diffuseTex.wrap = Repeat;
			diffuseTex.mipMap = Nearest;

			var trivialShader = new shaders.TrivialMaterial(diffuseTex);

			var glowpass = material.mainPass.clone();
			glowpass.addShader(trivialShader);
			var dtsshader = glowpass.getShader(shaders.DtsTexture);
			if (dtsshader != null)
				glowpass.removeShader(dtsshader);
			glowpass.setPassName("glow");
			glowpass.depthTest = LessEqual;
			glowpass.enableLights = false;
			glowpass.blendSrc = SrcAlpha;
			glowpass.blendDst = OneMinusSrcAlpha;
			material.addPass(glowpass);

			material.mainPass.setPassName("glowPre");
			material.mainPass.addShader(trivialShader);
			dtsshader = material.mainPass.getShader(shaders.DtsTexture);
			if (dtsshader != null)
				material.mainPass.removeShader(dtsshader);
			material.mainPass.enableLights = false;

			var thisprops:Dynamic = material.getDefaultProps();
			thisprops.light = false; // We will calculate our own lighting
			material.props = thisprops;
			material.shadows = false;
			material.blendMode = Alpha;
			material.mainPass.blendSrc = SrcAlpha;
			material.mainPass.blendDst = OneMinusSrcAlpha;
		}
	}
}

final fireworkSmoke:ParticleEmitterOptions = {
	ejectionPeriod: 100,
	ambientVelocity: new Vector(0, 0, 1),
	ejectionVelocity: 0,
	velocityVariance: 0,
	emitterLifetime: 4000,
	spawnOffset: () -> {
		var r = Math.sqrt(Math.random());
		var theta = Math.random() * Math.PI * 2;
		var randomPointInCircle = new Vector(r * Math.cos(theta), r * Math.sin(theta));
		return new Vector(randomPointInCircle.x * 1.6, randomPointInCircle.y * 1.6, Math.random() * 0.4 - 0.5);
	},
	inheritedVelFactor: 0,
	particleOptions: {
		texture: 'particles/saturn.png',
		blending: Alpha,
		spinSpeed: 0,
		spinRandomMin: -90,
		spinRandomMax: 90,
		lifetime: 2000,
		lifetimeVariance: 200,
		dragCoefficient: 0.5,
		acceleration: 0,
		colors: [new Vector(1, 1, 0, 0), new Vector(1, 0, 0, 1), new Vector(1, 0, 0, 0)],
		sizes: [0.1, 0.2, 0.3],
		times: [0, 0.2, 1]
	}
};

final redTrail:ParticleEmitterOptions = {
	ejectionPeriod: 30,
	ambientVelocity: new Vector(0, 0, 0),
	ejectionVelocity: 0,
	velocityVariance: 0,
	emitterLifetime: 10000,
	inheritedVelFactor: 0,
	particleOptions: {
		texture: 'particles/spark.png',
		blending: Alpha,
		spinSpeed: 0,
		spinRandomMin: -90,
		spinRandomMax: 90,
		lifetime: 600,
		lifetimeVariance: 100,
		dragCoefficient: 0,
		acceleration: 0,
		colors: [new Vector(1, 1, 0, 1), new Vector(1, 0, 0, 1), new Vector(1, 0, 0, 0)],
		sizes: [0.1, 0.05, 0.01],
		times: [0, 0.5, 1]
	}
};

final blueTrail:ParticleEmitterOptions = {
	ejectionPeriod: 30,
	ambientVelocity: new Vector(0, 0, 0),
	ejectionVelocity: 0,
	velocityVariance: 0,
	emitterLifetime: 10000,
	inheritedVelFactor: 0,
	particleOptions: {
		texture: 'particles/spark.png',
		blending: Alpha,
		spinSpeed: 0,
		spinRandomMin: -90,
		spinRandomMax: 90,
		lifetime: 600,
		lifetimeVariance: 100,
		dragCoefficient: 0,
		acceleration: 0,
		colors: [new Vector(0, 0, 1, 1), new Vector(0.5, 0.5, 1, 1), new Vector(1, 1, 1, 0)],
		sizes: [0.1, 0.05, 0.01],
		times: [0, 0.5, 1]
	}
};

final redSpark:ParticleEmitterOptions = {
	ejectionPeriod: 1,
	ambientVelocity: new Vector(0, 0, 0),
	ejectionVelocity: 0.8,
	velocityVariance: 0.25,
	emitterLifetime: 10,
	inheritedVelFactor: 0,
	particleOptions: {
		texture: 'particles/star.png',
		blending: Alpha,
		spinSpeed: 40,
		spinRandomMin: -90,
		spinRandomMax: 90,
		lifetime: 500,
		lifetimeVariance: 50,
		dragCoefficient: 0.5,
		acceleration: 0,
		colors: [new Vector(1, 1, 0, 1), new Vector(1, 1, 0, 1), new Vector(1, 0, 0, 0)],
		sizes: [0.2, 0.2, 0.2],
		times: [0, 0.5, 1]
	}
};

final blueSpark:ParticleEmitterOptions = {
	ejectionPeriod: 1,
	ambientVelocity: new Vector(0, 0, 0),
	ejectionVelocity: 0.5,
	velocityVariance: 0.25,
	emitterLifetime: 10,
	inheritedVelFactor: 0,
	particleOptions: {
		texture: 'particles/bubble.png',
		blending: Alpha,
		spinSpeed: 40,
		spinRandomMin: -90,
		spinRandomMax: 90,
		lifetime: 2000,
		lifetimeVariance: 200,
		dragCoefficient: 0,
		acceleration: 0,
		colors: [new Vector(0, 0, 1, 1), new Vector(0.5, 0.5, 1, 1), new Vector(1, 1, 1, 0)],
		sizes: [0.2, 0.2, 0.2],
		times: [0, 0.5, 1]
	}
};

typedef Trail = {
	var type:String;
	var smokeEmitter:ParticleEmitter;
	var targetPos:Vector;
	var spawnTime:Float;
	var lifetime:Float;
}

@:publicFields
class Firework extends Scheduler {
	var pos:Vector;
	var spawnTime:Float;
	var trails:Array<Trail> = [];

	/** The fireworks are spawned in waves, this controls how many are left. */
	var wavesLeft = 4;

	var level:MarbleWorld;

	var fireworkSmokeData:ParticleData;
	var fireworkRedTrailData:ParticleData;
	var fireworkBlueTrailData:ParticleData;
	var fireworkRedSparkData:ParticleData;
	var fireworkBlueSparkData:ParticleData;

	var textureResources:Array<Resource<Texture>> = [];

	public function new(pos:Vector, spawnTime:Float, level:MarbleWorld) {
		this.pos = pos;
		this.spawnTime = spawnTime;
		this.level = level;

		fireworkSmokeData = new ParticleData();
		fireworkSmokeData.identifier = "fireworkSmoke";
		var res1 = ResourceLoader.getTexture("data/particles/saturn.png");
		res1.acquire();
		if (!this.textureResources.contains(res1))
			this.textureResources.push(res1);
		fireworkSmokeData.texture = res1.resource;

		fireworkRedTrailData = new ParticleData();
		fireworkRedTrailData.identifier = "fireworkRedTrail";
		var res2 = ResourceLoader.getTexture("data/particles/spark.png");
		res2.acquire();
		if (!this.textureResources.contains(res2))
			this.textureResources.push(res2);
		fireworkRedTrailData.texture = res2.resource;

		fireworkBlueTrailData = new ParticleData();
		fireworkBlueTrailData.identifier = "fireworkBlueTrail";
		var res3 = ResourceLoader.getTexture("data/particles/spark.png");
		res3.acquire();
		if (!this.textureResources.contains(res3))
			this.textureResources.push(res3);
		fireworkBlueTrailData.texture = res3.resource;

		fireworkRedSparkData = new ParticleData();
		fireworkRedSparkData.identifier = "fireworkRedSpark";
		var res4 = ResourceLoader.getTexture("data/particles/star.png");
		res4.acquire();
		if (!this.textureResources.contains(res4))
			this.textureResources.push(res4);
		fireworkRedSparkData.texture = res4.resource;

		fireworkBlueSparkData = new ParticleData();
		fireworkBlueSparkData.identifier = "fireworkBlueSpark";
		var res5 = ResourceLoader.getTexture("data/particles/bubble.png");
		res5.acquire();
		if (!this.textureResources.contains(res5))
			this.textureResources.push(res5);
		fireworkBlueSparkData.texture = res5.resource;

		level.particleManager.createEmitter(fireworkSmoke, fireworkSmokeData, this.pos); // Start the smoke
		this.doWave(this.spawnTime); // Start the first wave
	}

	public function tick(time:Float) {
		this.tickSchedule(time);

		// Update the trails
		for (trail in this.trails) {
			var completion = Util.clamp((time - trail.spawnTime) / trail.lifetime, 0, 1);
			completion = 1 - Math.pow((1 - completion), 2); // ease-out

			// Make the trail travel along an arc (parabola, whatever)
			var pos = this.pos.clone().multiply(1 - completion).add(trail.targetPos.clone().multiply(completion));
			pos = pos.sub(new Vector(0, 0, 1).multiply(Math.pow(completion, 2)));
			trail.smokeEmitter.setPos(pos, time);

			if (completion == 1) {
				// The trail has reached its end, remove the emitter and spawn the explosion.
				level.particleManager.removeEmitter(trail.smokeEmitter);
				this.trails.remove(trail);

				if (trail.type == 'red') {
					level.particleManager.createEmitter(redSpark, fireworkRedSparkData, pos);
				} else {
					level.particleManager.createEmitter(blueSpark, fireworkBlueSparkData, pos);
				}
			}
		}
	}

	/** Spawns a bunch of trails going in random directions. */
	function doWave(time:Float) {
		var count = Math.floor(17 + Math.random() * 10);
		for (i in 0...count)
			this.spawnTrail(time);
		this.wavesLeft--;
		if (this.wavesLeft > 0) {
			var nextWaveTime = time + 0.5 + 1 * Math.random();
			this.schedule(nextWaveTime, () -> this.doWave(nextWaveTime));
		}
		return null;
	}

	function spawnTrail(time:Float) {
		var type = (Math.random() < 0.5) ? 'red' : 'blue';
		var lifetime = 0.25 + Math.random() * 2;
		var distanceFac = 0.5 + lifetime / 5; // Make sure the firework doesn't travel a great distance way too quickly
		var emitter = level.particleManager.createEmitter((type == 'red') ? redTrail : blueTrail,
			(type == 'red') ? fireworkRedTrailData : fireworkBlueTrailData, this.pos);

		var r = Math.sqrt(Math.random());
		var theta = Math.random() * Math.PI * 2;

		var randomPointInCircle = new Vector(r * Math.cos(theta), r * Math.sin(theta));
		var targetPos = new Vector(randomPointInCircle.x * 3, randomPointInCircle.y * 3, 1 + Math.sqrt(Math.random()) * 3).multiply(distanceFac).add(this.pos);
		var trail:Trail = {
			type: type,
			smokeEmitter: emitter,
			targetPos: targetPos,
			spawnTime: time,
			lifetime: lifetime
		};
		this.trails.push(trail);
	}

	function dispose() {
		for (textureResource in this.textureResources) {
			textureResource.release();
		}
	}
}
