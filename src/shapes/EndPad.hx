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
import mis.MissionElement.MissionElementStaticShape;

class EndPad extends DtsObject {
	var fireworks:Array<Firework> = [];

	var finishCollider:ConvexHull;
	var finishBounds:Bounds;
	var localFinishBounds:Bounds;
	var inFinish:Bool = false;
	var isMbu:Bool;

	public function new(?element:MissionElementStaticShape) {
		super();
		var datablockLower = element != null ? element.datablock.toLowerCase() : "";
		this.isMbu = datablockLower == "endpad_mbu";
		this.dtsPath = switch (datablockLower) {
			case "endpad_pq": "data/shapes_pq/gameplay/pads/endpad.dts";
			case "endpad_pq_construction": "data/shapes_pq/gameplay/pads/endpadconst.dts";
			case "endpad_mbu": "data/shapes_mbu/pads/mbu/endarea.dts";
			default: "data/shapes/pads/endarea.dts";
		}
		this.isCollideable = true;
		this.identifier = "EndPad";
		this.useInstancing = false;
	}

	public override function init(level:MarbleWorld, onFinish:Void->Void) {
		super.init(level, () -> {
			var worker = new src.ResourceLoaderWorker(onFinish);
			AudioManager.preloadPitchedSound("firewrks", worker);
			if (this.isMbu)
				worker.addTask(fwd -> this.spawnLightBeam(fwd));
			worker.run();
		});
	}

	/** Ported from `EndPad_MBU::onAdd` (`server/scripts/pads.cs`) - `EndPad_MBU` spawns a purely
		decorative light-beam column (`MBU_LightBeam`, `className = ""` despite inheriting the
		`EndPad` datablock - that inheritance is just for convenience defaults, not actual finish-pad
		behavior) rigidly attached with zero offset/rotation at the end pad's own transform. Same
		scene-graph-child approach as `Checkpoint.hx`'s `SillyGlass` (a checkpoint/end pad never
		moves, so real parent-child scene graph nesting - inheriting position/rotation/scale for free
		- is simpler than a separately-tracked, manually-synced object). */
	function spawnLightBeam(onFinish:Void->Void) {
		var beam = new DtsObject();
		beam.dtsPath = "data/shapes_mbu/pads/mbu/lightbeam.dts";
		beam.identifier = "MbuLightBeam";
		beam.isCollideable = false;
		beam.isBoundingBoxCollideable = false;
		beam.useInstancing = true;
		this.level.addDtsObject(beam, () -> {
			this.addChild(beam);
			onFinish();
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
		AudioManager.playPitchedSound("firewrks", this.soundResources, null, this.getAbsPos().getPosition());
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

		localFinishBounds = finishBounds.clone();
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

		if (this.hasMover()) {
			// Move!

			var tform = this.getAbsPos().clone();
			tform.prependRotation(Math.PI / 2, 0, 0);

			finishCollider.transform = tform;

			finishBounds.load(localFinishBounds);
			finishBounds.transform(tform);
		}
	}
}

/** Ported from `fireworks.cs`'s `FireWorkSmoke`/`FireWorkSmokeEmitter`. The real
	`ejectionOffset`+theta/phi cone (0-90deg off up) is what actually produces the "smoke expanding
	outward from a point" look - MBHaxe's previous version approximated this with a custom
	`spawnOffset` circle-area function and no real ejection velocity; now that the cone/offset
	system is accurately ported, that approximation isn't needed. */
final fireworkSmoke:ParticleEmitterOptions = {
	ejectionPeriod: 100,
	ambientVelocity: new Vector(0, 0, 0),
	ejectionVelocity: 1,
	velocityVariance: 0.2,
	emitterLifetime: 5000,
	ejectionOffset: 0.75,
	thetaMin: 0,
	thetaMax: 90,
	phiReferenceVel: 0,
	phiVariance: 360,
	inheritedVelFactor: 0,
	particleOptions: {
		texture: 'particles/saturn.png',
		blending: Alpha,
		spinSpeed: 0,
		spinRandomMin: -90,
		spinRandomMax: 90,
		lifetime: 2000,
		lifetimeVariance: 200,
		dragCoefficient: 1,
		constantAcceleration: 0,
		gravityCoefficient: 0,
		windCoefficient: 0,
		colors: [new Vector(1, 1, 0, 0), new Vector(1, 0, 0, 1), new Vector(1, 0, 0, 0)],
		sizes: [0.1, 0.2, 0.3],
		times: [0, 0.2, 1]
	}
};

/** Ported from `fireworks.cs`'s `RedFireWorkTrail`/`RedFireWorkTrailEmitter`. */
final redTrail:ParticleEmitterOptions = {
	ejectionPeriod: 30,
	ambientVelocity: new Vector(0, 0, 0),
	ejectionVelocity: 0.1,
	velocityVariance: 0,
	emitterLifetime: 5000,
	ejectionOffset: 0,
	thetaMin: 170,
	thetaMax: 180,
	phiReferenceVel: 0,
	phiVariance: 360,
	inheritedVelFactor: 0,
	particleOptions: {
		texture: 'particles/spark.png',
		blending: Alpha,
		spinSpeed: 0,
		spinRandomMin: -90,
		spinRandomMax: 90,
		lifetime: 600,
		lifetimeVariance: 100,
		dragCoefficient: 1,
		constantAcceleration: 0,
		gravityCoefficient: 0,
		windCoefficient: 0,
		colors: [new Vector(1, 1, 0, 1), new Vector(1, 0, 0, 1), new Vector(1, 0, 0, 0)],
		sizes: [0.1, 0.05, 0.01],
		times: [0, 0.5, 1]
	}
};

/** Ported from `fireworks.cs`'s `BlueFireWorkTrail`/`BlueFireWorkTrailEmitter`. */
final blueTrail:ParticleEmitterOptions = {
	ejectionPeriod: 30,
	ambientVelocity: new Vector(0, 0, 0),
	ejectionVelocity: 0.1,
	velocityVariance: 0,
	emitterLifetime: 5000,
	ejectionOffset: 0,
	thetaMin: 170,
	thetaMax: 180,
	phiReferenceVel: 0,
	phiVariance: 360,
	inheritedVelFactor: 0,
	particleOptions: {
		texture: 'particles/spark.png',
		blending: Alpha,
		spinSpeed: 0,
		spinRandomMin: -90,
		spinRandomMax: 90,
		lifetime: 600,
		lifetimeVariance: 100,
		dragCoefficient: 1,
		constantAcceleration: 0,
		gravityCoefficient: 0,
		windCoefficient: 0,
		colors: [new Vector(0, 0, 1, 1), new Vector(0.5, 0.5, 1, 1), new Vector(1, 1, 1, 0)],
		sizes: [0.1, 0.05, 0.01],
		times: [0, 0.5, 1]
	}
};

/** Ported from `fireworks.cs`'s `RedFireWorkSpark`/`RedFireWorkSparkEmitter` - the source doesn't
	set `spinSpeed`/`spinRandomMin`/`spinRandomMax` at all, so those default to 0 (`ParticleData`'s
	C++ constructor defaults), not MBHaxe's previous invented `40`/`-90`/`90`. */
final redSpark:ParticleEmitterOptions = {
	ejectionPeriod: 15,
	ambientVelocity: new Vector(0, 0, 0),
	ejectionVelocity: 1,
	velocityVariance: 0.25,
	emitterLifetime: 300,
	ejectionOffset: 0,
	thetaMin: 0,
	thetaMax: 180,
	phiReferenceVel: 0,
	phiVariance: 360,
	inheritedVelFactor: 0.2,
	particleOptions: {
		texture: 'particles/star.png',
		blending: Alpha,
		spinSpeed: 0,
		spinRandomMin: 0,
		spinRandomMax: 0,
		lifetime: 500,
		lifetimeVariance: 50,
		dragCoefficient: 0,
		constantAcceleration: 0,
		gravityCoefficient: 0,
		windCoefficient: 0,
		colors: [new Vector(1, 1, 0, 1), new Vector(1, 1, 0, 1), new Vector(1, 0, 0, 0)],
		sizes: [0.2, 0.2, 0.2],
		times: [0, 0.5, 1]
	}
};

/** Ported from `fireworks.cs`'s `BlueFireWorkSpark`/`BlueFireWorkSparkEmitter` - same "no spin
	fields set = defaults to 0" note as `redSpark`. */
final blueSpark:ParticleEmitterOptions = {
	ejectionPeriod: 60,
	ambientVelocity: new Vector(0, 0, 0),
	ejectionVelocity: 0.5,
	velocityVariance: 0.25,
	emitterLifetime: 300,
	ejectionOffset: 0,
	thetaMin: 0,
	thetaMax: 180,
	phiReferenceVel: 0,
	phiVariance: 360,
	inheritedVelFactor: 0.2,
	particleOptions: {
		texture: 'particles/bubble.png',
		blending: Alpha,
		spinSpeed: 0,
		spinRandomMin: 0,
		spinRandomMax: 0,
		lifetime: 2000,
		lifetimeVariance: 200,
		dragCoefficient: 0,
		constantAcceleration: 0,
		gravityCoefficient: 0,
		windCoefficient: 0,
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
