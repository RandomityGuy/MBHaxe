package src;

import mis.MisParser;
import triggers.Trigger;
import net.Net;
import gui.MarbleSelectGui;
import net.NetPacket.MarbleNetFlags;
import net.BitStream.OutputBitStream;
import net.ClientConnection;
import net.ClientConnection.GameConnection;
import net.NetPacket.MarbleUpdatePacket;
import net.MoveManager;
import net.MoveManager.NetMove;
import collision.CollisionPool;
import collision.CollisionHull;
import dif.Plane;
import shaders.marble.ClassicGlass;
import shaders.marble.ClassicMetal;
import shaders.marble.ClassicMarb3;
import shaders.marble.ClassicMarb2;
import shaders.marble.ClassicGlassPureSphere;
import h3d.mat.MaterialDatabase;
import shaders.MarbleReflection;
import shaders.CubemapRenderer;
import h3d.shader.AlphaMult;
import shaders.DtsTexture;
import collision.gjk.GJK;
import collision.gjk.ConvexHull;
import hxd.snd.effect.Pitch;
import hxd.snd.effect.Spatialization;
import hxd.snd.Channel;
import shapes.TriangleBumper;
import shapes.RoundBumper;
import src.Util;
import src.AudioManager;
import src.Settings;
import h3d.scene.Mesh;
import h3d.col.Bounds;
import collision.CollisionEntity;
import src.TimeState;
import src.ParticleSystem.ParticleEmitter;
import src.ParticleSystem.ParticleData;
import src.ParticleSystem.ParticleEmitterOptions;
import src.DtsObject;
import hxd.Cursor;
import shapes.PowerUp;
import src.GameObject;
import src.ForceObject;
import src.MarbleWorld;
import h3d.Quat;
import src.ResourceLoader;
import collision.Collision;
import dif.math.Point3F;
import dif.math.PlaneF;
import collision.CollisionSurface;
import src.PathedInterior;
import collision.SphereCollisionEntity;
import hxd.Key;
import collision.CollisionInfo;
import h3d.Matrix;
import collision.CollisionWorld;
import h3d.col.ObjectCollider;
import h3d.col.Collider.GroupCollider;
import h3d.Vector;
import h3d.mat.Material;
import h3d.prim.Sphere;
import h3d.scene.Object;
import src.MarbleGame;
import src.CameraController;
import src.Resource;
import h3d.mat.Texture;
import collision.CCDCollision.TraceInfo;
import src.ResourceLoaderWorker;
import src.InteriorObject;
import src.Console;
import src.Gamepad;
import net.Move;
import src.ProfilerUI;
import src.PhysicsAttributeOverride;

enum Mode {
	Start;
	Play;
	Finish;
}

/** Ported from `marble.cs`'s `BounceParticle`/`MarbleBounceEmitter` ($pref::Video::particleSystem
	== 1, or the identical `else` fallback - both branches have the same values). */
final bounceParticleOptions:ParticleEmitterOptions = {
	ejectionPeriod: 80,
	ambientVelocity: new Vector(0, 0, 0.0),
	ejectionVelocity: 3,
	velocityVariance: 0.25,
	emitterLifetime: 250,
	inheritedVelFactor: 0,
	thetaMin: 80,
	thetaMax: 90,
	phiReferenceVel: 0,
	phiVariance: 360,
	ejectionOffset: 0,
	particleOptions: {
		texture: 'particles/star.png',
		blending: Alpha,
		spinSpeed: 90,
		spinRandomMin: -90,
		spinRandomMax: 90,
		lifetime: 500,
		lifetimeVariance: 100,
		dragCoefficient: 1,
		constantAcceleration: -2,
		gravityCoefficient: 0,
		windCoefficient: 0,
		colors: [new Vector(0.9, 0, 0, 1), new Vector(0.9, 0.9, 0, 1), new Vector(0.9, 0.9, 0, 0)],
		sizes: [0.25, 0.25, 0.25],
		times: [0, 0.75, 1]
	}
};

/** Ported from `server/scripts/particles/MarbleTrailEmitter.cs`'s default (`$pref::Video::
	particleSystem == 0`) branch - `MarbleTrailParticle`/`MarbleTrailEmitter`, the real "gold" speed
	trail shown when `$TrailEmitterSpeed < speed < $TrailEmitterWhiteSpeed` (see
	`Marble.updateTrailEmitters`). Distinct from the dead, never-referenced `TrailParticle`/
	`MarbleTrailOldEmitter` pair in `marble.cs` (kept only "so the engine don't go KABOOM" per its
	own comment) - this is the datablock `Marble::assignNewTrailEmitter` actually wires up. */
final trailParticleOptions:ParticleEmitterOptions = {
	ejectionPeriod: 100,
	periodVariance: 8,
	ejectionVelocity: 2,
	velocityVariance: 0.25,
	emitterLifetime: 1e9,
	inheritedVelFactor: 0,
	ambientVelocity: new Vector(),
	thetaMin: 90,
	thetaMax: 100,
	phiReferenceVel: 0,
	phiVariance: 360,
	ejectionOffset: 0,
	particleOptions: {
		texture: 'particles/spark.png',
		blending: Alpha,
		spinSpeed: 10,
		spinRandomMin: 0,
		spinRandomMax: 0.5,
		dragCoefficient: 0,
		lifetime: 992,
		lifetimeVariance: 128,
		constantAcceleration: 0,
		gravityCoefficient: -0.002442,
		windCoefficient: 0,
		colors: [
			new Vector(1.0, 1.0, 0.236220, 0.227451),
			new Vector(1.0, 1.0, 0.740157, 1.0),
			new Vector(1.0, 1.0, 0.141732, 0.0),
			new Vector(1.0, 1.0, 1.0, 1.0)
		],
		sizes: [0.19, 0.19, 0.29, 1],
		times: [0, 0.2, 1, 1]
	}
};

/** Ported from `MarbleTrailEmitter.cs`'s default branch - `MarbleWhiteTrailParticle`/
	`MarbleWhiteTrailEmitter`, shown when `speed >= $TrailEmitterWhiteSpeed`. */
final whiteTrailParticleOptions:ParticleEmitterOptions = {
	ejectionPeriod: 50,
	periodVariance: 20,
	ejectionVelocity: 2,
	velocityVariance: 0.25,
	emitterLifetime: 1e9,
	inheritedVelFactor: 0,
	ambientVelocity: new Vector(),
	thetaMin: 90,
	thetaMax: 100,
	phiReferenceVel: 0,
	phiVariance: 360,
	ejectionOffset: 0,
	particleOptions: {
		texture: 'particles/spark.png',
		blending: Alpha,
		spinSpeed: 10,
		spinRandomMin: 0,
		spinRandomMax: 0.5,
		dragCoefficient: 0,
		lifetime: 992,
		lifetimeVariance: 128,
		constantAcceleration: 0,
		gravityCoefficient: -0.002442,
		windCoefficient: 0,
		colors: [
			new Vector(1.0, 1.0, 1.0, 0.227451),
			new Vector(1.0, 1.0, 1.0, 1.0),
			new Vector(1.0, 1.0, 1.0, 0.0),
			new Vector(1.0, 1.0, 1.0, 1.0)
		],
		sizes: [0.19, 0.19, 0.29, 1],
		times: [0, 0.2, 1, 1]
	}
};

/** Ported from `server/scripts/marble.cs`'s `MarbleTrailBubbleParticle`/`MarbleTrailBubbleEmitter` -
	the continuous "bubble trail" shown while moving fully submerged in water (as opposed to
	`Splash4`, shown while partially submerged/skimming the surface - see `updateTrailEmitters`). */
final trailBubbleParticleOptions:ParticleEmitterOptions = {
	ejectionPeriod: 20,
	periodVariance: 19,
	ejectionVelocity: 0,
	velocityVariance: 0,
	emitterLifetime: 1e9,
	inheritedVelFactor: 0,
	ambientVelocity: new Vector(),
	thetaMin: 0,
	thetaMax: 61.7647,
	phiReferenceVel: 0,
	phiVariance: 360,
	ejectionOffset: 0.2,
	particleOptions: {
		texture: 'particles/bubble.png',
		blending: Add,
		spinSpeed: 1,
		spinRandomMin: 0,
		spinRandomMax: 0.5,
		dragCoefficient: 1.176,
		lifetime: 1000,
		lifetimeVariance: 176,
		constantAcceleration: 0,
		gravityCoefficient: -0.176,
		windCoefficient: 0,
		colors: [
			new Vector(0.843137, 0.833333, 0.843137, 1.0),
			new Vector(0.784314, 0.813725, 0.882353, 1.0),
			new Vector(0.843137, 0.862745, 0.892157, 1.0),
			new Vector(0.892157, 0.911765, 0.980392, 0.0)
		],
		sizes: [0, 0.05, 0.1, 0.3],
		times: [0, 0.0212202, 0.93756, 1]
	}
};

/** Ported from `server/scripts/particles/Splash4Emitter.cs` - the continuous "skimming the
	surface" trail (as opposed to the one-shot entry/exit `Splash1/2/3` bursts already ported -
	see `updateWater`). Reuses the same `splash1.png` texture as `Splash1Emitter` (the source
	itself references `platinum/data/particles/splash1`, not a distinct "splash4" asset). */
final splash4ParticleOptions:ParticleEmitterOptions = {
	ejectionPeriod: 49,
	periodVariance: 48,
	ejectionVelocity: 0,
	velocityVariance: 0,
	emitterLifetime: 1e9,
	inheritedVelFactor: 0,
	ambientVelocity: new Vector(),
	thetaMin: 0,
	thetaMax: 37.0588,
	phiReferenceVel: 0,
	phiVariance: 360,
	ejectionOffset: 0.294118,
	particleOptions: {
		texture: 'particles/splash1.png',
		blending: Add,
		spinSpeed: 10,
		spinRandomMin: -90,
		spinRandomMax: 156.863,
		dragCoefficient: 5.71236,
		lifetime: 618,
		lifetimeVariance: 96,
		constantAcceleration: 0,
		gravityCoefficient: -0.176471,
		windCoefficient: 0,
		colors: [
			new Vector(0.843137, 0.833333, 0.843137, 0.441176),
			new Vector(0.784314, 0.813725, 0.882353, 0.686275),
			new Vector(0.843137, 0.862745, 0.892157, 0.264706),
			new Vector(0.892157, 0.911765, 0.980392, 0.0)
		],
		sizes: [0.25, 0.25, 0.34, 0.34],
		times: [0, 0.28, 0.73, 1]
	}
};

/** Ported from `server/scripts/particles/MarbleSnoreEmitter.cs` - shown when the marble hasn't
	moved for `snoreTimeout` (10s) while play is actually in progress (see `updateTrailEmitters`).
	Gated on a hardcoded-enabled equivalent of `$pref::Snore` (defaults `true` in real PQ,
	`client/defaults.cs`) - not wired to a settings toggle here, since none exists yet for it. */
final snoreParticleOptions:ParticleEmitterOptions = {
	ejectionPeriod: 1500,
	periodVariance: 300,
	ejectionVelocity: 0.2,
	velocityVariance: 0.05,
	emitterLifetime: 1e9,
	inheritedVelFactor: 0,
	ambientVelocity: new Vector(),
	thetaMin: 7.5,
	thetaMax: 45,
	phiReferenceVel: 20,
	phiVariance: 0,
	ejectionOffset: 0.2,
	particleOptions: {
		texture: 'particles/zzz.png',
		blending: Add,
		spinSpeed: 0,
		spinRandomMin: 0,
		spinRandomMax: 0,
		dragCoefficient: 0.9975,
		lifetime: 3000,
		lifetimeVariance: 475,
		constantAcceleration: 0,
		gravityCoefficient: -0.0525,
		windCoefficient: 0,
		colors: [
			new Vector(0.787402, 1.0, 0.787402, 1.0),
			new Vector(0.787402, 1.0, 0.787402, 1.0),
			new Vector(1.0, 1.0, 1.0, 0.0),
			new Vector(1.0, 1.0, 1.0, 1.0)
		],
		sizes: [0, 0.5, 0, 1],
		times: [0, 0.15, 1, 1]
	}
};

/** Ported from `server/scripts/particles/Fireball3Emitter.cs` - part of the "fireball" trail set,
	shown instead of the normal Trail/WhiteTrail while `%player.fireball` is set (see
	`updateTrailEmitters`). Nothing in `marble.cs`/`powerups.cs` ever actually sets that datafield
	in real PQ - this is genuinely dead/unreachable content there too, reproduced faithfully rather
	than skipped, matching [PQ Port Fidelity](pq-port-fidelity.md). */
final fireball3ParticleOptions:ParticleEmitterOptions = {
	ejectionPeriod: 49,
	periodVariance: 48,
	ejectionVelocity: 0,
	velocityVariance: 0,
	emitterLifetime: 1e9,
	inheritedVelFactor: 0,
	ambientVelocity: new Vector(),
	thetaMin: 0,
	thetaMax: 90,
	phiReferenceVel: 0,
	phiVariance: 360,
	ejectionOffset: 0.2,
	particleOptions: {
		texture: 'particles/fireball_3.png',
		blending: Add,
		spinSpeed: 10,
		spinRandomMin: 2000,
		spinRandomMax: 2000,
		dragCoefficient: 2.54902,
		lifetime: 480,
		lifetimeVariance: 96,
		constantAcceleration: 0,
		gravityCoefficient: -0.2,
		windCoefficient: 0,
		colors: [
			new Vector(0.843137, 0.833333, 0.843137, 0.441176),
			new Vector(0.784314, 0.813725, 0.882353, 1.0),
			new Vector(0.843137, 0.862745, 0.892157, 0.0),
			new Vector(0.892157, 0.911765, 0.980392, 0.0)
		],
		sizes: [0.1, 0.24, 1.08, 1],
		times: [0, 0.28, 0.74, 1]
	}
};

/** Ported from `server/scripts/particles/Fireball4_2Emitter.cs` - the second half of the fireball
	trail pair, always shown alongside `Fireball3`. Same dead/unreachable status as above. */
final fireball4ParticleOptions:ParticleEmitterOptions = {
	ejectionPeriod: 10,
	periodVariance: 0,
	ejectionVelocity: 0,
	velocityVariance: 0,
	emitterLifetime: 1e9,
	inheritedVelFactor: 0,
	ambientVelocity: new Vector(),
	thetaMin: 0,
	thetaMax: 61.7647,
	phiReferenceVel: 0,
	phiVariance: 360,
	ejectionOffset: 0,
	particleOptions: {
		texture: 'particles/fireball_4.png',
		blending: Add,
		spinSpeed: 10,
		spinRandomMin: -100,
		spinRandomMax: 0.5,
		dragCoefficient: 2.54902,
		lifetime: 150,
		lifetimeVariance: 0,
		constantAcceleration: 0,
		gravityCoefficient: 0.215686,
		windCoefficient: 0,
		colors: [
			new Vector(0.843137, 0.833333, 0.843137, 0.0),
			new Vector(0.784314, 0.813725, 0.882353, 1.0),
			new Vector(0.843137, 0.862745, 0.892157, 0.0),
			new Vector(0.892157, 0.911765, 0.980392, 0.0)
		],
		sizes: [0.88, 0.59, 0, 1],
		times: [0, 0.14, 0.72, 1]
	}
};

/** Ported from `server/scripts/particles/Fireball3MegaEmitter.cs` - the Mega-marble-scaled variant
	of `Fireball3`, swapped in when `Marble.isMegaMarbleEnabled` (see `updateTrailEmitters`). Same
	dead/unreachable status as `Fireball3` itself (nothing sets `fireball`). */
final fireball3MegaParticleOptions:ParticleEmitterOptions = {
	ejectionPeriod: 49,
	periodVariance: 48,
	ejectionVelocity: 0,
	velocityVariance: 0,
	emitterLifetime: 1e9,
	inheritedVelFactor: 0,
	ambientVelocity: new Vector(),
	thetaMin: 0,
	thetaMax: 90,
	phiReferenceVel: 0,
	phiVariance: 360,
	ejectionOffset: 0.2,
	particleOptions: {
		texture: 'particles/fireball_3.png',
		blending: Add,
		spinSpeed: 10,
		spinRandomMin: 2000,
		spinRandomMax: 2000,
		dragCoefficient: 2.54902,
		lifetime: 480,
		lifetimeVariance: 96,
		constantAcceleration: 0,
		gravityCoefficient: -0.2,
		windCoefficient: 0,
		colors: [
			new Vector(0.843137, 0.833333, 0.843137, 0.441176),
			new Vector(0.784314, 0.813725, 0.882353, 1.0),
			new Vector(0.843137, 0.862745, 0.892157, 0.0),
			new Vector(0.892157, 0.911765, 0.980392, 0.0)
		],
		sizes: [0.35, 0.84, 3.2, 2.9],
		times: [0, 0.28, 0.74, 1]
	}
};

/** Ported from `server/scripts/particles/Fireball4_2MegaEmitter.cs` - the Mega-marble-scaled
	variant of `Fireball4_2`. Same dead/unreachable status. */
final fireball4MegaParticleOptions:ParticleEmitterOptions = {
	ejectionPeriod: 10,
	periodVariance: 0,
	ejectionVelocity: 0,
	velocityVariance: 0,
	emitterLifetime: 1e9,
	inheritedVelFactor: 0,
	ambientVelocity: new Vector(),
	thetaMin: 0,
	thetaMax: 61.7647,
	phiReferenceVel: 0,
	phiVariance: 360,
	ejectionOffset: 0,
	particleOptions: {
		texture: 'particles/fireball_4.png',
		blending: Add,
		spinSpeed: 10,
		spinRandomMin: -100,
		spinRandomMax: 0.5,
		dragCoefficient: 2.54902,
		lifetime: 150,
		lifetimeVariance: 0,
		constantAcceleration: 0,
		gravityCoefficient: 0.215686,
		windCoefficient: 0,
		colors: [
			new Vector(0.843137, 0.833333, 0.843137, 0.0),
			new Vector(0.784314, 0.813725, 0.882353, 1.0),
			new Vector(0.843137, 0.862745, 0.892157, 0.0),
			new Vector(0.892157, 0.911765, 0.980392, 0.0)
		],
		sizes: [2.7, 1.8, 0, 3.0],
		times: [0, 0.14, 0.72, 1]
	}
};

/** Ported from `server/scripts/particles/Fireball1Emitter.cs` - one of the 3 one-shot burst
	emitters `FireballItem::Blast` spawns at the marble's position when blasting (distinct from the
	continuous Fireball3/4_2 trail emitters above - see `Marble.fireballBlast`). */
final fireball1BlastParticleOptions:ParticleEmitterOptions = {
	ejectionPeriod: 2,
	periodVariance: 0,
	ejectionVelocity: 3.92157,
	velocityVariance: 0.05,
	emitterLifetime: 98,
	inheritedVelFactor: 0,
	ambientVelocity: new Vector(),
	thetaMin: 0,
	thetaMax: 180,
	phiReferenceVel: 0,
	phiVariance: 360,
	ejectionOffset: 0.2,
	particleOptions: {
		texture: 'particles/fireball_1.png',
		blending: Add,
		spinSpeed: 6.47059,
		spinRandomMin: -90,
		spinRandomMax: 210.784,
		dragCoefficient: 1.17647,
		lifetime: 480,
		lifetimeVariance: 96,
		constantAcceleration: 0,
		gravityCoefficient: 0.156863,
		windCoefficient: 0,
		colors: [
			new Vector(0.843137, 0.715686, 0.666667, 0.0),
			new Vector(0.784314, 0.607843, 0.529412, 1.0),
			new Vector(0.882353, 0.529412, 0.372549, 0.588235),
			new Vector(0.892157, 0.911765, 0.980392, 0.0)
		],
		sizes: [0.1, 0.24, 1.08, 1.91],
		times: [0, 0.28, 0.74, 1]
	}
};

/** Ported from `server/scripts/particles/Fireball2Emitter.cs` - always spawned alongside
	Fireball1/Fireball4 on a blast. Real source reuses the "fireball_4" texture despite the
	datablock name (`animTexName[0]` says "fireball_2" but `textureName` - the field the engine
	actually reads - says "fireball_4"), reproduced as-is. */
final fireball2BlastParticleOptions:ParticleEmitterOptions = {
	ejectionPeriod: 4,
	periodVariance: 3,
	ejectionVelocity: 3.92157,
	velocityVariance: 0.05,
	emitterLifetime: 166,
	inheritedVelFactor: 0,
	ambientVelocity: new Vector(),
	thetaMin: 109.412,
	thetaMax: 176.471,
	phiReferenceVel: 0,
	phiVariance: 360,
	ejectionOffset: 1.17647,
	particleOptions: {
		texture: 'particles/fireball_4.png',
		blending: Add,
		spinSpeed: 9.11765,
		spinRandomMin: -100,
		spinRandomMax: 460.784,
		dragCoefficient: 1.17647,
		lifetime: 480,
		lifetimeVariance: 96,
		constantAcceleration: 0.392157,
		gravityCoefficient: 0,
		windCoefficient: 0,
		colors: [
			new Vector(0.843137, 0.833333, 0.843137, 0.441176),
			new Vector(0.784314, 0.813725, 0.882353, 1.0),
			new Vector(0.843137, 0.862745, 0.892157, 0.0),
			new Vector(0.892157, 0.911765, 0.980392, 0.0)
		],
		sizes: [0.78, 0.93, 0, 0],
		times: [0, 0.28, 0.74, 1]
	}
};

/** Ported from `server/scripts/particles/Fireball4Emitter.cs` - the third blast-burst emitter.
	Distinct datablock from the continuous `fireball4ParticleOptions` (`Fireball4_2Emitter`) despite
	sharing a texture - different ejection/timing values. */
final fireball4BlastParticleOptions:ParticleEmitterOptions = {
	ejectionPeriod: 1,
	periodVariance: 0,
	ejectionVelocity: 0,
	velocityVariance: 0,
	emitterLifetime: 88,
	inheritedVelFactor: 0,
	ambientVelocity: new Vector(),
	thetaMin: 0,
	thetaMax: 61.7647,
	phiReferenceVel: 0,
	phiVariance: 360,
	ejectionOffset: 0,
	particleOptions: {
		texture: 'particles/fireball_4.png',
		blending: Add,
		spinSpeed: 10,
		spinRandomMin: -100,
		spinRandomMax: 500,
		dragCoefficient: 2.54902,
		lifetime: 300,
		lifetimeVariance: 31,
		constantAcceleration: 0,
		gravityCoefficient: 0,
		windCoefficient: 0,
		colors: [
			new Vector(0.843137, 0.833333, 0.843137, 0.441176),
			new Vector(0.784314, 0.813725, 0.882353, 1.0),
			new Vector(0.843137, 0.862745, 0.892157, 0.0),
			new Vector(0.892157, 0.911765, 0.980392, 0.0)
		],
		sizes: [0.1, 0.1, 1.08, 1],
		times: [0, 0.143236, 0.721485, 1]
	}
};

/** Ported from `mp/blast.cs`'s `BlastSmoke`/`BlastEmitter` (the plain, non-"MBU"/non-"Ultra"
	variant - matches this port's non-mega blast). */
final blastParticleOptions:ParticleEmitterOptions = {
	ejectionPeriod: 1,
	ambientVelocity: new Vector(0, 0, -0.3),
	ejectionVelocity: 4,
	velocityVariance: 0,
	emitterLifetime: 500,
	inheritedVelFactor: 0,
	thetaMin: 90,
	thetaMax: 100,
	phiReferenceVel: 0,
	phiVariance: 360,
	ejectionOffset: 0,
	particleOptions: {
		texture: 'particles/smoke.png',
		blending: Alpha,
		spinSpeed: 20,
		spinRandomMin: 0,
		spinRandomMax: 0,
		lifetime: 500,
		lifetimeVariance: 100,
		dragCoefficient: 1,
		constantAcceleration: 0,
		gravityCoefficient: 0,
		windCoefficient: 0,
		colors: [new Vector(0, 1, 1, 0.1), new Vector(0, 1, 1, 0.5), new Vector(0, 1, 1, 0.9)],
		sizes: [0.125, 0.125, 0.125],
		times: [0, 0.4, 1]
	}
}

/** Ported from `mp/blast.cs`'s `UltraBlastSmoke`/`UltraBlastEmitter`. */
final blastMaxParticleOptions:ParticleEmitterOptions = {
	ejectionPeriod: 1,
	ambientVelocity: new Vector(0, 0, -0.3),
	ejectionVelocity: 4,
	velocityVariance: 0,
	emitterLifetime: 500,
	inheritedVelFactor: 0,
	thetaMin: 90,
	thetaMax: 100,
	phiReferenceVel: 0,
	phiVariance: 360,
	ejectionOffset: 0,
	particleOptions: {
		texture: 'particles/smoke.png',
		blending: Alpha,
		spinSpeed: 20,
		spinRandomMin: 0,
		spinRandomMax: 0,
		lifetime: 500,
		lifetimeVariance: 100,
		dragCoefficient: 1,
		constantAcceleration: 0,
		gravityCoefficient: 0,
		windCoefficient: 0,
		colors: [
			new Vector(1, 0.7, 0, 0.1),
			new Vector(1, 0.7, 0, 0.5),
			new Vector(1, 0.7, 0, 0.9)
		],
		sizes: [0.125, 0.125, 0.125],
		times: [0, 0.4, 1]
	}
}

/** Ported from `server/scripts/particles/Splash1Emitter.cs` (`WaterPhysicsTrigger_onEnterWater`'s
	splash for entry speed >= 20 but < 50). Short `emitterLifetime` (98ms) - a single burst, not
	ambient. */
final splash1ParticleOptions:ParticleEmitterOptions = {
	ejectionPeriod: 3,
	periodVariance: 0,
	ambientVelocity: new Vector(0, 0, 0),
	ejectionVelocity: 6.07843,
	velocityVariance: 0.05,
	emitterLifetime: 98,
	inheritedVelFactor: 0,
	thetaMin: 0,
	thetaMax: 61.7647,
	phiReferenceVel: 0,
	phiVariance: 360,
	ejectionOffset: 0.2,
	particleOptions: {
		texture: 'particles/splash1.png',
		blending: Alpha,
		spinSpeed: 1,
		spinRandomMin: -90,
		spinRandomMax: 0.5,
		lifetime: 716,
		lifetimeVariance: 96,
		dragCoefficient: 2.54902,
		constantAcceleration: 0,
		gravityCoefficient: 0.705882,
		windCoefficient: 0,
		colors: [
			new Vector(0.843137, 0.833333, 0.843137, 0.441176),
			new Vector(0.784314, 0.813725, 0.882353, 1.0),
			new Vector(0.843137, 0.862745, 0.892157, 0.450980),
			new Vector(0.892157, 0.911765, 0.980392, 0.0)
		],
		sizes: [0.59, 0.69, 1, 1],
		times: [0, 0.28, 0.74, 1]
	}
}

/** Ported from `server/scripts/particles/Splash2Emitter.cs` (the "wasn't a hard enough splash"
	case, entry speed < 20 - also always played once on leaving the water regardless of speed). */
final splash2ParticleOptions:ParticleEmitterOptions = {
	ejectionPeriod: 3,
	periodVariance: 2,
	ambientVelocity: new Vector(0, 0, 0),
	ejectionVelocity: 3.92157,
	velocityVariance: 0.05,
	emitterLifetime: 166,
	inheritedVelFactor: 0,
	thetaMin: 0,
	thetaMax: 61.7647,
	phiReferenceVel: 0,
	phiVariance: 360,
	ejectionOffset: 0.2,
	particleOptions: {
		texture: 'particles/splash2.png',
		blending: Alpha,
		spinSpeed: 1,
		spinRandomMin: -90,
		spinRandomMax: 0.5,
		lifetime: 480,
		lifetimeVariance: 96,
		dragCoefficient: 2.54902,
		constantAcceleration: 0,
		gravityCoefficient: 0.705882,
		windCoefficient: 0,
		colors: [
			new Vector(0.843137, 0.833333, 0.843137, 0.441176),
			new Vector(0.784314, 0.813725, 0.882353, 1.0),
			new Vector(0.843137, 0.862745, 0.892157, 0.0),
			new Vector(0.892157, 0.911765, 0.980392, 0.0)
		],
		sizes: [0.1, 0.24, 1.08, 1],
		times: [0, 0.28125, 0.742706, 1]
	}
}

/** Ported from `server/scripts/particles/Splash3Emitter.cs` (the hardest splat, entry speed >= 50). */
final splash3ParticleOptions:ParticleEmitterOptions = {
	ejectionPeriod: 1,
	periodVariance: 0,
	ambientVelocity: new Vector(0, 0, 0),
	ejectionVelocity: 10.5882,
	velocityVariance: 0.05,
	emitterLifetime: 98,
	inheritedVelFactor: 0,
	thetaMin: 0,
	thetaMax: 61.7647,
	phiReferenceVel: 0,
	phiVariance: 360,
	ejectionOffset: 0.588235,
	particleOptions: {
		texture: 'particles/splash3.png',
		blending: Alpha,
		spinSpeed: 1,
		spinRandomMin: -90,
		spinRandomMax: 0.5,
		lifetime: 1009,
		lifetimeVariance: 96,
		dragCoefficient: 2.54902,
		constantAcceleration: 0,
		gravityCoefficient: 0.705882,
		windCoefficient: 0,
		colors: [
			new Vector(0.843137, 0.833333, 0.843137, 0.441176),
			new Vector(0.784314, 0.813725, 0.882353, 0.686275),
			new Vector(0.843137, 0.862745, 0.892157, 0.264706),
			new Vector(0.892157, 0.911765, 0.980392, 0.0)
		],
		sizes: [0.64, 0.64, 1, 1],
		times: [0, 0.28, 0.73, 1]
	}
}

/** Ported from `server/scripts/particles/Drop1Emitter.cs` - the extra "splatted hard against the
	water" emitter, added alongside Splash1/Splash3 (not Splash2) when entry speed >= 20. */
final drop1ParticleOptions:ParticleEmitterOptions = {
	ejectionPeriod: 1,
	periodVariance: 0,
	ambientVelocity: new Vector(0, 0, 0),
	ejectionVelocity: 15.6863,
	velocityVariance: 0.05,
	emitterLifetime: 176,
	inheritedVelFactor: 0,
	thetaMin: 8.82353,
	thetaMax: 86.4706,
	phiReferenceVel: 0,
	phiVariance: 360,
	ejectionOffset: 0.2,
	particleOptions: {
		texture: 'particles/drop1.png',
		blending: Alpha,
		spinSpeed: 1,
		spinRandomMin: -90,
		spinRandomMax: 0.5,
		lifetime: 1986,
		lifetimeVariance: 96,
		dragCoefficient: 2.54902,
		constantAcceleration: 0,
		gravityCoefficient: 1,
		windCoefficient: 0,
		colors: [
			new Vector(0.843137, 0.833333, 0.882353, 1.0),
			new Vector(0.794118, 0.803922, 0.862745, 1.0),
			new Vector(0.774510, 0.774510, 0.843137, 0.960784),
			new Vector(0.794118, 0.813725, 0.803922, 1.0)
		],
		sizes: [0.15, 0.2, 0.15, 0],
		times: [0, 0.28, 0.5, 1]
	}
}

/** Ported from `server/scripts/particles/IceChunkChunkEmitter.cs` - one of the two bursts
	`IceShard::unfreeze` spawns at the marble's position on natural unfreeze (not on `cancel`, e.g.
	a mission restart while frozen). The source orients the whole emitter node along the marble's
	gravity-up flipped 180° (`applyrotations(getGravityRot(), "0 180 0")`) - reproduced here as the
	ejection cone's `axis` pointing opposite `currentUp`, set per-unfreeze in `Marble.unfreeze`
	since it depends on the marble's gravity at that moment. */
final iceChunkChunkParticleOptions:ParticleEmitterOptions = {
	ejectionPeriod: 4,
	periodVariance: 0,
	ambientVelocity: new Vector(0, 0, 0),
	ejectionVelocity: 6.07843,
	velocityVariance: 0.05,
	emitterLifetime: 29,
	inheritedVelFactor: 0,
	thetaMin: 0,
	thetaMax: 120,
	phiReferenceVel: 0,
	phiVariance: 360,
	ejectionOffset: 0.3,
	particleOptions: {
		texture: 'particles/icechunk.png',
		blending: Alpha,
		spinSpeed: 10,
		spinRandomMin: -90.1961,
		spinRandomMax: 151.961,
		lifetime: 716,
		lifetimeVariance: 96,
		dragCoefficient: 2.54902,
		constantAcceleration: 0,
		gravityCoefficient: 0.705882,
		windCoefficient: 0,
		colors: [
			new Vector(0.843137, 0.833333, 0.843137, 0.441176),
			new Vector(0.784314, 0.813725, 0.882353, 1.0),
			new Vector(0.843137, 0.862745, 0.892157, 0.450980),
			new Vector(0.892157, 0.911765, 0.980392, 0.0)
		],
		sizes: [0.34, 0.34, 0.34, 0.34],
		times: [0, 0.28, 0.74, 1]
	}
}

/** Ported from `server/scripts/particles/IceChunkSnowEmitter.cs` - the second unfreeze burst,
	always spawned alongside `IceChunkChunkEmitter`. */
final iceChunkSnowParticleOptions:ParticleEmitterOptions = {
	ejectionPeriod: 1,
	periodVariance: 0,
	ambientVelocity: new Vector(0, 0, 0),
	ejectionVelocity: 6.41176,
	velocityVariance: 0.05,
	emitterLifetime: 90,
	inheritedVelFactor: 0,
	thetaMin: 0,
	thetaMax: 120,
	phiReferenceVel: 0,
	phiVariance: 360,
	ejectionOffset: 0.3,
	particleOptions: {
		texture: 'particles/snowflake.png',
		blending: Alpha,
		spinSpeed: 1,
		spinRandomMin: -90,
		spinRandomMax: 0.5,
		lifetime: 480,
		lifetimeVariance: 96,
		dragCoefficient: 2.54902,
		constantAcceleration: 0,
		gravityCoefficient: 0.705882,
		windCoefficient: 0,
		colors: [
			new Vector(1.0, 1.0, 1.0, 0.441176),
			new Vector(1.0, 1.0, 1.0, 1.0),
			new Vector(1.0, 1.0, 1.0, 0.0),
			new Vector(0.921569, 0.911765, 0.980392, 0.0)
		],
		sizes: [0.1, 0.15, 0.1, 0.05],
		times: [0, 0.28, 0.74, 1]
	}
}

@:publicFields
@:structInit
class MarbleTestMoveFoundContact {
	var v:Array<Vector>;
	var n:Vector;
}

@:publicFields
@:structInit
class MarbleTestMoveResult {
	var position:Vector;
	var t:Float;
	var found:Bool;
	var foundContacts:Array<MarbleTestMoveFoundContact>;
	var lastContactPos:Null<Vector>;
	var lastContactNormal:Null<Vector>;
	var foundMarbles:Array<SphereCollisionEntity>;
}

class Marble extends GameObject {
	public var camera:CameraController;
	public var cameraObject:Object;
	public var controllable:Bool = false;

	public var collider:SphereCollisionEntity;

	public var velocity:Vector;
	public var omega:Vector;

	public var level:MarbleWorld;
	public var collisionWorld:CollisionWorld;

	public var _radius = 0.2;

	var _dtsRadius = 0.2;
	var marbleDts:DtsObject;

	var _prevRadius:Float;

	var _maxRollVelocity:Float = 15;
	var _angularAcceleration:Float = 75;
	var _jumpImpulse = 7.5;
	var _kineticFriction = 0.7;
	var _staticFriction = 1.1;
	var _brakingAcceleration:Float = 30;
	var _gravity:Float = 20;
	var _airAccel:Float = 5;
	var _maxDotSlide = 0.5;
	var _minBounceVel:Float = 0.1;
	var _minBounceSpeed:Float = 3;
	var _minTrailVel:Float = 10;
	var _bounceKineticFriction = 0.2;
	var minVelocityBounceSoft = 2.5;
	var minVelocityBounceHard = 12.0;
	var bounceMinGain = 0.2;
	var blastShockwaveStrength = 5.0;
	var blastRechargeShockwaveStrength = 10.0;

	public var _bounceRestitution = 0.5;

	var _maxForceRadius:Float = 50;

	var _bounceYet:Bool;
	var _bounceSpeed:Float;
	var _bouncePos:Vector;
	var _bounceNormal:Vector;
	var _slipAmount:Float;
	var _contactTime:Float;
	var _totalTime:Float;

	/** Mirrors PQ's `$Game::LastJumpTime` (`default.bind.cs`'s `fireballBlast`) - how long since the
		marble last actually jumped, accumulated in seconds rather than stored as an absolute
		timestamp so it doesn't need a `TimeState` threaded into `applyContactForces`. Used only to
		soften the Fireball blast's upward impulse right after a jump (see `fireballBlast`). */
	var timeSinceLastJump:Float = 1e8;

	public var _mass:Float = 1;

	var physicsAccumulator:Float = 0;
	var oldPos:Vector;
	var newPos:Vector;
	var prevRot:Quat;
	var posStore:Vector;
	var lastRenderPos:Vector;
	var netSmoothOffset:Vector;
	var netCorrected:Bool;

	public var contacts:Array<CollisionInfo> = [];
	public var bestContact:CollisionInfo;

	static var contactScratch:Array<CollisionEntity> = [];
	static var surfaceScratch:Array<CollisionSurface> = [];

	var queuedContacts:Array<CollisionInfo> = [];
	var appliedImpulses:Array<{impulse:Vector, contactImpulse:Bool}> = [];

	public var heldPowerup:PowerUp;
	public var lastContactPosition:Vector;
	public var lastContactNormal:Vector;
	public var currentUp = new Vector(0, 0, 1);

	public var outOfBounds:Bool = false;
	public var outOfBoundsTime:TimeState;
	public var oobSchedule:Float;

	var forcefield:DtsObject;
	var helicopter:DtsObject;
	var helicopterPQ:DtsObject;
	var megaHelicopter:DtsObject;
	var usePQHelicopter:Bool = false;

	/** TeleportItem's armed state lives on the marble (matching PQ's `%user.teleporterX`
		fields), not on any particular TeleportItem instance - PQ stores it globally on the
		user, so the marker/position/config are shared across every TeleportItem in a level
		regardless of which one armed it or which one fires it. */
	public var teleporterMarker:DtsObject;

	public var teleporterArmed:Bool = false;
	public var teleporterSavedPosition:Vector = new Vector();
	public var teleporterSavedYaw:Float = 0;
	public var teleporterSavedPitch:Float = 0;
	public var teleporterSavedGravity:Vector = new Vector(0, 0, -1);
	public var teleporterKeepVelocity:Bool = false;
	public var teleporterTeleTime:Float = 2;
	public var teleporterLastUseTime:Float = -1000;

	/** Set by `TeleportItem.use`'s second press (fire) instead of PQ's `schedule($time,
		"finishTeleport")` (banned by [No Schedules](feedback_no_schedules.md)) - checked every tick
		in `updateTeleporterState`, which already runs the (also teleport-related) cloak-fade check,
		rather than adding a separate call site for this. */
	public var teleporterFiring:Bool = false;

	var teleporterFireStartTime:Float = 0;

	/** IceShard freeze state, ported from PQ's `IceShard::onCollision`/`unfreeze`
		(`server/scripts/hazards.cs`). `iceChunk` is a visual-only DtsObject snapped to the
		marble's transform every frame while frozen (mirroring `%marble.iceChunk.setParent(%marble,
		"0 0 0", 1)` - a "simple" 1:1 parent with no offset), scaled to the marble's current radius. */
	public var isFrozen:Bool = false;

	public var lastFreezeTime:Float = -1e8;

	var iceChunk:DtsObject;
	var iceShard:shapes.IceShard;

	/** Ported from PQ's `water.cs` - `waterTriggers` mirrors `%marble.waterIsInSet` (every
		`WaterPhysicsTrigger` currently overlapped, since adjacent/overlapping water volumes should
		feel seamless - entering/leaving physics only actually happens when this goes from empty to
		non-empty or back, not on every individual trigger transition). All the "am I in water, did
		I just enter/leave, how deep am I" logic is centralized in `updateWater` (called once per
		tick from `MarbleWorld`), matching PQ's own split between the trigger's on-enter/leave
		callbacks (which just add/remove from the set) and the separate `updateClientWater()`
		function that does the actual work every frame. */
	public var waterTriggers:Array<triggers.WaterPhysicsTrigger> = [];

	public var isInWater:Bool = false;

	/** The closest overlapping `WaterPhysicsTrigger`, recomputed every `updateWater` tick - also
		used by `updateTrailEmitters` to tell fully-submerged (bubble trail) from skimming-the-
		surface (Splash4 trail) via the same `collider.boundingBox.zMax` comparison. */
	var currentWaterTrigger:triggers.WaterPhysicsTrigger;

	var waterPhysicsLayer:Array<PhysicsAttributeOverride> = null;

	/** Bubble PowerUp state - ported from PQ's `water.cs` (`$Game::BubbleTime`/`BubbleInfinite`/
		`BubbleActive` globals). Unlike every other `PowerUp`, Bubble is held-to-use (`Move.
		powerupHeld`, not the click-edge `Move.powerup`) and never occupies the single `heldPowerup`
		inventory slot - picking one up just banks time directly onto the marble (`BubbleItem.pickUp`),
		so it doesn't block picking up another one-shot powerup while bubble time is banked. */
	public var bubbleTime:Float = 0;

	public var bubbleTotalTime:Float = 0;
	public var bubbleInfinite:Bool = false;
	public var bubbleActive:Bool = false;

	var bubblePhysicsLayer:Array<PhysicsAttributeOverride> = null;
	var bubbleVisual:DtsObject;
	var bubbleSound:Channel;

	/** Counts reasons the held powerup currently can't be used (only freezing, for now - PQ also
		locks it from cannons/on respawn, matching `Marble::lockPowerup`/`unlockPowerup` in
		`server/scripts/marble.cs`, neither of which is ported yet). A count instead of a plain
		bool so multiple simultaneous lock reasons don't clobber each other. */
	public var powerupLockCount:Int = 0;

	var superBounceEnableTime:Float = -1e8;
	var shockAbsorberEnableTime:Float = -1e8;
	var helicopterEnableTime:Float = -1e8;
	var megaMarbleEnableTime:Float = -1e8;

	public var helicopterUseTick:Int = 0;
	public var megaMarbleUseTick:Int = 0;
	public var shockAbsorberUseTick:Int = 0;
	public var superBounceUseTick:Int = 0;

	/** Ref-counted so overlapping `NoMovementKeysTrigger` volumes behave correctly. */
	public var movementTriggerCount:Int = 0;

	public var blastAmount:Float = 0;
	public var blastTicks:Int = 0;
	public var blastUseTick:Int = 0; // blast is 12 ticks long

	var blastPerc:Float = 0.0;

	var teleportEnableTime:Null<Float> = null;
	var teleportDisableTime:Null<Float> = null;
	var bounceEmitDelay:Float = 0;

	var bounceEmitterData:ParticleData;
	var trailEmitterData:ParticleData;
	var blastEmitterData:ParticleData;
	var blastMaxEmitterData:ParticleData;
	var splash1EmitterData:ParticleData;
	var splash2EmitterData:ParticleData;
	var splash3EmitterData:ParticleData;
	var drop1EmitterData:ParticleData;
	var iceChunkChunkEmitterData:ParticleData;
	var iceChunkSnowEmitterData:ParticleData;
	var trailEmitterNode:ParticleEmitter;

	/** Ported from `Marble::assignNewTrailEmitter`'s full slot list (`server/scripts/game.cs`) minus
		the Mega-marble-only slots, which reuse the same node fields gated by `isMegaMarbleEnabled`
		instead of separate always-different assets. See `updateTrailEmitters`. */
	var whiteTrailEmitterData:ParticleData;

	var trailBubbleEmitterData:ParticleData;
	var splash4EmitterData:ParticleData;
	var snoreEmitterData:ParticleData;
	var fireball3EmitterData:ParticleData;
	var fireball4EmitterData:ParticleData;
	var fireball3MegaEmitterData:ParticleData;
	var fireball4MegaEmitterData:ParticleData;

	var whiteTrailEmitterNode:ParticleEmitter;
	var trailBubbleEmitterNode:ParticleEmitter;
	var splash4EmitterNode:ParticleEmitter;
	var snoreEmitterNode:ParticleEmitter;
	var fireball3EmitterNode:ParticleEmitter;
	var fireball4EmitterNode:ParticleEmitter;
	var fireball3MegaEmitterNode:ParticleEmitter;
	var fireball4MegaEmitterNode:ParticleEmitter;

	/** One-shot burst emitter data for `Marble.fireballBlast` - unlike the trail data above, these
		are created fresh per-burst (matching the existing `splash1EmitterData`/`bounceEmitterData`
		one-shot convention), not toggled show/hide. `IceShard`'s own break-burst particles
		(`IceShardBreak1/2Emitter`) live on `IceShard.hx` instead, since only `IceShard` spawns
		them. */
	var fireball1BlastEmitterData:ParticleData;

	var fireball2BlastEmitterData:ParticleData;
	var fireball4BlastEmitterData:ParticleData;

	/** Mirrors PQ's `%player.fireball` datafield (`client/scripts/fireball.cs`'s
		`clientCmdFireballStartParticles`/`EndParticles`) - true for the whole duration the Fireball
		PowerUp is active, driving both the trail visibility gate in `updateTrailEmitters` and the
		actual gameplay state (`FireballItem.hx`, `IceShard.hx`, `fireballBlast`). This port
		collapses PQ's separate server (`%player._fireballActive`) and client (`%player.fireball`)
		flags into this single field, matching how `bubbleActive` already does the same for Bubble. */
	public var fireball:Bool = false;

	/** Remaining/total banked Fireball time, in seconds - mirrors `%player._fireballTime`/
		`%obj.activeTime`. Decremented continuously in `updateFireball` rather than PQ's
		schedule-based `fireballExpire` (see [No Schedules](feedback_no_schedules.md)), and directly
		by 500ms (`FireballItem::IceCollision`) when melting through an `IceShard` by contact. */
	public var fireballTime:Float = 0;

	public var fireballTotalTime:Float = 0;

	/** Mirrors `$Client::FireballLastBlastTime` - gates the 2-second blast cooldown
		(`fireballBlast`/`canFireballBlast`). */
	var fireballLastBlastTime:Float = -1e8;

	/** Mirrors PQ's `%player.lastMovement` (`client/scripts/mp/particles.cs`) for the Snore trail's
		idle-timeout check - real sim time (`timeSinceLoad`), not the attempt/gameplay clock, since
		idling should count even before/after an attempt is actively running. */
	var lastMovementTime:Float = 0;

	var rollSound:Channel;
	var rollMegaSound:Channel;
	var slipSound:Channel;

	var superbounceSound:Channel;
	var shockabsorberSound:Channel;
	var helicopterSound:Channel;
	var playedSounds = [];

	public var mode:Mode = Play;

	public var prevPos:Vector;

	var cloak:Bool = false;
	var teleporting:Bool = false;
	var isUltra:Bool = false;
	var _firstTick = true;

	public var cubemapRenderer:CubemapRenderer;

	var shadowVolume:h3d.scene.Mesh;

	var connection:GameConnection;
	var moveMotionDir:Vector;
	var lastMove:Move;
	var isNetUpdate:Bool = false;
	var netFlags:Int = 0;
	var serverTicks:Int;
	var recvServerTick:Int;
	var serverUsePowerup:Bool;
	var lastRespawnTick:Int = -100000;
	var trapdoorContacts:Map<Int, Int> = [];

	var shapeImmunity:Array<DtsObject> = [];
	var shapeOrTriggerInside:Array<GameObject> = [];

	public function new() {
		super();

		this.velocity = new Vector();
		this.omega = new Vector();
		this.camera = new CameraController(cast this);
		this.isCollideable = true;

		this.bounceEmitterData = new ParticleData();
		this.bounceEmitterData.identifier = "MarbleBounceParticle";
		this.bounceEmitterData.texture = ResourceLoader.getResource("data/particles/star.png", ResourceLoader.getTexture, this.textureResources);

		this.trailEmitterData = new ParticleData();
		this.trailEmitterData.identifier = "MarbleTrailParticle";
		this.trailEmitterData.texture = ResourceLoader.getResource("data/particles/smoke.png", ResourceLoader.getTexture, this.textureResources);

		this.blastEmitterData = new ParticleData();
		this.blastEmitterData.identifier = "MarbleBlastParticle";
		this.blastEmitterData.texture = ResourceLoader.getResource("data/particles/smoke.png", ResourceLoader.getTexture, this.textureResources);

		this.blastMaxEmitterData = new ParticleData();
		this.blastMaxEmitterData.identifier = "MarbleBlastMaxParticle";
		this.blastMaxEmitterData.texture = ResourceLoader.getResource("data/particles/smoke.png", ResourceLoader.getTexture, this.textureResources);

		this.splash1EmitterData = new ParticleData();
		this.splash1EmitterData.identifier = "MarbleSplash1Particle";
		this.splash1EmitterData.texture = ResourceLoader.getResource("data/particles/splash1.png", ResourceLoader.getTexture, this.textureResources);

		this.splash2EmitterData = new ParticleData();
		this.splash2EmitterData.identifier = "MarbleSplash2Particle";
		this.splash2EmitterData.texture = ResourceLoader.getResource("data/particles/splash2.png", ResourceLoader.getTexture, this.textureResources);

		this.splash3EmitterData = new ParticleData();
		this.splash3EmitterData.identifier = "MarbleSplash3Particle";
		this.splash3EmitterData.texture = ResourceLoader.getResource("data/particles/splash3.png", ResourceLoader.getTexture, this.textureResources);

		this.drop1EmitterData = new ParticleData();
		this.drop1EmitterData.identifier = "MarbleDrop1Particle";
		this.drop1EmitterData.texture = ResourceLoader.getResource("data/particles/drop1.png", ResourceLoader.getTexture, this.textureResources);

		this.iceChunkChunkEmitterData = new ParticleData();
		this.iceChunkChunkEmitterData.identifier = "MarbleIceChunkChunkParticle";
		this.iceChunkChunkEmitterData.texture = ResourceLoader.getResource("data/particles/icechunk.png", ResourceLoader.getTexture, this.textureResources);

		this.iceChunkSnowEmitterData = new ParticleData();
		this.iceChunkSnowEmitterData.identifier = "MarbleIceChunkSnowParticle";
		this.iceChunkSnowEmitterData.texture = ResourceLoader.getResource("data/particles/snowflake.png", ResourceLoader.getTexture, this.textureResources);

		this.whiteTrailEmitterData = new ParticleData();
		this.whiteTrailEmitterData.identifier = "MarbleWhiteTrailParticle";
		this.whiteTrailEmitterData.texture = ResourceLoader.getResource("data/particles/spark.png", ResourceLoader.getTexture, this.textureResources);

		this.trailBubbleEmitterData = new ParticleData();
		this.trailBubbleEmitterData.identifier = "MarbleTrailBubbleParticle";
		this.trailBubbleEmitterData.texture = ResourceLoader.getResource("data/particles/bubble.png", ResourceLoader.getTexture, this.textureResources);

		this.splash4EmitterData = new ParticleData();
		this.splash4EmitterData.identifier = "Splash4Particle";
		this.splash4EmitterData.texture = ResourceLoader.getResource("data/particles/splash1.png", ResourceLoader.getTexture, this.textureResources);

		this.snoreEmitterData = new ParticleData();
		this.snoreEmitterData.identifier = "SnoreParticle";
		this.snoreEmitterData.texture = ResourceLoader.getResource("data/particles/zzz.png", ResourceLoader.getTexture, this.textureResources);

		this.fireball3EmitterData = new ParticleData();
		this.fireball3EmitterData.identifier = "Fireball3Particle";
		this.fireball3EmitterData.texture = ResourceLoader.getResource("data/particles/fireball_3.png", ResourceLoader.getTexture, this.textureResources);

		this.fireball4EmitterData = new ParticleData();
		this.fireball4EmitterData.identifier = "Fireball4_2Particle";
		this.fireball4EmitterData.texture = ResourceLoader.getResource("data/particles/fireball_4.png", ResourceLoader.getTexture, this.textureResources);

		this.fireball3MegaEmitterData = new ParticleData();
		this.fireball3MegaEmitterData.identifier = "Fireball3MegaParticle";
		this.fireball3MegaEmitterData.texture = ResourceLoader.getResource("data/particles/fireball_3.png", ResourceLoader.getTexture, this.textureResources);

		this.fireball4MegaEmitterData = new ParticleData();
		this.fireball4MegaEmitterData.identifier = "Fireball4_2MegaParticle";
		this.fireball4MegaEmitterData.texture = ResourceLoader.getResource("data/particles/fireball_4.png", ResourceLoader.getTexture, this.textureResources);

		this.fireball1BlastEmitterData = new ParticleData();
		this.fireball1BlastEmitterData.identifier = "Fireball1Particle";
		this.fireball1BlastEmitterData.texture = ResourceLoader.getResource("data/particles/fireball_1.png", ResourceLoader.getTexture, this.textureResources);

		this.fireball2BlastEmitterData = new ParticleData();
		this.fireball2BlastEmitterData.identifier = "Fireball2Particle";
		this.fireball2BlastEmitterData.texture = ResourceLoader.getResource("data/particles/fireball_4.png", ResourceLoader.getTexture, this.textureResources);

		this.fireball4BlastEmitterData = new ParticleData();
		this.fireball4BlastEmitterData.identifier = "Fireball4Particle";
		this.fireball4BlastEmitterData.texture = ResourceLoader.getResource("data/particles/fireball_4.png", ResourceLoader.getTexture, this.textureResources);

		this.rollSound = AudioManager.playSound(ResourceLoader.getResource("data/sound/rolling_hard.wav", ResourceLoader.getAudio, this.soundResources),
			this.getAbsPos().getPosition(), true);
		this.slipSound = AudioManager.playSound(ResourceLoader.getResource("data/sound/sliding.wav", ResourceLoader.getAudio, this.soundResources),
			this.getAbsPos().getPosition(), true);
		this.rollSound.volume = 0;
		this.slipSound.volume = 0;
		this.shockabsorberSound = AudioManager.playSound(ResourceLoader.getResource("data/sound/superbounceactive.wav", ResourceLoader.getAudio,
			this.soundResources), null, true);
		this.shockabsorberSound.pause = true;
		this.superbounceSound = AudioManager.playSound(ResourceLoader.getResource("data/sound/forcefield.wav", ResourceLoader.getAudio, this.soundResources),
			null, true);
		this.superbounceSound.pause = true;
		this.helicopterSound = AudioManager.playSound(ResourceLoader.getResource("data/sound/use_gyrocopter.wav", ResourceLoader.getAudio,
			this.soundResources), null, true);
		this.helicopterSound.pause = true;
		this.bubbleSound = AudioManager.playSound(ResourceLoader.getResource("data/sound/bubble.wav", ResourceLoader.getAudio, this.soundResources), null,
			true);
		this.bubbleSound.pause = true;
	}

	public function init(level:MarbleWorld, connection:GameConnection, onFinish:Void->Void) {
		this.level = level;
		if (this.level != null)
			this.collisionWorld = this.level.collisionWorld;

		this.connection = connection;

		var isUltra = level.mission.game.toLowerCase() == "ultra";

		this.posStore = new Vector();
		this.lastRenderPos = new Vector();
		this.netSmoothOffset = new Vector();
		this.netCorrected = false;
		this.currentUp = new Vector(0, 0, 1);
		this.lastContactNormal = new Vector(0, 0, 1);

		var marbleDts = new DtsObject();
		var marbleShader = "";
		if (connection == null) {
			Console.log("Marble: " + Settings.optionsSettings.marbleModel + " (" + Settings.optionsSettings.marbleSkin + ")");
			marbleDts.dtsPath = Settings.optionsSettings.marbleModel;
			marbleDts.matNameOverride.set("base.marble", Settings.optionsSettings.marbleSkin + ".marble");
			marbleShader = Settings.optionsSettings.marbleShader;
		} else {
			var marbleData = MarbleSelectGui.marbleData[connection.getMarbleCatId()][connection.getMarbleId()]; // FIXME category support
			Console.log("Marble: " + marbleData.dts + " (" + marbleData.skin + ")");
			marbleDts.dtsPath = marbleData.dts;
			marbleDts.matNameOverride.set("base.marble", marbleData.skin + ".marble");
			marbleShader = marbleData.shader;
		}
		marbleDts.identifier = "Marble";
		marbleDts.showSequences = false;
		marbleDts.useInstancing = false;
		marbleDts.init(null, () -> {}); // SYNC
		for (mat in marbleDts.materials) {
			mat.castShadows = true;
			mat.shadows = true;
			mat.receiveShadows = false;
			// mat.mainPass.culling = None;

			if (Settings.optionsSettings.reflectiveMarble) {
				this.cubemapRenderer = new CubemapRenderer(level.scene, level.sky, !this.controllable && level != null);

				if (marbleShader == null || marbleShader == "Default" || marbleShader == "" || !isUltra) { // Use this shit everywhere except ultra
					mat.mainPass.addShader(new MarbleReflection(this.cubemapRenderer.cubemap));
				} else {
					// Generate tangents for next shaders, only for Ultra
					for (node in marbleDts.graphNodes) {
						for (ch in node.children) {
							var chmesh = cast(ch, Mesh);
							var chpoly = cast(chmesh.primitive, src.Polygon);
							chpoly.addTangents();
						}
					}

					mat.mainPass.removeShader(mat.textureShader);

					if (marbleShader == "ClassicGlassPureSphere") {
						var marbleNormal = ResourceLoader.getTexture("data/shapes/balls/pack1/marble01.normal.png").resource;
						var classicGlassShader = new ClassicGlassPureSphere(mat.texture, marbleNormal, this.cubemapRenderer.cubemap, 12,
							new Vector(0.6, 0.6, 0.6, 0.6), this.level.ambient, this.level.dirLight, this.level.dirLightDir, 1);
						mat.mainPass.addShader(classicGlassShader);
					}

					if (marbleShader == "ClassicMarb2") {
						var classicMarb2 = new ClassicMarb2(mat.texture, this.cubemapRenderer.cubemap, 12, new Vector(0.6, 0.6, 0.6, 0.6), this.level.ambient,
							this.level.dirLight, this.level.dirLightDir, 1);
						mat.mainPass.addShader(classicMarb2);
					}

					if (marbleShader == "ClassicMarb3") {
						var classicMarb3 = new ClassicMarb3(mat.texture, this.cubemapRenderer.cubemap, 12, new Vector(0.6, 0.6, 0.6, 0.6), this.level.ambient,
							this.level.dirLight, this.level.dirLightDir, 1);
						mat.mainPass.addShader(classicMarb3);
					}

					if (marbleShader == "ClassicMetal") {
						var marbleNormal = ResourceLoader.getTexture("data/shapes/balls/pack1/marble18.normal.png").resource;
						marbleNormal.wrap = Repeat;
						var classicMetalShader = new ClassicMetal(mat.texture, marbleNormal, this.cubemapRenderer.cubemap, 12, new Vector(0.6, 0.6, 0.6, 0.6),
							this.level.ambient, this.level.dirLight, this.level.dirLightDir, 1);
						mat.mainPass.addShader(classicMetalShader);
					}

					if (marbleShader == "ClassicMarbGlass20") {
						var marbleNormal = ResourceLoader.getTexture("data/shapes/balls/pack1/marble20.normal.png").resource;
						marbleNormal.wrap = Repeat;
						var classicGlassShader = new ClassicGlass(mat.texture, marbleNormal, this.cubemapRenderer.cubemap, 12, new Vector(0.6, 0.6, 0.6, 0.6),
							this.level.ambient, this.level.dirLight, this.level.dirLightDir, 1);
						mat.mainPass.addShader(classicGlassShader);
					}

					if (marbleShader == "ClassicMarbGlass18") {
						var marbleNormal = ResourceLoader.getTexture("data/shapes/balls/pack1/marble18.normal.png").resource;
						marbleNormal.wrap = Repeat;
						var classicGlassShader = new ClassicGlass(mat.texture, marbleNormal, this.cubemapRenderer.cubemap, 12, new Vector(0.6, 0.6, 0.6, 0.6),
							this.level.ambient, this.level.dirLight, this.level.dirLightDir, 1);
						mat.mainPass.addShader(classicGlassShader);
					}

					var thisprops:Dynamic = mat.getDefaultProps();
					thisprops.light = false; // We will calculate our own lighting
					mat.props = thisprops;
					mat.castShadows = true;
					mat.shadows = true;
					mat.receiveShadows = false;
				}
			}

			mat.mainPass.setPassName("marble");
		}

		// Calculate radius according to marble model (egh)
		var b = marbleDts.getBounds();
		var avgRadius = (b.xSize + b.ySize + b.zSize) / 6;
		_dtsRadius = avgRadius;
		if (isUltra) {
			this._radius = 0.3;
			marbleDts.scale(0.3 / avgRadius);
		} else
			this._radius = avgRadius;

		if (Net.isMP) {
			this._radius = 0.2; // For the sake of physics
			marbleDts.scale(0.2 / avgRadius);
		}
		this.marbleDts = marbleDts;

		this._prevRadius = this._radius;

		if (isUltra || level.isMultiplayer) {
			this.rollMegaSound = AudioManager.playSound(ResourceLoader.getResource("data/sound/mega_roll.wav", ResourceLoader.getAudio, this.soundResources),
				this.getAbsPos().getPosition(), true);
			this.rollMegaSound.volume = 0;
		}

		this.isUltra = isUltra;

		this.collider = new SphereCollisionEntity(cast this);

		this.addChild(marbleDts);

		buildShadowVolume();
		if (level != null)
			level.scene.addChild(this.shadowVolume);

		// var geom = Sphere.defaultUnitSphere();
		// geom.addUVs();
		// var marbleTexture = ResourceLoader.getFileEntry("data/shapes/balls/base.marble.png").toTexture();
		// var marbleMaterial = Material.create(marbleTexture);
		// marbleMaterial.shadows = false;
		// marbleMaterial.castShadows = true;
		// marbleMaterial.mainPass.removeShader(marbleMaterial.textureShader);
		// var dtsShader = new DtsTexture();
		// dtsShader.texture = marbleTexture;
		// dtsShader.currentOpacity = 1;
		// marbleMaterial.mainPass.addShader(dtsShader);
		// var obj = new Mesh(geom, marbleMaterial, this);
		// obj.scale(_radius * 0.1);
		// if (Settings.optionsSettings.reflectiveMarble) {
		// 	this.cubemapRenderer = new CubemapRenderer(level.scene);
		// 	marbleMaterial.mainPass.addShader(new MarbleReflection(this.cubemapRenderer.cubemap));
		// }

		this.forcefield = new DtsObject();
		this.forcefield.dtsPath = "data/shapes/images/glow_bounce.dts";
		this.forcefield.useInstancing = true;
		this.forcefield.identifier = "GlowBounce";
		this.forcefield.showSequences = false;
		this.addChild(this.forcefield);
		this.forcefield.x = 1e8;
		this.forcefield.y = 1e8;
		this.forcefield.z = 1e8;
		this.forcefield.isBoundingBoxCollideable = false;

		this.helicopter = new DtsObject();
		this.helicopter.dtsPath = "data/shapes/images/helicopter.dts";
		this.helicopter.useInstancing = true;
		this.helicopter.identifier = "Helicopter";
		this.helicopter.showSequences = true;
		this.helicopter.isBoundingBoxCollideable = false;
		// this.addChild(this.helicopter);
		this.helicopter.x = 1e8;
		this.helicopter.y = 1e8;
		this.helicopter.z = 1e8;

		this.helicopterPQ = new DtsObject();
		this.helicopterPQ.dtsPath = "data/shapes_pq/gameplay/powerups/gyrocopter.dts";
		this.helicopterPQ.useInstancing = true;
		this.helicopterPQ.identifier = "HelicopterPQ";
		this.helicopterPQ.showSequences = true;
		this.helicopterPQ.isBoundingBoxCollideable = false;
		this.helicopterPQ.x = 1e8;
		this.helicopterPQ.y = 1e8;
		this.helicopterPQ.z = 1e8;

		this.megaHelicopter = new DtsObject();
		this.megaHelicopter.dtsPath = "data/shapes/items/megahelicopter.dts";
		this.megaHelicopter.useInstancing = false;
		this.megaHelicopter.identifier = "MegaHelicopter";
		this.megaHelicopter.showSequences = true;
		this.megaHelicopter.isBoundingBoxCollideable = false;
		// this.addChild(this.helicopter);
		this.megaHelicopter.x = 1e8;
		this.megaHelicopter.y = 1e8;
		this.megaHelicopter.z = 1e8;

		this.teleporterMarker = new DtsObject();
		this.teleporterMarker.dtsPath = "data/shapes_pq/other/wireball.dts";
		this.teleporterMarker.useInstancing = true;
		this.teleporterMarker.identifier = "TeleportMarker";
		this.teleporterMarker.isCollideable = false;
		this.teleporterMarker.isBoundingBoxCollideable = false;
		this.teleporterMarker.x = 1e8;
		this.teleporterMarker.y = 1e8;
		this.teleporterMarker.z = 1e8;

		this.iceChunk = new DtsObject();
		this.iceChunk.dtsPath = "data/shapes_pq/gameplay/hazards/ice.dts";
		this.iceChunk.useInstancing = true;
		this.iceChunk.identifier = "IceChunk";
		this.iceChunk.isCollideable = false;
		this.iceChunk.isBoundingBoxCollideable = false;
		this.iceChunk.x = 1e8;
		this.iceChunk.y = 1e8;
		this.iceChunk.z = 1e8;

		this.bubbleVisual = new DtsObject();
		this.bubbleVisual.dtsPath = "data/shapes_pq/gameplay/powerups/bubble.dts";
		this.bubbleVisual.useInstancing = true;
		this.bubbleVisual.identifier = "BubbleVisual";
		this.bubbleVisual.isCollideable = false;
		this.bubbleVisual.isBoundingBoxCollideable = false;
		this.bubbleVisual.x = 1e8;
		this.bubbleVisual.y = 1e8;
		this.bubbleVisual.z = 1e8;

		var worker = new ResourceLoaderWorker(onFinish);
		worker.addTask(fwd -> level.addDtsObject(this.forcefield, fwd));
		worker.addTask(fwd -> level.addDtsObject(this.helicopter, fwd));
		worker.addTask(fwd -> level.addDtsObject(this.helicopterPQ, fwd));
		worker.addTask(fwd -> level.addDtsObject(this.megaHelicopter, fwd));
		worker.addTask(fwd -> level.addDtsObject(this.teleporterMarker, fwd));
		worker.addTask(fwd -> level.addDtsObject(this.iceChunk, fwd));
		worker.addTask(fwd -> level.addDtsObject(this.bubbleVisual, fwd));
		worker.run();

		loadMarbleAttributes();
		capturePhysicsAttributeBaseline();
	}

	function buildShadowVolume() {
		var idx = new hxd.IndexBuffer();
		// slanted part of cone
		var circleVerts = 32;
		for (i in 1...circleVerts) {
			idx.push(0);
			idx.push(i + 1);
			idx.push(i);
		}
		// connect to start
		idx.push(0);
		idx.push(1);
		idx.push(circleVerts);

		// base of cone
		for (i in 1...circleVerts - 1) {
			idx.push(1);
			idx.push(i + 1);
			idx.push(i + 2);
		}
		var pts = [];
		pts.push(new h3d.col.Point(0, 0, -40.0));

		for (i in 0...circleVerts) {
			var x = i / (circleVerts - 1) * (2 * Math.PI);
			pts.push(new h3d.col.Point(Math.cos(x) * 0.2, -Math.sin(x) * 0.2, 0.0));
		}
		var shadowPoly = new h3d.prim.Polygon(pts, idx);
		shadowPoly.addUVs();
		shadowPoly.addNormals();
		shadowVolume = new h3d.scene.Mesh(shadowPoly, h3d.mat.Material.create());
		shadowVolume.material.castShadows = false;
		shadowVolume.material.receiveShadows = false;
		shadowVolume.material.shadows = false;

		var colShader = new h3d.shader.FixedColor(0x000026, 0.35);

		var shadowPass1 = shadowVolume.material.mainPass.clone();
		shadowPass1.setPassName("shadowPass1");
		shadowPass1.stencil = new h3d.mat.Stencil();
		shadowPass1.stencil.setFunc(Always, 1, 0xFF, 0xFF);
		shadowPass1.depth(false, Less);
		shadowPass1.setColorMask(false, false, false, false);
		shadowPass1.culling = Back;
		shadowPass1.stencil.setOp(Keep, Increment, Keep);
		shadowPass1.addShader(colShader);

		var shadowPass2 = shadowVolume.material.mainPass.clone();
		shadowPass2.setPassName("shadowPass2");
		shadowPass2.stencil = new h3d.mat.Stencil();
		shadowPass2.stencil.setFunc(Always, 1, 0xFF, 0xFF);
		shadowPass2.depth(false, Less);
		shadowPass2.setColorMask(false, false, false, false);
		shadowPass2.culling = Front;
		shadowPass2.stencil.setOp(Keep, Decrement, Keep);
		shadowPass2.addShader(colShader);

		var shadowPass3 = shadowVolume.material.mainPass.clone();
		shadowPass3.setPassName("shadowPass3");
		shadowPass3.stencil = new h3d.mat.Stencil();
		shadowPass3.stencil.setFunc(LessEqual, 1, 0xFF, 0xFF);
		shadowPass3.depth(false, Less);
		shadowPass3.culling = Front;
		shadowPass3.stencil.setOp(Keep, Keep, Keep);
		shadowPass3.blend(SrcAlpha, OneMinusSrcAlpha);
		shadowPass3.addShader(colShader);

		shadowVolume.material.addPass(shadowPass1);
		shadowVolume.material.addPass(shadowPass2);
		shadowVolume.material.addPass(shadowPass3);

		shadowVolume.material.removePass(shadowVolume.material.mainPass);

		var q = new Quat();
		q.initNormal(@:privateAccess this.level.dirLightDir.toPoint());

		shadowVolume.setRotationQuat(q);
	}

	function loadMarbleAttributes() {
		if (this.level == null || this.level.mission == null || this.level.mission.marbleAttributes == null)
			return;
		var attribs = this.level.mission.marbleAttributes;
		if (attribs.exists("maxrollvelocity"))
			this._maxRollVelocity = MisParser.parseNumber(attribs.get("maxrollvelocity"));
		if (attribs.exists("angularacceleration"))
			this._angularAcceleration = MisParser.parseNumber(attribs.get("angularacceleration"));
		if (attribs.exists("jumpimpulse"))
			this._jumpImpulse = MisParser.parseNumber(attribs.get("jumpimpulse"));
		if (attribs.exists("kineticfriction"))
			this._kineticFriction = MisParser.parseNumber(attribs.get("kineticfriction"));
		if (attribs.exists("staticfriction"))
			this._staticFriction = MisParser.parseNumber(attribs.get("staticfriction"));
		if (attribs.exists("brakingacceleration"))
			this._brakingAcceleration = MisParser.parseNumber(attribs.get("brakingacceleration"));
		if (attribs.exists("gravity"))
			this._gravity = MisParser.parseNumber(attribs.get("gravity"));
		if (attribs.exists("airaccel"))
			this._airAccel = MisParser.parseNumber(attribs.get("airaccel"));
		if (attribs.exists("maxdotslide"))
			this._maxDotSlide = MisParser.parseNumber(attribs.get("maxdotslide"));
		if (attribs.exists("minbouncevel"))
			this._minBounceVel = MisParser.parseNumber(attribs.get("minbouncevel"));
		if (attribs.exists("minbouncespeed"))
			this._minBounceSpeed = MisParser.parseNumber(attribs.get("minbouncespeed"));
		if (attribs.exists("mintrailvel"))
			this._minTrailVel = MisParser.parseNumber(attribs.get("mintrailvel"));
		if (attribs.exists("bouncekineticfriction"))
			this._bounceKineticFriction = MisParser.parseNumber(attribs.get("bouncekineticfriction"));
	}

	/** Every attribute PQ's `MarbleAttributeInfoArray`/`PhysMod` system can override on a marble
		(`shared/defaultProperties.cs`/`client/scripts/physics.cs`) - excludes the "global" (non-
		datablock) attributes (`cameraSpeedMultiplier`, `timeScale`, etc.) and mega-marble-specific
		`megaValue` overrides, neither of which are in scope here. Recognizes both PQ's real attribute
		name (`airAcceleration`) and this codebase's pre-existing shorthand (`airAccel`) for the same
		field, since both appear in the wild (mission-wide `setMarbleAttributes` vs. real PQ `.mis`
		`PhysMod` triggers). */
	public function setMarbleAttribute(attr:String, value:Float) {
		switch (attr.toLowerCase()) {
			case "maxrollvelocity":
				this._maxRollVelocity = value;
			case "angularacceleration":
				this._angularAcceleration = value;
			case "jumpimpulse":
				this._jumpImpulse = value;
			case "kineticfriction":
				this._kineticFriction = value;
			case "staticfriction":
				this._staticFriction = value;
			case "brakingacceleration":
				this._brakingAcceleration = value;
			case "gravity":
				this._gravity = value;
			case "airaccel", "airacceleration":
				this._airAccel = value;
			case "maxdotslide":
				this._maxDotSlide = value;
			case "minbouncevel":
				this._minBounceVel = value;
			case "minbouncespeed":
				this._minBounceSpeed = value;
			case "mintrailvel":
				this._minTrailVel = value;
			case "bouncekineticfriction":
				this._bounceKineticFriction = value;
			case "bouncerestitution":
				this._bounceRestitution = value;
			case "mass":
				this._mass = value;
			case "maxforceradius":
				this._maxForceRadius = value;
		}
	}

	/** Counterpart to `setMarbleAttribute` - reads the current value of an overridable attribute,
		used by `pushPhysicsLayer`/`popPhysicsLayer` to snapshot the baseline to reset to and to
		re-apply each still-active layer's overrides on top of it. Returns 0 for an unrecognized
		attribute name (matches `setMarbleAttribute`'s silent-ignore behavior). */
	function getMarbleAttribute(attr:String):Float {
		return switch (attr.toLowerCase()) {
			case "maxrollvelocity": this._maxRollVelocity;
			case "angularacceleration": this._angularAcceleration;
			case "jumpimpulse": this._jumpImpulse;
			case "kineticfriction": this._kineticFriction;
			case "staticfriction": this._staticFriction;
			case "brakingacceleration": this._brakingAcceleration;
			case "gravity": this._gravity;
			case "airaccel", "airacceleration": this._airAccel;
			case "maxdotslide": this._maxDotSlide;
			case "minbouncevel": this._minBounceVel;
			case "minbouncespeed": this._minBounceSpeed;
			case "mintrailvel": this._minTrailVel;
			case "bouncekineticfriction": this._bounceKineticFriction;
			case "bouncerestitution": this._bounceRestitution;
			case "mass": this._mass;
			case "maxforceradius": this._maxForceRadius;
			default: 0;
		}
	}

	/** All attributes currently overridden by pushed `PhysMod` layers, outermost (most-recently-
		pushed) last - see `pushPhysicsLayer`/`popPhysicsLayer`. Every entry is just an
		attribute-name/value pair (ported from PQ's `Physics::pushLayer`'s `attribute[i]`/`value[i]`
		record, `client/scripts/physics.cs`); `megaValue` isn't tracked here since mega-marble-specific
		attribute overrides are out of scope for this port. */
	var physicsLayers:Array<Array<PhysicsAttributeOverride>> = [];

	/** Baseline attribute values to reset to before replaying every still-active layer - captured
		once after `loadMarbleAttributes()` applies the mission's own permanent overrides (see
		`init()`), so popping every layer returns the marble to the *level's* configured defaults,
		not the engine's hardcoded ones. */
	var physicsAttributeBaseline:Map<String, Float>;

	static var PHYSMOD_ATTRIBUTES = [
		"maxrollvelocity",
		"angularacceleration",
		"jumpimpulse",
		"kineticfriction",
		"staticfriction",
		"brakingacceleration",
		"gravity",
		"airacceleration",
		"maxdotslide",
		"minbouncevel",
		"minbouncespeed",
		"mintrailvel",
		"bouncekineticfriction",
		"bouncerestitution",
		"mass",
		"maxforceradius"
	];

	function capturePhysicsAttributeBaseline() {
		this.physicsAttributeBaseline = new Map();
		for (attr in PHYSMOD_ATTRIBUTES)
			this.physicsAttributeBaseline.set(attr, getMarbleAttribute(attr));
	}

	/** Ported from PQ's `Physics::pushLayer` (`client/scripts/physics.cs`) - each `PhysMod` trigger
		(and, later, things like water) pushes one layer of attribute overrides on marble-enter and
		pops the same layer on marble-leave (`popPhysicsLayer`). Applies every override in this new
		layer immediately; doesn't touch attributes the layer doesn't mention, so whatever the
		previously-active layers (or the baseline) left them at stays in effect. Returns the layer so
		the caller can pass it back to `popPhysicsLayer` later - overlapping PhysMod volumes combine
		correctly because the most-recently-pushed layer's value for a given attribute always wins
		(pushed last = applied last = still in effect until *that* layer is popped). */
	public function pushPhysicsLayer(overrides:Array<PhysicsAttributeOverride>) {
		this.physicsLayers.push(overrides);
		for (o in overrides)
			setMarbleAttribute(o.attribute, o.value);
		return overrides;
	}

	/** Ported from PQ's `Physics::popLayer` - removing a layer can't just re-apply the baseline,
		since other layers might still be active and need their overrides preserved; instead, like
		the original, this resets every tracked attribute to the captured baseline and replays every
		*remaining* layer's overrides back in order, so whichever still-active layer touched an
		attribute most recently ends up in effect again. */
	public function popPhysicsLayer(layer:Array<PhysicsAttributeOverride>) {
		if (!this.physicsLayers.remove(layer))
			return;
		if (this.physicsAttributeBaseline == null)
			return;
		for (attr in PHYSMOD_ATTRIBUTES)
			setMarbleAttribute(attr, this.physicsAttributeBaseline.get(attr));
		for (remaining in this.physicsLayers)
			for (o in remaining)
				setMarbleAttribute(o.attribute, o.value);
	}

	/** Ported from PQ's `"water"` physics layer (`client/scripts/physics.cs`) - the discrete,
		one-time-per-entry half of water's physics change. Only the first value of each attribute
		pair is used (the second is the mega-marble-specific variant - out of scope, same as
		`PhysModTrigger`'s `megaValue[i]`). */
	static function buildWaterPhysicsLayer():Array<PhysicsAttributeOverride> {
		return [
			{attribute: "maxrollvelocity", value: 5},
			{attribute: "angularacceleration", value: 35},
			{attribute: "gravity", value: 10},
			{attribute: "staticfriction", value: 1.1},
			{attribute: "kineticfriction", value: 0.7},
			{attribute: "bouncekineticfriction", value: 0.2},
			{attribute: "maxdotslide", value: 0.5},
			{attribute: "bouncerestitution", value: 0.2},
			{attribute: "jumpimpulse", value: 7.5},
		];
	}

	/** Ported from PQ's `"bubble"` physics layer (`client/scripts/physics.cs`). */
	static function buildBubblePhysicsLayer():Array<PhysicsAttributeOverride> {
		return [
			{attribute: "maxrollvelocity", value: 10},
			{attribute: "angularacceleration", value: 55},
			{attribute: "brakingacceleration", value: 30},
			{attribute: "airacceleration", value: 7},
			{attribute: "gravity", value: -5},
			{attribute: "staticfriction", value: 1.1},
			{attribute: "kineticfriction", value: 0.7},
			{attribute: "bouncekineticfriction", value: 0.2},
			{attribute: "maxdotslide", value: 0.5},
			{attribute: "bouncerestitution", value: 0.7},
			{attribute: "jumpimpulse", value: 7.5},
			{attribute: "mintrailvel", value: 1.2},
		];
	}

	/** Ported from `WaterPhysicsTrigger_onEnterWater`/`onLeaveWater` (`client/scripts/water.cs`) -
		splash burst spawned at the marble's position offset `(0,0,-0.4)`, exactly matching the
		source's `vectorAdd($MP::MyMarble.getPosition(), "0 0 -0.4")`. Emitter choice is based on
		entry speed (captured *before* the velocity-dampening impulse, matching the source reading
		`%velocity`/`%speed` first): Splash3 at >= 50, Splash1 (plus an extra Drop1 burst) at >= 20,
		otherwise Splash2 - and Splash2 again, unconditionally, on leaving. */
	function spawnWaterSplash(entrySpeed:Float) {
		var pos = this.getAbsPos().getPosition().add(new Vector(0, 0, -0.4));
		if (entrySpeed >= 50) {
			this.level.particleManager.createEmitter(splash3ParticleOptions, this.splash3EmitterData, pos);
		} else if (entrySpeed >= 20) {
			this.level.particleManager.createEmitter(splash1ParticleOptions, this.splash1EmitterData, pos);
			this.level.particleManager.createEmitter(drop1ParticleOptions, this.drop1EmitterData, pos);
		} else {
			this.level.particleManager.createEmitter(splash2ParticleOptions, this.splash2EmitterData, pos);
		}
	}

	function spawnWaterExitSplash() {
		var pos = this.getAbsPos().getPosition().add(new Vector(0, 0, -0.4));
		this.level.particleManager.createEmitter(splash2ParticleOptions, this.splash2EmitterData, pos);
	}

	/** Ported from PQ's `updateClientWater()` (`client/scripts/water.cs`) - called once per tick
		from `MarbleWorld`. Entering/leaving the water's bulk physics layer only happens on the
		zero/non-zero transition of `waterTriggers.length` (overlapping/adjacent water volumes feel
		seamless, matching `waterIsInSet`/`waterLastCount`); the continuous depth-based
		`maxRollVelocity`/`angularAcceleration` scaling is recomputed every tick directly via
		`setMarbleAttribute` (bypassing the layer-replay mechanism, since it changes continuously
		with depth rather than being a one-time push) using whichever overlapping trigger is
		closest, matching `findClosestWaterTrigger`. */
	public function updateWater(timeState:TimeState) {
		if (this.waterTriggers.length == 0) {
			if (this.isInWater) {
				this.isInWater = false;
				if (this.waterPhysicsLayer != null) {
					this.popPhysicsLayer(this.waterPhysicsLayer);
					this.waterPhysicsLayer = null;
				}
				this.spawnWaterExitSplash();
			}
			return;
		}

		var pos = this.getAbsPos().getPosition();
		var closest = this.waterTriggers[0];
		var closestDist = 1e30;
		for (t in this.waterTriggers) {
			var center = t.collider.boundingBox.getCenter().toVector();
			var dist = center.distance(pos);
			if (dist <= closestDist) {
				closest = t;
				closestDist = dist;
			}
		}
		this.currentWaterTrigger = closest;

		if (!this.isInWater) {
			this.isInWater = true;
			this.waterPhysicsLayer = this.pushPhysicsLayer(buildWaterPhysicsLayer());
			var entrySpeed = this.velocity.length();
			var velocityChange = this.velocity.multiply(-closest.velocityMultiplier);
			this.velocity = this.velocity.add(velocityChange);
			this.spawnWaterSplash(entrySpeed);
		}

		var zdist = Util.clamp(pos.z - closest.collider.boundingBox.zMax, 0, 0.2);
		this.setMarbleAttribute("maxrollvelocity", zdist / 0.2 * 10 + 5);
		this.setMarbleAttribute("angularacceleration", zdist / 0.2 * 40 + 35);
	}

	/** Ported from PQ's `setBubbleTime` (`clientCmdSetBubbleTime`, `client/scripts/water.cs`) -
		called once on pickup. Only actually banks the new time if the bubble isn't already active
		with more time banked (or becoming infinite), matching the source's `!active || infinite ||
		time > bubbleTime` guard - picking up a weaker bubble while a stronger one is still running
		doesn't downgrade it. */
	public function setBubbleTime(time:Float, infinite:Bool) {
		var active = time > 0;
		if (!active || infinite || time > this.bubbleTime) {
			this.bubbleTotalTime = time;
			this.bubbleTime = time;
			this.bubbleInfinite = infinite;
		}
		if (this.level != null)
			this.level.playGui.updateBubbleBar(this.bubbleTime, this.bubbleTotalTime, this.bubbleInfinite);
	}

	function activateBubble() {
		this.bubbleActive = true;
		this.bubblePhysicsLayer = this.pushPhysicsLayer(buildBubblePhysicsLayer());
	}

	function deactivateBubble() {
		if (!this.bubbleActive)
			return;
		this.bubbleActive = false;
		if (this.bubblePhysicsLayer != null) {
			this.popPhysicsLayer(this.bubblePhysicsLayer);
			this.bubblePhysicsLayer = null;
		}
		if (this.level != null)
			this.level.playGui.updateBubbleBar(this.bubbleTime, this.bubbleTotalTime, this.bubbleInfinite);
	}

	/** Ported from PQ's `BubbleLoop` (`client/scripts/water.cs`) - held-to-use, undoes itself the
		instant the powerup button is released or the marble leaves the water (matching the "let go
		pops it"/"exit the water pops it" checks), and depletes while active unless infinite. Called
		once per substep, right alongside the click-based `heldPowerup.use()` consumption check,
		since Bubble deliberately bypasses that mechanism entirely - it never occupies the single
		`heldPowerup` slot (see the field doc on `bubbleTime`). */
	function updateBubble(move:Move, timeStep:Float) {
		var use = move.powerupHeld;
		if (this.bubbleActive) {
			if (!use || !this.isInWater)
				this.deactivateBubble();
		} else if (this.isInWater && use && this.bubbleTime > 0 && !this.outOfBounds && this.powerupLockCount <= 0) {
			this.activateBubble();
			if (this.level != null)
				this.level.playGui.updateBubbleBar(this.bubbleTime, this.bubbleTotalTime, this.bubbleInfinite);
		}

		if (this.bubbleActive) {
			if (!this.bubbleInfinite) {
				this.bubbleTime -= timeStep;
				if (this.bubbleTime <= 0) {
					this.bubbleTime = 0;
					this.deactivateBubble();
				}
			}
			if (this.level != null)
				this.level.playGui.updateBubbleBar(this.bubbleTime, this.bubbleTotalTime, this.bubbleInfinite);
		}
	}

	/** Ported from `GameConnection::fireballInit` (`server/scripts/fireball.cs`) - called from
		`FireballItem.pickUp`. Cancels any banked Bubble time (`%user.client.setBubbleTime(0, false)`
		- "Ruin their bubble", matching `BubbleItem::onPickup`'s one-directional counterpart that
		blocks picking up a Bubble while Fireball is active). */
	public function activateFireball(time:Float) {
		this.fireball = true;
		this.fireballTime = time;
		this.fireballTotalTime = time;
		// "So we can instantly blast after getting a new fireball" (`clientCmdFireballInit`).
		this.fireballLastBlastTime = -1e8;
		this.setBubbleTime(0, false);
		if (this.level != null)
			this.level.playGui.updateFireballBar(this.fireballTime, this.fireballTotalTime, this.canFireballBlast());
	}

	/** Ported from `GameConnection::fireballExpire`. */
	function deactivateFireball() {
		if (!this.fireball)
			return;
		this.fireball = false;
		this.fireballTime = 0;
		if (this.level != null)
			this.level.playGui.updateFireballBar(0, 0, false);
	}

	/** Continuous decrement, replacing PQ's `schedule($time, "fireballExpire")` (banned by
		[No Schedules](feedback_no_schedules.md)) - functionally identical, since PQ's own
		`getFireballTime` already computes remaining time as a pure function of elapsed time anyway. */
	function updateFireball(timeStep:Float) {
		if (!this.fireball)
			return;
		this.fireballTime -= timeStep;
		if (this.fireballTime <= 0) {
			this.fireballTime = 0;
			this.deactivateFireball();
		} else if (this.level != null) {
			this.level.playGui.updateFireballBar(this.fireballTime, this.fireballTotalTime, this.canFireballBlast());
		}
	}

	/** Deducts banked Fireball time - ported from `FireballItem::IceCollision`'s `%marble.
		_fireballTime -= 500` (melting through an `IceShard` by contact, as opposed to `Blast`'s
		radius search, which doesn't cost any time). */
	public function deductFireballTime(amount:Float) {
		if (!this.fireball)
			return;
		this.fireballTime -= amount;
		if (this.fireballTime <= 0) {
			this.fireballTime = 0;
			this.deactivateFireball();
		} else if (this.level != null) {
			this.level.playGui.updateFireballBar(this.fireballTime, this.fireballTotalTime, this.canFireballBlast());
		}
	}

	/** Ported from `fireballBlast`'s cooldown guard (`client/scripts/fireball.cs`) - needs at least
		1 second of Fireball time left, and at least 2 seconds since the last blast. */
	function canFireballBlast():Bool {
		if (!this.fireball || this.level == null)
			return false;
		return this.fireballTime >= 1 && (this.level.timeState.currentAttemptTime - this.fireballLastBlastTime) >= 2;
	}

	/** Ported from `fireballBlast`/`serverCmdFireballBlast`/`FireballItem::Blast`
		(`client/scripts/fireball.cs` + `server/scripts/fireball.cs`) - called from `useBlast`, which
		the same physical input (`Settings.controlsSettings.blast`) already drives for the Ultra
		"blast" mechanic; Fireball intercepts that input first when active, matching real PQ's
		`input_useBlast` (`if ($Client::FireballActive) { if (fireballBlast()) return; }`). Doesn't
		consume any Fireball time itself - only contact-melting an `IceShard` costs time (see
		`deductFireballTime`). Returns `true` if the blast actually fired (so `useBlast` can skip the
		normal Ultra blast for this call), matching `fireballBlast`'s own return value. */
	function fireballBlast(timeState:TimeState):Bool {
		if (!this.canFireballBlast())
			return false;
		this.fireballLastBlastTime = timeState.currentAttemptTime;

		// Base 2 + up to 5 scaled by remaining time fraction + up to 5 scaled by how long it's been
		// since the last jump (ramps 0 -> 1 over 0.4s - jumping right before blasting is weaker, "so
		// you can't combine for crazy height").
		var timeFraction = this.fireballTotalTime > 0 ? this.fireballTime / this.fireballTotalTime : 0;
		var jumpFraction = Util.clamp(this.timeSinceLastJump / 0.4, 0, 1);
		var scale = timeFraction * 5 + jumpFraction * 5 + 2;
		this.applyImpulse(this.currentUp.multiply(scale));

		var pos = this.getAbsPos().getPosition();

		// Blast out nearby ice shards - radius shrinks from 3 (full time) down to 1.5 (empty).
		var radius = timeFraction * 1.5 + 1.5;
		var smashedAny = false;
		if (this.level != null) {
			for (shard in this.level.iceShards) {
				if (!shard.destroyed && shard.getAbsPos().getPosition().distance(pos) <= radius) {
					shard.destroyByFireball();
					smashedAny = true;
				}
			}
		}

		if (!this.isNetUpdate && this.controllable) {
			if (smashedAny)
				AudioManager.playSound(ResourceLoader.getResource('data/sound/ice_smash.wav', ResourceLoader.getAudio, this.soundResources));
			AudioManager.playSound(ResourceLoader.getResource('data/sound/explode1_tweaked.wav', ResourceLoader.getAudio, this.soundResources));
		}

		var blastPos = pos.add(new Vector(0, 0, 0.5));
		this.level.particleManager.createEmitter(fireball1BlastParticleOptions, this.fireball1BlastEmitterData, blastPos);
		this.level.particleManager.createEmitter(fireball2BlastParticleOptions, this.fireball2BlastEmitterData, blastPos);
		this.level.particleManager.createEmitter(fireball4BlastParticleOptions, this.fireball4BlastEmitterData, blastPos);

		return true;
	}

	function findContacts(collisiomWorld:CollisionWorld, timeState:TimeState) {
		this.contacts = queuedContacts;
		CollisionPool.clear();
		collisiomWorld.sphereIntersection(this.collider, timeState, this.contacts);
	}

	public function queueCollision(collisionInfo:CollisionInfo) {
		this.queuedContacts.push(collisionInfo);
	}

	public function getMarbleAxis() {
		var motiondir = new Vector(0, -1, 0);
		if (level.isReplayingMovement)
			return level.currentInputMoves[1].marbleAxes;
		if (this.controllable && !this.isNetUpdate) {
			motiondir.transform(Matrix.R(0, 0, camera.CameraYaw));
			motiondir.transform(level.newOrientationQuat.toMatrix());
			var updir = this.currentUp;
			var sidedir = motiondir.cross(updir);

			sidedir.normalize();
			motiondir = updir.cross(sidedir);
			return [sidedir, motiondir, updir];
		} else {
			if (moveMotionDir != null)
				motiondir = moveMotionDir;
			var updir = this.currentUp;
			var sidedir = motiondir.cross(updir);
			return [sidedir, motiondir, updir];
		}
	}

	function getExternalForces(timeState:TimeState, m:Move) {
		if (this.mode == Finish)
			return this.velocity.multiply(-16);
		var gWorkGravityDir = this.currentUp.multiply(-1);
		var A = new Vector();
		A = gWorkGravityDir.multiply(this._gravity);
		var helicopter = isHelicopterEnabled(timeState);
		if (helicopter) {
			A.load(A.multiply(0.25));
		}
		if (this.level != null && level.forceObjects.length > 0) {
			var mass = this.getMass();
			var externalForce = new Vector();
			var pos = this.collider.transform.getPosition();
			for (obj in level.forceObjects) {
				cast(obj, ForceObject).getForce(pos, externalForce);
			}
			A.load(A.add(externalForce.multiply(1 / mass)));
		}

		if (contacts.length != 0 && this.mode != Start) {
			var contactForce = 0.0;
			var contactNormal = new Vector();
			var forceObjectCount = 0;

			var forceObjects = [];

			for (contact in contacts) {
				if (contact.force != 0 && !forceObjects.contains(contact.otherObject)) {
					if (contact.otherObject is RoundBumper) {
						if (!playedSounds.contains("data/sound/bumperding1.wav") && !this.isNetUpdate) {
							if (level.marble == cast this)
								AudioManager.playSound(ResourceLoader.getResource("data/sound/bumperding1.wav", ResourceLoader.getAudio, this.soundResources));
							else
								AudioManager.playSound(ResourceLoader.getResource("data/sound/bumperding1.wav", ResourceLoader.getAudio, this.soundResources),
									this.getAbsPos().getPosition());
							playedSounds.push("data/sound/bumperding1.wav");
						}
					}
					if (contact.otherObject is TriangleBumper) {
						if (!playedSounds.contains("data/sound/bumper1.wav") && !this.isNetUpdate) {
							if (level.marble == cast this)
								AudioManager.playSound(ResourceLoader.getResource("data/sound/bumper1.wav", ResourceLoader.getAudio, this.soundResources));
							else
								AudioManager.playSound(ResourceLoader.getResource("data/sound/bumper1.wav", ResourceLoader.getAudio, this.soundResources),
									this.getAbsPos().getPosition());
							playedSounds.push("data/sound/bumper1.wav");
						}
					}
					forceObjectCount++;
					contactNormal = contactNormal.add(contact.normal);
					contactForce += contact.force;
					forceObjects.push(contact.otherObject);
				}
			}

			if (forceObjectCount != 0) {
				contactNormal.normalize();

				var a = contactForce / this.getMass();

				var dot = this.velocity.dot(contactNormal);
				if (a > dot) {
					if (dot > 0)
						a -= dot;

					A.load(A.add(contactNormal.multiply(a / timeState.dt)));
				}
			}
		}
		if (contacts.length == 0 && this.mode != Start) {
			var axes = this.getMarbleAxis();
			var sideDir = axes[0];
			var motionDir = axes[1];
			var upDir = axes[2];
			var airAccel = this._airAccel;
			if (helicopter) {
				airAccel *= 2;
			}
			A.load(A.add(sideDir.multiply(m.d.x).add(motionDir.multiply(m.d.y)).multiply(airAccel)));
		}
		return A;
	}

	function computeMoveForces(m:Move, aControl:Vector, desiredOmega:Vector) {
		var currentGravityDir = this.currentUp.multiply(-1);
		var R = this.currentUp.multiply(this._radius);
		var rollVelocity = this.omega.cross(R);
		var axes = this.getMarbleAxis();
		// if (!level.isReplayingMovement)
		// 	level.inputRecorder.recordAxis(axes);
		var sideDir = axes[0];
		var motionDir = axes[1];
		var upDir = axes[2];
		var currentYVelocity = rollVelocity.dot(motionDir);
		var currentXVelocity = rollVelocity.dot(sideDir);
		var mv = m.d;

		// mv = mv.multiply(1.538461565971375);
		// var mvlen = mv.length();
		// if (mvlen > 1) {
		// 	mv = mv.multiply(1 / mvlen);
		// }
		var desiredYVelocity = this._maxRollVelocity * mv.y;
		var desiredXVelocity = this._maxRollVelocity * mv.x;

		if (desiredYVelocity != 0 || desiredXVelocity != 0) {
			if (currentYVelocity > desiredYVelocity && desiredYVelocity > 0) {
				desiredYVelocity = currentYVelocity;
			} else if (currentYVelocity < desiredYVelocity && desiredYVelocity < 0) {
				desiredYVelocity = currentYVelocity;
			}
			if (currentXVelocity > desiredXVelocity && desiredXVelocity > 0) {
				desiredXVelocity = currentXVelocity;
			} else if (currentXVelocity < desiredXVelocity && desiredXVelocity < 0) {
				desiredXVelocity = currentXVelocity;
			}
			var rsq = R.lengthSq();
			var crossP = R.cross(motionDir.multiply(desiredYVelocity).add(sideDir.multiply(desiredXVelocity))).multiply(1 / rsq);
			desiredOmega.load(crossP);
			aControl.load(desiredOmega.sub(this.omega));
			var aScalar = aControl.length();
			if (aScalar > this._angularAcceleration) {
				aControl.scale(this._angularAcceleration / aScalar);
			}
			return false;
		}
		return true;
	}

	function velocityCancel(timeState:TimeState, surfaceSlide:Bool, noBounce:Bool, stoppedPaths:Bool, pi:Array<PathedInterior>) {
		var SurfaceDotThreshold = 0.0001;
		var looped = false;
		var itersIn = 0;
		var done:Bool;
		do {
			done = true;
			itersIn++;
			for (i in 0...contacts.length) {
				var sVel = this.velocity.sub(contacts[i].velocity);
				var surfaceDot = contacts[i].normal.dot(sVel);

				if ((!looped && surfaceDot < 0.0) || surfaceDot < -SurfaceDotThreshold) {
					var velLen = this.velocity.length();
					var surfaceVel = this.contacts[i].normal.multiply(surfaceDot);

					if (!_bounceYet) {
						_bounceYet = true;
						playBoundSound(timeState.currentAttemptTime, -surfaceDot);
					}

					if (noBounce) {
						this.velocity.load(this.velocity.sub(surfaceVel));
					} else if (contacts[i].collider != null) {
						var otherMarble:Marble = cast contacts[i].collider.go;

						var ourMass = this.getMass();
						var theirMass = otherMarble.getMass();

						var bounce = Math.max(this._bounceRestitution, otherMarble._bounceRestitution);

						var dp = this.velocity.multiply(ourMass).sub(otherMarble.velocity.multiply(theirMass));
						var normP = contacts[i].normal.multiply(dp.dot(contacts[i].normal));

						normP.scale(1 + bounce);

						velocity.load(velocity.sub(normP.multiply(1 / ourMass)));
						if (Math.isNaN(velocity.lengthSq())) {
							velocity.set(0, 0, 0);
						}

						otherMarble.velocity.load(otherMarble.velocity.add(normP.multiply(1 / theirMass)));
						if (Math.isNaN(otherMarble.velocity.lengthSq())) {
							otherMarble.velocity.set(0, 0, 0);
						}
						contacts[i].velocity.load(otherMarble.velocity);
					} else {
						if (contacts[i].velocity.length() == 0.0 && !surfaceSlide && surfaceDot > -this._maxDotSlide * velLen) {
							this.velocity.load(this.velocity.sub(surfaceVel));
							this.velocity.normalize();
							this.velocity.load(this.velocity.multiply(velLen));
							surfaceSlide = true;
						} else if (surfaceDot >= -this._minBounceVel) {
							this.velocity.load(this.velocity.sub(surfaceVel));
						} else {
							var restitution = this._bounceRestitution;
							if (isSuperBounceEnabled(timeState)) {
								restitution = 0.9;
							}
							if (isShockAbsorberEnabled(timeState)) {
								restitution = 0.01;
							}
							restitution *= contacts[i].restitution;

							var velocityAdd = surfaceVel.multiply(-(1 + restitution));
							var vAtC = sVel.add(this.omega.cross(contacts[i].normal.multiply(-this._radius)));
							var normalVel = -contacts[i].normal.dot(sVel);

							bounceEmitter(sVel.length() * restitution, contacts[i].normal);

							vAtC.load(vAtC.sub(contacts[i].normal.multiply(contacts[i].normal.dot(sVel))));

							var vAtCMag = vAtC.length();
							if (vAtCMag != 0.0) {
								var friction = this._bounceKineticFriction * contacts[i].friction;

								var angVMagnitude = friction * 5 * normalVel / (2 * this._radius);
								if (vAtCMag / this._radius < angVMagnitude)
									angVMagnitude = vAtCMag / this._radius;

								var vAtCDir = vAtC.multiply(1 / vAtCMag);

								var deltaOmega = contacts[i].normal.cross(vAtCDir).multiply(angVMagnitude);
								this.omega.load(this.omega.add(deltaOmega));

								this.velocity.load(this.velocity.sub(deltaOmega.cross(contacts[i].normal.multiply(_radius))));
							}
							this.velocity.load(this.velocity.add(velocityAdd));
						}
					}

					done = false;
				}
			}
			looped = true;
			if (itersIn > 6 && !stoppedPaths) {
				stoppedPaths = true;
				if (noBounce)
					done = true;

				for (contact in contacts) {
					contact.velocity.set(0, 0, 0);
				}

				for (interior in pi) {
					interior.setStopped();
				}
			}
		} while (!done && itersIn < 1e4); // Maximum limit pls
		if (this.velocity.lengthSq() < 625.0) {
			var gotOne = false;
			var dir = new Vector(0, 0, 0);
			for (j in 0...contacts.length) {
				var dir2 = dir.add(contacts[j].normal);
				if (dir2.lengthSq() < 0.01) {
					dir2.load(dir2.add(contacts[j].normal));
				}
				dir = dir2;
				dir.normalize();
				gotOne = true;
			}
			if (gotOne) {
				dir.normalize();
				var soFar = 0.0;
				for (k in 0...contacts.length) {
					var dist = this._radius - contacts[k].contactDistance;
					var timeToSeparate = 0.1;
					var vel = this.velocity.sub(contacts[k].velocity);
					var outVel = vel.add(dir.multiply(soFar)).dot(contacts[k].normal);
					if (dist > timeToSeparate * outVel) {
						soFar += (dist - outVel * timeToSeparate) / timeToSeparate / contacts[k].normal.dot(dir);
					}
				}
				if (soFar < -25.0)
					soFar = -25.0;
				if (soFar > 25.0)
					soFar = 25.0;
				this.velocity.load(this.velocity.add(dir.multiply(soFar)));
			}
		}

		return stoppedPaths;
	}

	function applyContactForces(dt:Float, m:Move, isCentered:Bool, aControl:Vector, desiredOmega:Vector, A:Vector) {
		this.timeSinceLastJump += dt;
		var a = new Vector();
		this._slipAmount = 0;
		var gWorkGravityDir = this.currentUp.multiply(-1);
		var bestSurface = -1;
		var bestNormalForce = 0.0;
		for (i in 0...contacts.length) {
			if (contacts[i].collider == null) {
				contacts[i].normalForce = -contacts[i].normal.dot(A);
				if (contacts[i].normalForce > bestNormalForce) {
					bestNormalForce = contacts[i].normalForce;
					bestSurface = i;
				}
			}
		}
		bestContact = (bestSurface != -1) ? contacts[bestSurface] : null;
		var canJump = bestSurface != -1;
		if (canJump && m.jump) {
			var velDifference = this.velocity.sub(bestContact.velocity);
			var sv = bestContact.normal.dot(velDifference);
			if (sv < 0) {
				sv = 0;
			}
			if (sv < this._jumpImpulse) {
				this.velocity.load(this.velocity.add(bestContact.normal.multiply((this._jumpImpulse - sv))));
				this.timeSinceLastJump = 0;
				if (!playedSounds.contains("data/sound/jump.wav") && !this.isNetUpdate && this.controllable) {
					AudioManager.playSound(ResourceLoader.getResource("data/sound/jump.wav", ResourceLoader.getAudio, this.soundResources));
					playedSounds.push("data/sound/jump.wav");
				}
			}
		}
		for (j in 0...contacts.length) {
			var normalForce2 = -contacts[j].normal.dot(A);
			if (normalForce2 > 0 && contacts[j].normal.dot(this.velocity.sub(contacts[j].velocity)) <= 0.0001) {
				A.set(A.x
					+ contacts[j].normal.x * normalForce2, A.y
					+ contacts[j].normal.y * normalForce2, A.z
					+ contacts[j].normal.z * normalForce2);
			}
		}
		if (bestSurface != -1 && this.mode != Finish) {
			var vAtC = this.velocity.add(this.omega.cross(bestContact.normal.multiply(-this._radius))).sub(bestContact.velocity);
			var vAtCMag = vAtC.length();
			var slipping = false;
			var aFriction = new Vector(0, 0, 0);
			var AFriction = new Vector(0, 0, 0);
			if (vAtCMag != 0) {
				slipping = true;
				var friction = 0.0;
				if (this.mode != Start)
					friction = this._kineticFriction * bestContact.friction;
				var angAMagnitude = 5 * friction * bestNormalForce / (2 * this._radius);
				var AMagnitude = bestNormalForce * friction;
				var totalDeltaV = (angAMagnitude * this._radius + AMagnitude) * dt;
				if (totalDeltaV > vAtCMag) {
					var fraction = vAtCMag / totalDeltaV;
					angAMagnitude *= fraction;
					AMagnitude *= fraction;
					slipping = false;
				}
				var vAtCDir = vAtC.multiply(1 / vAtCMag);
				aFriction.load(bestContact.normal.cross(vAtCDir).multiply(angAMagnitude));
				AFriction.load(vAtCDir.multiply(-AMagnitude));
				this._slipAmount = vAtCMag - totalDeltaV;
			}
			if (!slipping) {
				var R = gWorkGravityDir.multiply(-this._radius);
				var aadd = R.cross(A).multiply(1 / R.lengthSq());
				if (isCentered) {
					var nextOmega = this.omega.add(a.multiply(dt));
					aControl = desiredOmega.sub(nextOmega);
					var aScalar = aControl.length();
					if (aScalar > this._brakingAcceleration) {
						aControl = aControl.multiply(this._brakingAcceleration / aScalar);
					}
				}
				var Aadd = aControl.cross(bestContact.normal.multiply(-this._radius)).multiply(-1);
				var aAtCMag = aadd.cross(bestContact.normal.multiply(-this._radius)).add(Aadd).length();
				var friction2 = 0.0;
				if (mode != Start)
					friction2 = this._staticFriction * bestContact.friction;

				if (aAtCMag > friction2 * bestNormalForce) {
					friction2 = 0;
					if (mode != Start)
						friction2 = this._kineticFriction * bestContact.friction;
					Aadd.load(Aadd.multiply(friction2 * bestNormalForce / aAtCMag));
				}
				A.load(A.add(Aadd));
				a.load(a.add(aadd));
			}
			A.load(A.add(AFriction));
			a.load(a.add(aFriction));

			lastContactNormal = bestContact.normal;
			lastContactPosition = this.getAbsPos().getPosition();
		}
		a.load(a.add(aControl));
		if (this.mode == Finish) {
			a.set(); // Zero it out
		}
		return a;
	}

	function bounceEmitter(speed:Float, normal:Vector) {
		if (!this.controllable || this.isNetUpdate)
			return;
		if (this.bounceEmitDelay == 0 && this._minBounceSpeed <= speed) {
			this.level.particleManager.createEmitter(bounceParticleOptions, this.bounceEmitterData, this.getAbsPos().getPosition());
			this.bounceEmitDelay = 0.3;
		}
	}

	static final TRAIL_EMITTER_SPEED = 10.0;
	static final TRAIL_EMITTER_WHITE_SPEED = 30.0;
	static final SNORE_THRESHOLD = 0.01;
	static final SNORE_TIMEOUT = 10.0;

	/** Creates or removes `node` (backed by `options`/`data`, following the marble every frame via
		the `getPos` closure convention already used elsewhere in this file) to match `show`. */
	function setTrailEmitterShown(node:ParticleEmitter, show:Bool, options:ParticleEmitterOptions, data:ParticleData):ParticleEmitter {
		if (show && node == null)
			return this.level.particleManager.createEmitter(options, data, null, () -> this.getAbsPos().getPosition());
		if (!show && node != null)
			this.level.particleManager.removeEmitter(node);
		return show ? node : null;
	}

	/** Ported from the native `updateTrailEmitters()`/`Marble::assignNewTrailEmitter` (real engine
		`interpolation.cpp` + `server/scripts/game.cs`) - decides which of the marble's persistent
		trail emitters should be visible this frame, purely from current state (speed/water/fireball/
		mega/game-state), and creates/removes each one to match. The real engine instead keeps 9
		always-existing `ParticleEmitterNode`s per marble and teleports the hidden ones off to
		`(-999999,...)` - functionally identical to create/remove here, since this codebase's
		`ParticleManager` already supports on-demand emitter creation/removal (see `createEmitter`/
		`removeEmitter`), so there's no need for the off-screen-parking indirection. */
	function updateTrailEmitters(timeState:TimeState) {
		if (!this.controllable || this.isNetUpdate)
			return;

		var speed = this.velocity.length();
		var pos = this.getAbsPos().getPosition();

		var showTrail = false;
		var showWhiteTrail = false;
		var showSplash4 = false;
		var showTrailBubble = false;
		var showFireball3 = false;
		var showFireball4 = false;
		var showFireball3Mega = false;
		var showFireball4Mega = false;
		var showSnore = false;

		if (this.isInWater) {
			// Ported from `%closestTrigger.testObject(%player)` - approximated here as "the marble's
			// entire radius is below the water's surface", the same `collider.boundingBox.zMax`
			// `updateWater` already compares against for its depth-based attribute scaling.
			var fullySubmerged = this.currentWaterTrigger != null
				&& (pos.z + this._radius) <= this.currentWaterTrigger.collider.boundingBox.zMax;
			showSplash4 = speed > 1 && !fullySubmerged;
			showTrailBubble = speed > 1 && fullySubmerged;
		} else if (this.fireball) {
			var mega = isMegaMarbleEnabled(timeState);
			showFireball3 = !mega;
			showFireball4 = !mega;
			showFireball3Mega = mega;
			showFireball4Mega = mega;
		} else {
			showTrail = speed > TRAIL_EMITTER_SPEED && speed < TRAIL_EMITTER_WHITE_SPEED;
			showWhiteTrail = speed >= TRAIL_EMITTER_WHITE_SPEED;
		}

		if (speed < SNORE_THRESHOLD && this.mode == Play && this.level.finishTime == null) {
			showSnore = (timeState.timeSinceLoad - this.lastMovementTime) > SNORE_TIMEOUT;
		} else {
			this.lastMovementTime = timeState.timeSinceLoad;
		}

		if (this.level.finishTime != null) {
			showTrail = false;
			showWhiteTrail = false;
			showSplash4 = false;
			showTrailBubble = false;
			showFireball3 = false;
			showFireball4 = false;
			showFireball3Mega = false;
			showFireball4Mega = false;
			showSnore = false;
		}

		this.trailEmitterNode = this.setTrailEmitterShown(this.trailEmitterNode, showTrail, trailParticleOptions, this.trailEmitterData);
		this.whiteTrailEmitterNode = this.setTrailEmitterShown(this.whiteTrailEmitterNode, showWhiteTrail, whiteTrailParticleOptions,
			this.whiteTrailEmitterData);
		this.splash4EmitterNode = this.setTrailEmitterShown(this.splash4EmitterNode, showSplash4, splash4ParticleOptions, this.splash4EmitterData);
		this.trailBubbleEmitterNode = this.setTrailEmitterShown(this.trailBubbleEmitterNode, showTrailBubble, trailBubbleParticleOptions,
			this.trailBubbleEmitterData);
		this.fireball3EmitterNode = this.setTrailEmitterShown(this.fireball3EmitterNode, showFireball3, fireball3ParticleOptions, this.fireball3EmitterData);
		this.fireball4EmitterNode = this.setTrailEmitterShown(this.fireball4EmitterNode, showFireball4, fireball4ParticleOptions, this.fireball4EmitterData);
		this.fireball3MegaEmitterNode = this.setTrailEmitterShown(this.fireball3MegaEmitterNode, showFireball3Mega, fireball3MegaParticleOptions,
			this.fireball3MegaEmitterData);
		this.fireball4MegaEmitterNode = this.setTrailEmitterShown(this.fireball4MegaEmitterNode, showFireball4Mega, fireball4MegaParticleOptions,
			this.fireball4MegaEmitterData);
		this.snoreEmitterNode = this.setTrailEmitterShown(this.snoreEmitterNode, showSnore, snoreParticleOptions, this.snoreEmitterData);
	}

	function ReportBounce(pos:Vector, normal:Vector, speed:Float) {
		if (this._bounceYet && speed < this._bounceSpeed) {
			return;
		}
		this._bounceYet = true;
		this._bouncePos = pos;
		this._bounceSpeed = speed;
		this._bounceNormal = normal;
	}

	function playBoundSound(time:Float, contactVel:Float) {
		if (this.isNetUpdate)
			return;
		if (minVelocityBounceSoft <= contactVel) {
			var hardBounceSpeed = minVelocityBounceHard;
			var bounceSoundNum = Math.floor(Math.random() * 4);
			var sndList = ((time - this.megaMarbleEnableTime < 10)
				|| (this.megaMarbleUseTick > 0
					&& ((Net.isHost && (this.level.timeState.ticks - this.megaMarbleUseTick) <= 312)
						|| (Net.isClient && (this.serverTicks - this.megaMarbleUseTick) <= 312)))) ? [
							"data/sound/mega_bouncehard1.wav",
							"data/sound/mega_bouncehard2.wav",
							"data/sound/mega_bouncehard3.wav",
							"data/sound/mega_bouncehard4.wav"
						] : [
							"data/sound/bouncehard1.wav",
							"data/sound/bouncehard2.wav",
							"data/sound/bouncehard3.wav",
							"data/sound/bouncehard4.wav"
						];

			var snd = ResourceLoader.getResource(sndList[bounceSoundNum], ResourceLoader.getAudio, this.soundResources);
			var gain = bounceMinGain;
			gain = Util.clamp(Math.pow(contactVel / 12, 1.5), 0, 1);

			// if (hardBounceSpeed <= contactVel)
			// 	gain = 1.0;
			// else
			// 	gain = (contactVel - minVelocityBounceSoft) / (hardBounceSpeed - minVelocityBounceSoft) * (1.0 - gain) + gain;

			if (this.connection != null) {
				var distFromUs = @:privateAccess this.level.marble.lastRenderPos.distanceSq(this.lastRenderPos);
				snd.play(false, Settings.optionsSettings.soundVolume * gain / Math.max(1, distFromUs));
			} else
				snd.play(false, Settings.optionsSettings.soundVolume * gain);
		}
	}

	function updateRollSound(time:TimeState, contactPct:Float, slipAmount:Float) {
		var rSpat = rollSound.getEffect(Spatialization);
		rSpat.position = this.collider.transform.getPosition();

		if (this.rollMegaSound != null) {
			var rmspat = this.rollMegaSound.getEffect(Spatialization);
			rmspat.position = this.collider.transform.getPosition();
		}

		var sSpat = slipSound.getEffect(Spatialization);
		sSpat.position = this.collider.transform.getPosition();

		var rollVel = bestContact != null ? this.velocity.sub(bestContact.velocity) : this.velocity;
		var scale = rollVel.length();
		scale /= this._maxRollVelocity;

		var rollVolume = 2 * scale;
		if (rollVolume > 1)
			rollVolume = 1;
		if (contactPct < 0.05)
			rollVolume = rollSound.volume / 5;

		var slipVolume = 0.0;
		if (slipAmount > 1e-4) {
			slipVolume = slipAmount / 5;
			if (slipVolume > 1)
				slipVolume = 1;
			rollVolume = (1 - slipVolume) * rollVolume;
		}

		if (rollVolume < 0)
			rollVolume = 0;
		if (slipVolume < 0)
			slipVolume = 0;

		if (time.currentAttemptTime - this.megaMarbleEnableTime < 10
			|| (this.megaMarbleUseTick > 0
				&& ((Net.isHost && (this.level.timeState.ticks - this.megaMarbleUseTick) <= 312)
					|| (Net.isClient && (this.serverTicks - this.megaMarbleUseTick) <= 312)))) {
			if (this.rollMegaSound != null) {
				rollMegaSound.volume = rollVolume;
				rollSound.volume = 0;
			}
		} else {
			rollSound.volume = rollVolume;
			if (this.rollMegaSound != null) {
				rollMegaSound.volume = 0;
			}
		}
		slipSound.volume = slipVolume;

		if (rollSound.getEffect(Pitch) == null) {
			rollSound.addEffect(new Pitch());
		}

		if (rollMegaSound != null) {
			if (rollMegaSound.getEffect(Pitch) == null) {
				rollMegaSound.addEffect(new Pitch());
			}
		}

		var pitch = Util.clamp(rollVel.length() / 15, 0, 1) * 0.75 + 0.75;

		// #if js
		// // Apparently audio crashes the whole thing if pitch is less than 0.2
		// if (pitch < 0.2)
		// 	pitch = 0.2;
		// #end
		var rPitch = rollSound.getEffect(Pitch);
		rPitch.value = pitch;

		if (rollMegaSound != null) {
			var rPitch = rollMegaSound.getEffect(Pitch);
			rPitch.value = pitch;
		}
	}

	function testMove(velocity:Vector, position:Vector, deltaT:Float, radius:Float, testPIs:Bool) {
		if (velocity.length() < 0.001) {
			return {
				position: position,
				t: deltaT,
				found: false,
				foundContacts: [],
				lastContactPos: null,
				lastContactNormal: null,
				foundMarbles: [],
			};
		}
		var searchbox = new Bounds();
		searchbox.addSpherePos(position.x, position.y, position.z, _radius);
		searchbox.addSpherePos(position.x + velocity.x * deltaT, position.y + velocity.y * deltaT, position.z + velocity.z * deltaT, _radius);

		contactScratch.resize(0);
		this.collisionWorld.boundingSearch(searchbox, contactScratch);

		var foundObjs = contactScratch;

		var finalT = deltaT;
		var found = false;

		var lastContactPos = new Vector();

		var testTriangles:Array<MarbleTestMoveFoundContact> = [];

		var finalContacts = [];
		var foundMarbles = [];

		// Marble-Marble
		var nextPos = position.add(velocity.multiply(deltaT));
		for (marble in this.collisionWorld.marbleEntities) {
			if (marble == this.collider || marble.ignore)
				continue;
			var otherPosition = marble.transform.getPosition();
			var isec = Collision.capsuleSphereNearestOverlap(position, nextPos, _radius, otherPosition, marble.radius);
			if (isec.result) {
				foundMarbles.push(marble);
				isec.t *= deltaT;
				if (isec.t >= finalT) {
					var vel = position.add(velocity.multiply(finalT)).sub(otherPosition);
					vel.normalize();
					var newVelLen = this.velocity.sub(marble.velocity).dot(vel);
					if (newVelLen < 0.0) {
						finalT = isec.t;

						var posDiff = nextPos.sub(position).multiply(isec.t);
						var p = posDiff.add(position);
						lastContactNormal = p.sub(otherPosition);
						lastContactNormal.normalize();
						lastContactPos = p.sub(lastContactNormal.multiply(_radius));
					}
				}
			}
		}

		// for (iter in 0...10) {
		//	var iterationFound = false;
		for (obj in foundObjs) {
			// Its an MP so bruh
			if (obj.go == this || (obj.go != null && !obj.go.isCollideable))
				continue;

			var isDts = obj.go is DtsObject;

			var invMatrix = @:privateAccess obj.invTransform;
			if (obj.go is PathedInterior)
				invMatrix = obj.transform.getInverse();
			var invTform = invMatrix.clone();
			invTform.transpose();
			var localpos = position.clone();
			localpos.transform(invMatrix);

			var relVel = velocity.sub(obj.velocity);
			var relLocalVel = relVel.transformed3x3(invMatrix);

			var invScale = invMatrix.getScale();
			var sphereRadius = new Vector(radius * invScale.x, radius * invScale.y, radius * invScale.z);

			var boundThing = new Bounds();
			boundThing.addSpherePos(localpos.x, localpos.y, localpos.z, radius * 2);
			boundThing.addSpherePos(localpos.x
				+ relLocalVel.x * deltaT * 5, localpos.y
				+ relLocalVel.y * deltaT * 5, localpos.z
				+ relLocalVel.z * deltaT * 5,
				Math.max(Math.max(sphereRadius.x, sphereRadius.y), sphereRadius.z) * 2);

			var currentFinalPos = position.add(relVel.multiply(finalT)); // localpos.add(relLocalVel.multiply(finalT));
			surfaceScratch.resize(0);
			if (@:privateAccess obj.grid != null)
				@:privateAccess obj.grid.boundingSearch(boundThing, surfaceScratch);
			var surfaces = surfaceScratch;

			for (surf in surfaces) {
				var surface:CollisionSurface = surf;

				currentFinalPos = position.add(relVel.multiply(finalT));

				var i = 0;
				while (i < surface.indices.length) {
					var verts = surface.transformTriangle(i, obj.transform, invTform, @:privateAccess obj._transformKey);
					// var v0 = surface.points[surface.indices[i]].transformed(tform);
					// var v = surface.points[surface.indices[i + 1]].transformed(tform);
					// var v2 = surface.points[surface.indices[i + 2]].transformed(tform);
					var v0 = new Vector(verts.v1x, verts.v1y, verts.v1z);
					var v = new Vector(verts.v2x, verts.v2y, verts.v2z);
					var v2 = new Vector(verts.v3x, verts.v3y, verts.v3z);
					// var v0 = surface.points[surface.indices[i]].transformed(obj.transform);
					// var v = surface.points[surface.indices[i + 1]].transformed(obj.transform);
					// var v2 = surface.points[surface.indices[i + 2]].transformed(obj.transform);

					// var triangleVerts = [v0, v, v2];

					var surfaceNormal = new Vector(verts.nx, verts.ny,
						verts.nz); // surface.normals[surface.indices[i]].transformed3x3(obj.transform).normalized();
					if (obj is DtsObject)
						surfaceNormal.load(v.sub(v0).cross(v2.sub(v0)).normalized().multiply(-1));
					var surfaceD = -surfaceNormal.dot(v0);

					// If we're going the wrong direction or not going to touch the plane, ignore...
					if (surfaceNormal.dot(relVel) > -0.001 || surfaceNormal.dot(currentFinalPos) + surfaceD > radius) {
						i += 3;
						continue;
					}

					// var v0T = v0.transformed(obj.transform);
					// var vT = v.transformed(obj.transform);
					// var v2T = v2.transformed(obj.transform);
					// var vN = surfaceNormal.transformed3x3(obj.transform);
					if (!isDts)
						testTriangles.push({
							v: [v0.clone(), v.clone(), v2.clone()],
							n: surfaceNormal.clone(),
						});

					// Time until collision with the plane
					var collisionTime = (radius - position.dot(surfaceNormal) - surfaceD) / surfaceNormal.dot(relVel);

					// Are we going to touch the plane during this time step?
					if (collisionTime >= 0.000001 && finalT >= collisionTime) {
						var collisionPoint = position.add(relVel.multiply(collisionTime));
						// If we're inside the poly, just get the position
						if (Collision.PointInTriangle(collisionPoint, v0, v, v2)) {
							finalT = collisionTime;
							currentFinalPos = position.add(relVel.multiply(finalT));
							found = true;
							lastContactPos = currentFinalPos.clone();
							// iterationFound = true;
							i += 3;
							// Debug.drawSphere(currentFinalPos, radius);
							continue;
						}
					}
					// We *might* be colliding with an edge
					var triangleVerts = [v0.clone(), v.clone(), v2.clone()];

					var lastVert = v2.clone();

					var radSq = radius * radius;
					for (iter in 0...3) {
						var thisVert = triangleVerts[iter];

						var vertDiff = lastVert.sub(thisVert);
						var posDiff = position.sub(thisVert);

						var velRejection = vertDiff.cross(relVel);
						var posRejection = vertDiff.cross(posDiff);

						// Build a quadratic equation to solve for the collision time
						var a = velRejection.lengthSq();
						var b = 2 * posRejection.dot(velRejection);
						var c = (posRejection.lengthSq() - vertDiff.lengthSq() * radSq);

						var discriminant = b * b - (4 * a * c);

						// If it's not quadratic or has no solution, ignore this edge.
						if (a == 0.0 || discriminant < 0.0) {
							lastVert.load(thisVert);
							continue;
						}

						var oneOverTwoA = 0.5 / a;
						var discriminantSqrt = Math.sqrt(discriminant);

						// Solve using the quadratic formula
						var edgeCollisionTime = (-b + discriminantSqrt) * oneOverTwoA;
						var edgeCollisionTime2 = (-b - discriminantSqrt) * oneOverTwoA;

						// Make sure the 2 times are in ascending order
						if (edgeCollisionTime2 < edgeCollisionTime) {
							var temp = edgeCollisionTime2;
							edgeCollisionTime2 = edgeCollisionTime;
							edgeCollisionTime = temp;
						}

						// If the collision doesn't happen on this time step, ignore this edge.
						if (edgeCollisionTime2 <= 0.0001 || finalT <= edgeCollisionTime) {
							lastVert = thisVert;
							continue;
						}

						// Check if the collision hasn't already happened
						if (edgeCollisionTime >= 0.000001) {
							var edgeLen = vertDiff.length();

							var relativeCollisionPos = position.add(relVel.multiply(edgeCollisionTime)).sub(thisVert);

							var distanceAlongEdge = relativeCollisionPos.dot(vertDiff) / edgeLen;

							// If the collision happens outside the boundaries of the edge, ignore this edge.
							if (-radius > distanceAlongEdge || edgeLen + radius < distanceAlongEdge) {
								lastVert.load(thisVert);
								continue;
							}

							// If the collision is within the edge, resolve the collision and continue.
							if (distanceAlongEdge >= 0.0 && distanceAlongEdge <= edgeLen) {
								finalT = edgeCollisionTime;
								currentFinalPos = position.add(relVel.multiply(finalT));
								lastContactPos = vertDiff.multiply(distanceAlongEdge / edgeLen).add(thisVert);
								lastVert.load(thisVert);
								found = true;
								// Debug.drawSphere(currentFinalPos, radius);
								// iterationFound = true;
								continue;
							}
						}

						// This is what happens when we collide with a corner

						a = relVel.lengthSq();

						// Build a quadratic equation to solve for the collision time
						var posVertDiff = position.sub(thisVert);
						b = 2 * posVertDiff.dot(relVel);
						c = posVertDiff.lengthSq() - radSq;
						discriminant = b * b - (4 * a * c);

						// If it's quadratic and has a solution ...
						if (a != 0.0 && discriminant >= 0.0) {
							oneOverTwoA = 0.5 / a;
							discriminantSqrt = Math.sqrt(discriminant);

							// Solve using the quadratic formula
							edgeCollisionTime = (-b + discriminantSqrt) * oneOverTwoA;
							edgeCollisionTime2 = (-b - discriminantSqrt) * oneOverTwoA;

							// Make sure the 2 times are in ascending order
							if (edgeCollisionTime2 < edgeCollisionTime) {
								var temp = edgeCollisionTime2;
								edgeCollisionTime2 = edgeCollisionTime;
								edgeCollisionTime = temp;
							}

							// If the collision doesn't happen on this time step, ignore this corner
							if (edgeCollisionTime2 > 0.0001 && finalT > edgeCollisionTime) {
								// Adjust to make sure very small negative times are counted as zero
								if (edgeCollisionTime <= 0.0 && edgeCollisionTime > -0.0001)
									edgeCollisionTime = 0.0;

								// Check if the collision hasn't already happened
								if (edgeCollisionTime >= 0.000001) {
									// Resolve it and continue
									finalT = edgeCollisionTime;
									currentFinalPos = position.add(relVel.multiply(finalT));
									lastContactPos = thisVert;
									found = true;
									// Debug.drawSphere(currentFinalPos, radius);
									// iterationFound = true;
								}
							}
						}

						// We still need to check the other corner ...
						// Build one last quadratic equation to solve for the collision time
						var posVertDiff = position.sub(lastVert);
						b = 2 * posVertDiff.dot(relVel);
						c = posVertDiff.lengthSq() - radSq;
						discriminant = b * b - (4 * a * c);

						// If it's not quadratic or has no solution, then skip this corner
						if (a == 0.0 || discriminant < 0.0) {
							lastVert.load(thisVert);
							continue;
						}

						oneOverTwoA = 0.5 / a;
						discriminantSqrt = Math.sqrt(discriminant);

						// Solve using the quadratic formula
						edgeCollisionTime = (-b + discriminantSqrt) * oneOverTwoA;
						edgeCollisionTime2 = (-b - discriminantSqrt) * oneOverTwoA;

						// Make sure the 2 times are in ascending order
						if (edgeCollisionTime2 < edgeCollisionTime) {
							var temp = edgeCollisionTime2;
							edgeCollisionTime2 = edgeCollisionTime;
							edgeCollisionTime = temp;
						}

						if (edgeCollisionTime2 <= 0.0001 || finalT <= edgeCollisionTime) {
							lastVert.load(thisVert);
							continue;
						}

						if (edgeCollisionTime <= 0.0 && edgeCollisionTime > -0.0001)
							edgeCollisionTime = 0;

						if (edgeCollisionTime < 0.000001) {
							lastVert.load(thisVert);
							continue;
						}

						finalT = edgeCollisionTime;
						currentFinalPos = position.add(relVel.multiply(finalT));
						// Debug.drawSphere(currentFinalPos, radius);

						lastVert.load(thisVert);
						found = true;
						// iterationFound = true;
					}

					i += 3;
				}
			}
		}

		//	if (!iterationFound)
		//		break;
		// }
		var deltaPosition = velocity.multiply(finalT);
		var finalPosition = position.add(deltaPosition);
		position = finalPosition;

		return {
			position: position,
			t: finalT,
			found: found,
			foundContacts: testTriangles,
			lastContactPos: lastContactPos,
			lastContactNormal: position.sub(lastContactPos).normalized(),
			foundMarbles: foundMarbles
		};
	}

	function nudgeToContacts(position:Vector, radius:Float, foundContacts:Array<MarbleTestMoveFoundContact>, foundMarbles:Array<SphereCollisionEntity>) {
		if (Net.isMP)
			return position;
		var it = 0;
		var concernedContacts = foundContacts; // PathedInteriors have their own nudge logic
		var prevResolved = 0;
		do {
			var resolved = 0;
			for (testTri in concernedContacts) {
				// Check if we are on wrong side of the triangle
				if (testTri.n.dot(position) - testTri.n.dot(testTri.v[0]) < 0) {
					continue;
				}

				var t1 = testTri.v[1].sub(testTri.v[0]);
				var t2 = testTri.v[2].sub(testTri.v[0]);
				var tarea = Math.abs(t1.cross(t2).length()) / 2.0;

				// Check if our triangle is too small to be collided with
				if (tarea < 0.001) {
					continue;
				}

				// Intersection with plane of testTri and current position
				var t = (testTri.v[0].sub(position)).dot(testTri.n) / testTri.n.lengthSq();
				var intersect = position.add(testTri.n.multiply(t));

				var tsi = Collision.PointInTriangle(intersect, testTri.v[0], testTri.v[1], testTri.v[2]);
				if (tsi) {
					var separatingDistance = position.sub(intersect).normalized();
					var distToContactPlane = intersect.distance(position);
					if (radius - 0.005 - distToContactPlane > 0.0001) {
						// Nudge to the surface of the contact plane
						Debug.drawTriangle(testTri.v[0], testTri.v[1], testTri.v[2]);
						Debug.drawSphere(position, radius);
						position.load(position.add(separatingDistance.multiply(radius - distToContactPlane - 0.005)));
						resolved++;
					}
				}

				// var tsi = Collision.TriangleSphereIntersection(testTri.v[0], testTri.v[1], testTri.v[2], testTri.n, position, radius, testTri.edge,
				// 	testTri.concavity);
				// if (tsi.result) {
				// 	var separatingDistance = position.sub(tsi.point).normalized();
				// 	var distToContactPlane = tsi.point.distance(position);
				// 	if (radius - 0.005 - distToContactPlane > 0.0001) {
				// 		// Nudge to the surface of the contact plane
				// 		Debug.drawTriangle(testTri.v[0], testTri.v[1], testTri.v[2]);
				// 		Debug.drawSphere(position, radius);
				// 		position = position.add(separatingDistance.multiply(radius - distToContactPlane - 0.005));
				// 		resolved++;
				// 	}
				// }

				// var distToContactPlane = position.dot(contact.normal) - contact.point.dot(contact.normal);
			}
			if (resolved == 0 && prevResolved == 0)
				break;
			prevResolved = resolved;
			it++;
		} while (true && it < 10);
		for (marble in foundMarbles) {
			var marblePosition = marble.transform.getPosition();
			var dist = marblePosition.distance(position);
			if (dist < radius + marble.radius + 0.001) {
				var separatingDistance = position.sub(marblePosition).normalized();
				position.load(position.add(separatingDistance.multiply(radius + marble.radius + 0.001 - dist)));
			}
		}
		return position;
	}

	function advancePhysics(timeState:TimeState, m:Move, collisionWorld:CollisionWorld, pathedInteriors:Array<PathedInterior>) {
		var timeRemaining = timeState.dt;
		var startTime = timeRemaining;
		var it = 0;

		var piTime = timeRemaining;

		if (this.isNetUpdate) {
			lastMove = m;
		}

		if (m == null) {
			m = new Move();
			m.d = new Vector();
		}

		if (Net.isMP && this.blastTicks < (25000 >> 5))
			this.blastTicks += 1;

		if (Net.isClient)
			this.serverTicks++;

		_bounceYet = false;

		var contactTime = 0.0;
		var it = 0;

		var passedTime = timeState.currentAttemptTime;

		oldPos = this.collider.transform.getPosition();
		prevRot = this.getRotationQuat().clone();

		// Handle spectator hacky bullshit
		if (Net.isMP && this.level.serverStartTicks != 0) {
			if ((connection != null && connection.spectator) || (connection == null && (Net.hostSpectate || Net.clientSpectate))) {
				this.collider.transform.setPosition(new Vector(1e8, 1e8, 1e8));
				this.collisionWorld.updateTransform(this.collider);
				this.setPosition(1e8, 1e8, 1e8);

				if (Net.clientSpectate && this.connection == null) {
					this.camera.enableSpectate();
				}
				this.blastTicks = 0;
				return;
			}

			var ticks = Net.isClient ? serverTicks : timeState.ticks;

			if ((ticks - this.level.serverStartTicks) < (10000 >> 5)) // 10 seconds marble collision invulnerability - competitive mode needs this
				this.collider.ignore = true;
			else
				this.collider.ignore = false;
		}

		// if (this.controllable) {
		for (interior in pathedInteriors) {
			if (Net.isMP)
				interior.pushTickState();
		}
		if (this.level != null) {
			for (mover in this.level.movingObjects)
				mover.computeNextPathStep(timeRemaining);
		}
		// }

		// Blast
		if (m != null && m.blast) {
			this.useBlast(timeState);
			if (level.isRecording) {
				level.replay.recordMarbleStateFlags(false, false, false, true);
			}
		}

		do {
			if (timeRemaining <= 0)
				break;

			var timeStep = 0.004;
			if (timeRemaining < timeStep)
				timeStep = timeRemaining;

			passedTime += timeStep;

			var stoppedPaths = false;
			var tempState = timeState.clone();

			tempState.dt = timeStep;

			it++;

			this.findContacts(collisionWorld, tempState);

			if (this._firstTick) {
				contacts = [];
				this._firstTick = false;
			}

			var aControl = new Vector();
			var desiredOmega = new Vector();
			var isCentered = this.computeMoveForces(m, aControl, desiredOmega);

			stoppedPaths = this.velocityCancel(timeState, isCentered, false, stoppedPaths, pathedInteriors);
			var A = this.getExternalForces(tempState, m);
			var a = this.applyContactForces(timeStep, m, isCentered, aControl, desiredOmega, A);

			// NaN check so OpenAL doesn't freak out
			if (Math.isNaN(A.lengthSq())) {
				A.set(0, 0, 0);
			}

			if (Math.isNaN(a.lengthSq())) {
				a.set(0, 0, 0);
			}

			this.velocity.set(this.velocity.x + A.x * timeStep, this.velocity.y + A.y * timeStep, this.velocity.z + A.z * timeStep);
			this.omega.set(this.omega.x + a.x * timeStep, this.omega.y + a.y * timeStep, this.omega.z + a.z * timeStep);
			if (this.mode == Start) {
				// Bruh...
				this.velocity.y = 0;
				this.velocity.x = 0;
			}
			stoppedPaths = this.velocityCancel(timeState, isCentered, true, stoppedPaths, pathedInteriors);
			this._totalTime += timeStep;
			if (contacts.length != 0) {
				this._contactTime += timeStep;
			}

			for (impulse in appliedImpulses) {
				this.velocity = this.velocity.add(impulse.impulse);
				if (m.jump && impulse.contactImpulse) {
					this.velocity = this.velocity.add(impulse.impulse.normalized().multiply(this._jumpImpulse));
				}
			}
			appliedImpulses = [];

			if (this.isFrozen) {
				this.velocity.set(0, 0, 0);
				this.omega.set(0, 0, 0);
			}

			velocity.w = 0;

			var pos = this.collider.transform.getPosition();
			this.prevPos = pos.clone();

			var tdiff = timeStep;

			var finalPosData = testMove(velocity, pos, timeStep, _radius, true); // this.getIntersectionTime(timeStep, velocity);
			if (finalPosData.found) {
				var diff = timeStep - finalPosData.t;
				this.velocity = this.velocity.sub(A.multiply(diff));
				this.omega = this.omega.sub(a.multiply(diff));
				// if (finalPosData.t > 0.00001)
				timeStep = finalPosData.t;
				tdiff = diff;
			}
			var expectedPos = finalPosData.position;
			// var newPos = expectedPos;
			var newPos = nudgeToContacts(expectedPos, _radius, finalPosData.foundContacts, finalPosData.foundMarbles);

			if (this.velocity.lengthSq() > 1e-8) {
				var posDiff = newPos.sub(expectedPos);
				if (posDiff.lengthSq() > 1e-8) {
					var velDiffProj = this.velocity.multiply(posDiff.dot(this.velocity) / (this.velocity.lengthSq()));
					var expectedProjPos = expectedPos.add(velDiffProj);
					var updatedTimestep = expectedProjPos.sub(pos).length() / velocity.length();

					var tDiff = updatedTimestep - timeStep;
					if (tDiff > 0) {
						this.velocity = this.velocity.sub(A.multiply(tDiff));
						this.omega = this.omega.sub(a.multiply(tDiff));

						timeStep = updatedTimestep;
					}
				}
			}

			var rot = this.getRotationQuat();
			var quat = new Quat();
			quat.initRotation(omega.x * timeStep, omega.y * timeStep, omega.z * timeStep);
			quat.multiply(quat, rot);
			if (!Net.isMP)
				this.setRotationQuat(quat);

			var totMatrix = quat.toMatrix();
			newPos.w = 1; // Fix shit blowing up
			totMatrix.setPosition(newPos);

			if (!Net.isMP)
				this.setPosition(newPos.x, newPos.y, newPos.z);

			this.collider.setTransform(totMatrix);
			this.collisionWorld.updateTransform(this.collider);
			this.collider.velocity = this.velocity;

			if (this.heldPowerup != null
				&& (m.powerup || (Net.isClient && this.serverUsePowerup && !this.controllable))
				&& !this.outOfBounds
				&& this.powerupLockCount <= 0) {
				var pTime = timeState.clone();
				pTime.dt = timeStep;
				pTime.currentAttemptTime = passedTime;
				var netUpdate = this.isNetUpdate;
				if (this.serverUsePowerup)
					this.isNetUpdate = false;
				var consumed = this.heldPowerup.use(this, pTime);
				this.isNetUpdate = netUpdate;
				this.serverUsePowerup = false;
				if (consumed) {
					this.heldPowerup = null;
					if (!this.isNetUpdate) {
						this.netFlags |= MarbleNetFlags.PickupPowerup | MarbleNetFlags.UsePowerup;
					}
					if (this.level.isRecording) {
						this.level.replay.recordPowerupPickup(null);
					}
				}
			}

			this.updateBubble(m, timeStep);
			this.updateFireball(timeStep);

			if (contacts.length != 0)
				contactTime += timeStep;

			timeRemaining -= timeStep;

			// if (this.controllable) {
			if (this.level != null) {
				for (mover in this.level.movingObjects)
					mover.advancePath(timeStep);
				for (parented in this.level.parentedObjects)
					parented.advanceParent();
			}
			// }

			piTime += timeStep;

			if (tdiff == 0 || it > 10)
				break;
		} while (true);
		if (timeRemaining > 0) {
			// Advance pls
			// if (this.controllable) {
			if (this.level != null) {
				for (mover in this.level.movingObjects)
					mover.advancePath(timeRemaining);
				for (parented in this.level.parentedObjects)
					parented.advanceParent();
			}
			// }
		}
		this.queuedContacts.resize(0);

		newPos = this.collider.transform.getPosition(); // this.getAbsPos().getPosition().clone();

		if (this.prevPos != null && this.level != null) {
			var tempTimeState = timeState.clone();
			tempTimeState.currentAttemptTime = passedTime;
			this.callCollisionHandlers(tempTimeState, oldPos, newPos);
		}

		this.updateRollSound(timeState, contactTime / timeState.dt, this._slipAmount);

		var megaMarbleDurationTicks = Net.isMP && Net.connectedServerInfo.competitiveMode ? 156 : 312;

		if (this.megaMarbleUseTick > 0) {
			if (Net.isHost) {
				if ((timeState.ticks - this.megaMarbleUseTick) <= megaMarbleDurationTicks && this.megaMarbleUseTick > 0) {
					this._radius = 0.6666;
					this.collider.radius = 0.6666;
				} else if ((timeState.ticks - this.megaMarbleUseTick) > megaMarbleDurationTicks) {
					this.collider.radius = this._radius = 0.2;
					this.megaMarbleUseTick = 0;
					this.netFlags |= MarbleNetFlags.DoMega;
				}
			}
			if (Net.isClient) {
				if (this.serverTicks - this.megaMarbleUseTick <= megaMarbleDurationTicks && this.megaMarbleUseTick > 0) {
					this._radius = 0.6666;
					this.collider.radius = 0.6666;
				} else {
					this.collider.radius = this._radius = 0.2;
					this.megaMarbleUseTick = 0;
				}
			}
		}
		if (Net.isClient && this.megaMarbleUseTick == 0) {
			this.collider.radius = this._radius = 0.2;
		}

		if (Net.isMP) {
			if (m.powerup && this.outOfBounds) {
				this.level.cancel(this.oobSchedule);
				this.level.restart(cast this);
			}

			for (interior in pathedInteriors) {
				interior.popTickState();
			}

			if (m.respawn && !Net.connectedServerInfo.competitiveMode) { // Competitive mode disables quick respawning
				if (timeState.ticks - lastRespawnTick > (25000 >> 5)) {
					this.level.restart(cast this);
					lastRespawnTick = timeState.ticks;
				}
			}
		}
	}

	public function callCollisionHandlers(timeState:TimeState, start:Vector, end:Vector) {
		var expansion = this._radius + 0.2;
		var minP = new Vector(Math.min(start.x, end.x) - expansion, Math.min(start.y, end.y) - expansion, Math.min(start.z, end.z) - expansion);
		var maxP = new Vector(Math.max(start.x, end.x) + expansion, Math.max(start.y, end.y) + expansion, Math.max(start.z, end.z) + expansion);
		var box = Bounds.fromPoints(minP.toPoint(), maxP.toPoint());

		var marbleAABB = new Bounds();
		marbleAABB.xMin = end.x - this._radius;
		marbleAABB.xMax = end.x + this._radius;
		marbleAABB.yMin = end.y - this._radius;
		marbleAABB.yMax = end.y + this._radius;
		marbleAABB.zMin = end.z - this._radius;
		marbleAABB.zMax = end.z + this._radius;

		// var marbleHitbox = new Bounds();
		// marbleHitbox.addSpherePos(0, 0, 0, marble._radius);
		// marbleHitbox.transform(startQuat.toMatrix());
		// marbleHitbox.transform(endQuat.toMatrix());
		// marbleHitbox.offset(end.x, end.y, end.z);

		// spherebounds.addSpherePos(gjkCapsule.p2.x, gjkCapsule.p2.y, gjkCapsule.p2.z, gjkCapsule.radius);
		contactScratch.resize(0);
		this.collisionWorld.boundingSearch(box, contactScratch);
		var contacts = contactScratch;
		// var contacts = marble.contactEntities;
		var inside = [];

		for (contact in contacts) {
			if (contact.go != this) {
				if (contact.go is DtsObject) {
					var shape:DtsObject = cast contact.go;

					if (contact.boundingBox.collide(box)) {
						shape.onMarbleInside(cast this, timeState);
						if (!this.shapeOrTriggerInside.contains(contact.go)) {
							this.shapeOrTriggerInside.push(contact.go);
							shape.onMarbleEnter(cast this, timeState);
						}
						inside.push(contact.go);
					}
				}
				if (contact.go is Trigger) {
					var trigger:Trigger = cast contact.go;
					var triggeraabb = trigger.collider.boundingBox;

					if (triggeraabb.collide(marbleAABB)) {
						trigger.onMarbleInside(cast this, timeState);
						if (!this.shapeOrTriggerInside.contains(contact.go)) {
							this.shapeOrTriggerInside.push(contact.go);
							trigger.onMarbleEnter(cast this, timeState);
						}
						inside.push(contact.go);
					}
				}
			}
		}

		for (object in shapeOrTriggerInside) {
			if (!inside.contains(object)) {
				this.shapeOrTriggerInside.remove(object);
				object.onMarbleLeave(cast this, timeState);
			}
		}

		if (this.level.finishTime == null && @:privateAccess this.level.endPad != null) {
			if (box.collide(@:privateAccess this.level.endPad.finishBounds)) {
				var padUp = @:privateAccess this.level.endPad.getAbsPos().up();
				padUp = padUp.multiply(10);

				var checkBounds = box.clone();
				checkBounds.zMin -= 10;
				checkBounds.zMax += 10;
				var checkBoundsCenter = checkBounds.getCenter();
				var checkSphereRadius = checkBounds.getMax().sub(checkBoundsCenter).length();
				var checkSphere = new Bounds();
				checkSphere.addSpherePos(checkBoundsCenter.x, checkBoundsCenter.y, checkBoundsCenter.z, checkSphereRadius);
				contactScratch.resize(0);
				this.collisionWorld.boundingSearch(checkSphere, contactScratch, false);
				var endpadBB = contactScratch;
				var found = false;
				for (collider in endpadBB) {
					if (collider.go == @:privateAccess this.level.endPad) {
						var chull = cast(collider, collision.CollisionEntity);
						var chullinvT = @:privateAccess chull.invTransform.clone();
						chullinvT.clone();
						chullinvT.transpose();
						for (surface in chull.surfaces) {
							var i = 0;
							while (i < surface.indices.length) {
								var surfaceN = surface.getNormal(surface.indices[i]).transformed3x3(chullinvT);
								var v1 = surface.getPoint(surface.indices[i]).transformed(chull.transform);
								var surfaceD = -surfaceN.dot(v1);

								if (surfaceN.dot(padUp.multiply(-10)) < 0) {
									var dist = surfaceN.dot(checkBoundsCenter.toVector()) + surfaceD;
									if (dist >= 0 && dist < 5) {
										var intersectT = -(checkBoundsCenter.dot(surfaceN.toPoint()) + surfaceD) / (padUp.dot(surfaceN));
										var intersectP = checkBoundsCenter.add(padUp.multiply(intersectT).toPoint()).toVector();
										if (Collision.PointInTriangle(intersectP, v1, surface.getPoint(surface.indices[i + 1]).transformed(chull.transform),
											surface.getPoint(surface.indices[i + 2]).transformed(chull.transform))) {
											found = true;
											break;
										}
									}
								}

								i += 3;
							}

							if (found) {
								break;
							}
						}
						if (found) {
							break;
						}
					}
				}
				if (found) {
					if (@:privateAccess !this.level.endPad.inFinish) {
						@:privateAccess this.level.touchFinish();
						@:privateAccess this.level.endPad.inFinish = true;
					}
				} else {
					if (@:privateAccess this.level.endPad.inFinish)
						@:privateAccess this.level.endPad.inFinish = false;
				}
			} else {
				if (@:privateAccess this.level.endPad.inFinish)
					@:privateAccess this.level.endPad.inFinish = false;
			}
		}
	}

	// MP Only Functions
	public inline function clearNetFlags() {
		this.netFlags = 0;
	}

	public inline function queueTrapdoorUpdate(tId:Int, lastContactTick:Int) {
		trapdoorContacts.set(tId, lastContactTick);
		this.netFlags |= MarbleNetFlags.UpdateTrapdoor;
	}

	public function packUpdate(move:NetMove, timeState:TimeState) {
		var b = new OutputBitStream();
		b.writeByte(NetPacketType.MarbleUpdate);
		var marbleUpdate = new MarbleUpdatePacket();
		marbleUpdate.clientId = connection != null ? connection.id : 0;
		marbleUpdate.serverTicks = timeState.ticks;
		marbleUpdate.position = this.newPos;
		marbleUpdate.velocity = this.velocity;
		marbleUpdate.omega = this.omega;
		marbleUpdate.lastContactNormal = this.lastContactNormal;
		marbleUpdate.move = move;
		marbleUpdate.moveQueueSize = this.connection != null ? this.connection.moveManager.getQueueSize() : 255;
		marbleUpdate.blastAmount = this.blastTicks;
		marbleUpdate.blastTick = this.blastUseTick;
		marbleUpdate.heliTick = this.helicopterUseTick;
		marbleUpdate.megaTick = this.megaMarbleUseTick;
		marbleUpdate.superBounceTick = this.superBounceUseTick;
		marbleUpdate.shockAbsorberTick = this.shockAbsorberUseTick;
		marbleUpdate.oob = this.outOfBounds;
		marbleUpdate.powerUpId = this.heldPowerup != null ? this.heldPowerup.netIndex : 0x1FF;
		marbleUpdate.netFlags = this.netFlags;
		marbleUpdate.gravityDirection = this.currentUp;
		marbleUpdate.trapdoorUpdates = this.trapdoorContacts;
		marbleUpdate.pingTicks = connection != null ? connection.pingTicks : 0;
		marbleUpdate.serialize(b);

		this.trapdoorContacts = [];

		return b.getBytes();
	}

	public function unpackUpdate(p:MarbleUpdatePacket) {
		// Assume packet header is already read
		// Check if we aren't colliding with a marble
		// for (marble in this.level.collisionWorld.marbleEntities) {
		// 	if (marble != this.collider && marble.transform.getPosition().distance(p.position) < marble.radius + this._radius) {
		// 		Console.log("Marble updated inside another one!");
		// 		return false;
		// 	}
		// }
		// trace('Tick RTT: ', this.serverTicks - p.serverTicks);
		this.serverTicks = p.serverTicks;
		this.recvServerTick = p.serverTicks;
		// this.oldPos = this.newPos;
		// this.newPos = p.position;
		this.collider.transform.setPosition(p.position);
		this.velocity = p.velocity;
		this.omega = p.omega;
		this.lastContactNormal = p.lastContactNormal;
		this.blastTicks = p.blastAmount;
		this.blastUseTick = p.blastTick;
		this.helicopterUseTick = p.heliTick;
		this.megaMarbleUseTick = p.megaTick;
		this.superBounceUseTick = p.superBounceTick;
		this.shockAbsorberUseTick = p.shockAbsorberTick;
		this.serverUsePowerup = p.netFlags & MarbleNetFlags.UsePowerup > 0;
		// this.currentUp = p.gravityDirection;
		if (p.gravityDirection != null)
			this.level.setUp(cast this, p.gravityDirection, this.level.timeState);
		if (this.outOfBounds && !p.oob && this.controllable)
			@:privateAccess this.level.playGui.setCenterText('');
		this.outOfBounds = p.oob;
		this.camera.oob = p.oob;
		if (p.powerUpId == 0x1FF) {
			if (!this.serverUsePowerup)
				this.level.deselectPowerUp(cast this);
			else
				Console.log("Using powerup");
		} else {
			this.level.pickUpPowerUp(cast this, this.level.powerUps[p.powerUpId]);
		}
		if (p.moveQueueSize == 0 && this.connection != null) {
			// Pad null move on client
			this.connection.moveManager.duplicateLastMove();
		}
		if (this.connection != null) {
			if (ProfilerUI.instance.fps < 30) {
				this.connection.moveManager.stall = true; // Our fps fucked, stall pls
			} else {
				this.connection.moveManager.stall = false;
			}
		}
		if (p.netFlags & MarbleNetFlags.UpdateTrapdoor > 0) {
			for (tId => tTime in p.trapdoorUpdates) {
				@:privateAccess level.trapdoorPredictions.acknowledgeTrapdoorUpdate(tId, tTime);
			}
		}
		if (p.netFlags & MarbleNetFlags.DoBlast > 0 && blastUseTick != 0 && !this.controllable) {
			var ublast = p.netFlags & MarbleNetFlags.DoUltraBlast > 0;
			this.level.particleManager.createEmitter(ublast ? blastMaxParticleOptions : blastParticleOptions, ublast ? blastMaxEmitterData : blastEmitterData,
				this.getAbsPos().getPosition(), () -> {
					this.getAbsPos().getPosition().add(this.currentUp.multiply(-this._radius * 0.4));
				});
		}
		// if (Net.isClient && !this.controllable && (this.serverTicks - this.blastUseTick) < 12) {
		// 	var ticksSince = (this.serverTicks - this.blastUseTick);
		// 	if (ticksSince >= 0) {
		// 		this.blastWave.doSequenceOnceBeginTime = this.level.timeState.timeSinceLoad - ticksSince * 0.032;
		// 		this.blastUseTime = this.level.timeState.currentAttemptTime - ticksSince * 0.032;
		// 	}
		// }

		// if (this.controllable && Net.isClient) {
		// 	// We are client, need to do something about the queue
		// 	var mm = Net.clientConnection.moveManager;
		// 	// trace('Queue size: ${mm.getQueueSize()}, server: ${p.moveQueueSize}');
		// 	if (mm.getQueueSize() / p.moveQueueSize < 2) {
		// 		mm.stall = true;
		// 	} else {
		// 		mm.stall = false;
		// 	}
		// }
		return true;
	}

	function calculateNetSmooth() {
		if (this.netCorrected) {
			this.netCorrected = false;
			this.netSmoothOffset.load(this.lastRenderPos.sub(this.oldPos));
			// this.oldPos.load(this.posStore);
		}
	}

	public function updateServer(timeState:TimeState, collisionWorld:CollisionWorld, pathedInteriors:Array<PathedInterior>) {
		var move:NetMove = null;
		if (this.controllable && this.mode != Finish) {
			if (Net.isClient) {
				var axis = getMarbleAxis()[1];
				move = Net.clientConnection.recordMove(cast this, axis, timeState, recvServerTick);
			} else if (Net.isHost) {
				var axis = getMarbleAxis()[1];
				var innerMove = recordMove();
				if (MarbleGame.instance.paused) {
					innerMove.d.x = 0;
					innerMove.d.y = 0;
					innerMove.blast = innerMove.jump = innerMove.powerup = false;
				} else {
					var qx = Std.int((innerMove.d.x * 16) + 16);
					var qy = Std.int((innerMove.d.y * 16) + 16);
					innerMove.d.x = (qx - 16) / 16.0;
					innerMove.d.y = (qy - 16) / 16.0;
				}
				move = new NetMove(innerMove, axis, timeState, recvServerTick, 65535);
			}
		}
		var moveId = 65535;
		if (!this.controllable && this.connection != null && Net.isHost) {
			var nextMove = this.connection.getNextMove();
			// trace('Moves left: ${@:privateAccess this.connection.moveManager.queuedMoves.length}');
			if (nextMove == null) {
				var axis = moveMotionDir != null ? moveMotionDir : getMarbleAxis()[1];
				var innerMove = lastMove;
				if (innerMove == null) {
					innerMove = new Move();
					innerMove.d = new Vector(0, 0);
				}
				move = new NetMove(innerMove, axis, timeState, recvServerTick, 65535);
			} else {
				move = nextMove;
				moveMotionDir = nextMove.motionDir;
				moveId = nextMove.id;
				lastMove = move.move;
			}
		}
		if (move == null && !this.controllable || this.mode == Finish) {
			var axis = moveMotionDir != null ? moveMotionDir : new Vector(0, -1, 0);
			var innerMove = lastMove;
			if (innerMove == null) {
				innerMove = new Move();
				innerMove.d = new Vector(0, 0);
			}
			move = new NetMove(innerMove, axis, timeState, recvServerTick, 65535);
		}

		if (move != null) {
			playedSounds = [];
			advancePhysics(timeState, move.move, collisionWorld, pathedInteriors);
			physicsAccumulator = 0;
		} else {
			physicsAccumulator = 0;
			newPos.load(oldPos);
		}

		return move;
		// if (Net.isHost) {
		// 	packets.push({b: packUpdate(move, timeState), c: this.connection != null ? this.connection.id : 0});
		// }
	}

	public function updateClient(timeState:TimeState, pathedInteriors:Array<PathedInterior>) {
		calculateNetSmooth();
		this.level.updateBlast(cast this, timeState);

		var newDt = 2.3 * (timeState.dt / 0.4);
		var smooth = 1.0 / (newDt * (newDt * 0.235 * newDt) + newDt + 1.0 + 0.48 * newDt * newDt);
		this.netSmoothOffset.scale(smooth);
		var smoothScale = this.netSmoothOffset.lengthSq();
		if (smoothScale < 0.01 || smoothScale > 25.0)
			this.netSmoothOffset.set(0, 0, 0);

		if (oldPos != null && newPos != null) {
			var deltaT = physicsAccumulator / 0.032;
			// if (Net.isClient && !this.controllable)
			//	deltaT *= 0.75; // Don't overshoot
			var renderPos = Util.lerpThreeVectors(this.oldPos, this.newPos, deltaT);
			if (Net.isClient) {
				renderPos.load(renderPos.add(this.netSmoothOffset));
			}
			this.setPosition(renderPos.x, renderPos.y, renderPos.z);
			this.lastRenderPos.load(renderPos);

			var rot = this.getRotationQuat();
			var quat = new Quat();
			quat.initRotation(omega.x * timeState.dt, omega.y * timeState.dt, omega.z * timeState.dt);
			quat.multiply(quat, rot);
			this.setRotationQuat(quat);

			var adt = timeState.clone();
			adt.dt = Util.adjustedMod(physicsAccumulator, 0.032);
			for (pi in pathedInteriors) {
				pi.update(adt);
			}
		}
		physicsAccumulator += timeState.dt;

		if (this.controllable
			&& this.level != null
			&& !this.level.rewinding
			&& !(Net.clientSpectate || Net.hostSpectate)) { // Separately update the camera if spectate
			// this.camera.startCenterCamera();
			this.camera.update(timeState.currentAttemptTime, timeState.dt);
		}

		updatePowerupStates(timeState);
		updateTeleporterState(timeState);

		if (isMegaMarbleEnabled(timeState)) {
			marbleDts.setScale(0.6666 / _dtsRadius);
		} else {
			marbleDts.setScale(0.2 / _dtsRadius);
		}

		// if (isMegaMarbleEnabled(timeState)) {
		// 	this._marbleScale = this._defaultScale * 2.25;
		// } else {
		// 	this._marbleScale = this._defaultScale;
		// }

		// var s = this._renderScale * this._renderScale;
		// if (s <= this._marbleScale * this._marbleScale)
		// 	s = 0.1;
		// else
		// 	s = 0.4;

		// s = timeState.dt / s * 2.302585124969482;
		// s = 1.0 / (s * (s * 0.235 * s) + s + 1.0 + 0.48 * s * s);
		// this._renderScale *= s;
		// s = 1 - s;
		// this._renderScale += s * this._marbleScale;
		// var marbledts = cast(this.getChildAt(0), DtsObject);
		// marbledts.setScale(this._renderScale);

		if (bounceEmitDelay > 0)
			bounceEmitDelay -= timeState.dt;
		if (bounceEmitDelay < 0)
			bounceEmitDelay = 0;
	}

	public function recordMove() {
		var move = new Move();
		move.d = new Vector();
		move.d.x = Gamepad.getAxis(Settings.gamepadSettings.moveYAxis);
		move.d.y = -Gamepad.getAxis(Settings.gamepadSettings.moveXAxis);
		if (@:privateAccess !MarbleGame.instance.world.playGui.isChatFocused()) {
			if (Key.isDown(Settings.controlsSettings.forward)) {
				move.d.x -= 1;
			}
			if (Key.isDown(Settings.controlsSettings.backward)) {
				move.d.x += 1;
			}
			if (Key.isDown(Settings.controlsSettings.left)) {
				move.d.y += 1;
			}
			if (Key.isDown(Settings.controlsSettings.right)) {
				move.d.y -= 1;
			}
			move.d.x = Util.clamp(move.d.x, -1, 1);
			move.d.y = Util.clamp(move.d.y, -1, 1);
			if (Key.isDown(Settings.controlsSettings.jump)
				|| MarbleGame.instance.touchInput.jumpButton.pressed
				|| Gamepad.isDown(Settings.gamepadSettings.jump)) {
				move.jump = true;
			}
			if ((!Util.isTouchDevice() && Key.isPressed(Settings.controlsSettings.powerup))
				|| (Util.isTouchDevice() && MarbleGame.instance.touchInput.powerupClicked)
				|| Gamepad.isPressed(Settings.gamepadSettings.powerup)) {
				move.powerup = true;
			}
			if ((!Util.isTouchDevice() && Key.isDown(Settings.controlsSettings.powerup))
				|| (Util.isTouchDevice() && MarbleGame.instance.touchInput.powerupButton.pressed)
				|| Gamepad.isDown(Settings.gamepadSettings.powerup)) {
				move.powerupHeld = true;
			}

			if (Key.isDown(Settings.controlsSettings.blast)
				|| (MarbleGame.instance.touchInput.blastbutton.pressed)
				|| Gamepad.isDown(Settings.gamepadSettings.blast))
				move.blast = true;

			if (Key.isDown(Settings.controlsSettings.respawn) || Gamepad.isDown(Settings.gamepadSettings.respawn)) {
				move.respawn = true;
				if (Net.isMP) {
					@:privateAccess Key.keyPressed[Settings.controlsSettings.respawn] = 0;
					Gamepad.releaseKey(Settings.gamepadSettings.respawn);
				}
			}

			if (MarbleGame.instance.touchInput.movementInput.pressed) {
				move.d.y = -MarbleGame.instance.touchInput.movementInput.value.x;
				move.d.x = MarbleGame.instance.touchInput.movementInput.value.y;
			}
		}
		return move;
	}

	public function update(timeState:TimeState, collisionWorld:CollisionWorld, pathedInteriors:Array<PathedInterior>) {
		var move:Move = null;
		if (this.controllable && !this.level.isWatching) {
			move = recordMove();
		}
		if (level.isReplayingMovement)
			move = level.currentInputMoves[1].move;

		if (this.level.isWatching) {
			move = new Move();
			move.d = new Vector(0, 0);
			if (this.level.replay.currentPlaybackFrame.marbleStateFlags.has(Jumped))
				move.jump = true;
			if (this.level.replay.currentPlaybackFrame.marbleStateFlags.has(UsedPowerup))
				move.powerup = true;
			move.d = new Vector(this.level.replay.currentPlaybackFrame.marbleX, this.level.replay.currentPlaybackFrame.marbleY, 0);
		} else {
			if (this.level.isRecording) {
				this.level.replay.recordMarbleStateFlags(move.jump, move.powerup, false, false);
				this.level.replay.recordMarbleInput(move.d.x, move.d.y);
			}
		}
		if (!this.controllable && (this.connection != null || this.level == null)) {
			move = new Move();
			move.d = new Vector(0, 0);
		}

		playedSounds = [];
		advancePhysics(timeState, move, collisionWorld, pathedInteriors);

		for (pi in pathedInteriors) {
			pi.update(timeState);
		}

		// physicsAccumulator += timeState.dt;

		// while (physicsAccumulator > 0.032) {
		// 	var adt = timeState.clone();
		// 	adt.dt = 0.032;
		// 	advancePhysics(adt, move, collisionWorld, pathedInteriors);
		// 	physicsAccumulator -= 0.032;
		// }
		// if (oldPos != null && newPos != null) {
		// 	var deltaT = physicsAccumulator / 0.032;
		// 	var renderPos = Util.lerpThreeVectors(this.oldPos, this.newPos, deltaT);
		// 	this.setPosition(renderPos.x, renderPos.y, renderPos.z);

		// 	var rot = this.getRotationQuat();
		// 	var quat = new Quat();
		// 	quat.initRotation(omega.x * timeState.dt, omega.y * timeState.dt, omega.z * timeState.dt);
		// 	quat.multiply(quat, rot);
		// 	this.setRotationQuat(quat);

		// 	var adt = timeState.clone();
		// 	adt.dt = physicsAccumulator;
		// 	for (pi in pathedInteriors) {
		// 		pi.update(adt);
		// 	}
		// }

		if (!this.level.isWatching) {
			if (this.level.isRecording) {
				this.level.replay.recordMarbleState(this.getAbsPos().getPosition(), this.velocity, this.getRotationQuat(), this.omega);
			}
		} else {
			var expectedPos = this.level.replay.currentPlaybackFrame.marblePosition.clone();
			var expectedVel = this.level.replay.currentPlaybackFrame.marbleVelocity.clone();
			var expectedOmega = this.level.replay.currentPlaybackFrame.marbleAngularVelocity.clone();

			this.setPosition(expectedPos.x, expectedPos.y, expectedPos.z);
			var tform = this.level.replay.currentPlaybackFrame.marbleOrientation.toMatrix();

			tform.setPosition(new Vector(expectedPos.x, expectedPos.y, expectedPos.z));
			this.collider.setTransform(tform);
			this.velocity = expectedVel;
			this.setRotationQuat(this.level.replay.currentPlaybackFrame.marbleOrientation.clone());
			this.omega = expectedOmega;
		}

		if (this.controllable && !this.level.rewinding) {
			this.camera.update(timeState.currentAttemptTime, timeState.dt);
		}

		updatePowerupStates(timeState);

		if (this._radius != 0.6666 && timeState.currentAttemptTime - this.megaMarbleEnableTime < 10) {
			this._prevRadius = this._radius;
			this._radius = 0.6666;
			this.collider.radius = 0.6666;
			var marbledts = cast(this.getChildAt(0), DtsObject);
			marbledts.scale(this._radius / this._prevRadius);
		} else if (timeState.currentAttemptTime - this.megaMarbleEnableTime > 10) {
			if (this._radius != this._prevRadius) {
				this._radius = this._prevRadius;
				this.collider.radius = this._radius;
				var marbledts = cast(this.getChildAt(0), DtsObject);
				marbledts.scale(this._prevRadius / 0.6666);
			}
		}

		this.updateTeleporterState(timeState);
		this.updateWater(timeState);

		this.updateTrailEmitters(timeState);
		if (bounceEmitDelay > 0)
			bounceEmitDelay -= timeState.dt;
		if (bounceEmitDelay < 0)
			bounceEmitDelay = 0;

		// this.camera.target.load(this.getAbsPos().getPosition().toPoint());
	}

	public function updatePowerupStates(timeState:TimeState) {
		this.shadowVolume.setPosition(x, y, z);
		this.shadowVolume.setScale(this._radius / 0.2);
		if (this.level == null)
			return;
		if (this.isFrozen && timeState.currentAttemptTime - this.lastFreezeTime >= shapes.IceShard.FREEZE_TIME)
			this.unfreeze(false);
		var shockEnabled = isShockAbsorberEnabled(timeState);
		var bounceEnabled = isSuperBounceEnabled(timeState);
		var helicopterEnabled = isHelicopterEnabled(timeState);
		var megaEnabled = isMegaMarbleEnabled(timeState);
		var selfMarble = level.marble == cast this;
		if (selfMarble) {
			if (shockEnabled) {
				this.shockabsorberSound.pause = false;
			} else {
				this.shockabsorberSound.pause = true;
			}
			if (bounceEnabled) {
				this.superbounceSound.pause = false;
			} else {
				this.superbounceSound.pause = true;
			}
		}

		if (shockEnabled || bounceEnabled) {
			this.forcefield.setPosition(0, 0, 0);
		} else {
			this.forcefield.x = 1e8;
			this.forcefield.y = 1e8;
			this.forcefield.z = 1e8;
		}
		if (megaEnabled) {
			this.helicopter.setPosition(1e8, 1e8, 1e8);
			if (helicopterEnabled) {
				this.megaHelicopter.setPosition(x, y, z);
				this.megaHelicopter.setRotationQuat(this.level.getOrientationQuat(timeState.currentAttemptTime));
				if (selfMarble)
					this.helicopterSound.pause = false;
			} else {
				this.megaHelicopter.setPosition(1e8, 1e8, 1e8);
				if (selfMarble)
					this.helicopterSound.pause = true;
			}
		} else {
			this.megaHelicopter.setPosition(1e8, 1e8, 1e8);
			var activeHelicopter = this.usePQHelicopter ? this.helicopterPQ : this.helicopter;
			var inactiveHelicopter = this.usePQHelicopter ? this.helicopter : this.helicopterPQ;
			inactiveHelicopter.setPosition(1e8, 1e8, 1e8);
			if (helicopterEnabled) {
				activeHelicopter.setPosition(x, y, z);
				activeHelicopter.setRotationQuat(this.level.getOrientationQuat(timeState.currentAttemptTime));
				if (selfMarble)
					this.helicopterSound.pause = false;
			} else {
				activeHelicopter.setPosition(1e8, 1e8, 1e8);
				if (selfMarble)
					this.helicopterSound.pause = true;
			}
		}

		if (this.isFrozen) {
			this.iceChunk.setPosition(x, y, z);
			// PQ: `%scale = %marble.getCollisionRadius() / 0.18975; setScale(%scale + 0.1)`.
			this.iceChunk.setScale(this._radius / 0.18975 + 0.1);
		} else {
			this.iceChunk.setPosition(1e8, 1e8, 1e8);
		}

		if (this.bubbleActive) {
			var camPos = this.level.scene.camera.pos;
			var objPos = this.bubbleVisual.getAbsPos().getPosition();
			var faceDir = camPos.sub(objPos).normalized();
			var visualPos = new Vector(x, y, z).add(faceDir.multiply(0.2));
			this.bubbleVisual.setPosition(visualPos.x, visualPos.y, visualPos.z);
			if (selfMarble)
				this.bubbleSound.pause = false;
		} else {
			this.bubbleVisual.setPosition(1e8, 1e8, 1e8);
			if (selfMarble)
				this.bubbleSound.pause = true;
		}
	}

	public function getMass() {
		if (this.level == null)
			return 1;
		if (this.level.timeState.currentAttemptTime - this.megaMarbleEnableTime < 10
			|| (Net.isHost && this.megaMarbleUseTick > 0 && (this.level.timeState.ticks - this.megaMarbleUseTick) < 312)
			|| (Net.isClient && this.megaMarbleUseTick > 0 && (this.serverTicks - this.megaMarbleUseTick) < 312)) {
			return 4;
		} else {
			return 1;
		}
	}

	public function useBlast(timeState:TimeState) {
		// Fireball intercepts the blast input first when active - if it fires, skip the normal
		// Ultra blast entirely for this call (matches `input_useBlast`'s early return).
		if (this.fireballBlast(timeState))
			return;
		if (Net.isMP) {
			if (this.blastTicks < 156)
				return;
			var blastAmt = this.blastTicks / (25000 >> 5);
			var impulse = this.currentUp.multiply((blastAmt > 1.0 ? blastAmt : Math.sqrt(blastAmt)) * 10);
			this.applyImpulse(impulse);
			if (!isNetUpdate && this.controllable)
				AudioManager.playSound(ResourceLoader.getResource('data/sound/blast.wav', ResourceLoader.getAudio, this.soundResources));
			if (!isNetUpdate)
				this.level.particleManager.createEmitter(blastAmt > 1 ? blastMaxParticleOptions : blastParticleOptions,
					blastAmt > 1 ? blastMaxEmitterData : blastEmitterData, this.getAbsPos().getPosition(), () -> {
						this.getAbsPos().getPosition().add(this.currentUp.multiply(-this._radius * 0.4));
					});
			this.blastTicks = 0;
			// Now send the impulse to other marbles
			if (!Net.connectedServerInfo.competitiveMode || blastAmt > 1) { // Competitor mode only allows ultra blasts
				var strength = blastAmt * (blastAmt > 1 ? blastRechargeShockwaveStrength : blastShockwaveStrength);
				var ourPos = this.collider.transform.getPosition();
				for (marble in level.marbles) {
					if (marble != cast this) {
						var theirPos = marble.collider.transform.getPosition();
						var posDiff = ourPos.distance(theirPos);
						if (posDiff < 5) {
							var myMod = isMegaMarbleEnabled(timeState) ? 0.7 : 1.0;
							var theirMod = @:privateAccess marble.isMegaMarbleEnabled(timeState) ? 0.7 : 1.0;
							var impulse = theirPos.sub(ourPos).normalized().multiply(strength * (theirMod / myMod));
							marble.applyImpulse(impulse);
						}
					}
				}
			}
			if (Net.isHost) {
				this.blastUseTick = timeState.ticks;
				this.netFlags |= MarbleNetFlags.DoBlast;
				if (blastAmt > 1)
					this.netFlags |= MarbleNetFlags.DoUltraBlast;
			}
		} else {
			if (this.blastAmount < 0.2 || this.level.game != "ultra")
				return;
			var impulse = this.currentUp.multiply((this.blastAmount > 1.0 ? this.blastAmount : Math.sqrt(this.blastAmount)) * 10);
			this.applyImpulse(impulse);
			AudioManager.playSound(ResourceLoader.getResource('data/sound/blast.wav', ResourceLoader.getAudio, this.soundResources));
			this.level.particleManager.createEmitter(this.blastAmount > 1 ? blastMaxParticleOptions : blastParticleOptions,
				this.blastAmount > 1 ? blastMaxEmitterData : blastEmitterData, this.getAbsPos().getPosition(), () -> {
					this.getAbsPos().getPosition().add(this.currentUp.multiply(-this._radius * 0.4));
				});
			this.blastAmount = 0;
		}
	}

	public function applyImpulse(impulse:Vector, contactImpulse:Bool = false) {
		this.appliedImpulses.push({impulse: impulse, contactImpulse: contactImpulse});
	}

	public function enableSuperBounce(timeState:TimeState) {
		if (this.level.isMultiplayer) {
			this.superBounceUseTick = Net.isHost ? timeState.ticks : serverTicks;
			if (!this.isNetUpdate)
				this.netFlags |= MarbleNetFlags.DoSuperBounce;
		} else
			this.superBounceEnableTime = timeState.currentAttemptTime;
	}

	inline function isSuperBounceEnabled(timeState:TimeState) {
		if (this.level == null)
			return false;
		if (!this.level.isMultiplayer) {
			return timeState.currentAttemptTime - this.superBounceEnableTime < 5;
		} else {
			if (Net.isHost) {
				return (superBounceUseTick > 0 && (this.level.timeState.ticks - superBounceUseTick) <= 156);
			} else {
				return (superBounceUseTick > 0 && (serverTicks - superBounceUseTick) <= 156);
			}
		}
	}

	public function enableShockAbsorber(timeState:TimeState) {
		if (this.level.isMultiplayer) {
			this.shockAbsorberUseTick = Net.isHost ? timeState.ticks : serverTicks;
			if (!this.isNetUpdate)
				this.netFlags |= MarbleNetFlags.DoShockAbsorber;
		} else
			this.shockAbsorberEnableTime = timeState.currentAttemptTime;
	}

	inline function isShockAbsorberEnabled(timeState:TimeState) {
		if (this.level == null)
			return false;
		if (!this.level.isMultiplayer) {
			return timeState.currentAttemptTime - this.shockAbsorberEnableTime < 5;
		} else {
			if (Net.isHost) {
				return (shockAbsorberUseTick > 0 && (this.level.timeState.ticks - shockAbsorberUseTick) <= 156);
			} else {
				return (shockAbsorberUseTick > 0 && (serverTicks - shockAbsorberUseTick) <= 156);
			}
		}
	}

	public function enableHelicopter(timeState:TimeState, usePQModel:Bool = false) {
		this.usePQHelicopter = usePQModel;
		if (this.level.isMultiplayer) {
			this.helicopterUseTick = Net.isHost ? timeState.ticks : serverTicks;
			if (!this.isNetUpdate)
				this.netFlags |= MarbleNetFlags.DoHelicopter;
		} else
			this.helicopterEnableTime = timeState.currentAttemptTime;
	}

	inline function isHelicopterEnabled(timeState:TimeState) {
		if (this.level == null)
			return false;
		if (!this.level.isMultiplayer) {
			return timeState.currentAttemptTime - this.helicopterEnableTime < 5;
		} else {
			if (Net.isHost) {
				return (helicopterUseTick > 0 && (this.level.timeState.ticks - helicopterUseTick) <= 156);
			} else {
				return (helicopterUseTick > 0 && (serverTicks - helicopterUseTick) <= 156);
			}
		}
	}

	inline function isMegaMarbleEnabled(timeState:TimeState) {
		var megaMarbleTicks = Net.isMP && Net.connectedServerInfo.competitiveMode ? 156 : 312;
		if (this.level == null)
			return false;
		if (!this.level.isMultiplayer) {
			return timeState.currentAttemptTime - this.megaMarbleEnableTime < 10;
		} else {
			if (Net.isHost) {
				return (megaMarbleUseTick > 0 && (this.level.timeState.ticks - megaMarbleUseTick) <= megaMarbleTicks);
			} else {
				return (megaMarbleUseTick > 0 && (serverTicks - megaMarbleUseTick) <= megaMarbleTicks);
			}
		}
	}

	public function enableMegaMarble(timeState:TimeState) {
		if (this.level.isMultiplayer) {
			this.megaMarbleUseTick = Net.isHost ? timeState.ticks : serverTicks;
			if (!this.isNetUpdate)
				this.netFlags |= MarbleNetFlags.DoMega;
		} else
			this.megaMarbleEnableTime = timeState.currentAttemptTime;
	}

	function updateTeleporterState(time:TimeState) {
		var teleportFadeCompletion:Float = 0;

		if (this.teleportEnableTime != null)
			teleportFadeCompletion = Util.clamp((time.currentAttemptTime - this.teleportEnableTime) / 0.5, 0, 1);
		if (this.teleportDisableTime != null)
			teleportFadeCompletion = Util.clamp(1 - (time.currentAttemptTime - this.teleportDisableTime) / 0.5, 0, 1);

		if (teleportFadeCompletion > 0) {
			var ourDts:DtsObject = cast this.children[0];
			ourDts.setOpacity(Util.lerp(1, 0.25, teleportFadeCompletion));
			this.teleporting = true;
		} else {
			if (this.teleporting) {
				var ourDts:DtsObject = cast this.children[0];
				ourDts.setOpacity(1);
				this.teleporting = false;
			}
		}

		// Ported from `TeleportItem::finishTeleport` - fires once `teleporterTeleTime` has elapsed
		// since the second (fire) press. See `teleporterFiring`'s doc comment for why this lives
		// here instead of a schedule.
		if (this.teleporterFiring && time.currentAttemptTime - this.teleporterFireStartTime >= this.teleporterTeleTime) {
			this.teleporterFiring = false;
			this.setCloaking(false, time);
			if (!this.teleporterKeepVelocity) {
				this.velocity.set(0, 0, 0);
				this.omega.set(0, 0, 0);
			}
			this.prevPos.load(this.teleporterSavedPosition);
			this.setPosition(this.teleporterSavedPosition.x, this.teleporterSavedPosition.y, this.teleporterSavedPosition.z);
			var ct = this.collider.transform.clone();
			ct.setPosition(this.teleporterSavedPosition);
			this.collider.setTransform(ct);

			if (this == this.level.marble) {
				this.camera.CameraYaw = this.teleporterSavedYaw;
				this.camera.CameraPitch = this.teleporterSavedPitch;
				this.camera.nextCameraYaw = this.teleporterSavedYaw;
				this.camera.nextCameraPitch = this.teleporterSavedPitch;
				this.level.setUp(this, this.teleporterSavedGravity, time, true);
			}
		}
	}

	public function setCloaking(active:Bool, time:TimeState) {
		this.cloak = active;
		if (this.cloak) {
			var completion = (this.teleportDisableTime != null) ? Util.clamp((time.currentAttemptTime - this.teleportDisableTime) / 0.5, 0, 1) : 1;
			this.teleportEnableTime = time.currentAttemptTime - 0.5 * (1 - completion);
			this.teleportDisableTime = null;
		} else {
			var completion = Util.clamp((time.currentAttemptTime - this.teleportEnableTime) / 0.5, 0, 1);
			this.teleportDisableTime = time.currentAttemptTime - 0.5 * (1 - completion);
			this.teleportEnableTime = null;
		}
	}

	/** Ported from PQ's `IceShard::onCollision` (`server/scripts/hazards.cs`). MegaMarble is
		immune - touching a shard while mega just cancels MegaMarble instead of freezing. Otherwise
		locks movement (reusing the existing `movementTriggerCount` gate) and zeroes velocity every
		tick while frozen (see `advancePhysics`). Unfreezing itself is driven by `lastFreezeTime`
		(checked every frame in `updatePowerupStates`, same pattern as `PowerUp.cooldownDuration`/
		`PushButton.getCurrentCompletion`) rather than a one-shot schedule, so it survives rewind
		and mission-reset the same way every other timed state in this class already does. */
	public function freeze(ice:shapes.IceShard, timeState:TimeState) {
		if (isMegaMarbleEnabled(timeState)) {
			this.megaMarbleEnableTime = -1e8;
			ice.playCrackSound(this);
			return;
		}

		this.isFrozen = true;
		this.movementTriggerCount++;
		this.lockPowerupUse();
		this.iceShard = ice;
		this.lastFreezeTime = timeState.currentAttemptTime;
		this.velocity.set(0, 0, 0);
		this.omega.set(0, 0, 0);
		ice.playFreezeSound(this);
	}

	/** Ported from PQ's `Marble::lockPowerup`/`unlockPowerup` (`server/scripts/marble.cs`) -
		swaps the HUD's powerup frame to a "locked" graphic. A count rather than a plain toggle so
		multiple simultaneous lock reasons (only freezing, currently) don't unlock each other early. */
	public function lockPowerupUse() {
		this.powerupLockCount++;
		if (this.level != null)
			@:privateAccess this.level.playGui.lockPowerup(true);
	}

	public function unlockPowerupUse() {
		this.powerupLockCount--;
		if (this.powerupLockCount < 0)
			this.powerupLockCount = 0;
		if (this.powerupLockCount == 0 && this.level != null)
			@:privateAccess this.level.playGui.lockPowerup(false);
	}

	/** `cancel` mirrors PQ's own parameter - `true` when the freeze is being cut short (e.g. a
		mission restart) rather than expiring naturally, skipping the un-freeze impulse/sound. */
	public function unfreeze(cancel:Bool) {
		if (!this.isFrozen)
			return;
		this.isFrozen = false;
		this.movementTriggerCount--;
		if (this.movementTriggerCount < 0)
			this.movementTriggerCount = 0;
		this.unlockPowerupUse();

		if (!cancel) {
			var pos = this.getAbsPos().getPosition();
			var icePos = this.iceShard != null ? this.iceShard.getAbsPos().getPosition() : pos;
			var away = pos.sub(icePos);
			away = away.length() > 0.0001 ? away.normalized() : new Vector(1, 0, 0);
			var impulse = away.multiply(3).add(this.currentUp.multiply(5));
			this.velocity = this.velocity.add(impulse);
			if (this.iceShard != null)
				this.iceShard.playCrackSound(this);

			// Ported from `IceShard::unfreeze` - two particle bursts at the marble's position, the
			// ejection cone oriented along gravity-up flipped 180° (`applyrotations(getGravityRot(),
			// "0 180 0")`), matching the impulse direction above.
			if (this.level != null) {
				var axis = this.currentUp.multiply(-1);
				iceChunkChunkParticleOptions.axis = axis;
				iceChunkSnowParticleOptions.axis = axis;
				this.level.particleManager.createEmitter(iceChunkChunkParticleOptions, this.iceChunkChunkEmitterData, pos);
				this.level.particleManager.createEmitter(iceChunkSnowParticleOptions, this.iceChunkSnowEmitterData, pos);
			}
		} else {
			this.lastFreezeTime = -1e8;
		}
		this.iceShard = null;
	}

	public inline function setMode(mode:Mode) {
		this.mode = mode;
	}

	public function setMarblePosition(x:Float, y:Float, z:Float) {
		this.collider.transform.setPosition(new Vector(x, y, z));
		this.setPosition(x, y, z);
	}

	public inline function getConnectionId() {
		if (this.connection == null) {
			return Net.isHost ? 0 : Net.clientId;
		} else {
			return this.connection.id;
		}
	}

	public override function reset() {
		this.velocity = new Vector();
		this.collider.velocity = new Vector();
		this.omega = new Vector();
		this.superBounceEnableTime = Math.NEGATIVE_INFINITY;
		this.shockAbsorberEnableTime = Math.NEGATIVE_INFINITY;
		this.helicopterEnableTime = Math.NEGATIVE_INFINITY;
		this.megaMarbleEnableTime = Math.NEGATIVE_INFINITY;
		this.blastUseTick = 0;
		this.blastTicks = 0;
		this.movementTriggerCount = 0;
		this.teleporterArmed = false;
		this.teleporterLastUseTime = -1000;
		if (this.teleporterMarker != null)
			this.teleporterMarker.setPosition(1e8, 1e8, 1e8);
		if (this.isFrozen)
			this.unlockPowerupUse();
		this.isFrozen = false;
		this.lastFreezeTime = -1e8;
		this.physicsLayers = [];
		if (this.physicsAttributeBaseline != null)
			for (attr in PHYSMOD_ATTRIBUTES)
				setMarbleAttribute(attr, this.physicsAttributeBaseline.get(attr));
		// physicsLayers was just wiped wholesale above, so the layers backing these no longer
		// exist - clear their bookkeeping directly rather than via popPhysicsLayer/deactivate*
		// (which would try to remove an already-gone layer and skip the flag resets).
		this.isInWater = false;
		this.waterTriggers = [];
		this.waterPhysicsLayer = null;
		this.currentWaterTrigger = null;
		this.bubbleActive = false;
		this.bubbleTime = 0;
		this.bubbleTotalTime = 0;
		this.bubbleInfinite = false;
		this.bubblePhysicsLayer = null;
		if (this.bubbleSound != null)
			this.bubbleSound.pause = true;
		if (this.level != null)
			this.level.playGui.updateBubbleBar(0, 0, false);
		this.fireball = false;
		this.fireballTime = 0;
		this.fireballTotalTime = 0;
		this.fireballLastBlastTime = -1e8;
		if (this.level != null)
			this.level.playGui.updateFireballBar(0, 0, false);
		this.iceShard = null;
		if (this.iceChunk != null)
			this.iceChunk.setPosition(1e8, 1e8, 1e8);
		this.helicopterUseTick = 0;
		this.megaMarbleUseTick = 0;
		this.netFlags = MarbleNetFlags.DoBlast | MarbleNetFlags.DoMega | MarbleNetFlags.DoHelicopter | MarbleNetFlags.DoShockAbsorber | MarbleNetFlags.DoSuperBounce | MarbleNetFlags.PickupPowerup | MarbleNetFlags.GravityChange | MarbleNetFlags.UsePowerup;
		this.lastContactNormal = new Vector(0, 0, 1);
		this.cloak = false;
		this._firstTick = true;
		this.lastRespawnTick = -100000;
		if (this.teleporting) {
			var ourDts:DtsObject = cast this.children[0];
			ourDts.setOpacity(1);
		}
		this.teleporting = false;
		this.teleportDisableTime = null;
		this.teleportEnableTime = null;
		this.physicsAccumulator = 0;
		this.prevRot = this.getRotationQuat().clone();
		this.oldPos = this.getAbsPos().getPosition();
		this.newPos = this.getAbsPos().getPosition();
		this.posStore = new Vector();
		this.netSmoothOffset = new Vector();
		this.lastRenderPos = new Vector();
		this.netCorrected = false;
		this.serverUsePowerup = false;
		if (this._radius != this._prevRadius) {
			this._radius = this._prevRadius;
			this.collider.radius = this._radius;
			var marbledts = cast(this.getChildAt(0), DtsObject);
			marbledts.scale(this._prevRadius / 0.6666);
		}
	}

	public override function dispose() {
		if (this.rollSound != null)
			this.rollSound.stop();
		if (this.rollMegaSound != null)
			this.rollMegaSound.stop();
		if (this.slipSound != null)
			this.slipSound.stop();
		if (this.helicopterSound != null)
			this.helicopterSound.stop();
		if (this.bubbleSound != null)
			this.bubbleSound.stop();
		this.shadowVolume.remove();
		this.helicopter.remove();
		this.helicopterPQ.remove();
		this.teleporterMarker.remove();
		this.bubbleVisual.remove();
		super.dispose();
		removeChildren();
		camera = null;
		collider = null;
	}
}
