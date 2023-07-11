package src;

import gui.AchievementsGui;
import src.Radar;
import gui.LevelSelectGui;
import h3d.scene.fwd.Light;
import rewind.RewindManager;
import Macros.MarbleWorldMacros;
#if js
import gui.MainMenuGui;
#else
import gui.ReplayCenterGui;
#end
import gui.ReplayNameDlg;
import gui.MessageBoxOkDlg;
import collision.Collision;
import shapes.MegaMarble;
import shapes.Blast;
import shapes.Glass;
import shapes.Checkpoint;
import triggers.CheckpointTrigger;
import shapes.EasterEgg;
import shapes.Sign;
import src.Replay;
import gui.Canvas;
import hxd.snd.Channel;
import hxd.res.Sound;
import src.ResourceLoader;
import src.AudioManager;
import src.Settings;
import gui.LoadingGui;
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
import shapes.TimeTravel;
import shapes.SuperSpeed;
import shapes.AntiGravity;
import shapes.SmallDuctFan;
import shapes.DuctFan;
import shapes.Helicopter;
import shapes.RoundBumper;
import shapes.SignCaution;
import shapes.SuperJump;
import shapes.Gem;
import shapes.SignPlain;
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
import haxe.io.Path;
import src.Console;
import src.Gamepad;
import modes.GameMode;
import modes.NullMode;
import modes.GameMode.GameModeFactory;
import src.Renderer;

class MarbleWorld extends Scheduler {
	public var collisionWorld:CollisionWorld;
	public var instanceManager:InstanceManager;
	public var particleManager:ParticleManager;

	var playGui:PlayGui;
	var loadingGui:LoadingGui;
	var radar:Radar;

	public var interiors:Array<InteriorObject> = [];
	public var pathedInteriors:Array<PathedInterior> = [];
	public var marbles:Array<Marble> = [];
	public var dtsObjects:Array<DtsObject> = [];
	public var forceObjects:Array<ForceObject> = [];
	public var triggers:Array<Trigger> = [];
	public var gems:Array<Gem> = [];
	public var namedObjects:Map<String, {obj:DtsObject, elem:MissionElementBase}> = [];
	public var simGroups:Map<MissionElementSimGroup, Array<GameObject>> = [];

	var shapeImmunity:Array<DtsObject> = [];
	var shapeOrTriggerInside:Array<GameObject> = [];

	public var timeState:TimeState = new TimeState();
	public var bonusTime:Float = 0;
	public var sky:Sky;

	var endPadElement:MissionElementStaticShape;
	var endPad:EndPad;
	var skyElement:MissionElementSky;

	public var gameMode:GameMode;

	// Lighting
	public var ambient:Vector;
	public var dirLight:Vector;
	public var dirLightDir:Vector;

	public var scene:Scene;
	public var scene2d:h2d.Scene;
	public var mission:Mission;
	public var game:String;

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
	public var blastAmount:Float = 0;
	public var skipStartBug:Bool = false;

	var renderBlastAmount:Float = 0;

	public var cursorLock:Bool = true;

	var timeTravelSound:Channel;

	var helpTextTimeState:Float = -1e8;
	var alertTextTimeState:Float = -1e8;

	var respawnPressedTime:Float = -1e8;

	// Orientation
	var orientationChangeTime = -1e8;
	var oldOrientationQuat = new Quat();

	public var newOrientationQuat = new Quat();

	// Checkpoint
	var currentCheckpoint:DtsObject = null;
	var currentCheckpointTrigger:CheckpointTrigger = null;
	var checkpointCollectedGems:Map<Gem, Bool> = [];
	var checkpointHeldPowerup:PowerUp = null;
	var cheeckpointBlast:Float = 0;
	var checkpointSequence:Int = 0;

	// Replay
	public var replay:Replay;
	public var isWatching:Bool = false;
	public var isRecording:Bool = false;

	// Rewind
	public var rewindManager:RewindManager;
	public var rewinding:Bool = false;

	// Loading
	var resourceLoadFuncs:Array<(() -> Void)->Void> = [];

	public var _disposed:Bool = false;

	public var _ready:Bool = false;

	var _loadBegin:Bool = false;
	var _loaded:Bool = false;

	var _loadingLength:Int = 0;

	var _resourcesLoaded:Int = 0;

	var textureResources:Array<Resource<h3d.mat.Texture>> = [];
	var soundResources:Array<Resource<Sound>> = [];

	var oobSchedule:Float;
	var oobSchedule2:Float;

	var _cubemapNeedsUpdate:Bool = false;

	var lock:Bool = false;

	public function new(scene:Scene, scene2d:h2d.Scene, mission:Mission, record:Bool = false) {
		this.scene = scene;
		this.scene2d = scene2d;
		this.mission = mission;
		this.game = mission.game.toLowerCase();
		this.gameMode = GameModeFactory.getGameMode(this, mission.missionInfo.gamemode);
		this.replay = new Replay(mission.path, mission.isClaMission ? mission.id : 0);
		this.isRecording = record;
		this.rewindManager = new RewindManager(this);
	}

	public function init() {
		initLoading();
	}

	public function initLoading() {
		Console.log("*** LOADING MISSION: " + mission.path);
		this.loadingGui = new LoadingGui(this.mission.title, this.mission.game);
		MarbleGame.canvas.setContent(this.loadingGui);
		if (this.mission.isClaMission) {
			this.mission.download(() -> loadBegin());
		} else {
			loadBegin();
		}
	}

	function loadBegin() {
		_loadBegin = true;
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
		this.gameMode.missionScan(this.mission);
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
		// Add the sky at the last so that cubemap reflections work
		this.playGui.init(this.scene2d, this.mission.game.toLowerCase());
		this.scene.addChild(this.sky);
		this._ready = true;
		// AudioManager.playShell();
		MarbleGame.canvas.clearContent();
		if (this.endPad != null)
			this.endPad.generateCollider();
		this.playGui.formatGemCounter(this.gemCount, this.totalGems);
		Console.log("MISSION LOADED");
		start();
	}

	public function initScene(onFinish:Void->Void) {
		Console.log("Starting scene");
		this.collisionWorld = new CollisionWorld();
		this.playGui = new PlayGui();
		this.instanceManager = new InstanceManager(scene);
		this.particleManager = new ParticleManager(cast this);
		this.radar = new Radar(this, this.scene2d);
		radar.init();

		var worker = new ResourceLoaderWorker(() -> {
			var renderer = cast(this.scene.renderer, src.Renderer);

			for (element in mission.root.elements) {
				if (element._type != MissionElementType.Sun)
					continue;

				var sunElement:MissionElementSun = cast element;

				var directionalColor = MisParser.parseVector4(sunElement.color);
				var ambientColor = MisParser.parseVector4(sunElement.ambient);
				if (this.game == "ultra") {
					ambientColor.r *= 1.18;
					ambientColor.g *= 1.06;
					ambientColor.b *= 0.95;
				}
				var sunDirection = MisParser.parseVector3(sunElement.direction);
				sunDirection.x = -sunDirection.x;
				// sunDirection.x = 0;
				// sunDirection.y = 0;
				// sunDirection.z = -sunDirection.z;
				var ls = cast(scene.lightSystem, h3d.scene.fwd.LightSystem);

				ls.ambientLight.load(ambientColor);
				// ls.shadowLight.setDirection(new Vector(0, 0, -1));
				this.ambient = ambientColor;
				// ls.perPixelLighting = false;

				var shadow = scene.renderer.getPass(h3d.pass.DefaultShadowMap);
				shadow.power = 1;
				shadow.mode = Dynamic;
				shadow.minDist = 0.1;
				shadow.maxDist = 200;
				shadow.bias = 0;

				var sunlight = new DirLight(sunDirection, scene);
				sunlight.color = directionalColor;

				this.dirLight = directionalColor;
				this.dirLightDir = sunDirection;
			}

			onFinish();
		});
		var filestoload = [
			"particles/bubble.png",
			"particles/saturn.png",
			"particles/smoke.png",
			"particles/spark.png",
			"particles/star.png",
			"particles/twirl.png"
		];

		for (file in filestoload) {
			worker.loadFile(file);
		}

		this.scene.camera.zFar = Std.parseFloat(this.skyElement.visibledistance);

		this.sky = new Sky();

		sky.dmlPath = ResourceLoader.getProperFilepath(skyElement.materiallist);

		worker.addTask(fwd -> sky.init(cast this, fwd, skyElement));
		// worker.addTask(fwd -> {
		// 	scene.addChild(sky);
		// 	return fwd();
		// });

		worker.run();
	}

	public function initMarble(onFinish:Void->Void) {
		Console.log("Initializing marble");
		var worker = new ResourceLoaderWorker(onFinish);
		var marblefiles = [
			"particles/star.png",
			"particles/smoke.png",
			"particles/burst.png",
			"sound/rolling_hard.wav",
			"sound/sliding.wav",
			"sound/use_gyrocopter.wav",
			"sound/bumperding1.wav",
			"sound/jump.wav",
			"sound/mega_roll.wav",
			"sound/bouncehard1.wav",
			"sound/bouncehard2.wav",
			"sound/bouncehard3.wav",
			"sound/bouncehard4.wav",
			"sound/spawn_alternate.wav",
			"sound/missinggems.wav",
			"sound/level_text.wav",
			"sound/level_finish.wav",
			"sound/finish.wav",
			"shapes/images/helicopter.dts",
			"shapes/images/helicopter.jpg", // These irk us a lot because ifl shit
			"shapes/items/gem.dts", // Ew ew
			"shapes/items/gemshine.png",
			"shapes/items/enviro1.jpg",
			"shapes/hazards/null.png"
		];
		if (this.game == "ultra") {
			marblefiles.push("shapes/balls/marble20.normal.png");
			marblefiles.push("shapes/balls/marble18.normal.png");
			marblefiles.push("shapes/balls/marble01.normal.png");
			marblefiles.push("shapes/balls/marble02.normal.png");
			marblefiles.push("sound/use_blast.wav");
		}
		// Hacky
		marblefiles.push(StringTools.replace(Settings.optionsSettings.marbleModel, "data/", ""));
		// if (Settings.optionsSettings.marbleCategoryIndex == 0)
		// 	marblefiles.push("shapes/balls/" + Settings.optionsSettings.marbleSkin + ".marble.png");
		// else
		// 	marblefiles.push("shapes/balls/" + Settings.optionsSettings.marbleSkin + ".marble.png");
		var gameModeFiles = this.gameMode.getPreloadFiles();
		for (file in marblefiles) {
			worker.loadFile(file);
		}
		for (file in gameModeFiles) {
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
		Console.log("LEVEL START");
		restart(true);
		for (interior in this.interiors)
			interior.onLevelStart();
		for (shape in this.dtsObjects)
			shape.onLevelStart();
	}

	public function restart(full:Bool = false) {
		Console.log("LEVEL RESTART");
		if (!full && this.currentCheckpoint != null) {
			this.loadCheckpointState();
			return 0; // Load checkpoint
		}

		if (!full) {
			var respawnT = this.gameMode.getRespawnTransform();
			if (respawnT != null) {
				respawn(respawnT.position, respawnT.orientation, respawnT.up);
				return 0;
			}
		}

		if (!this.isWatching) {
			this.replay.clear();
		} else {
			this.replay.rewind();
		}

		this.rewindManager.clear();

		this.timeState.currentAttemptTime = 0;
		this.timeState.gameplayClock = this.gameMode.getStartTime();
		this.bonusTime = 0;
		this.outOfBounds = false;
		this.blastAmount = 0;
		this.renderBlastAmount = 0;
		this.outOfBoundsTime = null;
		this.finishTime = null;
		this.skipStartBug = false;

		this.currentCheckpoint = null;
		this.currentCheckpointTrigger = null;
		this.checkpointCollectedGems.clear();
		this.checkpointHeldPowerup = null;
		this.cheeckpointBlast = 0;
		this.checkpointSequence = 0;

		if (this.endPad != null)
			this.endPad.inFinish = false;
		if (this.totalGems > 0) {
			this.gemCount = 0;
			this.playGui.formatGemCounter(this.gemCount, this.totalGems);
		}

		radar.reset();

		// Record/Playback trapdoor and landmine states
		if (full) {
			var tidx = 0;
			var lidx = 0;
			var pidx = 0;
			for (dtss in this.dtsObjects) {
				if (dtss is Trapdoor) {
					var trapdoor:Trapdoor = cast dtss;
					if (!this.isWatching) {
						this.replay.recordTrapdoorState(trapdoor.lastContactTime - this.timeState.timeSinceLoad, trapdoor.lastDirection,
							trapdoor.lastCompletion);
					} else {
						var state = this.replay.getTrapdoorState(tidx);
						trapdoor.lastContactTime = state.lastContactTime + this.timeState.timeSinceLoad;
						trapdoor.lastDirection = state.lastDirection;
						trapdoor.lastCompletion = state.lastCompletion;
					}
					tidx++;
				}
			}
		}

		this.cancel(this.oobSchedule);
		this.cancel(this.oobSchedule2);

		var startquat = this.gameMode.getSpawnTransform();

		this.marble.setMarblePosition(startquat.position.x, startquat.position.y, startquat.position.z);
		this.marble.reset();

		var euler = startquat.orientation.toEuler();
		this.marble.camera.init(cast this);
		this.marble.camera.CameraYaw = euler.z + Math.PI / 2;
		this.marble.camera.CameraPitch = 0.45;
		this.marble.camera.nextCameraPitch = 0.45;
		this.marble.camera.nextCameraYaw = euler.z + Math.PI / 2;
		this.marble.camera.oob = false;
		this.marble.camera.finish = false;
		this.marble.setMode(Start);
		sky.follow = marble.camera;

		var missionInfo:MissionElementScriptObject = cast this.mission.root.elements.filter((element) -> element._type == MissionElementType.ScriptObject
			&& element._name == "MissionInfo")[0];
		if (missionInfo.starthelptext != null)
			displayHelp(missionInfo.starthelptext); // Show the start help text

		for (shape in dtsObjects)
			shape.reset();
		for (interior in this.interiors)
			interior.reset();

		this.setUp(startquat.up, this.timeState, true);
		this.deselectPowerUp();
		playGui.setCenterText('');

		AudioManager.playSound(ResourceLoader.getResource('data/sound/spawn_alternate.wav', ResourceLoader.getAudio, this.soundResources));

		this.gameMode.onRestart();

		return 0;
	}

	public function respawn(respawnPos:Vector, respawnQuat:Quat, respawnUp:Vector) {
		var marble = this.marble;
		// Determine where to spawn the marble
		this.marble.setMarblePosition(respawnPos.x, respawnPos.y, respawnPos.z);
		marble.velocity.set(0, 0, 0);
		marble.omega.set(0, 0, 0);
		Console.log('Respawn:');
		Console.log('Marble Position: ${respawnPos.x} ${respawnPos.y} ${respawnPos.z}');
		Console.log('Marble Velocity: ${marble.velocity.x} ${marble.velocity.y} ${marble.velocity.z}');
		Console.log('Marble Angular: ${marble.omega.x} ${marble.omega.y} ${marble.omega.z}');
		// Set camera orientation
		var euler = respawnQuat.toEuler();
		this.marble.camera.CameraYaw = euler.z + Math.PI / 2;
		this.marble.camera.CameraPitch = 0.45;
		this.marble.camera.nextCameraYaw = this.marble.camera.CameraYaw;
		this.marble.camera.nextCameraPitch = this.marble.camera.CameraPitch;
		this.marble.camera.oob = false;
		@:privateAccess this.marble.helicopterEnableTime = -1e8;
		@:privateAccess this.marble.megaMarbleEnableTime = -1e8;
		if (this.isRecording) {
			this.replay.recordCameraState(this.marble.camera.CameraYaw, this.marble.camera.CameraPitch);
			this.replay.recordMarbleInput(0, 0);
			this.replay.recordMarbleState(respawnPos, marble.velocity, marble.getRotationQuat(), marble.omega);
			this.replay.recordMarbleStateFlags(false, false, true, false);
		}

		// In this case, we set the gravity to the relative "up" vector of the checkpoint shape.
		var up = new Vector(0, 0, 1);
		up.transform(respawnQuat.toMatrix());
		this.setUp(up, this.timeState, true);

		this.playGui.setCenterText('');
		this.clearSchedule();
		this.outOfBounds = false;
		AudioManager.playSound(ResourceLoader.getResource('data/sound/spawn_alternate.wav', ResourceLoader.getAudio, this.soundResources));
	}

	public function updateGameState() {
		if (this.outOfBounds)
			return; // We will update state manually
		if (this.timeState.currentAttemptTime < 0.5) {
			this.marble.setMode(Start);
		}
		if ((this.timeState.currentAttemptTime >= 0.5) && (this.timeState.currentAttemptTime < 3.5)) {
			this.marble.setMode(Start);
		}
		if ((this.timeState.currentAttemptTime >= 3.5 || skipStartBug) && this.finishTime == null) {
			this.marble.setMode(Play);
		}
	}

	function addToSimgroup(obj:GameObject, simGroup:MissionElementSimGroup) {
		if (simGroup == null)
			return;
		if (!simGroups.exists(simGroup))
			simGroups[simGroup] = [obj];
		else
			simGroups[simGroup].push(obj);
	}

	public function addSimGroup(simGroup:MissionElementSimGroup) {
		if (simGroup.elements.filter((element) -> element._type == MissionElementType.PathedInterior).length != 0) {
			// Create the pathed interior
			resourceLoadFuncs.push(fwd -> {
				src.PathedInterior.createFromSimGroup(simGroup, cast this, pathedInterior -> {
					this.addPathedInterior(pathedInterior, () -> {
						if (pathedInterior == null) {
							fwd();
							Console.error("Unable to load pathed interior");
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
					resourceLoadFuncs.push(fwd -> this.addInteriorFromMis(cast element, simGroup, fwd));
				case MissionElementType.StaticShape:
					resourceLoadFuncs.push(fwd -> this.addStaticShape(cast element, simGroup, fwd));
				case MissionElementType.Item:
					resourceLoadFuncs.push(fwd -> this.addItem(cast element, simGroup, fwd));
				case MissionElementType.Trigger:
					resourceLoadFuncs.push(fwd -> this.addTrigger(cast element, simGroup, fwd));
				case MissionElementType.TSStatic:
					resourceLoadFuncs.push(fwd -> this.addTSStatic(cast element, simGroup, fwd));
				case MissionElementType.ParticleEmitterNode:
					resourceLoadFuncs.push(fwd -> {
						this.addParticleEmitterNode(cast element);
						fwd();
					});
				default:
			}
		}
	}

	public function addInteriorFromMis(element:MissionElementInteriorInstance, simGroup:MissionElementSimGroup, onFinish:Void->Void) {
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
			addToSimgroup(interior, simGroup);

			var interiorPosition = MisParser.parseVector3(element.position);
			interiorPosition.x = -interiorPosition.x;
			var interiorRotation = MisParser.parseRotation(element.rotation);
			interiorRotation.x = -interiorRotation.x;
			interiorRotation.w = -interiorRotation.w;
			var interiorScale = MisParser.parseVector3(element.scale);
			var hasCollision = interiorScale.x * interiorScale.y * interiorScale.z != 0; // Don't want to add buggy geometry

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
			interior.isCollideable = hasCollision;
			onFinish();
		});

		// interior.setTransform(interiorPosition, interiorRotation, interiorScale);

		// this.scene.add(interior.group);
		// if (hasCollision)
		// 	this.physics.addInterior(interior);
	}

	public function addStaticShape(element:MissionElementStaticShape, simGroup:MissionElementSimGroup, onFinish:Void->Void) {
		var shape:DtsObject = null;
		MarbleWorldMacros.addStaticShapeOrItem();
	}

	public function addItem(element:MissionElementItem, simGroup:MissionElementSimGroup, onFinish:Void->Void) {
		var shape:DtsObject = null;
		MarbleWorldMacros.addStaticShapeOrItem();
	}

	public function addTrigger(element:MissionElementTrigger, simGroup:MissionElementSimGroup, onFinish:Void->Void) {
		var trigger:Trigger = null;

		var datablockLowercase = element.datablock.toLowerCase();

		// Create a trigger based on type
		if (datablockLowercase == "outofboundstrigger") {
			trigger = new OutOfBoundsTrigger(element, cast this);
		} else if (datablockLowercase == "inboundstrigger") {
			trigger = new InBoundsTrigger(element, cast this);
		} else if (datablockLowercase == "helptrigger") {
			trigger = new HelpTrigger(element, cast this);
		} else if (datablockLowercase == "checkpointtrigger") {
			var chk = new CheckpointTrigger(element, cast this);
			trigger = chk;
			chk.simGroup = simGroup;
		} else {
			Console.error("Unknown trigger: " + element.datablock);
			onFinish();
			return;
		}

		trigger.init(() -> {
			this.triggers.push(trigger);
			addToSimgroup(trigger, simGroup);
			this.collisionWorld.addEntity(trigger.collider);
			onFinish();
		});
	}

	public function addTSStatic(element:MissionElementTSStatic, simGroup:MissionElementSimGroup, onFinish:Void->Void) {
		// !! WARNING - UNTESTED !!
		var shapeName = element.shapename;
		var index = shapeName.indexOf('data/');
		if (index == -1) {
			Console.error("Unable to parse shape path: " + shapeName);
			onFinish();
			return;
		}

		var dtsPath = 'data/' + shapeName.substring(index + 'data/'.length);
		if (ResourceLoader.getProperFilepath(dtsPath) == "") {
			Console.error("DTS path does not exist: " + dtsPath);
			onFinish();
			return;
		}

		var tsShape = new DtsObject();
		tsShape.useInstancing = true;
		tsShape.dtsPath = dtsPath;
		tsShape.identifier = shapeName;
		tsShape.isCollideable = true;
		tsShape.showSequences = false;

		if (element._name != null && element._name != "") {
			this.namedObjects.set(element._name, {
				obj: tsShape,
				elem: element
			});
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

		this.addDtsObject(tsShape, () -> {
			addToSimgroup(tsShape, simGroup);
			tsShape.setTransform(mat);
			onFinish();
		}, true);
	}

	public function addParticleEmitterNode(element:MissionElementParticleEmitterNode) {
		Console.warn("Unimplemented method addParticleEmitterNode");
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
		function parseIfl(path:String, onFinish:Array<String>->Void) {
			ResourceLoader.load(path).entry.load(() -> {
				var text = ResourceLoader.getFileEntry(path).entry.getText();
				var lines = text.split('\n');
				var keyframes = [];
				for (line in lines) {
					line = StringTools.trim(line);
					if (line.substr(0, 2) == "//")
						continue;
					if (line == "")
						continue;

					var parts = line.split(' ');
					var count = parts.length > 1 ? Std.parseInt(parts[1]) : 1;

					for (i in 0...count) {
						keyframes.push(parts[0]);
					}
				}

				onFinish(keyframes);
			});
		}

		ResourceLoader.load(obj.dtsPath).entry.load(() -> {
			var dtsFile = ResourceLoader.loadDts(obj.dtsPath);
			var texToLoad = obj.getPreloadMaterials(dtsFile.resource);

			var worker = new ResourceLoaderWorker(() -> {
				obj.idInLevel = this.dtsObjects.length; // Set the id of the thing
				this.dtsObjects.push(obj);
				if (obj is ForceObject) {
					this.forceObjects.push(cast obj);
				}
				obj.isTSStatic = isTsStatic;
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
			});

			for (texPath in texToLoad) {
				worker.loadFile(texPath);
			}

			worker.run();
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

	public function performRestart() {
		this.respawnPressedTime = timeState.timeSinceLoad;
		this.restart();
		if (!this.isWatching) {
			Settings.playStatistics.respawns++;

			if (!Settings.levelStatistics.exists(mission.path)) {
				Settings.levelStatistics.set(mission.path, {
					oobs: 0,
					respawns: 1,
					totalTime: 0,
				});
			} else {
				Settings.levelStatistics[mission.path].respawns++;
			}
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
			if ((Key.isReleased(Settings.controlsSettings.rewind)
				|| !MarbleGame.instance.touchInput.rewindButton.pressed
				|| Gamepad.isReleased(Settings.gamepadSettings.rewind))
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
				var misFile = haxe.io.Path.withoutExtension(haxe.io.Path.withoutDirectory(mission.path));
				this.dispose();
				MarbleGame.instance.setPreviewMission(misFile, () -> {
					#if !js
					MarbleGame.canvas.setContent(new ReplayCenterGui());
					#end
					#if js
					MarbleGame.canvas.setContent(new MainMenuGui());
					var pointercontainer = js.Browser.document.querySelector("#pointercontainer");
					pointercontainer.hidden = false;
					#end
				});

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

		// if ((Key.isPressed(Settings.controlsSettings.respawn) || Gamepad.isPressed(Settings.gamepadSettings.respawn))
		// 	&& this.finishTime == null) {
		// 	performRestart();
		// 	return;
		// }

		// if ((Key.isDown(Settings.controlsSettings.respawn)
		// 	|| MarbleGame.instance.touchInput.restartButton.pressed
		// 	|| Gamepad.isDown(Settings.gamepadSettings.respawn))
		// 	&& !this.isWatching
		// 	&& this.finishTime == null) {
		// 	if (timeState.timeSinceLoad - this.respawnPressedTime > 1.5) {
		// 		this.restart(true);
		// 		this.respawnPressedTime = Math.POSITIVE_INFINITY;
		// 		return;
		// 	}
		// }

		this.tickSchedule(timeState.currentAttemptTime);

		if (Key.isDown(Settings.controlsSettings.blast)
			|| (MarbleGame.instance.touchInput.blastbutton.pressed)
			|| Gamepad.isDown(Settings.gamepadSettings.blast)
			&& !this.isWatching
			&& this.game == "ultra") {
			if (this.marble.useBlast()) {
				if (this.isRecording) {
					this.replay.recordMarbleStateFlags(false, false, false, true);
				}
			}
		}

		if (this.isWatching && this.replay.currentPlaybackFrame.marbleStateFlags.has(UsedBlast))
			this.marble.useBlast();

		// Replay gravity
		if (this.isWatching) {
			if (this.replay.currentPlaybackFrame.gravityChange) {
				this.setUp(this.replay.currentPlaybackFrame.gravity, timeState, this.replay.currentPlaybackFrame.gravityInstant);
			}
			if (this.replay.currentPlaybackFrame.powerupPickup != null) {
				this.pickUpPowerUpReplay(this.replay.currentPlaybackFrame.powerupPickup);
			}
		}

		radar.update(dt);
		this.updateGameState();
		this.updateBlast(timeState);
		ProfilerUI.measure("updateDTS");
		for (obj in dtsObjects) {
			obj.update(timeState);
		}
		for (obj in triggers) {
			obj.update(timeState);
		}
		ProfilerUI.measure("updateMarbles");
		for (marble in marbles) {
			marble.update(timeState, collisionWorld, this.pathedInteriors);
		}
		_cubemapNeedsUpdate = true;
		Renderer.dirtyBuffers = true;
		if (this.rewinding) {
			// Update camera separately
			marble.camera.update(timeState.currentAttemptTime, realDt);
		}
		ProfilerUI.measure("updateInstances");
		this.instanceManager.render();
		ProfilerUI.measure("updateParticles");
		if (this.rewinding) {
			this.particleManager.update(1000 * timeState.timeSinceLoad, -realDt * rewindManager.timeScale);
		} else
			this.particleManager.update(1000 * timeState.timeSinceLoad, dt);
		ProfilerUI.measure("updatePlayGui");
		this.playGui.update(timeState);
		ProfilerUI.measure("updateAudio");
		AudioManager.update(this.scene);

		if (this.outOfBounds
			&& this.finishTime == null
			&& (Key.isDown(Settings.controlsSettings.powerup) || Gamepad.isDown(Settings.gamepadSettings.powerup))
			&& !this.isWatching) {
			this.restart();
			return;
		}

		if (!this.isWatching) {
			if (this.isRecording && !this.rewinding) {
				this.replay.endFrame();
			}
		}

		if (!this.rewinding && Settings.optionsSettings.rewindEnabled)
			this.rewindManager.recordFrame();

		this.updateTexts();
	}

	public function render(e:h3d.Engine) {
		if (!_ready)
			asyncLoadResources();
		if (this.playGui != null && _ready)
			this.playGui.render(e);
		if (this.marble != null && this.marble.cubemapRenderer != null && _ready) {
			ProfilerUI.measure("renderCubemap");
			if (_cubemapNeedsUpdate) {
				this.marble.cubemapRenderer.position.load(this.marble.getAbsPos().getPosition());
				this.marble.cubemapRenderer.render(e);
				_cubemapNeedsUpdate = false;
			}
		}
	}

	var postInited = false;

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
			});
			#end
			#if js
			func(() -> {
				lock = false;
				this._resourcesLoaded++;
			});
			#end
		} else {
			if (!this._loadBegin || lock)
				return;
			if (!_ready && !postInited) {
				postInited = true;
				Console.log("Finished loading, starting mission");
				haxe.Timer.delay(() -> postInit(), 15); // delay this a bit
			}
		}
	}

	public function updateTimer(dt:Float) {
		this.timeState.dt = dt;

		var prevGameplayClock = this.timeState.gameplayClock;

		var timeMultiplier = this.gameMode.timeMultiplier();

		if (!this.isWatching) {
			if (this.bonusTime != 0 && (this.timeState.currentAttemptTime >= 3.5 || skipStartBug)) {
				this.bonusTime -= dt;
				if (this.bonusTime < 0) {
					this.timeState.gameplayClock -= this.bonusTime * timeMultiplier;
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
				if ((this.timeState.currentAttemptTime >= 3.5 || skipStartBug)) {
					this.timeState.gameplayClock += dt * timeMultiplier;
				} else if (this.timeState.currentAttemptTime + dt >= 3.5) {
					this.timeState.gameplayClock += ((this.timeState.currentAttemptTime + dt) - 3.5) * timeMultiplier;
				}
				if (this.timeState.gameplayClock < 0)
					this.gameMode.onTimeExpire();
			}
			this.timeState.currentAttemptTime += dt;
		} else {
			this.timeState.currentAttemptTime = this.replay.currentPlaybackFrame.time;
			this.timeState.gameplayClock = this.replay.currentPlaybackFrame.clockTime;
			this.bonusTime = this.replay.currentPlaybackFrame.bonusTime;
			if (this.bonusTime != 0 && (this.timeState.currentAttemptTime >= 3.5 || skipStartBug)) {
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

	function updateBlast(timestate:TimeState) {
		if (this.game == "ultra") {
			if (this.blastAmount < 1) {
				this.blastAmount = Util.clamp(this.blastAmount + (timeState.dt / 30), 0, 1);
				this.renderBlastAmount = this.blastAmount;
			} else {
				this.renderBlastAmount = Math.min(this.blastAmount, timestate.dt * 0.75 + this.renderBlastAmount);
			}
			this.playGui.setBlastValue(this.renderBlastAmount);
		}
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
				if (funcdata[1] == "useblast")
					val = Util.getKeyForButton(Settings.controlsSettings.blast);
			}
			start = val.length + pos;
			text = pre + val + post;
			pos = text.indexOf("<func:", start);
		}
		this.playGui.setHelpText(text);
		this.helpTextTimeState = this.timeState.timeSinceLoad;
	}

	public function pickUpGem(gem:Gem) {
		this.gameMode.onGemPickup(gem);
	}

	public function callCollisionHandlers(marble:Marble, timeState:TimeState, start:Vector, end:Vector, startQuat:Quat, endQuat:Quat) {
		var expansion = marble._radius + 0.2;
		var minP = new Vector(Math.min(start.x, end.x) - expansion, Math.min(start.y, end.y) - expansion, Math.min(start.z, end.z) - expansion);
		var maxP = new Vector(Math.max(start.x, end.x) + expansion, Math.max(start.y, end.y) + expansion, Math.max(start.z, end.z) + expansion);
		var box = Bounds.fromPoints(minP.toPoint(), maxP.toPoint());

		var marbleHitbox = new Bounds();
		marbleHitbox.addSpherePos(0, 0, 0, marble._radius);
		marbleHitbox.transform(startQuat.toMatrix());
		marbleHitbox.transform(endQuat.toMatrix());
		marbleHitbox.offset(end.x, end.y, end.z);

		// spherebounds.addSpherePos(gjkCapsule.p2.x, gjkCapsule.p2.y, gjkCapsule.p2.z, gjkCapsule.radius);
		// var contacts = this.collisionWorld.radiusSearch(marble.getAbsPos().getPosition(), marble._radius);
		var contacts = marble.contactEntities;
		var inside = [];

		for (contact in contacts) {
			if (contact.go != marble) {
				if (contact.go is DtsObject) {
					var shape:DtsObject = cast contact.go;

					if (contact.boundingBox.collide(marbleHitbox)) {
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

					if (triggeraabb.collide(marbleHitbox)) {
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

		if (this.finishTime == null && this.endPad != null) {
			if (marbleHitbox.collide(this.endPad.finishBounds)) {
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
						var chull = cast(collider, collision.CollisionEntity);
						var chullinvT = @:privateAccess chull.invTransform.clone();
						chullinvT.clone();
						chullinvT.transpose();
						for (surface in chull.surfaces) {
							var i = 0;
							while (i < surface.indices.length) {
								var surfaceN = surface.normals[surface.indices[i]].transformed3x3(chullinvT);
								var v1 = surface.points[surface.indices[i]].transformed(chull.transform);
								var surfaceD = -surfaceN.dot(v1);

								if (surfaceN.dot(padUp.multiply(-10)) < 0) {
									var dist = surfaceN.dot(checkBoundsCenter.toVector()) + surfaceD;
									if (dist >= 0 && dist < 5) {
										var intersectT = -(checkBoundsCenter.dot(surfaceN.toPoint()) + surfaceD) / (padUp.dot(surfaceN));
										var intersectP = checkBoundsCenter.add(padUp.multiply(intersectT).toPoint()).toVector();
										if (Collision.PointInTriangle(intersectP, v1, surface.points[surface.indices[i + 1]].transformed(chull.transform),
											surface.points[surface.indices[i + 2]].transformed(chull.transform))) {
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
			displayAlert("You can't finish without all the gems!");
		} else {
			AudioManager.playSound(ResourceLoader.getResource('data/sound/finish.wav', ResourceLoader.getAudio, this.soundResources));
			this.finishTime = this.timeState.clone();
			this.marble.setMode(Finish);
			this.marble.camera.finish = true;
			this.finishYaw = this.marble.camera.CameraYaw;
			this.finishPitch = this.marble.camera.CameraPitch;
			displayAlert("Congratulations! You've finished!");
			if (!this.isWatching) {
				var notifies = AchievementsGui.check();
				var delay = 5.0;
				var achDelay = 0.0;
				for (i in 0...9) {
					if (notifies & (1 << i) > 0)
						achDelay += 3;
				}
				if (notifies > 0)
					achDelay += 0.5;
				this.schedule(this.timeState.currentAttemptTime + Math.max(delay, achDelay), () -> cast showFinishScreen());
			}
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
		playGui.setGuiVisibility(false);
		Console.log("State End");
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
			var endGameCode = () -> {
				this.dispose();
				LevelSelectGui.currentSelectionStatic = mission.index + 1;
				var pmg = new LevelSelectGui(["beginner", "intermediate", "advanced", "multiplayer"][mission.difficultyIndex]);
				MarbleGame.canvas.setContent(pmg);
				#if js
				pointercontainer.hidden = false;
				#end
			}
			if (MarbleGame.instance.toRecord) {
				MarbleGame.canvas.pushDialog(new ReplayNameDlg(endGameCode));
			} else {
				endGameCode();
			}
		}, (sender) -> {
			var restartGameCode = () -> {
				MarbleGame.canvas.popDialog(egg);
				playGui.setGuiVisibility(true);
				this.restart(true);
				#if js
				pointercontainer.hidden = true;
				#end
				if (Util.isTouchDevice()) {
					MarbleGame.instance.touchInput.setControlsEnabled(true);
				}
				// @:privateAccess playGui.playGuiCtrl.render(scene2d);
			}
			if (MarbleGame.instance.toRecord) {
				MarbleGame.canvas.pushDialog(new ReplayNameDlg(() -> {
					this.isRecording = true;
					restartGameCode();
				}));
			} else {
				restartGameCode();
			}
		}, (sender) -> {
			var nextLevelCode = () -> {
				var nextMission = mission.getNextMission();
				if (nextMission != null) {
					MarbleGame.instance.playMission(nextMission);
				}
			}
			if (MarbleGame.instance.toRecord) {
				MarbleGame.canvas.pushDialog(new ReplayNameDlg(nextLevelCode));
			} else {
				nextLevelCode();
			}
		}, mission, this.gameMode.getFinishScore(), this.gameMode.getScoreType());
		MarbleGame.canvas.pushDialog(egg);
		this.setCursorLock(false);
		return 0;
	}

	public function pickUpPowerUpReplay(powerupIdent:String) {
		if (powerupIdent == null)
			return false;
		if (this.marble.heldPowerup != null)
			if (this.marble.heldPowerup.identifier == powerupIdent)
				return false;

		this.playGui.setPowerupImage(powerupIdent);

		return true;
	}

	public function pickUpPowerUp(powerUp:PowerUp) {
		if (powerUp == null)
			return false;
		if (this.marble.heldPowerup != null)
			if (this.marble.heldPowerup.identifier == powerUp.identifier)
				return false;
		Console.log("PowerUp pickup: " + powerUp.identifier);
		this.marble.heldPowerup = powerUp;
		this.playGui.setPowerupImage(powerUp.identifier);
		MarbleGame.instance.touchInput.powerupButton.setEnabled(true);
		if (this.isRecording) {
			this.replay.recordPowerupPickup(powerUp);
		}
		return true;
	}

	public function deselectPowerUp() {
		this.marble.heldPowerup = null;
		this.playGui.setPowerupImage("");
		MarbleGame.instance.touchInput.powerupButton.setEnabled(false);
	}

	public function addBonusTime(t:Float) {
		this.bonusTime += t;
	}

	/** Get the current interpolated orientation quaternion. */
	public function getOrientationQuat(time:Float) {
		var completion = Util.clamp((time - this.orientationChangeTime) / 0.8, 0, 1);
		var newDt = completion / 0.4 * 2.302585124969482;
		var smooth = 1.0 / (newDt * (newDt * 0.235 * newDt) + newDt + 1.0 + 0.48 * newDt * newDt);
		var q = this.oldOrientationQuat.clone();
		q.slerp(q, this.newOrientationQuat, 1 - smooth);
		return q;
	}

	public function setUp(vec:Vector, timeState:TimeState, instant:Bool = false) {
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

		if (this.isRecording) {
			this.replay.recordGravity(vec, instant);
		}

		this.newOrientationQuat = quatChange;
		this.oldOrientationQuat = currentQuat;
		this.orientationChangeTime = instant ? -1e8 : timeState.currentAttemptTime;
	}

	public function goOutOfBounds() {
		if (this.outOfBounds || this.finishTime != null)
			return;
		// this.updateCamera(this.timeState); // Update the camera at the point of OOB-ing
		this.outOfBounds = true;
		this.outOfBoundsTime = this.timeState.clone();
		this.marble.camera.oob = true;
		if (!this.isWatching) {
			Settings.playStatistics.oobs++;
			if (!Settings.levelStatistics.exists(mission.path)) {
				Settings.levelStatistics.set(mission.path, {
					oobs: 1,
					respawns: 0,
					totalTime: 0,
				});
			} else {
				Settings.levelStatistics[mission.path].oobs++;
			}
		}
		// sky.follow = null;
		// this.oobCameraPosition = camera.position.clone();
		playGui.setCenterText('Out of Bounds');
		// if (this.replay.mode != = 'playback')
		this.oobSchedule = this.schedule(this.timeState.currentAttemptTime + 2, () -> {
			playGui.setCenterText('');
			return null;
		});
		this.oobSchedule2 = this.schedule(this.timeState.currentAttemptTime + 2.5, () -> {
			this.restart();
			return null;
		});
	}

	/** Sets a new active checkpoint. */
	public function saveCheckpointState(shape:DtsObject, trigger:CheckpointTrigger = null) {
		if (this.currentCheckpoint != null)
			if (this.currentCheckpoint == shape)
				return false;
		var disableOob = false;
		if (trigger != null) {
			disableOob = trigger.disableOOB;
			if (checkpointSequence > trigger.seqNum)
				return false;
		}
		checkpointSequence = trigger.seqNum;
		// (shape.srcElement as any) ?.disableOob || trigger?.element.disableOob;
		if (disableOob && this.outOfBounds)
			return false; // The checkpoint is configured to not work when the player is already OOB
		this.currentCheckpoint = shape;
		this.currentCheckpointTrigger = trigger;
		this.checkpointCollectedGems.clear();
		this.cheeckpointBlast = this.blastAmount;
		// Remember all gems that were collected up to this point
		for (gem in this.gems) {
			if (gem.pickedUp)
				this.checkpointCollectedGems.set(gem, true);
		}
		this.checkpointHeldPowerup = this.marble.heldPowerup;
		AudioManager.playSound(ResourceLoader.getResource('data/sound/checkpoint.wav', ResourceLoader.getAudio, this.soundResources));
		return true;
	}

	/** Resets to the last stored checkpoint state. */
	public function loadCheckpointState() {
		var marble = this.marble;
		// Determine where to spawn the marble
		var offset = new Vector(0, 0, 0.727843);
		offset.transform(this.currentCheckpoint.getRotationQuat().toMatrix());
		var mpos = this.currentCheckpoint.getAbsPos().getPosition().add(offset);
		this.marble.setMarblePosition(mpos.x, mpos.y, mpos.z);
		marble.velocity.load(new Vector(0, 0, 0));
		marble.omega.load(new Vector(0, 0, 0));
		Console.log('Respawn:');
		Console.log('Marble Position: ${mpos.x} ${mpos.y} ${mpos.z}');
		Console.log('Marble Velocity: ${marble.velocity.x} ${marble.velocity.y} ${marble.velocity.z}');
		Console.log('Marble Angular: ${marble.omega.x} ${marble.omega.y} ${marble.omega.z}');
		// Set camera orientation
		var euler = this.currentCheckpoint.getRotationQuat().toEuler();
		this.marble.camera.CameraYaw = euler.z + Math.PI / 2;
		this.marble.camera.CameraPitch = 0.45;
		this.marble.camera.nextCameraYaw = this.marble.camera.CameraYaw;
		this.marble.camera.nextCameraPitch = this.marble.camera.CameraPitch;
		this.marble.camera.oob = false;
		@:privateAccess this.marble.helicopterEnableTime = -1e8;
		@:privateAccess this.marble.megaMarbleEnableTime = -1e8;
		this.blastAmount = this.cheeckpointBlast;
		if (this.isRecording) {
			this.replay.recordCameraState(this.marble.camera.CameraYaw, this.marble.camera.CameraPitch);
			this.replay.recordMarbleInput(0, 0);
			this.replay.recordMarbleState(mpos, marble.velocity, marble.getRotationQuat(), marble.omega);
			this.replay.recordMarbleStateFlags(false, false, true, false);
		}
		var gravityField = ""; // (this.currentCheckpoint.srcElement as any) ?.gravity || this.currentCheckpointTrigger?.element.gravity;
		if (this.currentCheckpointTrigger != null) {
			if (@:privateAccess this.currentCheckpointTrigger.element.fields.exists('gravity')) {
				gravityField = @:privateAccess this.currentCheckpointTrigger.element.fields.get('gravity')[0];
			}
		}

		// In this case, we set the gravity to the relative "up" vector of the checkpoint shape.
		var up = new Vector(0, 0, 1);
		up.transform(this.currentCheckpoint.getRotationQuat().toMatrix());
		this.setUp(up, this.timeState, true);

		// Restore gem states
		for (gem in this.gems) {
			if (gem.pickedUp && !this.checkpointCollectedGems.exists(gem)) {
				gem.reset();
				this.gemCount--;
			}
		}
		this.playGui.formatGemCounter(this.gemCount, this.totalGems);
		this.playGui.setCenterText('');
		this.clearSchedule();
		this.outOfBounds = false;
		this.deselectPowerUp(); // Always deselect first
		// Wait a bit to select the powerup to prevent immediately using it incase the user skipped the OOB screen by clicking
		if (this.checkpointHeldPowerup != null)
			this.schedule(this.timeState.currentAttemptTime + 0.5, () -> this.pickUpPowerUp(this.checkpointHeldPowerup));
		AudioManager.playSound(ResourceLoader.getResource('data/sound/spawn_alternate.wav', ResourceLoader.getAudio, this.soundResources));
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
		this.replay.name = MarbleGame.instance.recordingName;
		#if hl
		sys.FileSystem.createDirectory(haxe.io.Path.join([Settings.settingsDir, "data", "replays"]));
		var replayPath = haxe.io.Path.join([Settings.settingsDir, "data", "replays", '${this.replay.name}.mbr']);
		if (sys.FileSystem.exists(replayPath)) {
			var count = 1;
			var found = false;
			while (!found) {
				replayPath = haxe.io.Path.join([Settings.settingsDir, "data", "replays", '${this.replay.name} (${count}).mbr']);
				if (!sys.FileSystem.exists(replayPath)) {
					this.replay.name += ' (${count})';
					found = true;
				} else {
					count++;
				}
			}
		}
		var replayBytes = this.replay.write();
		sys.io.File.saveBytes(replayPath, replayBytes);
		#end
		#if js
		var replayBytes = this.replay.write();
		var blob = new js.html.Blob([replayBytes.getData()], {
			type: 'application/octet-stream'
		});
		var url = js.html.URL.createObjectURL(blob);
		var fname = '${this.replay.name}.mbr';
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
		// Gotta add the timesinceload to our stats
		if (!this.isWatching) {
			Settings.playStatistics.totalTime += this.timeState.timeSinceLoad;

			if (!Settings.levelStatistics.exists(mission.path)) {
				Settings.levelStatistics.set(mission.path, {
					oobs: 0,
					respawns: 0,
					totalTime: this.timeState.timeSinceLoad,
				});
			} else {
				Settings.levelStatistics[mission.path].totalTime += this.timeState.timeSinceLoad;
			}
		}

		radar.dispose();

		if (this.playGui != null)
			this.playGui.dispose();
		scene.removeChildren();

		for (interior in this.interiors) {
			interior.dispose();
		}
		for (pathedInteriors in this.pathedInteriors) {
			pathedInteriors.dispose();
		}
		for (marble in this.marbles) {
			marble.dispose();
		}
		for (dtsObject in this.dtsObjects) {
			dtsObject.dispose();
		}
		for (trigger in this.triggers) {
			trigger.dispose();
		}
		for (soundResource in this.soundResources) {
			soundResource.release();
		}
		for (textureResource in this.textureResources) {
			textureResource.release();
		}

		if (sky != null)
			sky.dispose();

		this._disposed = true;
		AudioManager.stopAllSounds();
		// AudioManager.playShell();
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
