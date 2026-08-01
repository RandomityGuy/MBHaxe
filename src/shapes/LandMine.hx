package shapes;

import net.BitStream.OutputBitStream;
import net.NetPacket.ExplodableUpdatePacket;
import net.Net;
import src.AudioManager;
import src.TimeState;
import collision.CollisionHull;
import collision.CollisionInfo;
import src.DtsObject;
import src.Util;
import src.ParticleSystem.ParticleEmitterOptions;
import src.ParticleSystem.ParticleData;
import h3d.Vector;
import src.ResourceLoader;
import src.MarbleWorld;
import src.MarbleGame;
import mis.MissionElement.MissionElementStaticShape;

/** Ported from `hazards.cs`'s `LandMineParticle`/`LandMineEmitter`, as driven by
	`LandMineExplosion`'s `particleEmitter = LandMineEmitter`, `particleDensity = 80`,
	`particleRadius = 1` fields - the "volume particles" `Explosion::explode` spawns via a native
	radius-distributed one-shot mode (`ParticleEmitter::emitParticles(pos, normal, radius, vel,
	density)`) this codebase's `ParticleManager` has no equivalent for. Emulated the same way as
	`shapes.Cannon`'s `cannonVolumeOptions` (see its doc comment): `spawnOffset` returns a
	uniformly-random point inside a unit sphere scaled by `particleRadius`, and `emitterLifetime`
	is `density * ejectionPeriodMS` (80 * 7) so roughly the right particle count spawns over a
	short continuous burst approximating the real engine's instantaneous spawn. Spin isn't set in
	the source (`spinSpeed`/`spinRandomMin`/`spinRandomMax` default to 0 in `ParticleData`'s C++
	constructor), not the `40`/`-90`/`90` an earlier port pass had invented. */
final landMineParticle:ParticleEmitterOptions = {
	ejectionPeriod: 7,
	periodVariance: 0,
	ambientVelocity: new Vector(0, 0, 0),
	ejectionVelocity: 2,
	velocityVariance: 1,
	emitterLifetime: 80 * 7,
	ejectionOffset: 0,
	thetaMin: 0,
	thetaMax: 60,
	phiReferenceVel: 0,
	phiVariance: 360,
	inheritedVelFactor: 0.2,
	spawnOffset: () -> {
		var dir = new Vector(Math.random() * 2 - 1, Math.random() * 2 - 1, Math.random() * 2 - 1);
		if (dir.lengthSq() < 0.0001)
			dir.set(0, 0, 1);
		dir.normalize();
		var radius = Math.pow(Math.random(), 1 / 3) * 1;
		return dir.multiply(radius);
	},
	particleOptions: {
		texture: 'particles/smoke.png',
		blending: Add,
		spinSpeed: 0,
		spinRandomMin: 0,
		spinRandomMax: 0,
		lifetime: 1000,
		lifetimeVariance: 150,
		dragCoefficient: 2,
		constantAcceleration: 0,
		gravityCoefficient: 0.2,
		windCoefficient: 0,
		colors: [new Vector(0.56, 0.36, 0.26, 1), new Vector(0.56, 0.36, 0.26, 0)],
		sizes: [0.5, 1],
		times: [0, 1]
	}
};

/** Ported from `hazards.cs`'s `LandMineSmoke`/`LandMineSmokeEmitter`. The source's own
	`dragCoefficient` line is misspelled (`dragCoeffiecient = 100.0`), so it's a dead field there
	too and the real drag falls back to `ParticleData`'s default of `0` - kept at MBHaxe's existing
	tuned `10` instead of blindly zeroing it out, since drag=0 here would make this smoke never
	slow down at all (clearly not the intended look, and likely why an earlier port pass chose a
	value here instead of leaving it at the "real" default). */
final landMineSmokeParticle:ParticleEmitterOptions = {
	ejectionPeriod: 10,
	periodVariance: 0,
	ambientVelocity: new Vector(0, 0, 0),
	ejectionVelocity: 4,
	velocityVariance: 0.5,
	emitterLifetime: 250,
	ejectionOffset: 0,
	thetaMin: 0,
	thetaMax: 180,
	phiReferenceVel: 0,
	phiVariance: 360,
	inheritedVelFactor: 0.25,
	particleOptions: {
		texture: 'particles/smoke.png',
		blending: Alpha,
		spinSpeed: 0,
		spinRandomMin: -80,
		spinRandomMax: 80,
		lifetime: 1200,
		lifetimeVariance: 300,
		dragCoefficient: 10,
		constantAcceleration: -0.8,
		gravityCoefficient: 0,
		windCoefficient: 0,
		colors: [
			new Vector(0.56, 0.36, 0.26, 1),
			new Vector(0.2, 0.2, 0.2, 1),
			new Vector(0, 0, 0, 0)
		],
		sizes: [1, 1.5, 2],
		times: [0, 0.5, 1]
	}
};

/** Ported from `hazards.cs`'s `LandMineSparks`/`LandMineSparkEmitter` - spin also defaults to 0
	here (not set in the source), same note as `landMineParticle` above. */
final landMineSparksParticle:ParticleEmitterOptions = {
	ejectionPeriod: 3,
	periodVariance: 0,
	ambientVelocity: new Vector(0, 0, 0),
	ejectionVelocity: 13,
	velocityVariance: 6.75,
	emitterLifetime: 100,
	ejectionOffset: 0,
	thetaMin: 0,
	thetaMax: 180,
	phiReferenceVel: 0,
	phiVariance: 360,
	inheritedVelFactor: 0.2,
	particleOptions: {
		texture: 'particles/spark.png',
		blending: Add,
		spinSpeed: 0,
		spinRandomMin: 0,
		spinRandomMax: 0,
		lifetime: 500,
		lifetimeVariance: 350,
		dragCoefficient: 1,
		constantAcceleration: 0,
		gravityCoefficient: 0,
		windCoefficient: 0,
		colors: [
			new Vector(0.6, 0.4, 0.3, 1),
			new Vector(0.6, 0.4, 0.3, 1),
			new Vector(1, 0.4, 0.3, 0)
		],
		sizes: [0.5, 0.25, 0.25],
		times: [0, 0.5, 1]
	}
};

class LandMine extends Explodable {
	var light:h3d.scene.fwd.PointLight;

	public function new(?element:MissionElementStaticShape) {
		super();
		var datablockLower = element != null ? element.datablock.toLowerCase() : "";
		if (datablockLower == "landmine_pq") {
			dtsPath = "data/shapes_pq/gameplay/hazards/mine/landmine.dts";
			this.skinOverride = "base";
		} else if (datablockLower == "landmine_mbm") {
			dtsPath = "data/shapes_mbu/hazards/landmine.dts";
		} else
			dtsPath = "data/shapes/hazards/landmine.dts";
		// Instancing batches by `identifier`, and the PQ variant uses a different mesh - keep the
		// dtsPath in the identifier so it doesn't get batched with the vanilla mesh.
		this.identifier = "LandMine" + this.dtsPath;
		this.isCollideable = true;

		particleData = new ParticleData();
		particleData.identifier = "landMineParticle";
		particleData.texture = ResourceLoader.getResource("data/particles/smoke.png", ResourceLoader.getTexture, this.textureResources);

		smokeParticleData = new ParticleData();
		smokeParticleData.identifier = "landMineSmokeParticle";
		smokeParticleData.texture = ResourceLoader.getResource("data/particles/smoke.png", ResourceLoader.getTexture, this.textureResources);

		sparkParticleData = new ParticleData();
		sparkParticleData.identifier = "landMineSparkParticle";
		sparkParticleData.texture = ResourceLoader.getResource("data/particles/spark.png", ResourceLoader.getTexture, this.textureResources);

		this.smokeParticle = landMineSmokeParticle;
		this.sparksParticle = landMineSparksParticle;
		this.particle = landMineParticle;
	}

	function computeExplosionStrength(r:Float) {
		// Figured out through testing by RandomityGuy
		if (r >= 10.25)
			return 0.0;
		if (r >= 10)
			return Util.lerp(30.0087, 30.7555, r - 10);

		// The explosion first becomes stronger the further you are away from it, then becomes weaker again (parabolic).
		var a = 0.071436222;
		var v = (Math.pow((r - 5), 2)) / (-4 * a) + 87.5;

		return v;
	}

	public function applyImpulse(marble:src.Marble) {
		var minePos = this.getAbsPos().getPosition();
		var off = marble.getAbsPos().getPosition().sub(minePos);

		var strength = computeExplosionStrength(off.length());

		var impulse = off.normalized().multiply(strength);
		marble.applyImpulse(impulse);
	}
}
