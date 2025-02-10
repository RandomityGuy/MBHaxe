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

enum Mode {
	Start;
	Play;
	Finish;
}

final bounceParticleOptions:ParticleEmitterOptions = {
	ejectionPeriod: 80,
	ambientVelocity: new Vector(0, 0, 0.0),
	ejectionVelocity: 3,
	velocityVariance: 0.25,
	emitterLifetime: 250,
	inheritedVelFactor: 0,
	particleOptions: {
		texture: 'particles/star.png',
		blending: Alpha,
		spinSpeed: 90,
		spinRandomMin: -90,
		spinRandomMax: 90,
		lifetime: 500,
		lifetimeVariance: 100,
		dragCoefficient: 1,
		acceleration: -2,
		colors: [new Vector(0.9, 0, 0, 1), new Vector(0.9, 0.9, 0, 1), new Vector(0.9, 0.9, 0, 0)],
		sizes: [0.25, 0.25, 0.25],
		times: [0, 0.75, 1]
	}
};

final trailParticleOptions:ParticleEmitterOptions = {
	ejectionPeriod: 5,
	ejectionVelocity: 0.0,
	velocityVariance: 0.25,
	emitterLifetime: 1e8,
	inheritedVelFactor: 1,
	ambientVelocity: new Vector(),
	particleOptions: {
		texture: 'particles/smoke.png',
		blending: Alpha,
		spinSpeed: 0,
		spinRandomMin: 0,
		spinRandomMax: 0,
		dragCoefficient: 1,
		lifetime: 100,
		lifetimeVariance: 10,
		acceleration: 0,
		colors: [new Vector(1, 1, 0, 0), new Vector(1, 1, 0, 1), new Vector(1, 1, 1, 0)],
		sizes: [0.7, 0.4, 0.1],
		times: [0, 0.15, 1]
	}
};

final blastParticleOptions:ParticleEmitterOptions = {
	ejectionPeriod: 1,
	ambientVelocity: new Vector(0, 0, -0.3),
	ejectionVelocity: 4,
	velocityVariance: 0,
	emitterLifetime: 300,
	inheritedVelFactor: 0,
	particleOptions: {
		texture: 'particles/smoke.png',
		blending: Alpha,
		spinSpeed: 20,
		spinRandomMin: 0,
		spinRandomMax: 0,
		lifetime: 500,
		lifetimeVariance: 100,
		dragCoefficient: 1,
		acceleration: 0,
		colors: [new Vector(0, 1, 1, 0.1), new Vector(0, 1, 1, 0.5), new Vector(0, 1, 1, 0.9)],
		sizes: [0.125, 0.125, 0.125],
		times: [0, 0.4, 1]
	}
}

final blastMaxParticleOptions:ParticleEmitterOptions = {
	ejectionPeriod: 1,
	ambientVelocity: new Vector(0, 0, -0.3),
	ejectionVelocity: 4,
	velocityVariance: 0,
	emitterLifetime: 300,
	inheritedVelFactor: 0,
	particleOptions: {
		texture: 'particles/smoke.png',
		blending: Alpha,
		spinSpeed: 20,
		spinRandomMin: 0,
		spinRandomMax: 0,
		lifetime: 500,
		lifetimeVariance: 100,
		dragCoefficient: 1,
		acceleration: 0,
		colors: [
			new Vector(1, 0.7, 0, 0.1),
			new Vector(1, 0.7, 0, 0.5),
			new Vector(1, 0.7, 0, 0.9)
		],
		sizes: [0.125, 0.125, 0.125],
		times: [0, 0.4, 1]
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

	var _bounceYet:Bool;
	var _bounceSpeed:Float;
	var _bouncePos:Vector;
	var _bounceNormal:Vector;
	var _slipAmount:Float;
	var _contactTime:Float;
	var _totalTime:Float;

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
	public var contactEntities:Array<CollisionEntity> = [];

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
	var megaHelicopter:DtsObject;
	var superBounceEnableTime:Float = -1e8;
	var shockAbsorberEnableTime:Float = -1e8;
	var helicopterEnableTime:Float = -1e8;
	var megaMarbleEnableTime:Float = -1e8;

	public var helicopterUseTick:Int = 0;
	public var megaMarbleUseTick:Int = 0;
	public var shockAbsorberUseTick:Int = 0;
	public var superBounceUseTick:Int = 0;

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
	var trailEmitterNode:ParticleEmitter;

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

		var worker = new ResourceLoaderWorker(onFinish);
		worker.addTask(fwd -> level.addDtsObject(this.forcefield, fwd));
		worker.addTask(fwd -> level.addDtsObject(this.helicopter, fwd));
		worker.addTask(fwd -> level.addDtsObject(this.megaHelicopter, fwd));
		worker.run();

		loadMarbleAttributes();
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

	function findContacts(collisiomWorld:CollisionWorld, timeState:TimeState) {
		this.contacts = queuedContacts;
		CollisionPool.clear();
		var c = collisiomWorld.sphereIntersection(this.collider, timeState);
		this.contactEntities = c.foundEntities;
		contacts = contacts.concat(c.contacts);
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
		var R = currentGravityDir.multiply(-this._radius);
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
			desiredOmega.set(crossP.x, crossP.y, crossP.z);
			aControl.set(desiredOmega.x - this.omega.x, desiredOmega.y - this.omega.y, desiredOmega.z - this.omega.z);
			var aScalar = aControl.length();
			if (aScalar > this._angularAcceleration) {
				aControl.scale(this._angularAcceleration / aScalar);
			}
			return false;
		}
		return return true;
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

				if ((!looped && surfaceDot < 0) || surfaceDot < -SurfaceDotThreshold) {
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
						if (contacts[i].velocity.length() == 0 && !surfaceSlide && surfaceDot > -this._maxDotSlide * velLen) {
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
							if (vAtCMag != 0) {
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
		if (this.velocity.lengthSq() < 625) {
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
				if (soFar < -25)
					soFar = -25;
				if (soFar > 25)
					soFar = 25;
				this.velocity.load(this.velocity.add(dir.multiply(soFar)));
			}
		}

		return stoppedPaths;
	}

	function applyContactForces(dt:Float, m:Move, isCentered:Bool, aControl:Vector, desiredOmega:Vector, A:Vector) {
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
				aFriction.load(bestContact.normal.multiply(-1).cross(vAtCDir.multiply(-1)).multiply(angAMagnitude));
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
				A.set(A.x + Aadd.x, A.y + Aadd.y, A.z + Aadd.z);
				a.set(a.x + aadd.x, a.y + aadd.y, a.z + aadd.z);
			}
			A.set(A.x + AFriction.x, A.y + AFriction.y, A.z + AFriction.z);
			a.set(a.x + aFriction.x, a.y + aFriction.y, a.z + aFriction.z);

			lastContactNormal = bestContact.normal;
			lastContactPosition = this.getAbsPos().getPosition();
		}
		a.set(a.x + aControl.x, a.y + aControl.y, a.z + aControl.z);
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

	function trailEmitter() {
		// Trails are bugged
		// var speed = this.velocity.length();
		// if (this._minTrailVel > speed) {
		// 	if (this.trailEmitterNode != null) {
		// 		this.level.particleManager.removeEmitter(this.trailEmitterNode);
		// 		this.trailEmitterNode = null;
		// 	}
		// 	return;
		// }
		// if (this.trailEmitterNode == null)
		// 	this.trailEmitterNode = this.level.particleManager.createEmitter(trailParticleOptions, trailEmitterData, null,
		// 		() -> this.getAbsPos().getPosition());
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

		var foundObjs = this.collisionWorld.boundingSearch(searchbox);

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
			if (obj.go != null && !obj.go.isCollideable)
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
			var surfaces = @:privateAccess obj.grid != null ? @:privateAccess obj.grid.boundingSearch(boundThing) : (obj.bvh == null ? obj.octree.boundingSearch(boundThing)
				.map(x -> cast x) : obj.bvh.boundingSearch(boundThing));

			for (surf in surfaces) {
				var surface:CollisionSurface = cast surf;

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
						surfaceNormal.multiply(-1);
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
			interior.computeNextPathStep(timeRemaining);
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
				&& !this.outOfBounds) {
				var pTime = timeState.clone();
				pTime.dt = timeStep;
				pTime.currentAttemptTime = passedTime;
				var netUpdate = this.isNetUpdate;
				if (this.serverUsePowerup)
					this.isNetUpdate = false;
				this.heldPowerup.use(this, pTime);
				this.isNetUpdate = netUpdate;
				this.heldPowerup = null;
				this.serverUsePowerup = false;
				if (!this.isNetUpdate) {
					this.netFlags |= MarbleNetFlags.PickupPowerup | MarbleNetFlags.UsePowerup;
				}
				if (this.level.isRecording) {
					this.level.replay.recordPowerupPickup(null);
				}
			}

			if (contacts.length != 0)
				contactTime += timeStep;

			timeRemaining -= timeStep;

			// if (this.controllable) {
			for (interior in pathedInteriors) {
				interior.advance(timeStep);
			}
			// }

			piTime += timeStep;

			if (tdiff == 0 || it > 10)
				break;
		} while (true);
		if (timeRemaining > 0) {
			// Advance pls
			// if (this.controllable) {
			for (interior in pathedInteriors) {
				interior.advance(timeRemaining);
			}
			// }
		}
		this.queuedContacts = [];

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
		var contacts = this.collisionWorld.boundingSearch(box);
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
				var endpadBB = this.collisionWorld.boundingSearch(checkSphere, false);
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
				},
				new Vector(1, 1, 1).add(new Vector(Math.abs(this.currentUp.x), Math.abs(this.currentUp.y), Math.abs(this.currentUp.z)).multiply(-0.8)));
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

		this.trailEmitter();
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
			if (Key.isDown(Settings.controlsSettings.jump)
				|| MarbleGame.instance.touchInput.jumpButton.pressed
				|| Gamepad.isDown(Settings.gamepadSettings.jump)) {
				move.jump = true;
			}
			if ((!Util.isTouchDevice() && Key.isDown(Settings.controlsSettings.powerup))
				|| (Util.isTouchDevice() && MarbleGame.instance.touchInput.powerupButton.pressed)
				|| Gamepad.isDown(Settings.gamepadSettings.powerup)) {
				move.powerup = true;
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

		this.trailEmitter();
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
			if (helicopterEnabled) {
				this.helicopter.setPosition(x, y, z);
				this.helicopter.setRotationQuat(this.level.getOrientationQuat(timeState.currentAttemptTime));
				if (selfMarble)
					this.helicopterSound.pause = false;
			} else {
				this.helicopter.setPosition(1e8, 1e8, 1e8);
				if (selfMarble)
					this.helicopterSound.pause = true;
			}
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
					},
					new Vector(1, 1, 1).add(new Vector(Math.abs(this.currentUp.x), Math.abs(this.currentUp.y), Math.abs(this.currentUp.z)).multiply(-0.8)));
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
				},
				new Vector(1, 1, 1).add(new Vector(Math.abs(this.currentUp.x), Math.abs(this.currentUp.y), Math.abs(this.currentUp.z)).multiply(-0.8)));
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

	public function enableHelicopter(timeState:TimeState) {
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
		this.helicopterUseTick = 0;
		this.megaMarbleUseTick = 0;
		this.netFlags = MarbleNetFlags.DoBlast | MarbleNetFlags.DoMega | MarbleNetFlags.DoHelicopter | MarbleNetFlags.DoShockAbsorber | MarbleNetFlags.DoSuperBounce | MarbleNetFlags.PickupPowerup | MarbleNetFlags.GravityChange | MarbleNetFlags.UsePowerup;
		this.lastContactNormal = new Vector(0, 0, 1);
		this.contactEntities = [];
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
		this.shadowVolume.remove();
		this.helicopter.remove();
		super.dispose();
		removeChildren();
		camera = null;
		collider = null;
	}
}
