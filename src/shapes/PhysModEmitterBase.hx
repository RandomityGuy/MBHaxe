package shapes;

import src.DtsObject;
import src.MarbleWorld;
import src.ResourceLoader;
import src.ParticleSystem.ParticleData;
import mis.MisParser;
import mis.MissionElement.MissionElementStaticShape;
import triggers.PhysModTrigger;

/** Ported from PQ's standalone `PhysModEmitterBase` `StaticShapeData` (`server/scripts/
	physMod.cs`) - the same decorative shape `PhysModTrigger.buildCornerEmitters` auto-spawns at its
	own trigger volume's 4 corners, but here placed directly in the mission file as its own object
	(confirmed against real missions, e.g. `FistBump.mcs`, which places 4 of these with
	`noParticles = "0"` rather than relying on any trigger to spawn them). Reuses
	`PhysModTrigger.physModParticleOptions` so both spawn paths produce an identical-looking emitter. */
class PhysModEmitterBase extends DtsObject {
	var noParticles:Bool;

	public function new(element:MissionElementStaticShape) {
		super();
		this.dtsPath = "data/shapes_pq/other/physmodemitterbase.dts";
		this.useInstancing = true;
		this.identifier = "PhysModEmitterBase";
		this.isCollideable = false;
		this.isBoundingBoxCollideable = false;

		var noParticlesField = element.fields.get("noparticles");
		this.noParticles = noParticlesField != null && MisParser.parseBoolean(noParticlesField[0]);
	}

	public override function init(level:MarbleWorld, onFinish:Void->Void) {
		super.init(level, () -> {
			if (this.noParticles) {
				onFinish();
				return;
			}
			var particleData = new ParticleData();
			particleData.identifier = "physModParticle";
			particleData.texture = ResourceLoader.getResource("data/particles/orb.png", ResourceLoader.getTexture, this.textureResources);
			this.level.particleManager.createEmitter(physModParticleOptions, particleData, null, () -> this.getAbsPos().getPosition());
			onFinish();
		});
	}
}
