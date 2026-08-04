package triggers;

import h3d.Vector;
import h3d.mat.BlendMode;
import src.TimeState;
import src.Marble;
import src.MarbleWorld;
import src.PhysicsAttributeOverride;
import src.DtsObject;
import src.ResourceLoader;
import src.ResourceLoaderWorker;
import src.ParticleSystem.ParticleData;
import src.ParticleSystem.ParticleEmitterOptions;
import mis.MisParser;
import mis.MissionElement.MissionElementTrigger;

final physModParticleOptions:ParticleEmitterOptions = {
	ejectionPeriod: 150,
	periodVariance: 5,
	ambientVelocity: new Vector(0, 0, 0),
	ejectionVelocity: 1.5,
	velocityVariance: 0.25,
	emitterLifetime: 1e9,
	ejectionOffset: 0,
	thetaMin: -11.25,
	thetaMax: 11.25,
	phiReferenceVel: 0,
	phiVariance: 360,
	inheritedVelFactor: 0,
	particleOptions: {
		texture: 'particles/orb.png',
		blending: BlendMode.Add,
		spinSpeed: 10,
		spinRandomMin: 0,
		spinRandomMax: 0,
		lifetime: 6000,
		lifetimeVariance: 0,
		dragCoefficient: 1,
		constantAcceleration: 0,
		gravityCoefficient: -0.2,
		windCoefficient: 0,
		colors: [new Vector(1, 1, 1, 1), new Vector(0.5, 0.5, 1, 0.75), new Vector(0, 0, 1, 0.25)],
		sizes: [1, 2, 5],
		times: [1, 1.5, 2]
	}
};

class PhysModTrigger extends Trigger {
	var overrides:Array<PhysicsAttributeOverride>;
	var noEmitters:Bool;

	public var disabled:Bool;

	var activeLayers:Map<Marble, Array<PhysicsAttributeOverride>> = new Map();

	public function new(element:MissionElementTrigger, level:MarbleWorld) {
		super(element, level);

		this.overrides = [];
		var i = 0;
		while (true) {
			var attrField = element.fields.get("marbleattribute" + i);
			if (attrField == null || attrField[0] == "")
				break;
			var valueField = element.fields.get("value" + i);
			var value = valueField != null && valueField[0] != "" ? MisParser.parseNumber(valueField[0]) : 0;
			this.overrides.push({attribute: attrField[0].toLowerCase(), value: value});
			i++;
		}

		var disabledField = element.fields.get("disabled");
		this.disabled = disabledField != null && MisParser.parseBoolean(disabledField[0]);

		var noEmittersField = element.fields.get("noemitters");
		var builtEmittersField = element.fields.get("_builtemitters");
		this.noEmitters = noEmittersField != null
			&& MisParser.parseBoolean(noEmittersField[0])
			|| (builtEmittersField != null && MisParser.parseBoolean(builtEmittersField[0]));
	}

	public override function init(onFinish:Void->Void) {
		super.init(() -> {
			if (this.noEmitters) {
				onFinish();
				return;
			}
			buildCornerEmitters(onFinish);
		});
	}

	function buildCornerEmitters(onFinish:Void->Void) {
		var scale = MisParser.parseVector3(this.element.scale);
		var x = this.x, y = this.y, z = this.z;
		var corners = [
			new Vector(x, y, z),
			new Vector(x - scale.x, y, z),
			new Vector(x, y - scale.y, z),
			new Vector(x - scale.x, y - scale.y, z)
		];

		var worker = new ResourceLoaderWorker(onFinish);
		for (i in 0...corners.length) {
			var corner = corners[i];
			worker.addTask(fwd -> {
				var base = new DtsObject();
				base.dtsPath = "data/shapes_pq/other/physmodemitterbase.dts";
				base.useInstancing = true;
				base.identifier = "PhysModEmitterBase";
				base.isCollideable = false;
				base.isBoundingBoxCollideable = false;
				this.level.addDtsObject(base, () -> {
					base.setPosition(corner.x, corner.y, corner.z);

					var particleData = new ParticleData();
					particleData.identifier = "physModParticle";
					particleData.texture = ResourceLoader.getResource("data/particles/orb.png", ResourceLoader.getTexture, this.textureResources);
					this.level.particleManager.createEmitter(physModParticleOptions, particleData, null, () -> base.getAbsPos().getPosition());

					fwd();
				});
			});
		}
		worker.run();
	}

	override function onMarbleEnter(marble:Marble, timeState:TimeState) {
		if (this.disabled || this.activeLayers.exists(marble) || this.overrides.length == 0)
			return;
		this.activeLayers.set(marble, marble.pushPhysicsLayer(this.overrides));
	}

	override function onMarbleLeave(marble:Marble, timeState:TimeState) {
		var layer = this.activeLayers.get(marble);
		if (layer == null)
			return;
		marble.popPhysicsLayer(layer);
		this.activeLayers.remove(marble);
	}
}
