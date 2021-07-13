package src;

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

	var orientationChangeTime = -1e8;
	var oldOrientationQuat = new Quat();

	var resourceLoadFuncs:Array<Void->Void> = [];

	/** The new target camera orientation quat  */
	public var newOrientationQuat = new Quat();

	public var _disposed:Bool = false;

	public var _ready:Bool = false;

	var _loadingLength:Int = 0;

	public function new(scene:Scene, scene2d:h2d.Scene, mission:Mission) {
		this.scene = scene;
		this.scene2d = scene2d;
		this.mission = mission;
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
					MissionElementType.TSStatic
				].contains(element._type)) {
					// this.loadingState.total++;

					// Override the end pad element. We do this because only the last finish pad element will actually do anything.
					if (element._type == MissionElementType.StaticShape) {
						var so:MissionElementStaticShape = cast element;
						if (so.datablock.toLowerCase() == 'endpad')
							this.endPadElement = so;
					}
				} else if (element._type == MissionElementType.SimGroup) {
					scanMission(cast element);
				}
			}
		};

		this.resourceLoadFuncs.push(() -> {
			this.addSimGroup(this.mission.root);
			this._loadingLength = resourceLoadFuncs.length;
		});
		this.resourceLoadFuncs.push(() -> this.initMarble());
		this.resourceLoadFuncs.push(() -> this.initScene());
		this.resourceLoadFuncs.push(() -> scanMission(this.mission.root));
		this.resourceLoadFuncs.push(() -> this.mission.load());
		this._loadingLength = resourceLoadFuncs.length;
	}

	public function postInit() {
		this._ready = true;
		MarbleGame.canvas.clearContent();
		this.endPad.generateCollider();
		this.playGui.formatGemCounter(this.gemCount, this.totalGems);
		start();
	}

	public function initScene() {
		this.collisionWorld = new CollisionWorld();
		this.playGui = new PlayGui();
		this.instanceManager = new InstanceManager(scene);
		this.particleManager = new ParticleManager(cast this);

		// var renderer = cast(this.scene.renderer, h3d.scene.pbr.Renderer);

		// renderer.skyMode = Hide;

		for (element in mission.root.elements) {
			if (element._type != MissionElementType.Sun)
				continue;

			var sunElement:MissionElementSun = cast element;

			var directionalColor = MisParser.parseVector4(sunElement.color);
			var ambientColor = MisParser.parseVector4(sunElement.ambient);
			var sunDirection = MisParser.parseVector3(sunElement.direction);
			sunDirection.x = -sunDirection.x;
			// sunDirection.z = -sunDirection.z;

			scene.lightSystem.ambientLight.load(ambientColor);

			var shadow = scene.renderer.getPass(h3d.pass.DefaultShadowMap);
			shadow.power = 0.5;

			var sunlight = new DirLight(sunDirection, scene);
			sunlight.color = directionalColor;
		}

		// var skyElement:MissionElementSky = cast this.mission.root.elements.filter((element) -> element._type == MissionElementType.Sky)[0];

		this.sky = new Sky();
		sky.dmlPath = "data/skies/sky_day.dml";

		sky.init(cast this);
		playGui.init(scene2d);
		scene.addChild(sky);
	}

	public function initMarble() {
		var marble = new Marble();
		marble.controllable = true;
		this.addMarble(marble);
	}

	public function start() {
		restart();
		for (interior in this.interiors)
			interior.onLevelStart();
		for (shape in this.dtsObjects)
			shape.onLevelStart();
	}

	public function restart() {
		this.timeState.currentAttemptTime = 0;
		this.timeState.gameplayClock = 0;
		this.bonusTime = 0;
		this.outOfBounds = false;
		this.outOfBoundsTime = null;
		this.finishTime = null;
		this.helpTextTimeState = Math.NEGATIVE_INFINITY;
		this.alertTextTimeState = Math.NEGATIVE_INFINITY;
		if (this.endPad != null)
			this.endPad.inFinish = false;
		if (this.totalGems > 0) {
			this.gemCount = 0;
			this.playGui.formatGemCounter(this.gemCount, this.totalGems);
		}

		var startquat = this.getStartPositionAndOrientation();

		this.marble.setPosition(startquat.position.x, startquat.position.y, startquat.position.z + 3);
		this.marble.collider.transform.setPosition(startquat.position);
		this.marble.reset();

		var euler = startquat.quat.toEuler();
		this.marble.camera.init(cast this);
		this.marble.camera.CameraYaw = euler.z + Math.PI / 2;
		this.marble.camera.CameraPitch = 0.45;
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

		AudioManager.playSound(ResourceLoader.getAudio('data/sound/spawn.wav'));

		this.clearSchedule();
		this.schedule(0.5, () -> {
			// setCenterText('ready');
			AudioManager.playSound(ResourceLoader.getAudio('data/sound/ready.wav'));
			return 0;
		});
		this.schedule(2, () -> {
			// setCenterText('set');
			AudioManager.playSound(ResourceLoader.getAudio('data/sound/set.wav'));
			return 0;
		});
		this.schedule(3.5, () -> {
			// setCenterText('go');
			AudioManager.playSound(ResourceLoader.getAudio('data/sound/go.wav'));
			return 0;
		});

		return 0;
	}

	public function updateGameState() {
		if (this.timeState.currentAttemptTime < 0.5) {
			this.playGui.setCenterText('none');
		}
		if ((this.timeState.currentAttemptTime >= 0.5) && (this.timeState.currentAttemptTime < 2)) {
			this.playGui.setCenterText('ready');
		}
		if ((this.timeState.currentAttemptTime >= 2) && (this.timeState.currentAttemptTime < 3.5)) {
			this.playGui.setCenterText('set');
		}
		if ((this.timeState.currentAttemptTime >= 3.5) && (this.timeState.currentAttemptTime < 5.5)) {
			this.playGui.setCenterText('go');
			this.marble.mode = Play;
		}
		if (this.timeState.currentAttemptTime >= 5.5) {
			this.playGui.setCenterText('none');
		}
		if (this.outOfBounds) {
			this.playGui.setCenterText('outofbounds');
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
			resourceLoadFuncs.push(() -> {
				var pathedInterior = src.PathedInterior.createFromSimGroup(simGroup, cast this);
				this.addPathedInterior(pathedInterior);
				if (pathedInterior == null)
					return;

				// if (pathedInterior.hasCollision)
				// 	this.physics.addInterior(pathedInterior);
				for (trigger in pathedInterior.triggers) {
					this.triggers.push(trigger);
					this.collisionWorld.addEntity(trigger.collider);
				}
			});

			return;
		}

		for (element in simGroup.elements) {
			switch (element._type) {
				case MissionElementType.SimGroup:
					this.addSimGroup(cast element);
				case MissionElementType.InteriorInstance:
					resourceLoadFuncs.push(() -> this.addInteriorFromMis(cast element));
				case MissionElementType.StaticShape:
					resourceLoadFuncs.push(() -> this.addStaticShape(cast element));
				case MissionElementType.Item:
					resourceLoadFuncs.push(() -> this.addItem(cast element));
				case MissionElementType.Trigger:
					resourceLoadFuncs.push(() -> this.addTrigger(cast element));
				case MissionElementType.TSStatic:
					resourceLoadFuncs.push(() -> this.addTSStatic(cast element));
				case MissionElementType.ParticleEmitterNode:
					resourceLoadFuncs.push(() -> this.addParticleEmitterNode(cast element));
				default:
			}
		}
	}

	public function addInteriorFromMis(element:MissionElementInteriorInstance) {
		var difPath = this.mission.getDifPath(element.interiorfile);
		if (difPath == "")
			return;

		var interior = new InteriorObject();
		interior.interiorFile = difPath;
		// DifBuilder.loadDif(difPath, interior);
		// this.interiors.push(interior);
		this.addInterior(interior);

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

		var mat = new Matrix();
		interiorRotation.toMatrix(mat);
		mat.scale(interiorScale.x, interiorScale.y, interiorScale.z);
		mat.setPosition(interiorPosition);

		interior.setTransform(mat);

		// interior.setTransform(interiorPosition, interiorRotation, interiorScale);

		// this.scene.add(interior.group);
		// if (hasCollision)
		// 	this.physics.addInterior(interior);
	}

	public function addStaticShape(element:MissionElementStaticShape) {
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
		else if (dataBlockLowerCase == "oilslick")
			shape = new Oilslick();
		else {
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

		var mat = shapeRotation.toMatrix();
		mat.scale(shapeScale.x, shapeScale.y, shapeScale.z);
		mat.setPosition(shapePosition);

		this.addDtsObject(shape);

		shape.setTransform(mat);

		// else if (dataBlockLowerCase == "pushbutton")
		// 	shape = new PushButton();
	}

	public function addItem(element:MissionElementItem) {
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
		else if (dataBlockLowerCase == "oilslick")
			shape = new Oilslick();
		else {
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

		var mat = shapeRotation.toMatrix();
		mat.scale(shapeScale.x, shapeScale.y, shapeScale.z);
		mat.setPosition(shapePosition);

		this.addDtsObject(shape);

		shape.setTransform(mat);
	}

	public function addTrigger(element:MissionElementTrigger) {
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

		this.triggers.push(trigger);
		this.collisionWorld.addEntity(trigger.collider);
	}

	public function addTSStatic(element:MissionElementTSStatic) {
		// !! WARNING - UNTESTED !!
		var shapeName = element.shapename;
		var index = shapeName.indexOf('data/');
		if (index == -1)
			return;

		var tsShape = new DtsObject();
		tsShape.useInstancing = true;
		tsShape.dtsPath = shapeName.substring(index + 'data/'.length);

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

		var mat = shapeRotation.toMatrix();
		mat.scale(shapeScale.x, shapeScale.y, shapeScale.z);
		mat.setPosition(shapePosition);

		this.addDtsObject(tsShape);

		tsShape.setTransform(mat);
	}

	public function addParticleEmitterNode(element:MissionElementParticleEmitterNode) {
		// TODO THIS SHIT
	}

	public function addInterior(obj:InteriorObject) {
		this.interiors.push(obj);
		obj.init(cast this);
		this.collisionWorld.addEntity(obj.collider);
		if (obj.useInstancing)
			this.instanceManager.addObject(obj);
		else
			this.scene.addChild(obj);
	}

	public function addPathedInterior(obj:PathedInterior) {
		this.pathedInteriors.push(obj);
		obj.init(cast this);
		this.collisionWorld.addMovingEntity(obj.collider);
		if (obj.useInstancing)
			this.instanceManager.addObject(obj);
		else
			this.scene.addChild(obj);
	}

	public function addDtsObject(obj:DtsObject) {
		this.dtsObjects.push(obj);
		if (obj is ForceObject) {
			this.forceObjects.push(cast obj);
		}
		obj.init(cast this);
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
	}

	public function addMarble(marble:Marble) {
		this.marbles.push(marble);
		marble.level = cast this;
		if (marble.controllable) {
			marble.init(cast this);
			this.scene.addChild(marble.camera);
			this.marble = marble;
			// Ugly hack
			// sky.follow = marble;
			sky.follow = marble.camera;
		}
		this.collisionWorld.addMovingEntity(marble.collider);
		this.scene.addChild(marble);
	}

	public function update(dt:Float) {
		if (!_ready) {
			return;
		}
		this.updateTimer(dt);
		this.tickSchedule(timeState.currentAttemptTime);
		this.updateGameState();
		for (obj in dtsObjects) {
			obj.update(timeState);
		}
		for (marble in marbles) {
			marble.update(timeState, collisionWorld, this.pathedInteriors);
		}
		this.instanceManager.update(dt);
		this.particleManager.update(1000 * timeState.timeSinceLoad, dt);
		this.playGui.update(timeState);
		AudioManager.update(this.scene);

		if (this.outOfBounds && this.finishTime == null && Key.isPressed(Settings.controlsSettings.powerup)) {
			this.clearSchedule();
			this.restart();
			return;
		}

		this.updateTexts();
	}

	public function render(e:h3d.Engine) {
		if (!_ready)
			asyncLoadResources();
		if (this.playGui != null)
			this.playGui.render(e);
	}

	function asyncLoadResources() {
		if (this.resourceLoadFuncs.length != 0) {
			var func = this.resourceLoadFuncs.pop();
			func();
			this.loadingGui.setProgress((1 - resourceLoadFuncs.length / _loadingLength));
		} else {
			if (!_ready)
				postInit();
		}
	}

	public function updateTimer(dt:Float) {
		this.timeState.dt = dt;
		if (this.bonusTime != 0 && this.timeState.currentAttemptTime >= 3.5) {
			this.bonusTime -= dt;
			if (this.bonusTime < 0) {
				this.timeState.gameplayClock -= this.bonusTime;
				this.bonusTime = 0;
			}
			if (timeTravelSound == null) {
				var ttsnd = ResourceLoader.getAudio("data/sound/timetravelactive.wav");
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
		this.timeState.timeSinceLoad += dt;
		if (finishTime != null)
			this.timeState.gameplayClock = finishTime.gameplayClock;
		playGui.formatTimer(this.timeState.gameplayClock);
	}

	function updateTexts() {
		var helpTextTime = this.helpTextTimeState;
		var alertTextTime = this.alertTextTimeState;
		var helpTextCompletion = Math.pow(Util.clamp((this.timeState.currentAttemptTime - helpTextTime - 3), 0, 1), 2);
		var alertTextCompletion = Math.pow(Util.clamp((this.timeState.currentAttemptTime - alertTextTime - 3), 0, 1), 2);
		this.playGui.setHelpTextOpacity(1 - helpTextCompletion);
		this.playGui.setAlertTextOpacity(1 - alertTextCompletion);
	}

	public function displayAlert(text:String) {
		this.playGui.setAlertText(text);
		this.alertTextTimeState = this.timeState.currentAttemptTime;
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
		this.helpTextTimeState = this.timeState.currentAttemptTime;

		// TODO FIX
	}

	public function pickUpGem(gem:Gem) {
		this.gemCount++;
		var string:String;

		// Show a notification (and play a sound) based on the gems remaining
		if (this.gemCount == this.totalGems) {
			string = "You have all the gems, head for the finish!";
			// if (!this.rewinding)
			AudioManager.playSound(ResourceLoader.getAudio('data/sound/gotallgems.wav'));

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
			AudioManager.playSound(ResourceLoader.getAudio('data/sound/gotgem.wav'));
		}

		displayAlert(string);
		this.playGui.formatGemCounter(this.gemCount, this.totalGems);
	}

	public function callCollisionHandlers(marble:Marble, timeState:TimeState) {
		// var contacts = this.collisionWorld.radiusSearch(marble.getAbsPos().getPosition(), marble._radius);
		var contacts = marble.contactEntities;
		var newImmunity = [];
		var calledShapes = [];
		var inside = [];

		var contactsphere = new SphereCollisionEntity(marble);
		contactsphere.velocity = new Vector();

		var spherebounds = new Bounds();
		var center = marble.collider.transform.getPosition();
		var radius = marble._radius;
		spherebounds.addSpherePos(center.x, center.y, center.z, radius);

		var gjkSphere = new collision.gjk.Sphere();
		gjkSphere.position = center;
		gjkSphere.radius = radius;

		for (contact in contacts) {
			if (contact.go != marble) {
				if (contact.go is DtsObject) {
					var shape:DtsObject = cast contact.go;

					var contacttest = shape.colliders.filter(x -> x != null).map(x -> x.sphereIntersection(contactsphere, timeState));
					var contactlist:Array<collision.CollisionInfo> = [];
					for (l in contacttest) {
						contactlist = contactlist.concat(l);
					}

					if (!calledShapes.contains(shape) && !this.shapeImmunity.contains(shape) && contactlist.length != 0) {
						calledShapes.push(shape);
						newImmunity.push(shape);
						shape.onMarbleContact(timeState);
					}

					shape.onMarbleInside(timeState);
					if (!this.shapeOrTriggerInside.contains(contact.go)) {
						this.shapeOrTriggerInside.push(contact.go);
						shape.onMarbleEnter(timeState);
					}
					inside.push(contact.go);
				}
				if (contact.go is Trigger) {
					var trigger:Trigger = cast contact.go;
					var triggeraabb = trigger.collider.boundingBox;

					if (triggeraabb.collide(spherebounds)) {
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
			if (spherebounds.collide(this.endPad.finishBounds)) {
				if (collision.gjk.GJK.gjk(gjkSphere, this.endPad.finishCollider) != null) {
					if (!endPad.inFinish) {
						touchFinish();
						endPad.inFinish = true;
					}
				} else {
					if (endPad.inFinish)
						endPad.inFinish = false;
				}
			}
		}
		this.shapeImmunity = newImmunity;
	}

	function touchFinish() {
		if (this.finishTime != null
			|| (this.outOfBounds && this.timeState.currentAttemptTime - this.outOfBoundsTime.currentAttemptTime >= 0.5))
			return;

		if (this.gemCount < this.totalGems) {
			AudioManager.playSound(ResourceLoader.getAudio('data/sound/missinggems.wav'));
			displayAlert("You can't finish without all the gems!!");
		} else {
			this.endPad.spawnFirework(this.timeState);
			this.finishTime = this.timeState.clone();
			this.marble.mode = Finish;
			this.marble.camera.finish = true;
			this.finishYaw = this.marble.camera.CameraYaw;
			this.finishPitch = this.marble.camera.CameraPitch;
			displayAlert("Congratulations! You've finished!");
			this.schedule(this.timeState.currentAttemptTime + 2, () -> cast showFinishScreen());
		}
	}

	function showFinishScreen() {
		var egg:EndGameGui = null;
		egg = new EndGameGui((sender) -> {
			this.dispose();
			MarbleGame.canvas.setContent(new PlayMissionGui());
		}, (sender) -> {
			MarbleGame.canvas.popDialog(egg);
			this.setCursorLock(true);
			this.restart();
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
		return true;
	}

	public function deselectPowerUp() {
		this.marble.heldPowerup = null;
		this.playGui.setPowerupImage("");
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
		AudioManager.playSound(ResourceLoader.getAudio('data/sound/whoosh.wav'));
		// if (this.replay.mode != = 'playback')
		this.schedule(this.timeState.currentAttemptTime + 2, () -> this.restart());
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

	public function dispose() {
		this.playGui.dispose();
		scene.removeChildren();
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
