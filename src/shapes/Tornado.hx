package shapes;

import hxd.snd.effect.Spatialization;
import hxd.snd.Channel;
import h3d.Vector;
import h3d.mat.BlendMode;
import src.ForceObject;
import src.ResourceLoader;
import src.AudioManager;
import src.MarbleWorld;
import src.ParticleSystem.ParticleData;
import src.ParticleSystem.ParticleEmitterOptions;
import src.ParticleSystem.ParticleEmitter;
import mis.MissionElement.MissionElementStaticShape;
import src.ResourceLoaderWorker;

final tornadoGustOptions:ParticleEmitterOptions = {
	ejectionPeriod: 10,
	periodVariance: 9,
	ambientVelocity: new Vector(0, 0, 0),
	ejectionVelocity: 5.29,
	velocityVariance: 0.88,
	emitterLifetime: 1e9,
	ejectionOffset: 4.31,
	thetaMin: 98.82353,
	thetaMax: 139.4118,
	phiReferenceVel: 0,
	phiVariance: 360,
	inheritedVelFactor: 0,
	particleOptions: {
		texture: 'particles/gust.png',
		blending: BlendMode.Alpha,
		spinSpeed: 4.21569,
		spinRandomMin: -100,
		spinRandomMax: 0.5,
		lifetime: 608,
		lifetimeVariance: 96,
		dragCoefficient: 0,
		constantAcceleration: -5,
		gravityCoefficient: -0.002442002,
		windCoefficient: 0,
		colors: [
			new Vector(0.440945, 0.330709, 0.086614, 0),
			new Vector(0.448819, 0.299213, 0.062992, 0),
			new Vector(0.385827, 0.259843, 0.110236, 0.346457),
			new Vector(0.771654, 0.669291, 0.488189, 0)
		],
		sizes: [0.88, 3.73, 3.43, 2.35],
		times: [0, 0.24, 0.46, 1]
	}
};

final tornadoSpeckOptions:ParticleEmitterOptions = {
	ejectionPeriod: 10,
	periodVariance: 9,
	ambientVelocity: new Vector(0, 0, 0),
	ejectionVelocity: 11.5686,
	velocityVariance: 0.686275,
	emitterLifetime: 1e9,
	ejectionOffset: 6.27451,
	thetaMin: 236.471 - 180,
	thetaMax: 307.059 - 180,
	phiReferenceVel: 0,
	phiVariance: 360,
	inheritedVelFactor: 0,
	particleOptions: {
		texture: 'particles/speck.png',
		blending: BlendMode.Alpha,
		spinSpeed: 6.86275,
		spinRandomMin: -90,
		spinRandomMax: 161.765,
		lifetime: 911,
		lifetimeVariance: 96,
		dragCoefficient: 0,
		constantAcceleration: -5,
		gravityCoefficient: 0,
		windCoefficient: 0,
		colors: [
			new Vector(0.441176, 0.333333, 0.088235, 0),
			new Vector(0.745098, 0.568627, 0.382353, 0),
			new Vector(0.735294, 0.607843, 0.460784, 0.28),
			new Vector(0.774510, 0.676471, 0.490196, 1)
		],
		sizes: [0.78, 1, 1, 0],
		times: [0, 0.24, 0.39, 1]
	}
};

class Tornado extends ForceObject {
	var soundChannel:Channel;
	var isPQ:Bool;
	var gustData:ParticleData;
	var speckData:ParticleData;
	var gustEmitter:ParticleEmitter;
	var speckEmitter:ParticleEmitter;

	public function new(?element:MissionElementStaticShape) {
		super();
		var datablockLower = element != null ? element.datablock.toLowerCase() : "";
		this.isPQ = datablockLower == "tornado_pq";
		this.dtsPath = switch (datablockLower) {
			case "tornado_pq": "data/shapes_pq/gameplay/hazards/tornado.dts";
			case "tornado_mbm": "data/shapes_mbu/hazards/tornado.dts";
			default: "data/shapes/hazards/tornado.dts";
		}
		this.isCollideable = false;
		this.isTSStatic = false;
		this.identifier = "Tornado" + this.dtsPath;
		this.forceDatas = [
			{
				forceType: ForceSpherical,
				forceNode: 0,
				forceStrength: -60,
				forceRadius: 8,
				forceArc: 0,
				forceVector: new Vector()
			},
			{
				forceType: ForceSpherical,
				forceNode: 0,
				forceStrength: 60,
				forceRadius: 3,
				forceArc: 0,
				forceVector: new Vector()
			},
			{
				forceType: ForceField,
				forceNode: 0,
				forceStrength: 250,
				forceRadius: 3,
				forceArc: 0,
				forceVector: new Vector(0, 0, 1)
			},
		];
	}

	public override function init(level:src.MarbleWorld, onFinish:Void->Void) {
		super.init(level, () -> {
			ResourceLoader.load("sound/tornado.wav").entry.load(() -> {
				this.soundChannel = AudioManager.playSound(ResourceLoader.getResource("data/sound/tornado.wav", ResourceLoader.getAudio, this.soundResources),
					new Vector(1e8, 1e8, 1e8), true);
				this.soundChannel.pause = true;
				for (material in this.materials) {
					material.blendMode = Alpha;
					material.mainPass.culling = h3d.mat.Data.Face.None;
					material.mainPass.depthWrite = false;
				}
				if (this.isPQ) {
					var worker = new ResourceLoaderWorker(() -> {
						this.gustData = new ParticleData();
						this.gustData.identifier = "tornadoGust";
						this.gustData.texture = ResourceLoader.getResource("data/particles/gust.png", ResourceLoader.getTexture, this.textureResources);
						this.speckData = new ParticleData();
						this.speckData.identifier = "tornadoSpeck";
						this.speckData.texture = ResourceLoader.getResource("data/particles/speck.png", ResourceLoader.getTexture, this.textureResources);
						this.gustEmitter = this.level.particleManager.createEmitter(tornadoGustOptions, this.gustData, null,
							() -> this.getAbsPos().getPosition());
						this.speckEmitter = this.level.particleManager.createEmitter(tornadoSpeckOptions, this.speckData, null,
							() -> this.getAbsPos().getPosition());

						onFinish();
					});
					worker.loadFile("particles/gust.png");
					worker.loadFile("particles/speck.png");

					worker.run();
					return;
				}
				onFinish();
			});
		});
	}

	public override function dispose() {
		if (this.gustEmitter != null) {
			this.level.particleManager.removeEmitter(this.gustEmitter);
			this.gustEmitter = null;
		}
		if (this.speckEmitter != null) {
			this.level.particleManager.removeEmitter(this.speckEmitter);
			this.speckEmitter = null;
		}
		super.dispose();
	}

	public override function reset() {
		super.reset();

		var seffect = this.soundChannel.getEffect(Spatialization);
		seffect.position = this.getAbsPos().getPosition();

		if (this.soundChannel.pause)
			this.soundChannel.pause = false;
	}
}
