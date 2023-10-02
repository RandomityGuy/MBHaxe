package src;

import rewind.RewindManager;
import shapes.PushButton;
import collision.Collision;
import src.Replay;
import hxd.impl.Air3File.FileSeek;
import gui.Canvas;
import hxd.snd.Channel;
import hxd.res.Sound;
import src.ResourceLoader;
import src.AudioManager;
import src.Settings;
import gui.LoadingGui;
import gui.PlayMissionGui;
import src.MarbleGame;
import gui.EndGameGui;
#if hlsdl
import sdl.Cursor;
#end
#if hldx
import dx.Cursor;
#end
import src.ForceObject;
import shaders.DirLight;
import h3d.col.Bounds;
import triggers.HelpTrigger;
import triggers.InBoundsTrigger;
import triggers.OutOfBoundsTrigger;
import shapes.Trapdoor;
import shapes.Oilslick;
import shapes.Tornado;
import shapes.TimeTravel;
import shapes.SuperSpeed;
import shapes.ShockAbsorber;
import shapes.LandMine;
import shapes.AntiGravity;
import shapes.SmallDuctFan;
import shapes.DuctFan;
import shapes.Helicopter;
import shapes.TriangleBumper;
import shapes.RoundBumper;
import shapes.SuperBounce;
import shapes.SignCaution;
import shapes.SuperJump;
import shapes.Gem;
import shapes.SignPlain;
import shapes.SignFinish;
import shapes.EndPad;
import shapes.StartPad;
import h3d.Matrix;
import mis.MisParser;
import src.DifBuilder;
import mis.MissionElement;
import src.GameObject;
import triggers.Trigger;
import src.Mission;
import src.TimeState;
import gui.PlayGui;
import src.ParticleSystem.ParticleManager;
import src.Util;
import h3d.Quat;
import shapes.PowerUp;
import collision.SphereCollisionEntity;
import src.Sky;
import h3d.scene.Mesh;
import src.InstanceManager;
import h3d.scene.MeshBatch;
import src.DtsObject;
import src.PathedInterior;
import hxd.Key;
import h3d.Vector;
import src.InteriorObject;
import h3d.scene.Scene;
import collision.CollisionWorld;
import src.Marble;
import src.Resource;
import src.ProfilerUI;
import src.ResourceLoaderWorker;
import src.Gamepad;
import src.ResourceLoader;
import src.Analytics;

class MarbleWorld extends Scheduler {
	public var collisionWorld:CollisionWorld;
	public var instanceManager:InstanceManager;
	public var particleManager:ParticleManager;

	var playGui:PlayGui;
	var loadingGui:LoadingGui;

	public var interiors:Array<InteriorObject> = [];
	public var pathedInteriors:Array<PathedInterior> = [];
	public var marbles:Array<Marble> = [];
	public var dtsObjects:Array<DtsObject> = [];
	public var forceObjects:Array<ForceObject> = [];
	public var triggers:Array<Trigger> = [];

	var shapeImmunity:Array<DtsObject> = [];
	var shapeOrTriggerInside:Array<GameObject> = [];

	public var timeState:TimeState = new TimeState();
	public var bonusTime:Float = 0;
	public var sky:Sky;

	var endPadElement:MissionElementStaticShape;
	var endPad:EndPad;
	var skyElement:MissionElementSky;

	public var scene:Scene;
	public var scene2d:h2d.Scene;
	public var mission:Mission;

	public var marble:Marble;
	public var worldOrientation:Quat;
	public var currentUp = new Vector(0, 0, 1);
	public var outOfBounds:Bool = false;
	public var outOfBoundsTime:TimeState;
	public var finishTime:TimeState;
	public var finishPitch:Float;
	public var finishYaw:Float;
	public var totalGems:Int = 0;
	public var gemCount:Int = 0;

	public var cursorLock:Bool = true;

	var timeTravelSound:Channel;

	var helpTextTimeState:Float = -1e8;
	var alertTextTimeState:Float = -1e8;

	// Orientation
	var orientationChangeTime = -1e8;
	var oldOrientationQuat = new Quat();

	public var newOrientationQuat = new Quat();

	// Replay
	public var replay:Replay;
	public var isWatching:Bool = false;
	public var wasRecording:Bool = false;
	public var isRecording:Bool = false;

	// Rewind
	public var rewindManager:RewindManager;
	public var rewinding:Bool = false;

	// Loading
	var resourceLoadFuncs:Array<(() -> Void)->Void> = [];

	public var _disposed:Bool = false;

	public var _ready:Bool = false;

	var _loadingLength:Int = 0;

	var _resourcesLoaded:Int = 0;

	var textureResources:Array<Resource<h3d.mat.Texture>> = [];
	var soundResources:Array<Resource<Sound>> = [];

	var oobSchedule:Float;
	var oobSchedule2:Float;

	var lock:Bool = false;

	public function new(scene:Scene, scene2d:h2d.Scene, mission:Mission, record:Bool = false) {
		this.scene = scene;
		this.scene2d = scene2d;
		this.mission = mission;
		this.replay = new Replay(mission.path);
		this.isRecording = this.wasRecording = record;
		this.rewindManager = new RewindManager(this);
	}

	public function init() {
		initLoading();
	}

	public function initLoading() {
		this.loadingGui = new LoadingGui(this.mission.title);
		MarbleGame.canvas.setContent(this.loadingGui);

		function scanMission(simGroup:MissionElementSimGroup) {
			for (element in simGroup.elements) {
				if ([
					MissionElementType.InteriorInstance,
					MissionElementType.Item,
					MissionElementType.PathedInterior,
					MissionElementType.StaticShape,
					MissionElementType.TSStatic,
					MissionElementType.Sky
				].contains(element._type)) {
					// this.loadingState.total++;

					// Override the end pad element. We do this because only the last finish pad element will actually do anything.
					if (element._type == MissionElementType.StaticShape) {
						var so:MissionElementStaticShape = cast element;
						if (so.datablock.toLowerCase() == 'endpad')
							this.endPadElement = so;
					}

					if (element._type == Sky) {
						this.skyElement = cast element;
					}
				} else if (element._type == MissionElementType.SimGroup) {
					scanMission(cast element);
				}
			}
		};
		this.mission.load();
		scanMission(this.mission.root);
		this.resourceLoadFuncs.push(fwd -> this.initScene(fwd));
		this.resourceLoadFuncs.push(fwd -> this.initMarble(fwd));
		this.resourceLoadFuncs.push(fwd -> {
			this.addSimGroup(this.mission.root);
			this._loadingLength = resourceLoadFuncs.length;
			fwd();
		});
		this._loadingLength = resourceLoadFuncs.length;
	}

	public function postInit() {
		this.scene.addChild(this.sky);
		this._ready = true;
		this.playGui.init(this.scene2d);
		var musicFileName = [
			'data/sound/groovepolice.ogg',
			'data/sound/classic vibe.ogg',
			'data/sound/beach party.ogg'
		][(mission.index + 1) % 3];
		AudioManager.playMusic(ResourceLoader.getResource(musicFileName, ResourceLoader.getAudio, this.soundResources));
		MarbleGame.canvas.clearContent();
		this.endPad.generateCollider();
		this.playGui.formatGemCounter(this.gemCount, this.totalGems);
		start();
	}

	public function initScene(onFinish:Void->Void) {
		this.collisionWorld = new CollisionWorld();
		this.playGui = new PlayGui();
		this.instanceManager = new InstanceManager(scene);
		this.particleManager = new ParticleManager(cast this);

		// var skyElement:MissionElementSky = cast this.mission.root.elements.filter((element) -> element._type == MissionElementType.Sky)[0];

		var worker = new ResourceLoaderWorker(() -> {
			var renderer = cast(this.scene.renderer, h3d.scene.fwd.Renderer);

			for (element in mission.root.elements) {
				if (element._type != MissionElementType.Sun)
					continue;

				var sunElement:MissionElementSun = cast element;

				var directionalColor = MisParser.parseVector4(sunElement.color);
				var ambientColor = MisParser.parseVector4(sunElement.ambient);
				var sunDirection = MisParser.parseVector3(sunElement.direction);
				sunDirection.x = -sunDirection.x;
				// sunDirection.z = -sunDirection.z;
				var ls = cast(scene.lightSystem, h3d.scene.fwd.LightSystem);

				ls.ambientLight.load(ambientColor);

				var shadow = scene.renderer.getPass(h3d.pass.DefaultShadowMap);
				shadow.power = 0.5;
				shadow.mode = Dynamic;
				shadow.minDist = 0.1;
				shadow.maxDist = 200;
				shadow.bias = 0;

				var sunlight = new DirLight(sunDirection, scene);
				sunlight.color = directionalColor;
			}

			onFinish();
		});
		var filestoload = [
			"particles/bubble.png",
			"particles/saturn.png",
			"particles/smoke.png",
			"particles/spark.png",
			"particles/star.png",
			"particles/twirl.png",
			"skies/sky_day.dml"
		];

		for (file in filestoload) {
			worker.loadFile(file);
		}

		this.sky = new Sky();

		sky.dmlPath = "data/skies/sky_day.dml";

		worker.addTask(fwd -> sky.init(cast this, fwd, skyElement));

		worker.run();
	}

	public function initMarble(onFinish:Void->Void) {
		var worker = new ResourceLoaderWorker(onFinish);
		var marblefiles = [
			"particles/star.png",
			"particles/smoke.png",
			"sound/rolling_hard.wav",
			"sound/sliding.wav",
			"sound/superbounceactive.wav",
			"sound/forcefield.wav",
			"sound/use_gyrocopter.wav",
			"sound/bumperding1.wav",
			"sound/bumper1.wav",
			"sound/jump.wav",
			"sound/bouncehard1.wav",
			"sound/bouncehard2.wav",
			"sound/bouncehard3.wav",
			"sound/bouncehard4.wav",
			"sound/spawn.wav",
			"sound/ready.wav",
			"sound/set.wav",
			"sound/go.wav",
			"sound/missinggems.wav",
			"shapes/images/glow_bounce.dts",
			"shapes/images/glow_bounce.png",
			"shapes/images/helicopter.dts",
			"shapes/images/helicopter.jpg",
			"shapes/pads/white.jpg", // These irk us a lot because ifl shit
			"shapes/pads/red.jpg",
			"shapes/pads/blue.jpg",
			"shapes/pads/green.jpg",
			"shapes/items/gem.dts", // Ew ew
			"shapes/items/gemshine.png",
			"shapes/balls/base.marble.png"
		];
		for (file in marblefiles) {
			worker.loadFile(file);
		}
		worker.addTask(fwd -> {
			var marble = new Marble();
			marble.controllable = true;
			this.addMarble(marble, fwd);
		});
		worker.run();
	}

	public function start() {
		restart();
		for (interior in this.interiors)
			interior.onLevelStart();
		for (shape in this.dtsObjects)
			shape.onLevelStart();
	}

	public function restart() {
		if (!this.isWatching) {
			this.replay.clear();
		} else
			this.replay.rewind();
		this.rewindManager.clear();

		this.timeState.currentAttemptTime = 0;
		this.timeState.gameplayClock = 0;
		this.bonusTime = 0;
		this.outOfBounds = false;
		this.outOfBoundsTime = null;
		this.finishTime = null;
		if (this.endPad != null)
			this.endPad.inFinish = false;
		if (this.totalGems > 0) {
			this.gemCount = 0;
			this.playGui.formatGemCounter(this.gemCount, this.totalGems);
		}

		// Record/Playback trapdoor and landmine states
		var tidx = 0;
		var lidx = 0;
		var pidx = 0;
		for (dtss in this.dtsObjects) {
			if (dtss is Trapdoor) {
				var trapdoor:Trapdoor = cast dtss;
				if (!this.isWatching) {
					this.replay.recordTrapdoorState(trapdoor.lastContactTime - this.timeState.timeSinceLoad, trapdoor.lastDirection, trapdoor.lastCompletion);
				} else {
					var state = this.replay.getTrapdoorState(tidx);
					trapdoor.lastContactTime = state.lastContactTime + this.timeState.timeSinceLoad;
					trapdoor.lastDirection = state.lastDirection;
					trapdoor.lastCompletion = state.lastCompletion;
				}
				tidx++;
			}
			if (dtss is LandMine) {
				var landmine:LandMine = cast dtss;
				if (!this.isWatching) {
					this.replay.recordLandMineState(landmine.disappearTime - this.timeState.timeSinceLoad);
				} else {
					landmine.disappearTime = this.replay.getLandMineState(lidx) + this.timeState.timeSinceLoad;
				}
				lidx++;
			}
			if (dtss is PushButton) {
				var pushbutton:PushButton = cast dtss;
				if (!this.isWatching) {
					this.replay.recordPushButtonState(pushbutton.lastContactTime - this.timeState.timeSinceLoad);
				} else {
					pushbutton.lastContactTime = this.replay.getPushButtonState(pidx) + this.timeState.timeSinceLoad;
				}
				pidx++;
			}
		}

		var startquat = this.getStartPositionAndOrientation();

		this.marble.setPosition(startquat.position.x, startquat.position.y, startquat.position.z + 3);
		var oldtransform = this.marble.collider.transform.clone();
		oldtransform.setPosition(startquat.position);
		this.marble.collider.setTransform(oldtransform);
		this.marble.reset();

		var euler = startquat.quat.toEuler();
		this.marble.camera.init(cast this);
		this.marble.camera.CameraYaw = euler.z + Math.PI / 2;
		this.marble.camera.CameraPitch = 0.45;
		this.marble.camera.nextCameraPitch = 0.45;
		this.marble.camera.nextCameraYaw = euler.z + Math.PI / 2;
		this.marble.camera.oob = false;
		this.marble.camera.finish = false;
		this.marble.mode = Start;
		this.marble.startPad = cast startquat.pad;
		sky.follow = marble.camera;

		var missionInfo:MissionElementScriptObject = cast this.mission.root.elements.filter((element) -> element._type == MissionElementType.ScriptObject
			&& element._name == "MissionInfo")[0];
		if (missionInfo.starthelptext != null)
			displayHelp(missionInfo.starthelptext); // Show the start help text

		for (shape in dtsObjects)
			shape.reset();
		for (interior in this.interiors)
			interior.reset();

		this.currentUp = new Vector(0, 0, 1);
		this.orientationChangeTime = -1e8;
		this.oldOrientationQuat = new Quat();
		this.newOrientationQuat = new Quat();
		this.deselectPowerUp();

		AudioManager.playSound(ResourceLoader.getResource('data/sound/spawn.wav', ResourceLoader.getAudio, this.soundResources));

		this.clearSchedule();
		this.schedule(0.5, () -> {
			// setCenterText('ready');
			AudioManager.playSound(ResourceLoader.getResource('data/sound/ready.wav', ResourceLoader.getAudio, this.soundResources));
			return 0;
		});
		this.schedule(2, () -> {
			// setCenterText('set');
			AudioManager.playSound(ResourceLoader.getResource('data/sound/set.wav', ResourceLoader.getAudio, this.soundResources));
			return 0;
		});
		this.schedule(3.5, () -> {
			// setCenterText('go');
			AudioManager.playSound(ResourceLoader.getResource('data/sound/go.wav', ResourceLoader.getAudio, this.soundResources));
			return 0;
		});

		return 0;
	}

	public function updateGameState() {
		if (this.outOfBounds)
			return; // We will update state manually
		if (this.timeState.currentAttemptTime < 0.5 && this.finishTime == null) {
			this.playGui.setCenterText('none');
			this.marble.mode = Start;
		}
		if ((this.timeState.currentAttemptTime >= 0.5) && (this.timeState.currentAttemptTime < 2) && this.finishTime == null) {
			this.playGui.setCenterText('ready');
			this.marble.mode = Start;
		}
		if ((this.timeState.currentAttemptTime >= 2) && (this.timeState.currentAttemptTime < 3.5) && this.finishTime == null) {
			this.playGui.setCenterText('set');
			this.marble.mode = Start;
		}
		if ((this.timeState.currentAttemptTime >= 3.5) && (this.timeState.currentAttemptTime < 5.5) && this.finishTime == null) {
			this.playGui.setCenterText('go');
			this.marble.mode = Play;
		}
		if (this.timeState.currentAttemptTime >= 5.5 && this.finishTime == null) {
			this.playGui.setCenterText('none');
			this.marble.mode = Play;
		}
	}

	function getStartPositionAndOrientation() {
		// The player is spawned at the last start pad in the mission file.
		var startPad = this.dtsObjects.filter(x -> x is StartPad).pop();
		var position:Vector;
		var quat:Quat = new Quat();
		if (startPad != null) {
			// If there's a start pad, start there
			position = startPad.getAbsPos().getPosition();
			quat = startPad.getRotationQuat().clone();
		} else {
			position = new Vector(0, 0, 300);
		}
		return {
			position: position,
			quat: quat,
			pad: startPad
		};
	}

	public function addSimGroup(simGroup:MissionElementSimGroup) {
		if (simGroup.elements.filter((element) -> element._type == MissionElementType.PathedInterior).length != 0) {
			// Create the pathed interior
			resourceLoadFuncs.push(fwd -> {
				src.PathedInterior.createFromSimGroup(simGroup, cast this, pathedInterior -> {
					this.addPathedInterior(pathedInterior, () -> {
						if (pathedInterior == null) {
							fwd();
							return;
						}

						// if (pathedInterior.hasCollision)
						// 	this.physics.addInterior(pathedInterior);
						for (trigger in pathedInterior.triggers) {
							this.triggers.push(trigger);
							this.collisionWorld.addEntity(trigger.collider);
						}
						fwd();
					});
				});
			});

			return;
		}

		for (element in simGroup.elements) {
			switch (element._type) {
				case MissionElementType.SimGroup:
					this.addSimGroup(cast element);
				case MissionElementType.InteriorInstance:
					resourceLoadFuncs.push(fwd -> this.addInteriorFromMis(cast element, fwd));
				case MissionElementType.StaticShape:
					resourceLoadFuncs.push(fwd -> this.addStaticShape(cast element, fwd));
				case MissionElementType.Item:
					resourceLoadFuncs.push(fwd -> this.addItem(cast element, fwd));
				case MissionElementType.Trigger:
					resourceLoadFuncs.push(fwd -> this.addTrigger(cast element, fwd));
				case MissionElementType.TSStatic:
					resourceLoadFuncs.push(fwd -> this.addTSStatic(cast element, fwd));
				case MissionElementType.ParticleEmitterNode:
					resourceLoadFuncs.push(fwd -> {
						this.addParticleEmitterNode(cast element);
						fwd();
					});
				default:
			}
		}
	}

	public function addInteriorFromMis(element:MissionElementInteriorInstance, onFinish:Void->Void) {
		var difPath = this.mission.getDifPath(element.interiorfile);
		if (difPath == "") {
			onFinish();
			return;
		}

		var interior = new InteriorObject();
		interior.interiorFile = difPath;
		// DifBuilder.loadDif(difPath, interior);
		// this.interiors.push(interior);
		this.addInterior(interior, () -> {
			var interiorPosition = MisParser.parseVector3(element.position);
			interiorPosition.x = -interiorPosition.x;
			var interiorRotation = MisParser.parseRotation(element.rotation);
			interiorRotation.x = -interiorRotation.x;
			interiorRotation.w = -interiorRotation.w;
			var interiorScale = MisParser.parseVector3(element.scale);
			// var hasCollision = interiorScale.x != = 0 && interiorScale.y != = 0 && interiorScale.z != = 0; // Don't want to add buggy geometry

			// Fix zero-volume interiors so they receive correct lighting
			if (interiorScale.x == 0)
				interiorScale.x = 0.0001;
			if (interiorScale.y == 0)
				interiorScale.y = 0.0001;
			if (interiorScale.z == 0)
				interiorScale.z = 0.0001;

			var mat = Matrix.S(interiorScale.x, interiorScale.y, interiorScale.z);
			var tmp = new Matrix();
			interiorRotation.toMatrix(tmp);
			mat.multiply3x4(mat, tmp);
			var tmat = Matrix.T(interiorPosition.x, interiorPosition.y, interiorPosition.z);
			mat.multiply(mat, tmat);

			interior.setTransform(mat);
			onFinish();
		});

		// interior.setTransform(interiorPosition, interiorRotation, interiorScale);

		// this.scene.add(interior.group);
		// if (hasCollision)
		// 	this.physics.addInterior(interior);
	}

	public function addStaticShape(element:MissionElementStaticShape, onFinish:Void->Void) {
		var shape:DtsObject = null;

		// Add the correct shape based on type
		var dataBlockLowerCase = element.datablock.toLowerCase();
		if (dataBlockLowerCase == "") {} // Make sure we don't do anything if there's no data block
		else if (dataBlockLowerCase == "startpad")
			shape = new StartPad();
		else if (dataBlockLowerCase == "endpad") {
			shape = new EndPad();
			if (element == endPadElement)
				endPad = cast shape;
		} else if (dataBlockLowerCase == "signfinish")
			shape = new SignFinish();
		else if (StringTools.startsWith(dataBlockLowerCase, "signplain"))
			shape = new SignPlain(element);
		else if (StringTools.startsWith(dataBlockLowerCase, "gemitem")) {
			shape = new Gem(cast element);
			this.totalGems++;
		} else if (dataBlockLowerCase == "superjumpitem")
			shape = new SuperJump(cast element);
		else if (StringTools.startsWith(dataBlockLowerCase, "signcaution"))
			shape = new SignCaution(element);
		else if (dataBlockLowerCase == "superbounceitem")
			shape = new SuperBounce(cast element);
		else if (dataBlockLowerCase == "roundbumper")
			shape = new RoundBumper();
		else if (dataBlockLowerCase == "trianglebumper")
			shape = new TriangleBumper();
		else if (dataBlockLowerCase == "helicopteritem")
			shape = new Helicopter(cast element);
		else if (dataBlockLowerCase == "ductfan")
			shape = new DuctFan();
		else if (dataBlockLowerCase == "smallductfan")
			shape = new SmallDuctFan();
		else if (dataBlockLowerCase == "antigravityitem")
			shape = new AntiGravity(cast element);
		else if (dataBlockLowerCase == "landmine")
			shape = new LandMine();
		else if (dataBlockLowerCase == "shockabsorberitem")
			shape = new ShockAbsorber(cast element);
		else if (dataBlockLowerCase == "superspeeditem")
			shape = new SuperSpeed(cast element);
		else if (dataBlockLowerCase == "timetravelitem")
			shape = new TimeTravel(cast element);
		else if (dataBlockLowerCase == "tornado")
			shape = new Tornado();
		else if (dataBlockLowerCase == "trapdoor")
			shape = new Trapdoor();
		else if (dataBlockLowerCase == "pushbutton")
			shape = new PushButton();
		else if (dataBlockLowerCase == "oilslick")
			shape = new Oilslick();
		else {
			onFinish();
			return;
		}

		var shapePosition = MisParser.parseVector3(element.position);
		shapePosition.x = -shapePosition.x;
		var shapeRotation = MisParser.parseRotation(element.rotation);
		shapeRotation.x = -shapeRotation.x;
		shapeRotation.w = -shapeRotation.w;
		var shapeScale = MisParser.parseVector3(element.scale);

		// Apparently we still do collide with zero-volume shapes
		if (shapeScale.x == 0)
			shapeScale.x = 0.0001;
		if (shapeScale.y == 0)
			shapeScale.y = 0.0001;
		if (shapeScale.z == 0)
			shapeScale.z = 0.0001;

		var mat = Matrix.S(shapeScale.x, shapeScale.y, shapeScale.z);
		var tmp = new Matrix();
		shapeRotation.toMatrix(tmp);
		mat.multiply3x4(mat, tmp);
		var tmat = Matrix.T(shapePosition.x, shapePosition.y, shapePosition.z);
		mat.multiply(mat, tmat);

		this.addDtsObject(shape, () -> {
			shape.setTransform(mat);
			onFinish();
		});

		// else if (dataBlockLowerCase == "pushbutton")
		// 	shape = new PushButton();
	}

	public function addItem(element:MissionElementItem, onFinish:Void->Void) {
		var shape:DtsObject = null;

		// Add the correct shape based on type
		var dataBlockLowerCase = element.datablock.toLowerCase();
		if (dataBlockLowerCase == "") {} // Make sure we don't do anything if there's no data block
		else if (dataBlockLowerCase == "startpad")
			shape = new StartPad();
		else if (dataBlockLowerCase == "endpad")
			shape = new EndPad();
		else if (dataBlockLowerCase == "signfinish")
			shape = new SignFinish();
		else if (StringTools.startsWith(dataBlockLowerCase, "gemitem")) {
			shape = new Gem(cast element);
			this.totalGems++;
		} else if (dataBlockLowerCase == "superjumpitem")
			shape = new SuperJump(cast element);
		else if (dataBlockLowerCase == "superbounceitem")
			shape = new SuperBounce(cast element);
		else if (dataBlockLowerCase == "roundbumper")
			shape = new RoundBumper();
		else if (dataBlockLowerCase == "trianglebumper")
			shape = new TriangleBumper();
		else if (dataBlockLowerCase == "helicopteritem")
			shape = new Helicopter(cast element);
		else if (dataBlockLowerCase == "ductfan")
			shape = new DuctFan();
		else if (dataBlockLowerCase == "smallductfan")
			shape = new SmallDuctFan();
		else if (dataBlockLowerCase == "antigravityitem")
			shape = new AntiGravity(cast element);
		else if (dataBlockLowerCase == "landmine")
			shape = new LandMine();
		else if (dataBlockLowerCase == "shockabsorberitem")
			shape = new ShockAbsorber(cast element);
		else if (dataBlockLowerCase == "superspeeditem")
			shape = new SuperSpeed(cast element);
		else if (dataBlockLowerCase == "timetravelitem")
			shape = new TimeTravel(cast element);
		else if (dataBlockLowerCase == "tornado")
			shape = new Tornado();
		else if (dataBlockLowerCase == "trapdoor")
			shape = new Trapdoor();
		else if (dataBlockLowerCase == "pushbutton")
			shape = new PushButton();
		else if (dataBlockLowerCase == "oilslick")
			shape = new Oilslick();
		else {
			onFinish();
			return;
		}

		var shapePosition = MisParser.parseVector3(element.position);
		shapePosition.x = -shapePosition.x;
		var shapeRotation = MisParser.parseRotation(element.rotation);
		shapeRotation.x = -shapeRotation.x;
		shapeRotation.w = -shapeRotation.w;
		var shapeScale = MisParser.parseVector3(element.scale);

		// Apparently we still do collide with zero-volume shapes
		if (shapeScale.x == 0)
			shapeScale.x = 0.0001;
		if (shapeScale.y == 0)
			shapeScale.y = 0.0001;
		if (shapeScale.z == 0)
			shapeScale.z = 0.0001;

		var mat = Matrix.S(shapeScale.x, shapeScale.y, shapeScale.z);
		var tmp = new Matrix();
		shapeRotation.toMatrix(tmp);
		mat.multiply3x4(mat, tmp);
		mat.setPosition(shapePosition);

		this.addDtsObject(shape, () -> {
			shape.setTransform(mat);
			onFinish();
		});
	}

	public function addTrigger(element:MissionElementTrigger, onFinish:Void->Void) {
		var trigger:Trigger = null;

		// Create a trigger based on type
		if (element.datablock == "OutOfBoundsTrigger") {
			trigger = new OutOfBoundsTrigger(element, cast this);
		} else if (element.datablock == "InBoundsTrigger") {
			trigger = new InBoundsTrigger(element, cast this);
		} else if (element.datablock == "HelpTrigger") {
			trigger = new HelpTrigger(element, cast this);
		} else {
			return;
		}
		trigger.init(() -> {
			this.triggers.push(trigger);
			this.collisionWorld.addEntity(trigger.collider);
			onFinish();
		});
	}

	public function addTSStatic(element:MissionElementTSStatic, onFinish:Void->Void) {
		// !! WARNING - UNTESTED !!
		var shapeName = element.shapename;
		var index = shapeName.indexOf('data/');
		if (index == -1)
			return;

		var dtsPath = 'data/' + shapeName.substring(index + 'data/'.length);
		if (ResourceLoader.getProperFilepath(dtsPath) == "") {
			onFinish();
			return;
		}

		var tsShape = new DtsObject();
		tsShape.useInstancing = true;
		tsShape.dtsPath = dtsPath;
		tsShape.identifier = shapeName + "tsStatic";
		tsShape.isCollideable = true;
		tsShape.showSequences = false;

		var shapePosition = MisParser.parseVector3(element.position);
		shapePosition.x = -shapePosition.x;
		var shapeRotation = MisParser.parseRotation(element.rotation);
		shapeRotation.x = -shapeRotation.x;
		shapeRotation.w = -shapeRotation.w;
		var shapeScale = MisParser.parseVector3(element.scale);

		// Apparently we still do collide with zero-volume shapes
		if (shapeScale.x == 0)
			shapeScale.x = 0.0001;
		if (shapeScale.y == 0)
			shapeScale.y = 0.0001;
		if (shapeScale.z == 0)
			shapeScale.z = 0.0001;

		var mat = Matrix.S(shapeScale.x, shapeScale.y, shapeScale.z);
		var tmp = new Matrix();
		shapeRotation.toMatrix(tmp);
		mat.multiply3x4(mat, tmp);
		mat.setPosition(shapePosition);

		this.addDtsObject(tsShape, () -> {
			tsShape.setTransform(mat);
			onFinish();
		}, true);
	}

	public function addParticleEmitterNode(element:MissionElementParticleEmitterNode) {
		// TODO THIS SHIT
	}

	public function addInterior(obj:InteriorObject, onFinish:Void->Void) {
		this.interiors.push(obj);
		obj.init(cast this, () -> {
			this.collisionWorld.addEntity(obj.collider);
			if (obj.useInstancing)
				this.instanceManager.addObject(obj);
			else
				this.scene.addChild(obj);
			onFinish();
		});
	}

	public function addPathedInterior(obj:PathedInterior, onFinish:Void->Void) {
		this.pathedInteriors.push(obj);
		obj.init(cast this, () -> {
			this.collisionWorld.addMovingEntity(obj.collider);
			if (obj.useInstancing)
				this.instanceManager.addObject(obj);
			else
				this.scene.addChild(obj);
			onFinish();
		});
	}

	public function addDtsObject(obj:DtsObject, onFinish:Void->Void, isTsStatic:Bool = false) {
		obj.idInLevel = this.dtsObjects.length; // Set the id of the thing
		this.dtsObjects.push(obj);
		if (obj is ForceObject) {
			this.forceObjects.push(cast obj);
		}
		if (isTsStatic)
			obj.useInstancing = false;
		obj.init(cast this, () -> {
			obj.update(this.timeState);
			if (obj.useInstancing) {
				this.instanceManager.addObject(obj);
			} else
				this.scene.addChild(obj);
			for (collider in obj.colliders) {
				if (collider != null)
					this.collisionWorld.addEntity(collider);
			}
			if (obj.isBoundingBoxCollideable)
				this.collisionWorld.addEntity(obj.boundingCollider);

			onFinish();
		});
	}

	public function addMarble(marble:Marble, onFinish:Void->Void) {
		this.marbles.push(marble);
		marble.level = cast this;
		if (marble.controllable) {
			marble.init(cast this, () -> {
				this.scene.addChild(marble.camera);
				this.marble = marble;
				// Ugly hack
				// sky.follow = marble;
				sky.follow = marble.camera;
				this.collisionWorld.addMovingEntity(marble.collider);
				this.scene.addChild(marble);
				onFinish();
			});
		} else {
			this.collisionWorld.addMovingEntity(marble.collider);
			this.scene.addChild(marble);
		}
	}

	public function update(dt:Float) {
		if (!_ready) {
			return;
		}

		var realDt = dt;

		if ((Key.isDown(Settings.controlsSettings.rewind)
			|| MarbleGame.instance.touchInput.rewindButton.pressed
			|| Gamepad.isDown(Settings.gamepadSettings.rewind))
			&& Settings.optionsSettings.rewindEnabled
			&& !this.isWatching
			&& this.finishTime == null) {
			this.rewinding = true;
		} else {
			if (((Key.isReleased(Settings.controlsSettings.rewind) || Gamepad.isReleased(Settings.gamepadSettings.rewind))
				|| !MarbleGame.instance.touchInput.rewindButton.pressed)
				&& this.rewinding) {
				if (this.isRecording) {
					this.replay.spliceReplay(timeState.currentAttemptTime);
				}
			}
			this.rewinding = false;
		}

		if (!this.isWatching) {
			if (this.isRecording && !this.rewinding) {
				this.replay.startFrame();
			}
		} else {
			if (!this.replay.advance(dt)) {
				if (Util.isTouchDevice()) {
					MarbleGame.instance.touchInput.hideControls(@:privateAccess this.playGui.playGuiCtrl);
				}
				this.setCursorLock(false);
				this.dispose();
				var pmg = new PlayMissionGui();
				PlayMissionGui.currentSelectionStatic = mission.index + 1;
				MarbleGame.canvas.setContent(pmg);
				#if js
				var pointercontainer = js.Browser.document.querySelector("#pointercontainer");
				pointercontainer.hidden = false;
				#end
				return;
			}
		}

		if (this.rewinding && !this.isWatching) {
			var rframe = rewindManager.getNextRewindFrame(timeState.currentAttemptTime - dt * rewindManager.timeScale);
			if (rframe != null) {
				var actualDt = timeState.currentAttemptTime - rframe.timeState.currentAttemptTime - dt * rewindManager.timeScale;
				dt = actualDt;
				rewindManager.applyFrame(rframe);
			}
		}
		if (dt < 0)
			return;

		ProfilerUI.measure("updateTimer");
		this.updateTimer(dt);

		this.tickSchedule(timeState.currentAttemptTime);

		this.updateGameState();
		ProfilerUI.measure("updateDTS");
		for (obj in dtsObjects) {
			obj.update(timeState);
		}
		ProfilerUI.measure("updateMarbles");
		for (marble in marbles) {
			marble.update(timeState, collisionWorld, this.pathedInteriors);
		}
		if (this.rewinding) {
			// Update camera separately
			marble.camera.update(timeState.currentAttemptTime, realDt);
		}
		ProfilerUI.measure("updateInstances");
		this.instanceManager.update(dt);
		ProfilerUI.measure("updateParticles");
		if (this.rewinding) {
			this.particleManager.update(1000 * timeState.timeSinceLoad, -realDt * rewindManager.timeScale);
		} else
			this.particleManager.update(1000 * timeState.timeSinceLoad, dt);
		ProfilerUI.measure("updatePlayGui");
		this.playGui.update(timeState);
		ProfilerUI.measure("updateAudio");
		AudioManager.update(this.scene);

		if (!this.isWatching) {
			if (this.isRecording && !this.rewinding) {
				this.replay.endFrame();
			}
		}

		if (!this.rewinding && Settings.optionsSettings.rewindEnabled)
			this.rewindManager.recordFrame();

		if (this.outOfBounds
			&& this.finishTime == null
			&& (Key.isDown(Settings.controlsSettings.powerup) || Gamepad.isDown(Settings.gamepadSettings.powerup))) {
			this.clearSchedule();
			this.restart();
			return;
		}

		this.updateTexts();
	}

	public function render(e:h3d.Engine) {
		if (!_ready)
			asyncLoadResources();
		if (this.playGui != null && _ready)
			this.playGui.render(e);
	}

	function asyncLoadResources() {
		if (this.resourceLoadFuncs.length != 0) {
			if (lock)
				return;

			var func = this.resourceLoadFuncs.shift();
			lock = true;
			#if hl
			func(() -> {
				lock = false;
				this._resourcesLoaded++;
				this.loadingGui.setProgress((1 - resourceLoadFuncs.length / _loadingLength));
			});
			#end
			#if js
			func(() -> {
				lock = false;
				this.loadingGui.setProgress((1 - resourceLoadFuncs.length / _loadingLength));
				this._resourcesLoaded++;
			});
			#end
		} else {
			if (this._resourcesLoaded < _loadingLength || lock)
				return;
			if (!_ready)
				postInit();
		}
	}

	public function updateTimer(dt:Float) {
		this.timeState.dt = dt;
		if (!this.isWatching) {
			if (this.bonusTime != 0 && this.timeState.currentAttemptTime >= 3.5) {
				this.bonusTime -= dt;
				if (this.bonusTime < 0) {
					this.timeState.gameplayClock -= this.bonusTime;
					this.bonusTime = 0;
				}
				if (timeTravelSound == null) {
					var ttsnd = ResourceLoader.getResource("data/sound/timetravelactive.wav", ResourceLoader.getAudio, this.soundResources);
					timeTravelSound = AudioManager.playSound(ttsnd, null, true);
				}
			} else {
				if (timeTravelSound != null) {
					timeTravelSound.stop();
					timeTravelSound = null;
				}
				if (this.timeState.currentAttemptTime >= 3.5)
					this.timeState.gameplayClock += dt;
				else if (this.timeState.currentAttemptTime + dt >= 3.5) {
					this.timeState.gameplayClock += (this.timeState.currentAttemptTime + dt) - 3.5;
				}
			}
			this.timeState.currentAttemptTime += dt;
		} else {
			this.timeState.currentAttemptTime = this.replay.currentPlaybackFrame.time;
			this.timeState.gameplayClock = this.replay.currentPlaybackFrame.clockTime;
			this.bonusTime = this.replay.currentPlaybackFrame.bonusTime;
			if (this.bonusTime != 0 && this.timeState.currentAttemptTime >= 3.5) {
				if (timeTravelSound == null) {
					var ttsnd = ResourceLoader.getResource("data/sound/timetravelactive.wav", ResourceLoader.getAudio, this.soundResources);
					timeTravelSound = AudioManager.playSound(ttsnd, null, true);
				}
			} else {
				if (timeTravelSound != null) {
					timeTravelSound.stop();
					timeTravelSound = null;
				}
			}
		}
		this.timeState.timeSinceLoad += dt;
		if (finishTime != null)
			this.timeState.gameplayClock = finishTime.gameplayClock;
		playGui.formatTimer(this.timeState.gameplayClock);

		if (!this.isWatching && this.isRecording)
			this.replay.recordTimeState(timeState.currentAttemptTime, timeState.gameplayClock, this.bonusTime);
	}

	function updateTexts() {
		var helpTextTime = this.helpTextTimeState;
		var alertTextTime = this.alertTextTimeState;
		var helpTextCompletion = Math.pow(Util.clamp((this.timeState.timeSinceLoad - helpTextTime - 3), 0, 1), 2);
		var alertTextCompletion = Math.pow(Util.clamp((this.timeState.timeSinceLoad - alertTextTime - 3), 0, 1), 2);
		this.playGui.setHelpTextOpacity(1 - helpTextCompletion);
		this.playGui.setAlertTextOpacity(1 - alertTextCompletion);
	}

	public function displayAlert(text:String) {
		this.playGui.setAlertText(text);
		this.alertTextTimeState = this.timeState.timeSinceLoad;
	}

	public function displayHelp(text:String) {
		var start = 0;
		var pos = text.indexOf("<func:", start);
		while (pos != -1) {
			var end = text.indexOf(">", start + 5);
			if (end == -1)
				break;
			var pre = text.substr(0, pos);
			var post = text.substr(end + 1);
			var func = text.substr(pos + 6, end - (pos + 6));
			var funcdata = func.split(' ').map(x -> x.toLowerCase());
			var val = "";
			if (funcdata[0] == "bind") {
				if (funcdata[1] == "moveforward")
					val = Util.getKeyForButton(Settings.controlsSettings.forward);
				if (funcdata[1] == "movebackward")
					val = Util.getKeyForButton(Settings.controlsSettings.backward);
				if (funcdata[1] == "moveleft")
					val = Util.getKeyForButton(Settings.controlsSettings.left);
				if (funcdata[1] == "moveright")
					val = Util.getKeyForButton(Settings.controlsSettings.right);
				if (funcdata[1] == "panup")
					val = Util.getKeyForButton(Settings.controlsSettings.camForward);
				if (funcdata[1] == "pandown")
					val = Util.getKeyForButton(Settings.controlsSettings.camBackward);
				if (funcdata[1] == "turnleft")
					val = Util.getKeyForButton(Settings.controlsSettings.camLeft);
				if (funcdata[1] == "turnright")
					val = Util.getKeyForButton(Settings.controlsSettings.camRight);
				if (funcdata[1] == "jump")
					val = Util.getKeyForButton(Settings.controlsSettings.jump);
				if (funcdata[1] == "mousefire")
					val = Util.getKeyForButton(Settings.controlsSettings.powerup);
				if (funcdata[1] == "freelook")
					val = Util.getKeyForButton(Settings.controlsSettings.freelook);
			}
			start = val.length + pos;
			text = pre + val + post;
			pos = text.indexOf("<func:", start);
		}
		this.playGui.setHelpText(text);
		this.helpTextTimeState = this.timeState.timeSinceLoad;
	}

	public function pickUpGem(gem:Gem) {
		this.gemCount++;
		var string:String;

		// Show a notification (and play a sound) based on the gems remaining
		if (this.gemCount == this.totalGems) {
			string = "You have all the gems, head for the finish!";
			// if (!this.rewinding)
			AudioManager.playSound(ResourceLoader.getResource('data/sound/gotallgems.wav', ResourceLoader.getAudio, this.soundResources));

			// Some levels with this package end immediately upon collection of all gems
			// if (this.mission.misFile.activatedPackages.includes('endWithTheGems')) {
			// 	let
			// 	completionOfImpact = this.physics.computeCompletionOfImpactWithBody(gem.bodies[0], 2); // Get the exact point of impact
			// 	this.touchFinish(completionOfImpact);
			// }
		} else {
			string = "You picked up a gem.  ";

			var remaining = this.totalGems - this.gemCount;
			if (remaining == 1) {
				string += "Only one gem to go!";
			} else {
				string += '${remaining} gems to go!';
			}

			// if (!this.rewinding)
			AudioManager.playSound(ResourceLoader.getResource('data/sound/gotgem.wav', ResourceLoader.getAudio, this.soundResources));
		}

		displayAlert(string);
		this.playGui.formatGemCounter(this.gemCount, this.totalGems);
	}

	public function callCollisionHandlers(marble:Marble, timeState:TimeState, start:Vector, end:Vector) {
		var expansion = marble._radius + 0.2;
		var minP = new Vector(Math.min(start.x, end.x) - expansion, Math.min(start.y, end.y) - expansion, Math.min(start.z, end.z) - expansion);
		var maxP = new Vector(Math.max(start.x, end.x) + expansion, Math.max(start.y, end.y) + expansion, Math.max(start.z, end.z) + expansion);
		var box = Bounds.fromPoints(minP.toPoint(), maxP.toPoint());

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
			if (contact.go != marble) {
				if (contact.go is DtsObject) {
					var shape:DtsObject = cast contact.go;

					if (contact.boundingBox.collide(box)) {
						shape.onMarbleInside(timeState);
						if (!this.shapeOrTriggerInside.contains(contact.go)) {
							this.shapeOrTriggerInside.push(contact.go);
							shape.onMarbleEnter(timeState);
						}
						inside.push(contact.go);
					}
				}
				if (contact.go is Trigger) {
					var trigger:Trigger = cast contact.go;
					var triggeraabb = trigger.collider.boundingBox;

					if (triggeraabb.collide(box)) {
						trigger.onMarbleInside(timeState);
						if (!this.shapeOrTriggerInside.contains(contact.go)) {
							this.shapeOrTriggerInside.push(contact.go);
							trigger.onMarbleEnter(timeState);
						}
						inside.push(contact.go);
					}
				}
			}
		}

		for (object in shapeOrTriggerInside) {
			if (!inside.contains(object)) {
				this.shapeOrTriggerInside.remove(object);
				object.onMarbleLeave(timeState);
			}
		}

		if (this.finishTime == null) {
			if (box.collide(this.endPad.finishBounds)) {
				var padUp = this.endPad.getAbsPos().up();
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
					if (collider.go == this.endPad) {
						var chull = cast(collider, collision.CollisionHull);
						var chullinvT = @:privateAccess chull.invTransform.clone();
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
					if (!endPad.inFinish) {
						touchFinish();
						endPad.inFinish = true;
					}
				} else {
					if (endPad.inFinish)
						endPad.inFinish = false;
				}
			} else {
				if (endPad.inFinish)
					endPad.inFinish = false;
			}
		}
	}

	function touchFinish() {
		if (this.finishTime != null
			|| (this.outOfBounds && this.timeState.currentAttemptTime - this.outOfBoundsTime.currentAttemptTime >= 0.5))
			return;

		if (this.gemCount < this.totalGems) {
			AudioManager.playSound(ResourceLoader.getResource('data/sound/missinggems.wav', ResourceLoader.getAudio, this.soundResources));
			displayAlert("You can't finish without all the gems!!");
		} else {
			this.endPad.spawnFirework(this.timeState);
			this.finishTime = this.timeState.clone();
			this.marble.mode = Finish;
			this.marble.camera.finish = true;
			this.finishYaw = this.marble.camera.CameraYaw;
			this.finishPitch = this.marble.camera.CameraPitch;
			displayAlert("Congratulations! You've finished!");
			Analytics.trackLevelScore(mission.title, mission.path, Std.int(finishTime.gameplayClock * 1000), Settings.optionsSettings.rewindEnabled);
			if (!this.isWatching)
				this.schedule(this.timeState.currentAttemptTime + 2, () -> cast showFinishScreen());
			// Stop the ongoing sounds
			if (timeTravelSound != null) {
				timeTravelSound.stop();
				timeTravelSound = null;
			}
		}
	}

	function showFinishScreen() {
		if (this.isWatching)
			return 0;
		var egg:EndGameGui = null;
		#if js
		var pointercontainer = js.Browser.document.querySelector("#pointercontainer");
		pointercontainer.hidden = false;
		#end
		this.schedule(this.timeState.currentAttemptTime + 3, () -> {
			this.isRecording = false; // Stop recording here
		}, "stopRecordingTimeout");
		if (Util.isTouchDevice()) {
			MarbleGame.instance.touchInput.setControlsEnabled(false);
		}
		egg = new EndGameGui((sender) -> {
			if (Util.isTouchDevice()) {
				MarbleGame.instance.touchInput.hideControls(@:privateAccess this.playGui.playGuiCtrl);
			}
			if (this.isRecording) {
				this.isRecording = false; // Stop recording here if we haven't already
				this.clearScheduleId("stopRecordingTimeout");
			}
			if (this.wasRecording) {
				this.saveReplay();
			}
			this.dispose();
			var pmg = new PlayMissionGui();
			PlayMissionGui.currentSelectionStatic = mission.index + 1;
			MarbleGame.canvas.setContent(pmg);
			#if js
			pointercontainer.hidden = false;
			#end
		}, (sender) -> {
			MarbleGame.canvas.popDialog(egg);
			if (this.isRecording) {
				this.clearScheduleId("stopRecordingTimeout");
			}
			if (this.wasRecording) {
				this.saveReplay();
				this.isRecording = true;
			}
			this.restart();
			#if js
			pointercontainer.hidden = true;
			#end
			if (Util.isTouchDevice()) {
				MarbleGame.instance.touchInput.setControlsEnabled(true);
			}
			// @:privateAccess playGui.playGuiCtrl.render(scene2d);
		}, mission, finishTime);
		MarbleGame.canvas.pushDialog(egg);
		this.setCursorLock(false);
		return 0;
	}

	public function pickUpPowerUp(powerUp:PowerUp) {
		if (this.marble.heldPowerup != null)
			if (this.marble.heldPowerup.identifier == powerUp.identifier)
				return false;
		this.marble.heldPowerup = powerUp;
		this.playGui.setPowerupImage(powerUp.identifier);
		MarbleGame.instance.touchInput.powerupButton.setEnabled(true);
		return true;
	}

	public function deselectPowerUp() {
		this.marble.heldPowerup = null;
		this.playGui.setPowerupImage("");
		MarbleGame.instance.touchInput.powerupButton.setEnabled(false);
	}

	/** Get the current interpolated orientation quaternion. */
	public function getOrientationQuat(time:Float) {
		var completion = Util.clamp((time - this.orientationChangeTime) / 0.3, 0, 1);
		var q = this.oldOrientationQuat.clone();
		q.slerp(q, this.newOrientationQuat, completion);
		return q;
	}

	public function setUp(vec:Vector, timeState:TimeState) {
		this.currentUp = vec;
		var currentQuat = this.getOrientationQuat(timeState.currentAttemptTime);
		var oldUp = new Vector(0, 0, 1);
		oldUp.transform(currentQuat.toMatrix());

		function getRotQuat(v1:Vector, v2:Vector) {
			function orthogonal(v:Vector) {
				var x = Math.abs(v.x);
				var y = Math.abs(v.y);
				var z = Math.abs(v.z);
				var other = x < y ? (x < z ? new Vector(1, 0, 0) : new Vector(0, 0, 1)) : (y < z ? new Vector(0, 1, 0) : new Vector(0, 0, 1));
				return v.cross(other);
			}

			var u = v1.normalized();
			var v = v2.normalized();
			if (u.dot(v) == -1) {
				var q = new Quat();
				var o = orthogonal(u).normalized();
				q.x = o.x;
				q.y = o.y;
				q.z = o.z;
				q.w = 0;
				return q;
			}
			var half = u.add(v).normalized();
			var q = new Quat();
			q.w = u.dot(half);
			var vr = u.cross(half);
			q.x = vr.x;
			q.y = vr.y;
			q.z = vr.z;
			return q;
		}

		var quatChange = getRotQuat(oldUp, vec);
		// Instead of calculating the new quat from nothing, calculate it from the last one to guarantee the shortest possible rotation.
		// quatChange.initMoveTo(oldUp, vec);
		quatChange.multiply(quatChange, currentQuat);

		this.newOrientationQuat = quatChange;
		this.oldOrientationQuat = currentQuat;
		this.orientationChangeTime = timeState.currentAttemptTime;
	}

	public function goOutOfBounds() {
		if (this.outOfBounds || this.finishTime != null)
			return;
		// this.updateCamera(this.timeState); // Update the camera at the point of OOB-ing
		this.outOfBounds = true;
		this.outOfBoundsTime = this.timeState.clone();
		this.marble.camera.oob = true;
		// sky.follow = null;
		// this.oobCameraPosition = camera.position.clone();
		playGui.setCenterText('outofbounds');
		AudioManager.playSound(ResourceLoader.getResource('data/sound/whoosh.wav', ResourceLoader.getAudio, this.soundResources));
		// if (this.replay.mode != = 'playback')
		this.oobSchedule = this.schedule(this.timeState.currentAttemptTime + 2, () -> {
			playGui.setCenterText('none');
			return null;
		});
		this.oobSchedule2 = this.schedule(this.timeState.currentAttemptTime + 2.5, () -> {
			this.restart();
			return null;
		});
	}

	public function setCursorLock(enabled:Bool) {
		this.cursorLock = enabled;
		if (enabled) {
			if (this.marble != null)
				this.marble.camera.lockCursor();
		} else {
			if (this.marble != null)
				this.marble.camera.unlockCursor();
		}
	}

	public function saveReplay() {
		var replayBytes = this.replay.write();
		var defaultFilename = '${this.mission.title} ${this.finishTime == null ? "Unfinished Run" : Std.string(this.finishTime.gameplayClock)}.mbr';
		#if hl
		hxd.File.saveAs(replayBytes, {
			title: 'Save Replay',
			fileTypes: [
				{
					name: "Replay (*.mbr)",
					extensions: ["mbr"]
				}
			],
			defaultPath: defaultFilename
		});
		#end
		#if js
		var blob = new js.html.Blob([replayBytes.getData()], {
			type: 'application/octet-stream'
		});
		var url = js.html.URL.createObjectURL(blob);
		var fname = defaultFilename;
		var element = js.Browser.document.createElement('a');
		element.setAttribute('href', url);
		element.setAttribute('download', fname);

		element.style.display = 'none';
		js.Browser.document.body.appendChild(element);

		element.click();

		js.Browser.document.body.removeChild(element);
		js.html.URL.revokeObjectURL(url);
		#end
	}

	public function dispose() {
		this.playGui.dispose();
		scene.removeChildren();

		for (interior in this.interiors) {
			interior.dispose();
		}
		interiors = null;
		for (pathedInteriors in this.pathedInteriors) {
			pathedInteriors.dispose();
		}
		pathedInteriors = null;
		for (marble in this.marbles) {
			marble.dispose();
		}
		marbles = null;
		for (dtsObject in this.dtsObjects) {
			dtsObject.dispose();
		}
		dtsObjects = null;
		for (trigger in this.triggers) {
			trigger.dispose();
		}
		triggers = null;
		for (soundResource in this.soundResources) {
			soundResource.release();
		}
		for (textureResource in this.textureResources) {
			textureResource.release();
		}

		sky.dispose();
		sky = null;
		instanceManager = null;
		collisionWorld.dispose();
		collisionWorld = null;
		particleManager = null;
		shapeOrTriggerInside = null;
		shapeImmunity = null;
		marble = null;

		this._disposed = true;
		AudioManager.stopAllSounds();
		AudioManager.playShell();
	}
}

typedef ScheduleInfo = {
	var id:Float;
	var stringId:String;
	var time:Float;
	var callBack:Void->Any;
}

abstract class Scheduler {
	var scheduled:Array<ScheduleInfo> = [];

	public function tickSchedule(time:Float) {
		for (item in this.scheduled) {
			if (time >= item.time) {
				this.scheduled.remove(item);
				item.callBack();
			}
		}
	}

	public function schedule(time:Float, callback:Void->Any, stringId:String = null) {
		var id = Math.random();
		this.scheduled.push({
			id: id,
			stringId: '${id}',
			time: time,
			callBack: callback
		});
		return id;
	}

	/** Cancels a schedule */
	public function cancel(id:Float) {
		var idx = this.scheduled.filter((val) -> {
			return val.id == id;
		});
		if (idx.length == 0)
			return;
		this.scheduled.remove(idx[0]);
	}

	public function clearSchedule() {
		this.scheduled = [];
	}

	public function clearScheduleId(id:String) {
		var idx = this.scheduled.filter((val) -> {
			return val.stringId == id;
		});
		if (idx.length == 0)
			return;
		this.scheduled.remove(idx[0]);
	}
}
