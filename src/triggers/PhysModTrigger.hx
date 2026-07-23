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

/** Ambient orb particles drifting up from each corner emitter base - ported from PQ's
	`PhysModParticle`/`PhysModEmitter` datablocks (`server/scripts/physMod.cs`). PQ's engine has a
	true `gravityCoefficient` (a world-down accelerator independent of particle velocity); this
	engine's `ParticleOptions.acceleration` instead accelerates *along the particle's own velocity
	vector* - since these particles are ejected in a narrow cone (`thetaMin/Max = ±11.25°`) close to
	straight up, using the same numeric value as a negative "along-velocity" acceleration still
	closely approximates the original's slow upward-drift-then-fall-back arc. */
final physModParticleOptions:ParticleEmitterOptions = {
	ejectionPeriod: 150,
	ambientVelocity: new Vector(0, 0, 0),
	ejectionVelocity: 1.5,
	velocityVariance: 0.25,
	emitterLifetime: 1e9,
	inheritedVelFactor: 0,
	particleOptions: {
		texture: 'particles/orb.png',
		blending: BlendMode.Alpha,
		spinSpeed: 10,
		spinRandomMin: 0,
		spinRandomMax: 0,
		lifetime: 6000,
		lifetimeVariance: 0,
		dragCoefficient: 1,
		acceleration: -0.2,
		colors: [new Vector(1, 1, 1, 1), new Vector(0.5, 0.5, 1, 0.75), new Vector(0, 0, 1, 0.25)],
		sizes: [1, 2, 5],
		times: [1, 1.5, 2]
	}
};

/** Ported from PQ's `MarblePhysModTrigger` (`server/scripts/physMod.cs`) - reads a 0-based indexed
	list of `marbleAttribute[i]`/`value[i]` fields (confirmed against a real mission,
	`SpecificGravity.mis`: `marbleAttribute0 = "gravity"`, `value0 = "6"`) and pushes/pops a single
	physics layer of those overrides on marble-enter/marble-leave (`Marble.pushPhysicsLayer`/
	`popPhysicsLayer`, itself ported from `Physics::pushLayer`/`popLayer` in `client/scripts/
	physics.cs`) - this is exactly how overlapping `PhysMod` volumes combine correctly in the
	original, since it's the same generic layer stack every other temporary physics override
	(frozen, cannon-lock, etc.) uses. `megaValue[i]` (the mega-marble-specific override half of each
	field) isn't ported - out of scope for this pass.

	Unless `noEmitters` is set, also spawns 4 decorative `PhysModEmitterBase` shapes (each with an
	ambient orb particle emitter) at the trigger volume's corners, matching `buildPhysmodEmitters`'s
	`%pos[0..3]` computation (`%obj`'s own position, offset by its scale on X/Y only - not the real
	polyhedron shape, and never accounting for rotation - reproduced as-is, quirks included). */
class PhysModTrigger extends Trigger {
	var overrides:Array<PhysicsAttributeOverride>;
	var noEmitters:Bool;

	// One pushed layer per marble currently inside this volume - `pushPhysicsLayer`/
	// `popPhysicsLayer` operate per-`Marble` instance, so each overlapping marble (relevant in
	// multiplayer) needs its own tracked layer to pop later.
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
			this.overrides.push({attribute: attrField[0], value: value});
			i++;
		}

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
		// `%obj.getScale()` in the original - `Trigger` bakes its authored scale directly into
		// `collider`'s vertices rather than the scene object's own `scaleX`/`scaleY`, so it has to
		// be parsed again here rather than read off `this`.
		var scale = MisParser.parseVector3(this.element.scale);
		var x = this.x, y = this.y, z = this.z;
		// Only X gets negated when parsing mission coordinates (`Trigger`'s constructor), so a
		// `+scale` offset in PQ's own coordinate space becomes `-scale` here to land on the same
		// physical corner; Y isn't flipped, so its offset direction carries over unchanged.
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
		if (this.activeLayers.exists(marble) || this.overrides.length == 0)
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
