package shapes;

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

class EndPad extends DtsObject {
	var fireworks:Array<Firework> = [];

	var finishCollider:ConvexHull;
	var finishBounds:Bounds;
	var inFinish:Bool = false;

	public function new() {
		super();
		this.dtsPath = "data/shapes/pads/endarea.dts";
		this.useInstancing = false;
		this.isCollideable = true;
		this.identifier = "EndPad";
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
		// AudioManager.playSound(ResourceLoader.getAudio("data/sound/firewrks.wav"));
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
		finishCollider = new ConvexHull(vertices);

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

	public function new(pos:Vector, spawnTime:Float, level:MarbleWorld) {
		this.pos = pos;
		this.spawnTime = spawnTime;
		this.level = level;

		fireworkSmokeData = new ParticleData();
		fireworkSmokeData.identifier = "fireworkSmoke";
		fireworkSmokeData.texture = ResourceLoader.getTexture("data/particles/saturn.png");

		fireworkRedTrailData = new ParticleData();
		fireworkRedTrailData.identifier = "fireworkRedTrail";
		fireworkRedTrailData.texture = ResourceLoader.getTexture("data/particles/spark.png");

		fireworkBlueTrailData = new ParticleData();
		fireworkBlueTrailData.identifier = "fireworkBlueTrail";
		fireworkBlueTrailData.texture = ResourceLoader.getTexture("data/particles/spark.png");

		fireworkRedSparkData = new ParticleData();
		fireworkRedSparkData.identifier = "fireworkRedSpark";
		fireworkRedSparkData.texture = ResourceLoader.getTexture("data/particles/star.png");

		fireworkBlueSparkData = new ParticleData();
		fireworkBlueSparkData.identifier = "fireworkBlueSpark";
		fireworkBlueSparkData.texture = ResourceLoader.getTexture("data/particles/bubble.png");

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
}
