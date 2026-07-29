package src;

import net.NetPacket.ExplodableUpdatePacket;
import net.TrapdoorPredictionStore;
import shapes.Explodable;
import net.ExplodablePredictionStore;
import gui.MPPreGameDlg;
import src.Radar;
import rewind.InputRecorder;
import net.NetPacket.ScoreboardPacket;
import net.NetPacket.PowerupPickupPacket;
import net.Move;
import net.NetPacket.GemSpawnPacket;
import net.BitStream.OutputBitStream;
import net.MasterServerClient;
import gui.MarbleSelectGui;
import gui.MPPlayMissionGui;
import collision.CollisionPool;
import net.GemPredictionStore;
import modes.HuntMode;
import net.NetPacket.MarbleNetFlags;
import net.PowerupPredictionStore;
import net.MarblePredictionStore;
import net.MarblePredictionStore.MarblePrediction;
import net.MarbleUpdateQueue;
import haxe.Exception;
import net.NetPacket.MarbleUpdatePacket;
import net.NetPacket.MarbleMovePacket;
import net.MoveManager;
import net.NetCommands;
import net.Net;
import net.ClientConnection;
import net.ClientConnection.GameConnection;
import modes.GameMode;
import modes.GameMode.GameModeFactory;
import rewind.RewindManager;
import shapes.PushButton;
#if js
import gui.MainMenuGui;
#else
import gui.ReplayCenterGui;
#end
import gui.ReplayNameDlg;
import collision.Collision;
import shapes.MegaMarble;
import shapes.Blast;
import shapes.Glass;
import gui.OOBInsultGui;
import shapes.Checkpoint;
import triggers.CheckpointTrigger;
import shapes.EasterEgg;
import shapes.Sign;
import triggers.TeleportTrigger;
import triggers.DestinationTrigger;
import shapes.Nuke;
import shapes.Magnet;
import src.Replay;
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
import shapes.RandomPowerup;
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
import collision.CollisionEntity;
import src.Marble;
import src.Resource;
import src.ProfilerUI;
import src.ResourceLoaderWorker;
import haxe.io.Path;
import src.Console;
import src.Gamepad;
import src.Analytics;
import src.IPathMover;
import src.PathNodeElement;
import src.DatablockRegistry;
import src.GameObjectPathFollower;
import src.GameObjectParentFollower;
import triggers.PathTrigger;

class MarbleWorld extends Scheduler {
	public var collisionWorld:CollisionWorld;
	public var instanceManager:InstanceManager;
	public var particleManager:ParticleManager;

	public var playGui:PlayGui;

	var loadingGui:LoadingGui;
	var radar:Radar;

	public var interiors:Array<InteriorObject> = [];
	public var pathedInteriors:Array<PathedInterior> = [];
	public var marbles:Array<Marble> = [];
	public var dtsObjects:Array<DtsObject> = [];
	public var powerUps:Array<PowerUp> = [];
	public var forceObjects:Array<ForceObject> = [];
	public var explodables:Array<Explodable> = [];
	public var explodablesToTick:Array<Int> = [];
	public var trapdoors:Array<Trapdoor> = [];
	public var trapdoorsToTick:Array<Int> = [];
	public var triggers:Array<Trigger> = [];
	public var gems:Array<Gem> = [];

	/** All placed `IceShard1`/`IceShard2` instances - mirrors `gems` (used for rewind snapshotting
		of `IceShard.destroyed`, see `RewindFrame.iceShardStates`). */
	public var iceShards:Array<shapes.IceShard> = [];

	public var cannons:Array<shapes.Cannon> = [];

	public var namedObjects:Map<String, {obj:DtsObject, elem:MissionElementBase}> = [];

	/** General named-object lookup (any `GameObject` - DTS/interior/trigger) used for `path`/
		`parent` resolution, since those can target any placed object, not just DTS items like
		`namedObjects` above. Kept separate from `namedObjects` so existing DtsObject-only lookups
		(checkpoint respawn points, DisableShapeForceTrigger) aren't affected. */
	public var namedGameObjects:Map<String, GameObject> = [];

	/** `PathNode`/`BezierHandle` placements - pure data markers, never `GameObject`s. See
		`resolvePathNodeTransform`. */
	public var pathNodes:Map<String, PathNodeElement> = [];

	/** `PathedInterior`s plus every path-following `GameObject`, advanced once per frame
		(`computeNextPathStep`) and once per physics substep (`advancePath`), in that order,
		before `parentedObjects` are advanced. */
	public var movingObjects:Array<IPathMover> = [];

	/** Objects with a `parent` field, advanced after `movingObjects` every substep. Insertion
		order guarantees parent-before-child ordering - see `registerParentedObject`. */
	public var parentedObjects:Array<GameObject> = [];

	public function registerMovingObject(o:IPathMover) {
		if (this.movingObjects.indexOf(o) < 0)
			this.movingObjects.push(o);
	}

	public function registerParentedObject(o:GameObject) {
		var parentTarget = o.parentFollower != null ? o.parentFollower.parentObject : null;
		if (parentTarget != null && parentTarget.parentFollower != null && this.parentedObjects.indexOf(parentTarget) < 0)
			this.registerParentedObject(parentTarget);
		if (this.parentedObjects.indexOf(o) < 0)
			this.parentedObjects.push(o);
	}

	/** Resolves a `PathNode`/`BezierHandle`'s live world position/rotation. Most nodes are static
		(no `parent` field) so this just returns the authored local transform, but a node can
		itself be parented to a moving object, so this is resolved on demand every call rather than
		cached - a pure function of the parent's *current* transform, same reasoning as
		`GameObjectParentFollower`. */
	public function resolvePathNodeTransform(name:String):PathNodeLiveTransform {
		var node = this.pathNodes.get(name);
		if (node == null)
			return null;
		if (node.parentName == null || node.parentName == "")
			return {position: node.localPosition, rotation: node.localRotation};
		var parent = this.namedGameObjects.get(node.parentName);
		if (parent == null)
			return {position: node.localPosition, rotation: node.localRotation};
		return GameObjectParentFollower.applyOffset(parent.getAbsPos(), node.localPosition, node.localRotation);
	}

	public var timeState:TimeState = new TimeState();
	public var bonusTime:Float = 0;
	public var collectedBonusTime:Float = 0;
	public var sky:Sky;

	public var endPadElement:MissionElementStaticShape;
	public var endPad:EndPad;

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
	public var finishTime:TimeState;
	public var finishPitch:Float;
	public var finishYaw:Float;
	public var totalGems:Int = 0;
	public var gemCount:Int = 0;

	/** How many gems `NullMode.canFinish` requires before allowing the finish - `-1` means "use
		`totalGems`" (the base rule); `QuotaMode`'s constructor sets this to `MissionInfo.gemquota`
		instead (always >= 0). Living on `level` rather than as a `GameMode` interface method so any
		mode that just wants "the current gem requirement, whatever it is" (e.g. `HasteMode`, which
		inherits `NullMode.canFinish` and ANDs a speed check on top) automatically respects Quota
		without either mode needing to know about the other. */
	public var gemsRequiredToFinish:Int = -1;

	/** Highest `LapsCheckpoint.checkpointNumber` seen so far this mission - ported from PQ's
		`$Laps::LastCheckpointNumber` (`modes/laps.cs`), used to auto-number checkpoints that don't
		specify one and to know which checkpoint is "the last one" (arms `LapsCounterTrigger`). */
	public var lapsLastCheckpointNumber:Int = 0;

	/** Ported from PQ's `$Game::TimeStoppedClients`/`GameConnection.timeStopTriggers`
		(`server/scripts/triggers.cs`'s `TimeStopTrigger`) - a count rather than a plain toggle so
		overlapping `TimeStopTrigger` volumes don't unlock each other early, mirroring
		`Marble.powerupLockCount`'s same pattern. `Time::stop()`/`Time::start()` in PQ only gate
		`$Time::TimerRunning` (the scoring clock), not the whole simulation - `currentAttemptTime`
		(PQ's `$Time::TotalTime`) keeps advancing regardless. */
	public var timeStopTriggerCount:Int = 0;

	public var cursorLock:Bool = true;

	var timeTravelSound:Channel;
	var alarmSound:Channel;

	var countdownRemaining:Float = -1e8;
	var countdownActive:Bool = false;
	var countdownIcon:String = "timerTimeTravel";

	var respawnPressedTime:Float = -1e8;

	var timeMultiplier:Float = 1;

	// Orientation
	var orientationChangeTime = -1e8;
	var oldOrientationQuat = new Quat();

	public var newOrientationQuat = new Quat();

	// Checkpoint
	var currentCheckpoint:{obj:DtsObject, elem:MissionElementBase} = null;
	var currentCheckpointTrigger:CheckpointTrigger = null;
	var checkpointCollectedGems:Map<Gem, Bool> = [];
	var checkpointHeldPowerup:PowerUp = null;
	var checkpointUp:Vector = null;
	var cheeckpointBlast:Float = 0;

	// Replay
	public var replay:Replay;
	public var isWatching:Bool = false;
	public var isRecording:Bool = false;

	// Rewind
	public var rewindManager:RewindManager;
	public var rewinding:Bool = false;
	public var rewindUsed:Bool = false;

	public var cheatsUsed:Bool = false;

	public var inputRecorder:InputRecorder;
	public var isReplayingMovement:Bool = false;
	public var currentInputMoves:Array<InputRecorderFrame>;

	// Multiplayer
	public var isMultiplayer:Bool = false;

	public var serverStartTicks:Int = 0;
	public var startTime:Float = 1e8;
	public var multiplayerStarted:Bool = false;

	var tickAccumulator:Float = 0.0;
	var maxPredictionTicks:Int = 16;

	var clientMarbles:Map<GameConnection, Marble> = [];
	var predictions:MarblePredictionStore;
	var powerupPredictions:PowerupPredictionStore;
	var gemPredictions:GemPredictionStore;
	var explodablePredictions:ExplodablePredictionStore;
	var trapdoorPredictions:TrapdoorPredictionStore;

	public var lastMoves:MarbleUpdateQueue;

	// Loading
	var resourceLoadFuncs:Array<(() -> Void)->Void> = [];

	public var _disposed:Bool = false;

	public var _ready:Bool = false;

	var _skipPreGame:Bool = false;

	var _loadBegin:Bool = false;
	var _loaded:Bool = false;

	var _loadingLength:Int = 0;

	var _resourcesLoaded:Int = 0;

	var textureResources:Array<Resource<h3d.mat.Texture>> = [];
	var soundResources:Array<Resource<Sound>> = [];

	var oobSchedule:Float;

	var _instancesNeedsUpdate:Bool = false;
	var lock:Bool = false;

	public function new(scene:Scene, scene2d:h2d.Scene, mission:Mission, record:Bool = false, multiplayer:Bool = false) {
		this.scene = scene;
		this.scene2d = scene2d;
		this.mission = mission;
		this.game = mission.game.toLowerCase();
		this.replay = new Replay(mission.path, mission.isClaMission ? mission.id : 0);
		this.isRecording = record;
		this.rewindManager = new RewindManager(cast this);
		this.inputRecorder = new InputRecorder(cast this);
		this.isMultiplayer = multiplayer;
		if (this.isMultiplayer) {
			isRecording = false;
			isWatching = false;
			lastMoves = new MarbleUpdateQueue();
			predictions = new MarblePredictionStore();
			powerupPredictions = new PowerupPredictionStore();
			gemPredictions = new GemPredictionStore();
			explodablePredictions = new ExplodablePredictionStore(cast this);
			trapdoorPredictions = new TrapdoorPredictionStore(cast this);
		}
	}

	public function init() {
		initLoading();
	}

	public function initLoading() {
		Console.log("*** LOADING MISSION: " + mission.path);
		this.loadingGui = new LoadingGui(this.mission.title, this.mission.game, this.isMultiplayer);
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
						if (["endpad", "endpad_mbg", "endpad_mbp", "endpad_pq"].contains(so.datablock.toLowerCase()))
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

		// Ported from `TDTrigger::onAdd` ("TDTrigger needs 2d mode but it's not listed in
		// MissionInfo. Activating it ourselves") - a `TDTrigger` can appear in a mission that never
		// declares "2d" as one of its game modes, so pre-scan for one and force the mode word in
		// *before* the mode tree gets built, rather than trying to patch the tree after the fact.
		function missionHasTDTrigger(simGroup:MissionElementSimGroup):Bool {
			for (element in simGroup.elements) {
				if (element._type == MissionElementType.Trigger) {
					var t:MissionElementTrigger = cast element;
					if (t.datablock != null && t.datablock.toLowerCase() == "tdtrigger")
						return true;
				} else if (element._type == MissionElementType.SimGroup) {
					if (missionHasTDTrigger(cast element))
						return true;
				}
			}
			return false;
		}
		var gameModeStr = mission.gameMode;
		if (missionHasTDTrigger(this.mission.root)) {
			var words = gameModeStr == null ? [] : ~/\s+/g.split(StringTools.trim(gameModeStr)).filter(w -> w != "");
			if (words.filter(w -> w.toLowerCase() == "2d").length == 0)
				gameModeStr = (gameModeStr == null || gameModeStr == "" ? "" : gameModeStr + " ") + "2D";
		}
		this.gameMode = GameModeFactory.getGameMode(cast this, gameModeStr);
		scanMission(this.mission.root);
		this.gameMode.missionScan(this.mission);
		this.resourceLoadFuncs.push(fwd -> this.initScene(fwd));
		if (this.isMultiplayer) {
			for (client in Net.clientIdMap) {
				this.resourceLoadFuncs.push(fwd -> this.initMarble(client, fwd)); // Others
			}
		}
		this.resourceLoadFuncs.push(fwd -> this.initMarble(null, fwd));
		this.resourceLoadFuncs.push(fwd -> {
			this.addSimGroup(this.mission.root);
			this._loadingLength = resourceLoadFuncs.length;
			fwd();
		});
		this.resourceLoadFuncs.push(fwd -> this.loadMusic(fwd));
		this._loadingLength = resourceLoadFuncs.length;
		this.timeMultiplier = this.gameMode.timeMultiplier();
	}

	public function loadMusic(onFinish:Void->Void) {
		if (this.mission.missionInfo.music != null) {
			var musicFileName = 'sound/music/' + this.mission.missionInfo.music;
			if (ResourceLoader.exists(musicFileName))
				ResourceLoader.load(musicFileName).entry.load(onFinish);
			else
				onFinish();
		} else {
			onFinish();
		}
	}

	public function postInit() {
		// Add the sky at the last so that cubemap reflections work
		this.playGui.init(this.scene2d, this.mission.game.toLowerCase(), () -> {
			this.scene.addChild(this.sky);

			if (this.isMultiplayer) {
				// Add us
				if (Net.isHost) {
					this.playGui.addPlayer(0, Settings.highscoreName.substr(0, 15), true);
				} else {
					this.playGui.addPlayer(Net.clientId, Settings.highscoreName.substr(0, 15), true);
				}
				for (client in Net.clientIdMap) {
					this.playGui.addPlayer(client.id, client.name.substr(0, 15), false);
				}
			}

			this._ready = true;
			var musicFileName = 'data/sound/music/' + this.mission.missionInfo.music;
			if (ResourceLoader.exists(musicFileName))
				AudioManager.playMusic(ResourceLoader.getResource(musicFileName, ResourceLoader.getAudio, this.soundResources), this.mission.missionInfo.music);
			else
				AudioManager.playShell();
			MarbleGame.canvas.clearContent();
			if (this.endPad != null)
				this.endPad.generateCollider();
			if (this.isMultiplayer || this.gameMode.getScoreType() == Score) {
				this.playGui.formatGemHuntCounter(0);
				if (this.isMultiplayer)
					this.playGui.formatCountdownTimer(0, 0);
			} else {
				this.playGui.formatGemCounter(this.gemCount, this.gemCounterTotal());
			}
			Console.log("MISSION LOADED");
			start();
		});
	}

	public function initScene(onFinish:Void->Void) {
		Console.log("Starting scene");
		this.collisionWorld = new CollisionWorld();
		this.playGui = new PlayGui();
		this.instanceManager = new InstanceManager(scene);
		this.particleManager = new ParticleManager(cast this);
		if (this.isMultiplayer || this.game == "ultra" || this.mission.missionInfo.game == "PlatinumQuest") {
			this.radar = new Radar(cast this, this.scene2d);
			if (this.mission.missionInfo.radardistance != null && this.mission.missionInfo.radardistance != "")
				this.radar.itemSearchDistance = MisParser.parseNumber(this.mission.missionInfo.radardistance);
			if (this.mission.missionInfo.radargemdistance != null && this.mission.missionInfo.radargemdistance != "")
				this.radar.gemFinishSearchDistance = MisParser.parseNumber(this.mission.missionInfo.radargemdistance);
			if (this.mission.missionInfo.customradarrule != null && this.mission.missionInfo.customradarrule != "")
				this.radar.customRadarRule = Std.parseInt(this.mission.missionInfo.customradarrule);
			radar.init();
		}

		var worker = new ResourceLoaderWorker(() -> {
			var renderer = cast(this.scene.renderer, src.Renderer);

			var iter = mission.root.elements.copy();

			while (iter.length > 0) {
				var element = iter[0];
				iter.splice(0, 1);
				if (element._type == MissionElementType.SimGroup) {
					iter = iter.concat(cast(element, MissionElementSimGroup).elements);
				}
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
				this.ambient = ambientColor;
				// ls.perPixelLighting = false;

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
			"particles/twirl.png",
			"particles/glint.png",
			"particles/glint2.png",
			"particles/orb.png",
			"particles/smoke_blur32.png",
			"particles/drop1.png",
			"particles/fireball_1.png",
			"particles/fireball_1b.png",
			"particles/fireball_2.png",
			"particles/fireball_2b.png",
			"particles/fireball_3.png",
			"particles/fireball_4.png",
			"particles/icechunk.png",
			"particles/snowflake.png",
			"particles/splash1.png",
			"particles/splash2.png",
			"particles/splash3.png",
			"particles/zzz.png",
		];

		for (file in filestoload) {
			worker.loadFile(file);
		}

		this.scene.camera.zFar = Math.max(4000, Std.parseFloat(this.skyElement.visibledistance));

		this.sky = new Sky();

		sky.dmlPath = ResourceLoader.getProperFilepath(skyElement.materiallist);

		worker.addTask(fwd -> sky.init(cast this, fwd, skyElement));
		// worker.addTask(fwd -> {
		// 	scene.addChild(sky);
		// 	return fwd();
		// });

		worker.run();
	}

	public function initMarble(client:GameConnection, onFinish:Void->Void) {
		Console.log("Initializing marble");
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
			"sound/mega_roll.wav",
			"sound/bouncehard1.wav",
			"sound/bouncehard2.wav",
			"sound/bouncehard3.wav",
			"sound/bouncehard4.wav",
			"sound/ready.wav",
			"sound/set.wav",
			"sound/go.wav",
			"sound/alarm.wav",
			"sound/alarm_timeout.wav",
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
			"shapes/items/enviro1.jpg",
			"sound/bubble.wav",
		];
		for (key in AudioManager.pitchKeys) {
			marblefiles.push('sound/spawn/$key.wav');
			marblefiles.push('sound/missinggems/$key.wav');
		}
		if (this.game == "ultra" || Net.isMP) {
			marblefiles.push("shapes/balls/pack1/marble20.normal.png");
			marblefiles.push("shapes/balls/pack1/marble18.normal.png");
			marblefiles.push("shapes/balls/pack1/marble01.normal.png");
			marblefiles.push("sound/blast.wav");
		}
		// Hacky
		if (client == null) {
			marblefiles.push(StringTools.replace(Settings.optionsSettings.marbleModel, "data/", ""));

			if (Settings.optionsSettings.marbleCategoryIndex == 0)
				marblefiles.push("shapes/balls/" + Settings.optionsSettings.marbleSkin + ".marble.png");
			else
				marblefiles.push("shapes/balls/pack1/" + Settings.optionsSettings.marbleSkin + ".marble.png");
		} else {
			var marbleDts = MarbleSelectGui.marbleData[client.getMarbleCatId()][client.getMarbleId()].dts; // FIXME
			marblefiles.push(StringTools.replace(marbleDts, "data/", ""));

			var marbleSkin = MarbleSelectGui.marbleData[client.getMarbleCatId()][client.getMarbleId()].skin;

			if (client.getMarbleCatId() == 0)
				marblefiles.push("shapes/balls/" + marbleSkin + ".marble.png");
			else
				marblefiles.push("shapes/balls/pack1/" + marbleSkin + ".marble.png");
		}

		var gameModeFiles = this.gameMode.getPreloadFiles();
		for (file in marblefiles) {
			worker.loadFile(file);
		}
		for (file in gameModeFiles) {
			worker.loadFile(file);
		}
		worker.addTask(fwd -> {
			var marble = new Marble();
			if (client == null)
				marble.controllable = true;
			this.addMarble(marble, client, fwd);
		});
		worker.run();
	}

	public function start() {
		Console.log("LEVEL START");
		restart(this.marble, true);

		this.collisionWorld.build();

		for (interior in this.interiors)
			interior.onLevelStart();
		for (shape in this.dtsObjects)
			shape.onLevelStart();
		if (this.isMultiplayer && Net.isClient && !_skipPreGame)
			NetCommands.clientIsReady(Net.clientId);
		if (this.isMultiplayer && Net.isHost) {
			//  NetCommands.clientIsReady(-1);

			// Sort all the marbles so that they are updated in a deterministic order
			this.marbles.sort((a, b) -> @:privateAccess {
				var aId = a.connection != null ? a.connection.id : 0; // Must be a host
				var bId = b.connection != null ? b.connection.id : 0; // Must be a host
				return (aId > bId) ? 1 : (aId < bId) ? -1 : 0;
			});
		}
		// var cc = 0;
		// for (client in Net.clients)
		// 	cc++;
		// if (Net.isHost && cc == 0) {
		// 	allClientsReady();
		// 	Net.serverInfo.state = "PLAYING";
		// 	MasterServerClient.instance.sendServerInfo(Net.serverInfo); // notify the server of the playing state
		// }
		if (this.isMultiplayer) {
			// Push the pre - game
			if (!_skipPreGame) {
				showPreGame();
			} else {
				_skipPreGame = false;
				this.setCursorLock(true);
				NetCommands.requestMidGameJoinState(Net.clientId);
				NetCommands.clientIsReady(Net.clientId);
			}
		}
		this.prescanPathTriggerTargets();
		this.gameMode.onMissionLoad();
	}

	/** Ported from the user's own diagnosis of a rewind bug: an object only gets a `GameObjectPath
		Follower`/a slot in `level.movingObjects` the *first time* something actually calls
		`moveOnPath` on it (a `PathTrigger` firing, or `IceShard`'s `gotoTarget` reuse of the same
		field convention) - meaning `level.movingObjects` grows mid-game, which desyncs
		`RewindFrame.pathFollowerStates`' positional alignment against it (a frame recorded before
		the object was ever triggered doesn't have a slot for it at all). Fixed by pre-registering
		every such object into `level.movingObjects` here, once, before any gameplay tick or rewind
		frame is ever recorded - each starts with `pathFollower == null` (i.e. present in the array,
		but inactive) until something actually calls `moveOnPath` on it later, exactly mirroring how
		a stable list of `null`-or-real slots already works for `gemStates`/`iceShardStates`. */
	function prescanPathTriggerTargets() {
		for (trigger in this.triggers) {
			if (trigger is PathTrigger) {
				var targets = PathTrigger.collectObjectTargets(@:privateAccess trigger.element.fields, cast this);
				for (target in targets)
					this.registerMovingObject(target);
			}
		}
		for (dts in this.dtsObjects) {
			if (dts is shapes.IceShard) {
				var iceShard:shapes.IceShard = cast dts;
				var fields = @:privateAccess iceShard.element.fields;
				var gotoTargetField = fields.get("gototarget");
				if (gotoTargetField != null && MisParser.parseBoolean(gotoTargetField[0])) {
					var targets = PathTrigger.collectObjectTargets(fields, cast this);
					for (target in targets)
						this.registerMovingObject(target);
				}
			}
		}
	}

	public function showPreGame() {
		MarbleGame.canvas.pushDialog(new MPPreGameDlg());
		this.setCursorLock(false);
		if (Util.isTouchDevice()) {
			MarbleGame.instance.touchInput.setControlsEnabled(false);
		}
		this.marble.camera.startOverview();

		// Hide all gems
		for (gem in this.gems) {
			gem.setHide(true);
			gem.pickedUp = true;
			gem.setHide(true);
			this.collisionWorld.removeEntity(gem.boundingCollider); // remove from octree to make it easy
		}
	}

	public function addJoiningClient(cc:GameConnection, onAdded:() -> Void) {
		this.initMarble(cc, () -> {
			var addedMarble = clientMarbles.get(cc);
			this.restart(addedMarble); // spawn it
			this.playGui.addPlayer(cc.id, cc.getName(), false);
			this.playGui.redrawPlayerList();

			// Sort all the marbles so that they are updated in a deterministic order
			this.marbles.sort((a, b) -> @:privateAccess {
				var aId = a.getConnectionId();
				var bId = b.getConnectionId();
				return (aId > bId) ? 1 : (aId < bId) ? -1 : 0;
			});
			onAdded();
		});
	}

	public function addJoiningClientGhost(cc:GameConnection, onAdded:() -> Void) {
		this.initMarble(cc, () -> {
			var addedMarble = clientMarbles.get(cc);
			this.restart(addedMarble); // spawn it
			this.playGui.addPlayer(cc.id, cc.getName(), false);
			this.playGui.redrawPlayerList();

			// Sort all the marbles so that they are updated in a deterministic order
			this.marbles.sort((a, b) -> @:privateAccess {
				var aId = a.getConnectionId();
				var bId = b.getConnectionId();
				return (aId > bId) ? 1 : (aId < bId) ? -1 : 0;
			});
			onAdded();
		});
	}

	public function restartMultiplayerState() {
		if (this.isMultiplayer) {
			serverStartTicks = 0;
			startTime = 1e8;
			lastMoves = new MarbleUpdateQueue();
			predictions = new MarblePredictionStore();
			powerupPredictions.reset();
			gemPredictions.reset();
			explodablePredictions.reset();
		}
	}

	/** Ported from `getCheckpointPos`'s `%defaultPitch` (`server/scripts/checkpoint.cs`) -
		`MissionInfo.cameraPitch` overrides the initial camera pitch every spawn/respawn applies,
		falling back to the same `0.45` every spawn/respawn already hardcoded. */
	public function getDefaultCameraPitch():Float {
		var field = this.mission.missionInfo.camerapitch;
		return field != null && field != "" ? MisParser.parseNumber(field) : 0.45;
	}

	/** Ported from `GameConnection::respawnPlayer`'s `MissionInfo.initialCameraDistance $= "" ?
		$Physics::Defaults::CameraDistance : MissionInfo.initialCameraDistance` (`server/scripts/
		game.cs`) - applied on every spawn/respawn, not just `TwoDMode`'s own use of the same field. */
	public function getDefaultCameraDistance():Float {
		var field = this.mission.missionInfo.initialcameradistance;
		return field != null && field != "" ? MisParser.parseNumber(field) : 2.5;
	}

	public function restart(marble:Marble, full:Bool = false) {
		Console.log("LEVEL RESTART");
		if (!full && this.currentCheckpoint != null) {
			this.loadCheckpointState();
			return 0; // Load checkpoint
		}

		if (!full) {
			var respawnT = this.gameMode.getRespawnTransform(marble);
			if (respawnT != null) {
				respawn(marble, respawnT.position, respawnT.orientation, respawnT.up);
				return 0;
			}
		}

		if (!this.isWatching) {
			this.replay.clear();
		} else
			this.replay.rewind();

		this.rewindManager.clear();
		this.rewindUsed = false;

		if (!this.isMultiplayer || _skipPreGame) {
			setCursorLock(true);
		}

		this.timeState.currentAttemptTime = 0;
		this.timeState.gameplayClock = this.gameMode.getStartTime();
		this.timeState.ticks = 0;
		this.bonusTime = 0;
		this.collectedBonusTime = 0;
		this.marble.outOfBounds = false;
		this.marble.blastAmount = 0;
		this.marble.outOfBoundsTime = null;
		this.finishTime = null;
		if (this.alarmSound != null) {
			this.alarmSound.stop();
			this.alarmSound = null;
		}

		this.currentCheckpoint = null;
		this.currentCheckpointTrigger = null;
		this.checkpointCollectedGems.clear();
		this.checkpointHeldPowerup = null;
		this.checkpointUp = null;
		this.cheeckpointBlast = 0;

		if (this.endPad != null)
			this.endPad.inFinish = false;
		if (this.totalGems > 0) {
			this.gemCount = 0;
			this.playGui.formatGemCounter(this.gemCount, this.gemCounterTotal());
		}

		if (radar != null)
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
		}
		this.cancel(this.oobSchedule);
		this.cancel(this.marble.oobSchedule);

		var startquat = this.gameMode.getSpawnTransform();

		this.marble.setMarblePosition(startquat.position.x, startquat.position.y, startquat.position.z);
		this.marble.reset();

		var euler = startquat.orientation.toEuler();
		this.marble.camera.init(cast this);
		this.marble.camera.CameraYaw = euler.z + Math.PI / 2;
		this.marble.camera.CameraPitch = this.getDefaultCameraPitch();
		this.marble.camera.nextCameraPitch = this.marble.camera.CameraPitch;
		this.marble.camera.nextCameraYaw = euler.z + Math.PI / 2;
		this.marble.camera.CameraDistance = this.getDefaultCameraDistance();
		this.marble.camera.oob = false;
		this.marble.camera.finish = false;
		this.marble.mode = Start;
		sky.follow = marble.camera;

		if (isMultiplayer) {
			for (client => marble in clientMarbles) {
				this.cancel(marble.oobSchedule);
				var marbleStartQuat = this.gameMode.getSpawnTransform();
				marble.setMarblePosition(marbleStartQuat.position.x, marbleStartQuat.position.y, marbleStartQuat.position.z);
				marble.reset();
				marble.setMode(Start);
			}
			this.playGui.resetPlayerScores();
		}

		var missionInfo:MissionElementScriptObject = cast this.mission.root.elements.filter((element) -> element._type == MissionElementType.ScriptObject
			&& element._name == "MissionInfo")[0];
		if (missionInfo.starthelptext != null)
			displayHelp(missionInfo.starthelptext, 5); // Show the start help text

		for (shape in dtsObjects) {
			shape.reset();
		}
		for (interior in this.interiors) {
			interior.reset();
		}
		// Triggers previously had no reset pass at all on a full restart - `PathTrigger.triggered`
		// (and any other trigger with its own restart-relevant state, e.g. `CountdownStartTrigger.
		// activated`) would stay stuck from before the restart. Also resets any trigger-activated
		// path follower (a `Trigger` can itself be a `GameObject` path target, same as a DtsObject).
		for (trigger in this.triggers) {
			trigger.reset();
		}

		this.setUp(this.marble, startquat.up, this.timeState, true);
		this.deselectPowerUp(this.marble);

		if (!this.isMultiplayer)
			AudioManager.playPitchedSound("spawn", this.soundResources);

		Console.log("State Start");
		this.clearSchedule();

		if (!this.isMultiplayer)
			this.gameMode.onRestart();
		if (Net.isClient) {
			this.gameMode.onClientRestart();
		}

		return 0;
	}

	public function respawn(marble:Marble, respawnPos:Vector, respawnQuat:Quat, respawnUp:Vector) {
		// Determine where to spawn the marble
		marble.setMarblePosition(respawnPos.x, respawnPos.y, respawnPos.z);
		marble.velocity.set(0, 0, 0);
		marble.omega.set(0, 0, 0);
		Console.log('Respawn:');
		Console.log('Marble Position: ${respawnPos.x} ${respawnPos.y} ${respawnPos.z}');
		Console.log('Marble Velocity: ${marble.velocity.x} ${marble.velocity.y} ${marble.velocity.z}');
		Console.log('Marble Angular: ${marble.omega.x} ${marble.omega.y} ${marble.omega.z}');
		// Set camera orientation
		var euler = respawnQuat.toEuler();
		marble.camera.CameraYaw = euler.z + Math.PI / 2;
		marble.camera.CameraPitch = this.getDefaultCameraPitch();
		marble.camera.nextCameraYaw = marble.camera.CameraYaw;
		marble.camera.nextCameraPitch = marble.camera.CameraPitch;
		marble.camera.CameraDistance = this.getDefaultCameraDistance();
		marble.camera.oob = false;
		if (isMultiplayer) {
			marble.megaMarbleUseTick = 0;
			marble.helicopterUseTick = 0;
			marble.shockAbsorberUseTick = 0;
			marble.superBounceUseTick = 0;
			marble.collider.radius = marble._radius = 0.2;
			@:privateAccess marble.netFlags |= MarbleNetFlags.DoHelicopter | MarbleNetFlags.DoMega | MarbleNetFlags.DoShockAbsorber | MarbleNetFlags.DoSuperBounce | MarbleNetFlags.GravityChange;
		} else {
			@:privateAccess marble.helicopterEnableTime = -1e8;
			@:privateAccess marble.megaMarbleEnableTime = -1e8;
			@:privateAccess marble.shockAbsorberEnableTime = -1e8;
			@:privateAccess marble.superBounceEnableTime = -1e8;
		}
		if (this.isRecording) {
			this.replay.recordCameraState(marble.camera.CameraYaw, marble.camera.CameraPitch);
			this.replay.recordMarbleInput(0, 0);
			this.replay.recordMarbleState(respawnPos, marble.velocity, marble.getRotationQuat(), marble.omega);
			this.replay.recordMarbleStateFlags(false, false, true, false);
		}

		this.setUp(marble, respawnUp, this.timeState, true);

		var store = marble.heldPowerup;
		marble.heldPowerup = null;
		haxe.Timer.delay(() -> {
			if (marble.heldPowerup == null)
				marble.heldPowerup = store;
		}, 500); // This bs

		if (marble == this.marble)
			this.playGui.setCenterText('none');
		if (!this.isMultiplayer)
			this.clearSchedule();
		marble.outOfBounds = false;
		this.gameMode.onRespawn(marble);
		if (marble == this.marble && @:privateAccess !marble.isNetUpdate)
			AudioManager.playPitchedSound("spawn", this.soundResources);
	}

	public function allClientsReady() {
		NetCommands.setStartTicks(this.timeState.ticks);
		this.gameMode.onRestart();
	}

	public function updateGameState() {
		if (this.marble.outOfBounds)
			return; // We will update state manually
		if (!this.isMultiplayer) {
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
		} else {
			if (!this.multiplayerStarted && this.finishTime == null) {
				if ((Net.isHost && (this.timeState.timeSinceLoad < startTime - 3.0)) // 3.5 == 109 ticks
					|| (Net.isClient && this.serverStartTicks != 0 && @:privateAccess this.marble.serverTicks < this.serverStartTicks + 16)) {
					this.playGui.setCenterText('none');
					this.playGui.doStateChangeSound('none');
				}
				if ((Net.isHost
					&& (this.timeState.timeSinceLoad > startTime - 3.0)
					&& (this.timeState.timeSinceLoad < startTime - 1.5)) // 3.5 == 109 ticks
					|| (Net.isClient
						&& this.serverStartTicks != 0
						&& @:privateAccess this.marble.serverTicks > this.serverStartTicks + 16
						&& @:privateAccess this.marble.serverTicks < this.serverStartTicks + 63)) {
					this.playGui.setCenterText('ready');
					this.playGui.doStateChangeSound('ready');
				}
				if ((Net.isHost
					&& (this.timeState.timeSinceLoad > startTime - 1.5)
					&& (this.timeState.timeSinceLoad < startTime)) // 3.5 == 109 ticks
					|| (Net.isClient
						&& this.serverStartTicks != 0
						&& @:privateAccess this.marble.serverTicks > this.serverStartTicks + 63
						&& @:privateAccess this.marble.serverTicks < this.serverStartTicks + 109)) {
					this.playGui.setCenterText('set');
					this.playGui.doStateChangeSound('set');
				}
				if ((Net.isHost && (this.timeState.timeSinceLoad >= startTime)) // 3.5 == 109 ticks
					|| (Net.isClient && this.serverStartTicks != 0 && @:privateAccess this.marble.serverTicks >= this.serverStartTicks + 109)) {
					this.multiplayerStarted = true;
					this.marble.setMode(Play);
					for (client => marble in this.clientMarbles)
						marble.setMode(Play);

					this.playGui.redrawPlayerList(); // Update spectators display

					this.playGui.setCenterText('go');
					this.playGui.doStateChangeSound('go');

					var huntMode = cast(this.gameMode, HuntMode);

					huntMode.freeSpawns();
				}
			}
			if (this.multiplayerStarted) {
				if ((Net.isHost && (this.timeState.timeSinceLoad > startTime + 2.0)) // 3.5 == 109 ticks
					|| (Net.isClient && this.serverStartTicks != 0 && @:privateAccess this.marble.serverTicks > this.serverStartTicks + 172)) {
					this.playGui.setCenterText('none');
				}
			}
		}
	}

	public function addSimGroup(simGroup:MissionElementSimGroup) {
		var elements = simGroup.elements;

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
						// Named references (e.g. IceShard's `gotoTarget`/`pathedInterior[i]`) target
						// the PathedInterior element's own name, not the containing SimGroup's -
						// every other placed object is looked up by its own element name too.
						if (@:privateAccess pathedInterior.element._name != null && @:privateAccess pathedInterior.element._name != "")
							this.namedGameObjects.set(@:privateAccess pathedInterior.element._name, pathedInterior);
						if (simGroup._name != null && simGroup._name != "")
							this.namedGameObjects.set(simGroup._name, pathedInterior);
						for (trigger in pathedInterior.triggers) {
							this.triggers.push(trigger);
							this.collisionWorld.addEntity(trigger.collider);
						}
						fwd();
					});
				});
			});

			// add non-pathedinterior related entities
			elements = elements.filter((element) -> element._type != MissionElementType.PathedInterior
				&& element._type != MissionElementType.Path
				&& element._type != MissionElementType.Marker
				&& !(element._type == Trigger
					&& (["triggergototarget", "triggergotodelaytarget", "repetitivetriggergototarget"].contains(cast(element, MissionElementTrigger)
						.datablock))));
		}

		for (element in elements) {
			switch (element._type) {
				case MissionElementType.SimGroup:
					this.addSimGroup(cast element);
				case MissionElementType.InteriorInstance:
					resourceLoadFuncs.push(fwd -> this.addInteriorFromMis(cast element, fwd));
				case MissionElementType.StaticShape:
					var sse:MissionElementStaticShape = cast element;
					var datablockLower = sse.datablock != null ? sse.datablock.toLowerCase() : "";
					if (datablockLower == "pathnode" || datablockLower == "bezierhandle") {
						this.addPathNode(sse);
					} else {
						resourceLoadFuncs.push(fwd -> this.addStaticShape(cast element, fwd));
					}
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
		if (element._name != null && element._name != "")
			this.namedGameObjects.set(element._name, interior);
		// DifBuilder.loadDif(difPath, interior);
		// this.interiors.push(interior);
		this.addInterior(interior, () -> {
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

			// Always apply the authored placement first, *then* hand off to the path/parent
			// follower - see addPlaceableShape for why.
			interior.setTransform(mat);
			interior.initPathAndParent(cast element, this);
			this.promoteMoverColliders(interior, [interior.collider]);
			interior.isCollideable = hasCollision;
			onFinish();
		});

		// interior.setTransform(interiorPosition, interiorRotation, interiorScale);

		// this.scene.add(interior.group);
		// if (hasCollision)
		// 	this.physics.addInterior(interior);
	}

	/** `PathNode`/`BezierHandle` placements never become `GameObject`s - see `PathNodeElement`. */
	public function addPathNode(element:MissionElementStaticShape) {
		var position = MisParser.parseVector3(element.position);
		position.x = -position.x;
		var rotation = MisParser.parseRotation(element.rotation);
		rotation.x = -rotation.x;
		rotation.w = -rotation.w;
		var scale = MisParser.parseVector3(element.scale);
		if (scale.x == 0)
			scale.x = 0.0001;
		if (scale.y == 0)
			scale.y = 0.0001;
		if (scale.z == 0)
			scale.z = 0.0001;

		this.pathNodes.set(element._name.toLowerCase(), new PathNodeElement(element._name, position, rotation, scale, element.fields));
	}

	public function addStaticShape(element:MissionElementStaticShape, onFinish:Void->Void) {
		addPlaceableShape(element, onFinish);
	}

	public function addItem(element:MissionElementItem, onFinish:Void->Void) {
		addPlaceableShape(element, onFinish);
	}

	function addPlaceableShape(element:IPlaceableElement, onFinish:Void->Void) {
		var shape:DtsObject = null;
		var dataBlockLowerCase = element.datablock.toLowerCase();

		if (dataBlockLowerCase != "") {
			var entry = DatablockRegistry.resolveShape(dataBlockLowerCase);
			if (entry == null) {
				Console.error("Unknown item: " + element.datablock);
				onFinish();
				return;
			}
			shape = entry.create(element);
			if (entry.after != null)
				entry.after(shape, element, this);
		}

		if (element._name != null && element._name != "") {
			this.namedObjects.set(element._name, {
				obj: shape,
				elem: cast element
			});
			if (shape != null)
				this.namedGameObjects.set(element._name, shape);
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
			// Always apply the authored placement first, *then* hand off to the path/parent
			// follower - a path/parent-following shape may still fall back to its own current
			// absolute transform for any axis it doesn't drive (see
			// GameObjectPathFollower.evaluateTransform), so that fallback needs to be the real
			// placed transform, not whatever default origin the object started at.
			shape.setTransform(mat);
			shape.initPathAndParent(element, this);
			this.promoteMoverColliders(shape, shape.colliders);
			if (shape.isBoundingBoxCollideable)
				this.promoteMoverColliders(shape, [shape.boundingCollider]);
			onFinish();
		});
	}

	public function addTrigger(element:MissionElementTrigger, onFinish:Void->Void) {
		var datablockLowercase = element.datablock.toLowerCase();

		var entry = DatablockRegistry.resolveTrigger(datablockLowercase);
		if (entry == null) {
			Console.error("Unknown trigger: " + element.datablock);
			onFinish();
			return;
		}

		var trigger = entry.create(element, cast this);

		if (element._name != null && element._name != "")
			this.namedGameObjects.set(element._name, trigger);
		trigger.initPathAndParent(cast element, this);

		trigger.init(() -> {
			this.triggers.push(trigger);
			if (trigger.hasMover())
				this.collisionWorld.addMovingEntity(trigger.collider);
			else
				this.collisionWorld.addEntity(trigger.collider);
			onFinish();
		});
	}

	public function addTSStatic(element:MissionElementTSStatic, onFinish:Void->Void) {
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
			this.namedGameObjects.set(element._name, tsShape);
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
			// Always apply the authored placement first, *then* hand off to the path/parent
			// follower - see addPlaceableShape for why.
			tsShape.setTransform(mat);
			tsShape.initPathAndParent(cast element, this);
			this.promoteMoverColliders(tsShape, tsShape.colliders);
			if (tsShape.isBoundingBoxCollideable)
				this.promoteMoverColliders(tsShape, [tsShape.boundingCollider]);
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

	/** Promotes a `GameObject`'s collider(s) from the static to the moving broadphase grid after
		the fact - needed because `initPathAndParent` can only run once the object's *true* placed
		transform has been applied (its own current-absolute-transform is the fallback for any axis
		a path/parent doesn't drive - see `GameObjectPathFollower.evaluateTransform`), which itself
		can only happen once the DTS/interior has finished loading and its collider(s) exist. That's
		necessarily *after* `addDtsObject`/`addInterior` already decided which grid to use, so
		`hasMover()` isn't known yet at that point - fix it up here instead. */
	function promoteMoverColliders(obj:GameObject, colliders:Array<CollisionEntity>) {
		if (!obj.hasMover())
			return;
		for (collider in colliders) {
			if (collider == null)
				continue;
			this.collisionWorld.removeEntity(collider);
			this.collisionWorld.addMovingEntity(collider);
		}
	}

	public function addPathedInterior(obj:PathedInterior, onFinish:Void->Void) {
		this.pathedInteriors.push(obj);
		this.registerMovingObject(obj);
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
				var dirPath = haxe.io.Path.directory(path);
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
						// since these are TEXTURES we need to ensure the files exist
						if (ResourceLoader.exists(dirPath + '/' + parts[0]))
							keyframes.push(parts[0]);
						else if (ResourceLoader.exists(dirPath + '/' + parts[0] + ".jpg"))
							keyframes.push(parts[0] + ".jpg");
						else if (ResourceLoader.exists(dirPath + '/' + parts[0] + ".png"))
							keyframes.push(parts[0] + ".png");
					}
				}

				onFinish(keyframes);
			});
		}

		ResourceLoader.load(obj.dtsPath).entry.load(() -> {
			var dtsFile = ResourceLoader.loadDts(obj.dtsPath);
			var directoryPath = haxe.io.Path.directory(obj.dtsPath);
			var texToLoad = [];
			for (i in 0...dtsFile.resource.matNames.length) {
				var matName = obj.resolveMatName(dtsFile.resource.matNames[i]);
				var fullNames = ResourceLoader.getFullNamesOf(directoryPath + '/' + matName).filter(x -> haxe.io.Path.extension(x) != "dts");
				var fullName = fullNames.length > 0 ? fullNames[0] : null;
				if (fullName != null) {
					texToLoad.push(fullName);
				}
			}

			var worker = new ResourceLoaderWorker(() -> {
				obj.idInLevel = this.dtsObjects.length; // Set the id of the thing
				this.dtsObjects.push(obj);
				if (obj is PowerUp) {
					var pw:PowerUp = cast obj;
					pw.netIndex = this.powerUps.length;
					this.powerUps.push(cast obj);
					if (Net.isClient)
						powerupPredictions.alloc();
				}
				if (obj is ForceObject) {
					this.forceObjects.push(cast obj);
				}
				if (obj is Explodable) {
					var exp:Explodable = cast obj;
					exp.netId = this.explodables.length;
					this.explodables.push(exp);
					if (Net.isClient)
						explodablePredictions.alloc();
				}
				if (obj is Trapdoor) {
					var t:Trapdoor = cast obj;
					t.netId = this.trapdoors.length;
					this.trapdoors.push(t);
					if (Net.isClient)
						trapdoorPredictions.alloc();
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
				if (haxe.io.Path.extension(texPath) == "ifl") {
					if (isTsStatic)
						obj.useInstancing = false;
					worker.addTask(fwd -> {
						parseIfl(texPath, keyframes -> {
							var innerWorker = new ResourceLoaderWorker(() -> {
								fwd();
							});
							var loadedkf = [];
							for (kf in keyframes) {
								if (!loadedkf.contains(kf)) {
									innerWorker.loadFile(directoryPath + '/' + kf);
									loadedkf.push(kf);
								}
							}
							innerWorker.run();
						});
					});
				} else {
					worker.loadFile(texPath);
				}
			}

			worker.run();
		});
	}

	public function addMarble(marble:Marble, client:GameConnection, onFinish:Void->Void) {
		marble.level = cast this;
		if (marble.controllable) {
			marble.init(cast this, client, () -> {
				this.marbles.push(marble);
				this.scene.addChild(marble.camera);
				this.marble = marble;
				// Ugly hack
				// sky.follow = marble;
				sky.follow = marble.camera;
				this.collisionWorld.addMovingEntity(marble.collider);
				this.collisionWorld.addMarbleEntity(marble.collider);
				this.scene.addChild(marble);
				onFinish();
			});
		} else {
			marble.init(cast this, client, () -> {
				this.marbles.push(marble);
				marble.collisionWorld = this.collisionWorld;
				this.collisionWorld.addMovingEntity(marble.collider);
				this.collisionWorld.addMarbleEntity(marble.collider);
				this.scene.addChild(marble);
				if (client != null)
					clientMarbles.set(client, marble);
				onFinish();
			});
		}
	}

	public function performRestart() {
		this.respawnPressedTime = timeState.timeSinceLoad;
		this.restart(this.marble);
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

	// MP ONLY
	public function completeRestart() {
		for (id => client in Net.clientIdMap) {
			client.state = LOBBY;
			client.lobbyReady = false;
		}
		Net.hostReady = false;
		Net.lobbyHostReady = false;
		Net.lobbyClientReady = false;

		this.finishTime = null;
		this.multiplayerStarted = false;
		this.timeState.ticks = 0;

		for (marble in this.marbles) {
			restart(marble, true);
		}

		for (exp in explodables) {
			exp.lastContactTick = -100000;
		}
		trapdoorPredictions.reset();
		for (t in trapdoors) {
			t.lastContactTicks = -100000;
		}

		showPreGame();

		serverStartTicks = 0;
		startTime = 1e8;
	}

	public function partialRestart() {
		this.finishTime = null;
		this.multiplayerStarted = false;
		this.timeState.ticks = 0;

		for (marble in this.marbles) {
			restart(marble, true);
		}

		setCursorLock(true);

		startTime = this.timeState.timeSinceLoad + 4;

		for (exp in explodables) {
			exp.lastContactTick = -100000;
		}
		trapdoorPredictions.reset();
		for (t in trapdoors) {
			t.lastContactTicks = -100000;
		}

		if (Net.isHost) {
			haxe.Timer.delay(() -> {
				this.gameMode.onRestart();
				NetCommands.setStartTicks(this.timeState.ticks);
			}, 500);
		}
		this.gameMode.onRestart();
	}

	public function getWorldStateForClientJoin() {
		var packets = [];
		// First, gem spawn packet
		var bs = new OutputBitStream();
		bs.writeByte(GemSpawn);
		var packet = new GemSpawnPacket();

		var hunt = cast(this.gameMode, HuntMode);
		if (@:privateAccess hunt.activeGemSpawnGroup != null) {
			var activeGemIds = [];
			for (gemId in @:privateAccess hunt.activeGemSpawnGroup) {
				if (@:privateAccess hunt.gemSpawnPoints[gemId].gem != null && @:privateAccess !hunt.gemSpawnPoints[gemId].gem.pickedUp) {
					activeGemIds.push(gemId);
				}
			}
			packet.gemIds = activeGemIds;
			packet.serialize(bs);
			packets.push(bs.getBytes());
		}

		// Marble states
		for (marb in this.marbles) {
			var oldFlags = @:privateAccess marb.netFlags;
			@:privateAccess marb.netFlags = MarbleNetFlags.DoBlast | MarbleNetFlags.DoMega | MarbleNetFlags.DoHelicopter | MarbleNetFlags.DoShockAbsorber | MarbleNetFlags.DoSuperBounce | MarbleNetFlags.PickupPowerup | MarbleNetFlags.GravityChange | MarbleNetFlags.UsePowerup;

			if (oldFlags & MarbleNetFlags.UpdateTrapdoor > 0) {
				@:privateAccess marb.netFlags |= MarbleNetFlags.UpdateTrapdoor;
			}

			var innerMove = @:privateAccess marb.lastMove;
			if (innerMove == null) {
				innerMove = new Move();
				innerMove.d = new Vector(0, 0);
			}
			var motionDir = @:privateAccess marb.moveMotionDir;
			if (motionDir == null) {
				motionDir = marb.getMarbleAxis()[1];
			}

			var move = new NetMove(innerMove, motionDir, timeState, timeState.ticks, 65535);

			packets.push(@:privateAccess marb.packUpdate(move, timeState));

			@:privateAccess marb.netFlags = oldFlags;
		}

		// Powerup states
		for (powerup in this.powerUps) {
			if (powerup.currentOpacity != 1.0) { // it must be picked up or something
				if (@:privateAccess powerup.pickupClient != -1) {
					var b = new OutputBitStream();
					b.writeByte(NetPacketType.PowerupPickup);
					var pickupPacket = new PowerupPickupPacket();
					pickupPacket.clientId = @:privateAccess powerup.pickupClient;
					pickupPacket.serverTicks = @:privateAccess powerup.pickupTicks;
					pickupPacket.powerupItemId = powerup.netIndex;
					pickupPacket.serialize(b);
					packets.push(b.getBytes());
				}
			}
		}

		// Explosion states
		for (exp in this.explodables) {
			if (this.timeState.ticks < (exp.lastContactTick + exp.renewTime >> 5)) {
				var b = new OutputBitStream();
				b.writeByte(NetPacketType.ExplodableUpdate);
				var explPacket = new ExplodableUpdatePacket();
				explPacket.explodableId = exp.netId;
				explPacket.serverTicks = timeState.ticks;
				explPacket.serialize(b);
				packets.push(b.getBytes());
			}
		}

		// Scoreboard!
		var b = new OutputBitStream();
		b.writeByte(NetPacketType.ScoreBoardInfo);
		var sbPacket = new ScoreboardPacket();
		for (player in @:privateAccess this.playGui.playerList) {
			sbPacket.scoreBoard.set(player.id, player.score);
			sbPacket.rBoard.set(player.id, player.r);
			sbPacket.yBoard.set(player.id, player.y);
			sbPacket.bBoard.set(player.id, player.b);
		}
		sbPacket.serialize(b);
		packets.push(b.getBytes());

		return packets;
	}

	inline function hasPredictionFlag(mask:Int, clientId:Int):Bool {
		return (mask & (1 << clientId)) != 0;
	}

	public function applyReceivedMoves() {
		var needsPrediction = 0;

		inline function correctPrediction(target:Marble, packet:MarbleUpdatePacket, tick:Int, bitMask:Int, ?pending:Array<MarbleUpdatePacket>) {
			target.unpackUpdate(packet);
			needsPrediction |= bitMask;
			if (pending != null)
				pending.insert(0, packet);
			if (tick >= 0)
				predictions.clearStatesAfterTick(target, tick);
		}

		if (!lastMoves.ourMoveApplied) {
			var ourMove = lastMoves.myMarbleUpdate;
			if (ourMove != null) {
				var ourMoveStruct = Net.clientConnection.acknowledgeMove(ourMove.move, timeState);
				lastMoves.ourMoveApplied = true;

				var hasStruct = ourMoveStruct != null;
				var ourTick = hasStruct ? ourMoveStruct.timeState.ticks : -1;

				for (client => arr in lastMoves.otherMarbleUpdates) {
					var lastMove = null;
					while (arr.packets.length > 0) {
						var p = arr.packets[0];
						if (p.serverTicks <= ourMove.serverTicks) {
							lastMove = arr.packets.shift();
						} else {
							break;
						}
					}

					if (lastMove == null || ourMove.serverTicks != lastMove.serverTicks)
						continue;

					var connection = Net.clientIdMap[client];
					if (connection == null)
						continue;
					var clientMarble = clientMarbles[connection];
					if (clientMarble == null)
						continue;

					var mask = 1 << client;
					if (hasStruct) {
						var otherPred = predictions.retrieveState(clientMarble, ourMoveStruct.timeState.ticks);
						if (otherPred == null || otherPred.getError(lastMove) > 0.01) {
							correctPrediction(clientMarble, lastMove, ourTick, mask, arr.packets);
						}
					} else {
						correctPrediction(clientMarble, lastMove, -1, mask, arr.packets);
					}
				}
				if (!Net.clientSpectate) {
					if (hasStruct) {
						var ourPred = predictions.retrieveState(marble, ourTick);
						if (ourPred == null || ourPred.getError(ourMove) > 0.01) {
							correctPrediction(marble, ourMove, ourTick, 1 << Net.clientId);
						}
					} else {
						correctPrediction(marble, ourMove, -1, 1 << Net.clientId);
					}
				}
			}
		}
		return needsPrediction;
	}

	public function applyClientPrediction(marbleNeedsPrediction:Int) {
		// First acknowledge the marble's last move so we can get that over with
		var ourLastMove = lastMoves.myMarbleUpdate;
		if (ourLastMove == null || marbleNeedsPrediction == 0)
			return -1;
		var ackLag = @:privateAccess Net.clientConnection.getQueuedMovesLength();

		var ourLastMoveTime = ourLastMove.serverTicks;

		var ourQueuedMoves = @:privateAccess Net.clientConnection.getQueuedMoves().copy();

		var qm = ourQueuedMoves[0];
		var advanceTimeState = qm != null ? qm.timeState.clone() : timeState.clone();
		advanceTimeState.dt = 0.032;
		advanceTimeState.ticks = ourLastMoveTime;

		// if (marbleNeedsPrediction & (1 << Net.clientId) > 0) { // Only for our clients pls
		//	if (qm != null) {
		// var mvs = qm.powerupStates.copy();
		for (pw in powerUps) {
			// var val = mvs.shift();
			// if (pw.lastPickUpTime != val)
			//	Console.log('Revert powerup pickup: ${pw.lastPickUpTime} -> ${val}');

			if (pw.pickupClient != -1 && marbleNeedsPrediction & (1 << pw.pickupClient) > 0)
				pw.lastPickUpTime = powerupPredictions.getState(pw.netIndex);
		}
		for (expT in explodablesToTick) {
			var exp = explodables[expT];
			exp.revertContactTicks(explodablePredictions.getState(exp.netId));
		}
		explodablesToTick = [];
		for (tT in trapdoorsToTick) {
			var t = trapdoors[tT];
			t.lastContactTicks = trapdoorPredictions.getState(t.netId);
			t.update(advanceTimeState);
		}

		var huntMode:HuntMode = cast this.gameMode;
		if (@:privateAccess huntMode.activeGemSpawnGroup != null) {
			for (activeGem in @:privateAccess huntMode.activeGemSpawnGroup) {
				var g = @:privateAccess huntMode.gemSpawnPoints[activeGem].gem;
				if (g != null && g.pickUpClient != -1 && marbleNeedsPrediction & (1 << g.pickUpClient) > 0)
					huntMode.setGemHiddenStatus(activeGem, gemPredictions.getState(activeGem));
			}
		}
		//	}
		// }

		ackLag = ourQueuedMoves.length;

		// Tick the remaining moves (ours)
		@:privateAccess this.marble.isNetUpdate = true;
		var totalTicksToDo = ourQueuedMoves.length;
		var endTick = ourLastMoveTime + totalTicksToDo;
		var currentTick = ourLastMoveTime;
		//- Std.int(ourLastMove.moveQueueSize - @:privateAccess Net.clientConnection.moveManager.ackRTT); // - Std.int((@:privateAccess Net.clientConnection.moveManager.ackRTT)) - offset;

		var marblesToTick = new Map();

		for (client => arr in lastMoves.otherMarbleUpdates) {
			if (marbleNeedsPrediction & (1 << client) > 0 && arr.packets.length > 0) {
				var m = arr.packets[0];
				// if (m.serverTicks == ourLastMoveTime) {
				var marbleToUpdate = clientMarbles[Net.clientIdMap[client]];
				if (@:privateAccess marbleToUpdate.newPos == null)
					continue;
				// Debug.drawSphere(@:privateAccess marbleToUpdate.newPos, marbleToUpdate._radius);

				// var distFromUs = @:privateAccess marbleToUpdate.newPos.distance(this.marble.newPos);
				// if (distFromUs < 5) // {
				m.calculationTicks = ourQueuedMoves.length;
				@:privateAccess marbleToUpdate.posStore.load(marbleToUpdate.newPos);
				@:privateAccess marbleToUpdate.netCorrected = true;
				// } else {
				// 	m.calculationTicks = Std.int(Math.max(1, ourQueuedMoves.length - (distFromUs - 5) / 3));
				// }
				// - Std.int((@:privateAccess Net.clientConnection.moveManager.ackRTT - ourLastMove.moveQueueSize) / 2);

				marblesToTick.set(client, m);
				arr.packets.shift();
				// }
			}
		}

		Debug.drawSphere(@:privateAccess this.marble.newPos, this.marble._radius);
		// var syncTickStates = new Map();

		@:privateAccess this.marble.posStore.load(this.marble.newPos);
		@:privateAccess this.marble.netCorrected = true;

		// if ((marbleNeedsPrediction & (1 << Net.clientId) > 0)) {
		for (pi in this.pathedInteriors) {
			pi.rollbackToTick(currentTick);
		}
		// }

		for (move in ourQueuedMoves) {
			var m = move.move;
			Debug.drawSphere(@:privateAccess this.marble.newPos, this.marble._radius);
			if (marbleNeedsPrediction & (1 << Net.clientId) > 0) {
				@:privateAccess this.marble.moveMotionDir = move.motionDir;
				@:privateAccess this.marble.advancePhysics(advanceTimeState, m, this.collisionWorld, this.pathedInteriors);
				this.predictions.storeState(this.marble, move.timeState.ticks);
			}
			// var collidings = @:privateAccess this.marble.contactEntities.filter(x -> x is SphereCollisionEntity);

			for (client => m in marblesToTick) {
				if (m.calculationTicks > 0) {
					var marbleToUpdate = clientMarbles[Net.clientIdMap[client]];
					Debug.drawSphere(@:privateAccess marbleToUpdate.newPos, marbleToUpdate._radius);

					var mv = m.move.move;
					@:privateAccess marbleToUpdate.isNetUpdate = true;
					@:privateAccess marbleToUpdate.moveMotionDir = m.move.motionDir;
					@:privateAccess marbleToUpdate.advancePhysics(advanceTimeState, mv, this.collisionWorld, this.pathedInteriors);
					this.predictions.storeState(marbleToUpdate, move.timeState.ticks);
					@:privateAccess marbleToUpdate.isNetUpdate = false;
					m.calculationTicks--;
				}
			}

			advanceTimeState.currentAttemptTime += 0.032;
			advanceTimeState.ticks++;
			currentTick++;

			// if ((marbleNeedsPrediction & (1 << Net.clientId) > 0)) {
			for (pi in this.pathedInteriors) {
				pi.computeNextPathStep(0.032);
				pi.advance(0.032);
			}

			for (tT in trapdoorsToTick) {
				var t = trapdoors[tT];
				t.update(advanceTimeState);
			}
			// }
		}

		trapdoorsToTick = [];

		lastMoves.ourMoveApplied = true;
		@:privateAccess this.marble.isNetUpdate = false;
		return advanceTimeState.ticks;

		return -1;
	}

	public function spawnHuntGemsClientSide(gemIds:Array<Int>, expireds:Array<Bool>) {
		if (this.isMultiplayer && Net.isClient) {
			var huntMode:HuntMode = cast this.gameMode;
			huntMode.setActiveSpawnSphere(gemIds, expireds);
			// radar.blink();
		}
	}

	public function removePlayer(cc:GameConnection) {
		var otherMarble = this.clientMarbles[cc];
		if (otherMarble != null) {
			cancel(otherMarble.oobSchedule);
			this.predictions.removeMarbleFromPrediction(otherMarble);
			this.scene.removeChild(otherMarble);
			this.collisionWorld.removeMarbleEntity(otherMarble.collider);
			this.collisionWorld.removeMovingEntity(otherMarble.collider);
			this.playGui.removePlayer(cc.id);
			this.clientMarbles.remove(cc);
			otherMarble.dispose();
			this.marbles.remove(otherMarble);
		}
	}

	public function rollback(t:Float) {
		var newT = timeState.currentAttemptTime - t;
		var rewindFrame = rewindManager.getNextRewindFrame(timeState.currentAttemptTime - t);
		rewindManager.applyFrame(rewindFrame);
		this.isReplayingMovement = true;
		this.currentInputMoves = this.inputRecorder.getMovesFrom(timeState.currentAttemptTime);
	}

	public function advanceWorld(dt:Float) {
		ProfilerUI.measure("updateTimer");
		this.updateTimer(dt);
		this.tickSchedule(timeState.currentAttemptTime);

		this.updateGameState();
		ProfilerUI.measure("updateDTS");
		for (obj in dtsObjects) {
			obj.update(timeState);
		}
		for (obj in triggers) {
			obj.update(timeState);
		}

		ProfilerUI.measure("updateMarbles");
		marble.update(timeState, collisionWorld, this.pathedInteriors);
		for (client => marble in clientMarbles) {
			marble.update(timeState, collisionWorld, this.pathedInteriors);
		}
	}

	public function update(dt:Float) {
		if (!_ready) {
			return;
		}

		// if (Key.isPressed(Key.T)) {
		// 	rollback(0.4);
		// }

		var realDt = dt;

		if ((Key.isDown(Settings.controlsSettings.rewind)
			|| MarbleGame.instance.touchInput.rewindButton.pressed
			|| Gamepad.isDown(Settings.gamepadSettings.rewind))
			&& Settings.optionsSettings.rewindEnabled
			&& !this.isMultiplayer
			&& !this.isWatching
			&& this.finishTime == null) {
			this.rewinding = true;
		} else {
			if ((Key.isReleased(Settings.controlsSettings.rewind)
				|| !MarbleGame.instance.touchInput.rewindButton.pressed
				|| Gamepad.isReleased(Settings.gamepadSettings.rewind))
				&& !this.isMultiplayer
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
				MarbleGame.canvas.setContent(Type.createInstance(@:privateAccess MarbleGame.instance.replayEndClass, []));
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
				rewindUsed = true;
			}
		}
		if (dt < 0)
			return;

		if (this.isReplayingMovement) {
			trace('Rollback start');
			while (this.currentInputMoves.length > 1) {
				while (this.currentInputMoves[1].time <= timeState.currentAttemptTime) {
					this.currentInputMoves = this.currentInputMoves.slice(1);
					if (this.currentInputMoves.length == 1)
						break;
				}
				if (this.currentInputMoves.length > 1) {
					dt = this.currentInputMoves[1].time - this.currentInputMoves[0].time;
				}

				if (this.isReplayingMovement) {
					if (this.timeState.currentAttemptTime != this.currentInputMoves[0].time)
						trace("fucked");
				}

				if (this.currentInputMoves.length > 1) {
					advanceWorld(dt);
					trace('Position: ${@:privateAccess marble.newPos.sub(currentInputMoves[1].pos).length()}. Vel: ${marble.velocity.sub(currentInputMoves[1].velocity).length()}');
				}
			}
			this.isReplayingMovement = false;
		}

		ProfilerUI.measure("updateTimer");
		this.updateTimer(dt);
		this.gameMode.update(this.timeState);
		if (this.marble != null)
			this.playGui.updateSpeedometer(this.marble.velocity.length());
		this.updateUnderwaterOverlay();
		this.updateBubbleBarPosition();

		if (!this.isMultiplayer) {
			if ((Key.isPressed(Settings.controlsSettings.respawn) || Gamepad.isPressed(Settings.gamepadSettings.respawn))
				&& this.finishTime == null) {
				performRestart();
				return;
			}

			if ((Key.isDown(Settings.controlsSettings.respawn)
				|| MarbleGame.instance.touchInput.restartButton.pressed
				|| Gamepad.isDown(Settings.gamepadSettings.respawn))
				&& !this.isWatching
				&& this.finishTime == null) {
				if (timeState.timeSinceLoad - this.respawnPressedTime > 1.5) {
					this.restart(this.marble, true);
					this.respawnPressedTime = Math.POSITIVE_INFINITY;
					return;
				}
			}
		}

		this.tickSchedule(timeState.currentAttemptTime);

		if (Key.isPressed(Settings.controlsSettings.blast)
			|| (MarbleGame.instance.touchInput.blastbutton.pressed)
			|| Gamepad.isPressed(Settings.gamepadSettings.blast)
			&& !this.isWatching
			&& this.game == "ultra") {
			this.marble.useBlast(timeState);
			if (this.isRecording) {
				this.replay.recordMarbleStateFlags(false, false, false, true);
			}
		}

		if (this.isWatching && this.replay.currentPlaybackFrame.marbleStateFlags.has(UsedBlast))
			this.marble.useBlast(timeState);

		// Replay gravity
		if (this.isWatching) {
			if (this.replay.currentPlaybackFrame.gravityChange) {
				this.setUp(this.marble, this.replay.currentPlaybackFrame.gravity, timeState, this.replay.currentPlaybackFrame.gravityInstant);
			}
			if (this.replay.currentPlaybackFrame.powerupPickup != null) {
				this.pickUpPowerUpReplay(this.replay.currentPlaybackFrame.powerupPickup);
			}
		}

		this.updateGameState();
		if (!this.isMultiplayer)
			this.updateBlast(this.marble, timeState);
		ProfilerUI.measure("updateDTS");
		for (obj in dtsObjects) {
			obj.update(timeState);
		}
		for (obj in triggers) {
			obj.update(timeState);
		}

		// if (!isReplayingMovement) {
		// 	inputRecorder.recordInput(timeState.currentAttemptTime);
		// }

		ProfilerUI.measure("updateMarbles");
		if (this.isMultiplayer) {
			tickAccumulator += timeState.dt;
			while (tickAccumulator >= 0.032) {
				// Apply the server side ticks
				var lastPredTick = -1;
				if (Net.isClient) {
					var marbleNeedsTicking = applyReceivedMoves();
					// Catch up
					lastPredTick = applyClientPrediction(marbleNeedsTicking);
				}

				// Do the clientside prediction sim
				var fixedDt = timeState.clone();
				fixedDt.dt = 0.032;
				tickAccumulator -= 0.032;
				var packets = [];
				var otherMoves = [];
				var myMove = null;

				if (serverStartTicks != 0) {
					for (marble in marbles) {
						var move = marble.updateServer(fixedDt, collisionWorld, pathedInteriors);
						if (marble == this.marble)
							myMove = move;
						else
							otherMoves.push(move);
					}

					if (myMove != null && Net.isClient) {
						this.predictions.storeState(marble, myMove.timeState.ticks);
						for (client => marble in clientMarbles) {
							this.predictions.storeState(marble, myMove.timeState.ticks);
						}
					}

					if (Net.isHost) {
						packets.push(marble.packUpdate(myMove, fixedDt));
						for (othermarble in marbles) {
							if (othermarble != this.marble) {
								var mv = otherMoves.shift();
								packets.push(othermarble.packUpdate(mv, fixedDt));
							}
						}
						// for (client => othermarble in clientMarbles) { // Oh no!
						// 	var mv = otherMoves.shift();
						// 	packets.push(marble.packUpdate(myMove, fixedDt));
						// 	packets.push(othermarble.packUpdate(mv, fixedDt));
						// }
						var allRecv = true;
						for (client => marble in clientMarbles) { // Oh no!
							// var pktClone = packets.copy();
							// pktClone.sort((a, b) -> {
							// 	return (a.c == client.id) ? 1 : (b.c == client.id) ? -1 : 0;
							// });
							marble.clearNetFlags();

							if (client.state != GAME) {
								allRecv = false;
								continue; // Only send if in game
							}

							for (packet in packets) {
								client.sendBytes(packet);
							}
						}
						// if (allRecv)
						this.marble.clearNetFlags();
					}
				}
				for (pi in this.pathedInteriors) {
					pi.computeNextPathStep(0.032);
					pi.advance(0.032);
				}
				timeState.ticks++;
			}
			timeState.subframe = tickAccumulator / 0.032;
			marble.updateClient(timeState, this.pathedInteriors);
			for (client => marble in clientMarbles) {
				marble.updateClient(timeState, this.pathedInteriors);
			}
			if (Net.clientSpectate || Net.hostSpectate) {
				// this.camera.startCenterCamera();
				marble.camera.update(timeState.currentAttemptTime, timeState.dt);
			}
		} else {
			for (marble in marbles) {
				marble.update(timeState, collisionWorld, this.pathedInteriors);
			}
		}
		if (this.rewinding) {
			// Update camera separately
			marble.camera.update(timeState.currentAttemptTime, realDt);
		}

		if (radar != null)
			radar.update(dt);

		ProfilerUI.measure("updateParticles");
		if (this.rewinding) {
			this.particleManager.update(1000 * timeState.timeSinceLoad, -realDt * rewindManager.timeScale);
		} else
			this.particleManager.update(1000 * timeState.timeSinceLoad, dt);
		ProfilerUI.measure("updatePlayGui");
		this.playGui.update(timeState);
		ProfilerUI.measure("updateAudio");
		AudioManager.update(this.scene);

		if (!this.isMultiplayer) {
			if (this.marble.outOfBounds
				&& this.finishTime == null
				&& (Key.isDown(Settings.controlsSettings.powerup) || Gamepad.isDown(Settings.gamepadSettings.powerup))
				&& !this.isWatching) {
				this.restart(this.marble);
				return;
			}
		}

		if (!this.isWatching) {
			if (this.isRecording && !this.rewinding) {
				this.replay.endFrame();
			}
		}

		if (!this.rewinding && Settings.optionsSettings.rewindEnabled && !this.isMultiplayer)
			this.rewindManager.recordFrame();

		// if (!this.isReplayingMovement) {
		// 	inputRecorder.recordMarble();
		// }

		_instancesNeedsUpdate = true;
	}

	public function render(e:h3d.Engine) {
		if (!_ready)
			asyncLoadResources();
		if (this.playGui != null && _ready)
			this.playGui.render(e);
		if (this.marble != null && this.marble.cubemapRenderer != null && _instancesNeedsUpdate) {
			this.marble.cubemapRenderer.position.load(this.marble.getAbsPos().getPosition());
			this.marble.cubemapRenderer.render(e, 0.002);
		}
		if (_instancesNeedsUpdate) {
			if (this.radar != null)
				this.radar.render(this.serverStartTicks != 0 || !Net.isMP);
			_instancesNeedsUpdate = false;
			this.instanceManager.render();
		}
	}

	var postInited = false;

	function asyncLoadResources() {
		if (this.resourceLoadFuncs.length != 0) {
			if (lock)
				return;

			#if hl
			var loadPerTick = Math.max(1, this.resourceLoadFuncs.length / 20);
			var loadedFuncs = 0;
			while (this.resourceLoadFuncs.length != 0) {
				var func = this.resourceLoadFuncs.shift();
				lock = true;
				func(() -> {
					lock = false;
					this.loadingGui.setProgress((1 - resourceLoadFuncs.length / _loadingLength));
					this._resourcesLoaded++;
				});
				loadedFuncs += 1;
				if (loadedFuncs >= loadPerTick)
					break;
			}
			#end

			#if js
			lock = true;

			var loadPerTick = 100; // Stack limits???
			var loadedFuncs = 0;
			var func = this.resourceLoadFuncs.shift();

			var consumeFn;
			consumeFn = () -> {
				if (loadedFuncs >= loadPerTick) {
					lock = false;
					return;
				}
				loadedFuncs += 1;
				this._resourcesLoaded++;
				this.loadingGui.setProgress((1 - resourceLoadFuncs.length / _loadingLength));
				if (this.resourceLoadFuncs.length != 0) {
					var fn = this.resourceLoadFuncs.shift();
					fn(consumeFn);
				} else {
					lock = false;
				}
			}

			func(consumeFn);
			#end

			// var func = this.resourceLoadFuncs.shift();
			// lock = true;
			// #if hl
			// func(() -> {
			// 	lock = false;
			// 	this._resourcesLoaded++;
			// 	this.loadingGui.setProgress((1 - resourceLoadFuncs.length / _loadingLength));
			// });
			// #end
			// #if js
			// func(() -> {
			// 	lock = false;
			// 	this.loadingGui.setProgress((1 - resourceLoadFuncs.length / _loadingLength));
			// 	this._resourcesLoaded++;
			// });
			// #end
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

	/** Computes the clock time in MBP when the user should be warned that they're about to exceed the par time. */
	public function computeAlarmStartTime() {
		var alarmStart = this.mission.qualifyTime;
		if (this.timeMultiplier < 0) {
			alarmStart = 15;
			if (this.mission.missionInfo.alarmstarttime != null)
				alarmStart = MisParser.parseNumber(this.mission.missionInfo.alarmstarttime);
			if (alarmStart == 0)
				alarmStart = 15;
			return alarmStart;
		}
		var alarmStart = this.mission.qualifyTime;
		if (this.mission.missionInfo.alarmstarttime != null)
			alarmStart -= MisParser.parseNumber(this.mission.missionInfo.alarmstarttime);
		else {
			alarmStart -= 15;
		}

		alarmStart = Math.max(0, alarmStart);

		return alarmStart;
	}

	function determineClockColor(timeToDisplay:Float) {
		if (this.finishTime != null)
			return PlayGui.timerStopped;
		if (this.isMultiplayer || this.timeMultiplier < 0) {
			if ((this.isMultiplayer && !this.multiplayerStarted) || (this.timeState.currentAttemptTime < 3.5 || this.bonusTime > 0))
				return PlayGui.timerStopped;

			// Create the flashing effect
			var alarmStart = this.computeAlarmStartTime();
			var elapsed = timeToDisplay - alarmStart;
			if (alarmStart < timeToDisplay)
				return PlayGui.timerNormal;
			if (Math.floor(elapsed) % 2 == 0)
				return PlayGui.timerDanger;

			return PlayGui.timerNormal;
		} else {
			if (this.timeState.currentAttemptTime < 3.5 || this.bonusTime > 0)
				return PlayGui.timerStopped;
			if (timeToDisplay >= this.mission.qualifyTime)
				return PlayGui.timerDanger;

			if (this.timeState.currentAttemptTime >= 3.5 && !Net.isMP) {
				// Create the flashing effect
				var alarmStart = this.computeAlarmStartTime();
				var elapsed = timeToDisplay - alarmStart;
				if (elapsed < 0)
					return PlayGui.timerNormal;
				if (Math.floor(elapsed) % 2 == 0)
					return PlayGui.timerDanger;
			}

			return PlayGui.timerNormal; // Default yellow
		}
	}

	public function updateTimer(dt:Float) {
		this.timeState.dt = dt;

		if (this.countdownActive) {
			this.countdownRemaining -= dt;
			if (this.countdownRemaining <= -5) {
				this.countdownActive = false;
				this.playGui.formatCountdownThTimer(0);
			} else {
				var color = this.countdownRemaining <= 0 ? PlayGui.timerStopped : PlayGui.timerNormal;
				this.playGui.formatCountdownThTimer(Math.max(0, this.countdownRemaining), color);
			}
		}

		var prevGameplayClock = this.timeState.gameplayClock;

		var timeMultiplier = this.gameMode.timeMultiplier();

		if (!this.isWatching) {
			// Ported from PQ's `Time::advance` - the whole clock-advancement block below is gated
			// behind `$Time::TimerRunning`, which `TimeStopTrigger` toggles off; `currentAttemptTime`
			// (PQ's `$Time::TotalTime`) is outside that gate and always keeps advancing.
			if (this.timeStopTriggerCount <= 0) {
				if (this.bonusTime != 0 && this.timeState.currentAttemptTime >= 3.5) {
					this.bonusTime -= dt;
					if (this.bonusTime < 0) {
						this.timeState.gameplayClock -= this.bonusTime * timeMultiplier;
						this.bonusTime = 0;
					}
					if (timeTravelSound == null) {
						var ttsnd = ResourceLoader.getResource("data/sound/timetravelactive.wav", ResourceLoader.getAudio, this.soundResources);
						timeTravelSound = AudioManager.playSound(ttsnd, null, true);

						if (alarmSound != null)
							alarmSound.pause = true;
					}
				} else {
					if (timeTravelSound != null) {
						timeTravelSound.stop();
						timeTravelSound = null;
						if (alarmSound != null)
							alarmSound.pause = false;
					}
					if (!this.isMultiplayer) {
						if (this.timeState.currentAttemptTime >= 3.5) {
							this.timeState.gameplayClock += dt * timeMultiplier;
						} else if (this.timeState.currentAttemptTime + dt >= 3.5) {
							this.timeState.gameplayClock += ((this.timeState.currentAttemptTime + dt) - 3.5) * timeMultiplier;
						}
					} else if (this.multiplayerStarted) {
						if (Net.isClient) {
							var ticksSinceTimerStart = @:privateAccess this.marble.serverTicks - (this.serverStartTicks + 109);
							var ourStartTime = this.gameMode.getStartTime();
							var gameplayHigh = ourStartTime - ticksSinceTimerStart * 0.032;
							var gameplayLow = ourStartTime - (ticksSinceTimerStart + 1) * 0.032;
							// Clamp timer to be between these two

							if (gameplayHigh < this.timeState.gameplayClock || gameplayLow > this.timeState.gameplayClock) {
								var clockTicks = Math.floor((ourStartTime - this.timeState.gameplayClock) / 0.032);
								var clockTickTime = ourStartTime - clockTicks * 0.032;
								var delta = clockTickTime - this.timeState.gameplayClock;
								this.timeState.gameplayClock = Math.max(0, gameplayHigh - delta);
							}
						}

						this.timeState.gameplayClock += dt * timeMultiplier;
						this.timeState.gameplayClock = Math.max(0, this.timeState.gameplayClock);
					}
					if (this.timeState.gameplayClock <= 0 && !Net.isClient) {
						this.gameMode.onTimeExpire();
						this.timeState.gameplayClock = 0;
					}
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

		// Handle alarm warnings (that the user is about to exceed the par time)
		var alarmStart = this.computeAlarmStartTime();
		if (this.timeMultiplier == 1 && this.timeState.currentAttemptTime >= 3.5) {
			if (this.timeMultiplier == 1) {
				if (prevGameplayClock < alarmStart && this.timeState.gameplayClock >= alarmStart) {
					// Start the alarm
					this.alarmSound = AudioManager.playSound(ResourceLoader.getResource("data/sound/alarm.wav", ResourceLoader.getAudio, this.soundResources),
						null, true); // AudioManager.createAudioSource('alarm.wav');
					this.displayHelp('You have ${(this.mission.qualifyTime - alarmStart)} seconds remaining.', 5);
				}
				if (prevGameplayClock < this.mission.qualifyTime && this.timeState.gameplayClock >= this.mission.qualifyTime) {
					// Stop the alarm
					if (this.alarmSound != null) {
						this.alarmSound.stop();
						this.alarmSound = null;
					}
					this.displayHelp("The clock has passed the Par Time.", 5);
					AudioManager.playSound(ResourceLoader.getResource("data/sound/alarm_timeout.wav", ResourceLoader.getAudio, this.soundResources));
				}
			}
		}
		if (this.timeMultiplier == -1) {
			if (prevGameplayClock > alarmStart && this.timeState.gameplayClock <= alarmStart) {
				// Start the alarm
				this.alarmSound = AudioManager.playSound(ResourceLoader.getResource("data/sound/alarm.wav", ResourceLoader.getAudio, this.soundResources),
					null, true); // AudioManager.createAudioSource('alarm.wav');
				this.displayHelp('You have ${(this.mission.qualifyTime - alarmStart)} seconds remaining.', 5);
			}
			if (prevGameplayClock > 0 && this.timeState.gameplayClock <= 0) {
				// Stop the alarm
				if (this.alarmSound != null) {
					this.alarmSound.stop();
					this.alarmSound = null;
				}
			}
		}

		if (finishTime != null)
			this.timeState.gameplayClock = finishTime.gameplayClock;
		playGui.formatTimer(this.timeState.gameplayClock, determineClockColor(this.timeState.gameplayClock));

		if (!this.isWatching && this.isRecording)
			this.replay.recordTimeState(timeState.currentAttemptTime, timeState.gameplayClock, this.bonusTime);
	}

	public function updateBlast(marble:Marble, timestate:TimeState) {
		if (Net.isMP) {
			if (this.marble == marble) {
				this.playGui.setBlastValue(marble.blastTicks / (25000 >> 5));
			}
		} else if (this.game == "ultra") {
			if (marble.blastAmount < 1) {
				marble.blastAmount = Util.clamp(marble.blastAmount + (timeState.dt / 25), 0, 1);
			}
			this.playGui.setBlastValue(marble.blastAmount);
		}
	}

	/** The gem counter's "total" (right-hand side of the collected/total display) - `totalGems`
		normally, but `QuotaMode` overrides `gemsRequiredToFinish` (>= 0) to show collected/quota
		instead, and every `formatGemCounter` call site should respect that. */
	public function gemCounterTotal():Int {
		return this.gemsRequiredToFinish >= 0 ? this.gemsRequiredToFinish : this.totalGems;
	}

	/** Ported from PQ's `performWaterOverlay` (`client/scripts/water.cs`) - the underwater screen
		overlay is driven by the *camera's* position, not the marble's, so it's checked separately
		here rather than folding into `Marble.updateWater` (which only cares about the marble). */
	function updateUnderwaterOverlay() {
		var cameraPos = this.scene.camera.pos;
		var cameraInWater = false;
		if (this.marble == null)
			return;
		for (t in this.marble.waterTriggers) {
			if (t.collider.boundingBox.contains(cameraPos.toPoint())) {
				cameraInWater = true;
				break;
			}
		}
		this.playGui.setUnderwaterOverlayVisible(cameraInWater);
	}

	/** Ported from PQ's `PlayGui::updatePowerupTimerPos` (`client/scripts/playGui.cs`) - the bubble
		bar tracks the marble's projected screen position rather than sitting at a fixed HUD spot.
		Projects a point offset to the marble's *side* by its collision radius (`RotMulVector(
		MatrixRot(%trans), %rad SPC "0 0")` - the camera's local right axis scaled by the radius) for
		X, but the un-offset *center* projection's Y, exactly matching the source's `%rpix`-for-X/
		`%mpix`-for-Y split; both get PQ's own `+20`/`-38` pixel nudge on top. */
	/** Also positions the Fireball bar (`PG_FireballContainer`) at the same anchor - ported from
		`PlayGui::updateBarPositions`' combined bubble/fireball placement. Both showing at once is a
		defensive case the real source jokes it doesn't expect ("because I know SOMEONE will try
		this") - Fireball pickup always zeroes any banked Bubble time and Bubble can't be picked up
		while Fireball is active (see `Marble.activateFireball`/`BubbleItem.pickUp`), so in practice
		only one bar is ever visible - reproduced anyway since it's a cheap offset. */
	function updateBubbleBarPosition() {
		if (this.marble == null)
			return;
		var camera = this.scene.camera;
		var forward = camera.target.sub(camera.pos).normalized();
		var right = forward.cross(camera.up).normalized();
		var marblePos = this.marble.getAbsPos().getPosition();
		var sidePos = marblePos.add(right.multiply(this.marble._radius));

		var centerProjected = camera.project(marblePos.x, marblePos.y, marblePos.z, this.scene2d.width, this.scene2d.height);
		var sideProjected = camera.project(sidePos.x, sidePos.y, sidePos.z, this.scene2d.width, this.scene2d.height);

		var x = sideProjected.x + (70 / 800) * this.scene2d.width * Settings.uiScale;
		var y = centerProjected.y - (50 / 600) * this.scene2d.height * Settings.uiScale;

		var bubbleShown = this.marble.bubbleInfinite || this.marble.bubbleTime > 0;
		var fireballShown = this.marble.fireball;

		if (fireballShown && bubbleShown) {
			this.playGui.setBubbleBarPosition(x, y + 40 * Settings.uiScale);
			this.playGui.setFireballBarPosition(x, y - 20 * Settings.uiScale);
		} else if (bubbleShown) {
			this.playGui.setBubbleBarPosition(x, y);
		} else if (fireballShown) {
			this.playGui.setFireballBarPosition(x, y);
		}
	}

	/** Ported from PQ's `addHelpLine` (`client/scripts/chathud.cs`) - despite this port's own
		naming ("alert"), matches PQ's stacking/sliding toast notification system
		(`createHelpMessage`/`updateMessages`), not `addBubbleLine`'s persistent help-bubble
		machinery (`PlayGui.helpTextForeground`/`setHelpText`, unrelated despite the similar name).
		See `PlayGui.addHelpLine`'s doc comment for the implementation. */
	public function displayAlert(text:String) {
		this.playGui.addHelpLine(text);
	}

	public function displayHelp(text:String, duration:Float) {
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
		this.playGui.setHelpText(this.timeState.timeSinceLoad, text, duration);
	}

	public function pickUpGem(marble:src.Marble, gem:Gem) {
		this.gameMode.onGemPickup(marble, gem);
	}

	function touchFinish() {
		if (this.finishTime != null
			|| (this.marble.outOfBounds && this.timeState.currentAttemptTime - this.marble.outOfBoundsTime.currentAttemptTime >= 0.5))
			return;

		if (!this.gameMode.canFinish(this.marble)) {
			AudioManager.playPitchedSound("missinggems", this.soundResources);
			displayAlert(this.gameMode.getFinishMessage(this.marble));
		} else {
			if (this.endPad != null)
				this.endPad.spawnFirework(this.timeState);
			this.finishTime = this.timeState.clone();
			this.marble.mode = Finish;
			this.marble.camera.finish = true;
			this.finishYaw = this.marble.camera.CameraYaw;
			this.finishPitch = this.marble.camera.CameraPitch;
			displayAlert("Congratulations! You've finished!");
			if (!Settings.levelStatistics.exists(mission.path)) {
				Settings.levelStatistics.set(mission.path, {
					oobs: 0,
					respawns: 0,
					totalTime: 0,
				});
			}
			Analytics.trackLevelScore(mission.title, mission.path, Std.int(finishTime.gameplayClock * 1000), Settings.levelStatistics[mission.path].oobs,
				Settings.levelStatistics[mission.path].respawns, Settings.optionsSettings.rewindEnabled);
			if (!this.isWatching)
				this.schedule(this.timeState.currentAttemptTime + 2, () -> cast showFinishScreen());
			// Stop the ongoing sounds
			if (timeTravelSound != null) {
				timeTravelSound.stop();
				timeTravelSound = null;
			}
			if (alarmSound != null) {
				alarmSound.stop();
				alarmSound = null;
			}

			this.cancel(marble.oobSchedule);
		}
	}

	function mpFinish() {
		// playGui.setGuiVisibility(false);
		Console.log("State End");
		#if js
		var pointercontainer = js.Browser.document.querySelector("#pointercontainer");
		pointercontainer.hidden = false;
		#end
		if (Util.isTouchDevice()) {
			MarbleGame.instance.touchInput.setControlsEnabled(false);
		}
		this.setCursorLock(false);
		if (Net.isHost) {
			MarbleGame.instance.quitMission();
		}
		return 0;
	}

	function showFinishScreen() {
		if (this.isWatching)
			return 0;
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
		var finishScore = this.gameMode.getFinishScore();
		egg = new EndGameGui(finishScore.score, finishScore.type, (sender) -> {
			if (Util.isTouchDevice()) {
				MarbleGame.instance.touchInput.hideControls(@:privateAccess this.playGui.playGuiCtrl);
			}
			var endGameCode = () -> {
				this.dispose();
				var pmg = new PlayMissionGui();
				PlayMissionGui.currentSelectionStatic = mission.index + 1;
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
				this.restart(this.marble, true);
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
		}, mission, finishTime, this.replay.write());
		MarbleGame.canvas.pushDialog(egg);
		this.setCursorLock(false);
		return 0;
	}

	public function pickUpPowerUpReplay(powerupDtsPath:String) {
		if (powerupDtsPath == null)
			return false;
		if (this.marble.heldPowerup != null)
			if (this.marble.heldPowerup.dtsPath == powerupDtsPath)
				return false;

		this.playGui.setPowerupImage(powerupDtsPath);

		return true;
	}

	public function pickUpPowerUp(marble:Marble, powerUp:PowerUp) {
		if (powerUp == null)
			return false;
		if (marble.heldPowerup != null)
			if (marble.heldPowerup.identifier == powerUp.identifier)
				return false;
		Console.log("PowerUp pickup: " + powerUp.identifier);
		marble.heldPowerup = powerUp;
		if (@:privateAccess !marble.isNetUpdate)
			@:privateAccess marble.netFlags |= MarbleNetFlags.PickupPowerup;
		if (this.marble == marble) {
			this.playGui.setPowerupImage(powerUp.dtsPath);
			MarbleGame.instance.touchInput.powerupButton.setEnabled(true);
			if (this.isRecording) {
				this.replay.recordPowerupPickup(powerUp);
			}
		}
		return true;
	}

	public function deselectPowerUp(marble:Marble) {
		marble.heldPowerup = null;
		@:privateAccess marble.netFlags |= MarbleNetFlags.PickupPowerup;
		if (this.marble == marble) {
			this.playGui.setPowerupImage(null);
			MarbleGame.instance.touchInput.powerupButton.setEnabled(false);
		}
	}

	public function addBonusTime(t:Float) {
		this.bonusTime += t;
		this.collectedBonusTime += t;
		if (t > 0) {
			if (this.timeMultiplier > 0)
				this.playGui.addMiddleMessage('-${t}s', 0x99ff99);
			else
				this.playGui.addMiddleMessage('+${t}s', 0x99ff99);
		} else if (t < 0) {
			if (this.timeMultiplier > 0)
				this.playGui.addMiddleMessage('+${- t}s', 0xff9999);
			else
				this.playGui.addMiddleMessage('-${- t}s', 0xff9999);
		} else {
			this.playGui.addMiddleMessage('+0s', 0xcccccc);
		}
	}

	/** Starts (or restarts) the HUD countdown timer, e.g. from `CountdownStartTrigger`. */
	/** `icon` matches `CountdownStartTrigger`'s `icon` field (`server/scripts/triggers.cs` -
		a filename under `client/ui/game/countdown/`, default `"timerTimeTravel"`). */
	public function startCountdown(seconds:Float, icon:String = "timerTimeTravel") {
		this.countdownRemaining = seconds;
		this.countdownActive = seconds > 0;
		this.countdownIcon = icon;
		this.playGui.setCountdownThIcon(icon);
	}

	/** Stops the HUD countdown timer, e.g. from `CountdownStopTrigger`. */
	public function stopCountdown() {
		this.countdownActive = false;
		this.countdownRemaining = -1e8;
		this.playGui.formatCountdownThTimer(0);
	}

	/** Get the current interpolated orientation quaternion. */
	public function getOrientationQuat(time:Float) {
		if (this.oldOrientationQuat.lengthSq() == 0.0) {
			this.oldOrientationQuat = new Quat();
			// this.oldOrientationQuat.init(this.marble.currentUp.toPoint());
		}
		if (this.newOrientationQuat.lengthSq() == 0.0) {
			this.newOrientationQuat = new Quat();
			// this.newOrientationQuat.initNormal(this.marble.currentUp.toPoint());
		}
		if (time < this.orientationChangeTime)
			return this.oldOrientationQuat;
		if (time > this.orientationChangeTime + 0.3)
			return this.newOrientationQuat;
		var completion = Util.clamp((time - this.orientationChangeTime) / 0.3, 0, 1);
		var q = this.oldOrientationQuat.clone();
		q.slerp(q, this.newOrientationQuat, completion);
		return q;
	}

	public function setUp(marble:Marble, vec:Vector, timeState:TimeState, instant:Bool = false) {
		if (marble.currentUp == vec)
			return;
		if (isMultiplayer && Net.isHost) {
			@:privateAccess marble.netFlags |= MarbleNetFlags.GravityChange;
		}
		marble.currentUp = vec;
		if (marble == this.marble) {
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
				if (Math.abs(u.dot(v) + 1) < hxd.Math.EPSILON) {
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
	}

	public function goOutOfBounds(marble:Marble) {
		if (marble.outOfBounds || this.finishTime != null)
			return;
		// this.updateCamera(this.timeState); // Update the camera at the point of OOB-ing
		marble.outOfBounds = true;
		marble.outOfBoundsTime = this.timeState.clone();
		marble.camera.oob = true;
		if (!this.isWatching && !this.isMultiplayer) {
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
			if (Settings.optionsSettings.oobInsults)
				OOBInsultGui.OOBCheck();
		}
		// sky.follow = null;
		// this.oobCameraPosition = camera.position.clone();
		if (marble == this.marble) {
			playGui.setCenterText('outofbounds');
			if (@:privateAccess !this.marble.isNetUpdate)
				AudioManager.playSound(ResourceLoader.getResource('data/sound/whoosh.wav', ResourceLoader.getAudio, this.soundResources));
			// if (this.replay.mode != = 'playback')
			this.oobSchedule = this.schedule(this.timeState.currentAttemptTime + 2, () -> {
				playGui.setCenterText('none');
				return null;
			});
		}
		if (this.gameMode.onOutOfBounds(marble))
			return; // A mode (e.g. MadnessMode) took over entirely - no default restart.

		if (!this.isMultiplayer || Net.isHost) {
			marble.oobSchedule = this.schedule(this.timeState.currentAttemptTime + 2.5, () -> {
				this.restart(marble);
				return null;
			});
		}
	}

	/** Sets a new active checkpoint. */
	public function saveCheckpointState(shape:{obj:DtsObject, elem:MissionElementBase}, trigger:CheckpointTrigger = null) {
		if (this.currentCheckpoint != null)
			if (this.currentCheckpoint.obj == shape.obj)
				return;
		var disableOob = false;
		if (shape != null) {
			if (shape.elem.fields.exists('disableOob')) {
				disableOob = MisParser.parseBoolean(shape.elem.fields.get('disableOob')[0]);
			}
		}
		if (trigger != null) {
			disableOob = trigger.disableOOB;
		}
		// (shape.srcElement as any) ?.disableOob || trigger?.element.disableOob;
		if (disableOob && this.marble.outOfBounds)
			return; // The checkpoint is configured to not work when the player is already OOB
		this.currentCheckpoint = shape;
		this.currentCheckpointTrigger = trigger;
		this.checkpointCollectedGems.clear();
		this.checkpointUp = this.marble.currentUp.clone();
		this.cheeckpointBlast = this.marble.blastAmount;
		// Remember all gems that were collected up to this point
		for (gem in this.gems) {
			if (gem.pickedUp)
				this.checkpointCollectedGems.set(gem, true);
		}
		this.checkpointHeldPowerup = this.marble.heldPowerup;
		this.displayAlert("Checkpoint reached!");
		AudioManager.playPitchedSound("checkpoint", this.soundResources);
	}

	/** Resets to the last stored checkpoint state. */
	public function loadCheckpointState() {
		var marble = this.marble;
		// Determine where to spawn the marble
		var offset = new Vector(0, 0, 3);
		var add = ""; // (this.currentCheckpoint.srcElement as any)?.add || this.currentCheckpointTrigger?.element.add;
		if (this.currentCheckpoint.elem.fields.exists('add')) {
			add = this.currentCheckpoint.elem.fields.get('add')[0];
		}
		var sub = "";
		if (this.currentCheckpoint.elem.fields.exists('sub')) {
			sub = this.currentCheckpoint.elem.fields.get('sub')[0];
		}
		if (this.currentCheckpointTrigger != null) {
			if (this.currentCheckpointTrigger.add != null)
				offset = this.currentCheckpointTrigger.add;
		}
		if (add != "") {
			offset = MisParser.parseVector3(add);
			offset.x = -offset.x;
		}
		if (sub != "") {
			offset = MisParser.parseVector3(sub).multiply(-1);
			offset.x = -offset.x;
		}
		var mpos = this.currentCheckpoint.obj.getAbsPos().getPosition().add(offset);
		this.marble.setMarblePosition(mpos.x, mpos.y, mpos.z);
		marble.velocity.load(new Vector(0, 0, 0));
		marble.omega.load(new Vector(0, 0, 0));
		Console.log('Respawn:');
		Console.log('Marble Position: ${mpos.x} ${mpos.y} ${mpos.z}');
		Console.log('Marble Velocity: ${marble.velocity.x} ${marble.velocity.y} ${marble.velocity.z}');
		Console.log('Marble Angular: ${marble.omega.x} ${marble.omega.y} ${marble.omega.z}');
		// Set camera orientation
		var euler = this.currentCheckpoint.obj.getRotationQuat().toEuler();
		this.marble.camera.CameraYaw = euler.z + Math.PI / 2;
		this.marble.camera.CameraPitch = this.getDefaultCameraPitch();
		this.marble.camera.nextCameraYaw = this.marble.camera.CameraYaw;
		this.marble.camera.nextCameraPitch = this.marble.camera.CameraPitch;
		this.marble.camera.CameraDistance = this.getDefaultCameraDistance();
		this.marble.camera.oob = false;
		@:privateAccess this.marble.superBounceEnableTime = -1e8;
		@:privateAccess this.marble.shockAbsorberEnableTime = -1e8;
		@:privateAccess this.marble.helicopterEnableTime = -1e8;
		@:privateAccess this.marble.megaMarbleEnableTime = -1e8;
		this.marble.blastAmount = this.cheeckpointBlast;
		if (this.isRecording) {
			this.replay.recordCameraState(this.marble.camera.CameraYaw, this.marble.camera.CameraPitch);
			this.replay.recordMarbleInput(0, 0);
			this.replay.recordMarbleState(mpos, marble.velocity, marble.getRotationQuat(), marble.omega);
			this.replay.recordMarbleStateFlags(false, false, true, false);
		}
		var gravityField = ""; // (this.currentCheckpoint.srcElement as any) ?.gravity || this.currentCheckpointTrigger?.element.gravity;
		if (this.currentCheckpoint.elem.fields.exists('gravity')) {
			gravityField = this.currentCheckpoint.elem.fields.get('gravity')[0];
		}
		if (this.currentCheckpointTrigger != null) {
			if (@:privateAccess this.currentCheckpointTrigger.element.fields.exists('gravity')) {
				gravityField = @:privateAccess this.currentCheckpointTrigger.element.fields.get('gravity')[0];
			}
		}
		if (MisParser.parseBoolean(gravityField)) {
			// In this case, we set the gravity to the relative "up" vector of the checkpoint shape.
			var up = new Vector(0, 0, 1);
			up.transform(this.currentCheckpoint.obj.getRotationQuat().toMatrix());
			this.setUp(this.marble, up, this.timeState, true);
		} else {
			// Otherwise, we restore gravity to what was stored.
			this.setUp(this.marble, this.checkpointUp, this.timeState, true);
		}
		// Restore gem states
		for (gem in this.gems) {
			if (gem.pickedUp && !this.checkpointCollectedGems.exists(gem)) {
				gem.reset();
				this.gemCount--;
			}
		}
		this.playGui.formatGemCounter(this.gemCount, this.gemCounterTotal());
		this.playGui.setCenterText('none');
		this.clearSchedule();
		this.marble.outOfBounds = false;
		this.deselectPowerUp(this.marble); // Always deselect first
		// Wait a bit to select the powerup to prevent immediately using it incase the user skipped the OOB screen by clicking
		if (this.checkpointHeldPowerup != null)
			this.schedule(this.timeState.currentAttemptTime + 0.5, () -> this.pickUpPowerUp(this.marble, this.checkpointHeldPowerup));
		AudioManager.playPitchedSound("spawn", this.soundResources);
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

		if (this.playGui != null)
			this.playGui.dispose();
		scene.removeChildren();

		if (radar != null) {
			radar.dispose();
			radar = null;
		}

		CollisionPool.freeMemory();

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
		powerUps = null;
		explodables = null;
		trapdoors = null;
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
		gems = null;
		iceShards = null;

		if (sky != null)
			sky.dispose();
		sky = null;
		instanceManager = null;
		if (collisionWorld != null)
			collisionWorld.dispose();
		collisionWorld = null;
		particleManager = null;
		namedObjects = null;
		currentCheckpoint = null;
		checkpointCollectedGems = null;
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
