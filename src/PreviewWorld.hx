package src;

import collision.CollisionWorld;
import mis.MissionElement.MissionElementSky;
import shapes.Astrolabe;
import src.Sky;
import h3d.Vector;
import h3d.Quat;
import mis.MissionElement.MissionElementSpawnSphere;
import h3d.mat.Material;
import shaders.DirLight;
import mis.MissionElement.MissionElementSun;
import shapes.Glass;
import shapes.MegaMarble;
import shapes.Checkpoint;
import shapes.EasterEgg;
import Macros.MarbleWorldMacros;
import mis.MissionElement.MissionElementStaticShape;
import mis.MissionElement.MissionElementInteriorInstance;
import src.InteriorObject;
import src.InstanceManager;
import mis.MissionElement.MissionElementSimGroup;
import mis.MisFile;
import mis.MisParser;
import src.ResourceLoader;
import src.Mission;
import h3d.scene.Scene;
import src.MarbleWorld.Scheduler;
import src.Util;
import h3d.Matrix;
import src.ResourceLoaderWorker;
import src.DtsObject;
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
import shapes.PowerUp;
import shapes.Blast;
import src.Console;
import src.TimeState;
import src.MissionList;
import src.Settings;
import src.Marble;

class PreviewWorld extends Scheduler {
	var scene:Scene;
	var instanceManager:InstanceManager;
	var collisionWorld:CollisionWorld;

	var misFile:MisFile;
	var currentMission:String;

	var levelGroups:Map<String, MissionElementSimGroup> = [];

	public var timeState:TimeState = new TimeState();

	var interiors:Array<InteriorObject> = [];
	var dtsObjects:Array<DtsObject> = [];
	var marbles:Array<Marble> = [];

	var sky:Sky;

	var itrAddTime:Float = 0;

	var _loadToken = 0;

	public function new(scene:Scene) {
		this.scene = scene;
	}

	public function init(onFinish:() -> Void) {
		var entry = ResourceLoader.getFileEntry("data/missions/megaMission.mis").entry;
		var misText = entry.getText();
		var mparser = new MisParser(misText);
		misFile = mparser.parse();

		// Parse the mis file and get the simgroups of each levels
		for (elem in misFile.root.elements) {
			if (elem._type == SimGroup)
				levelGroups.set(elem._name.toLowerCase(), cast elem);
		}

		initScene();
		onFinish();
	}

	function initScene() {
		for (element in misFile.root.elements) {
			if (element._type != Sun)
				continue;

			var sunElement:MissionElementSun = cast element;

			var directionalColor = MisParser.parseVector4(sunElement.color);
			var ambientColor = MisParser.parseVector4(sunElement.ambient);
			ambientColor.r *= 1.18;
			ambientColor.g *= 1.06;
			ambientColor.b *= 0.95;
			var sunDirection = MisParser.parseVector3(sunElement.direction);
			sunDirection.x = -sunDirection.x;
			// sunDirection.x = 0;
			// sunDirection.y = 0;
			// sunDirection.z = -sunDirection.z;
			var ls = cast(scene.lightSystem, h3d.scene.fwd.LightSystem);

			ls.ambientLight.load(ambientColor);
			// ls.shadowLight.setDirection(new Vector(0, 0, -1));
			// ls.perPixelLighting = false;

			var shadow = scene.renderer.getPass(h3d.pass.DefaultShadowMap);
			shadow.power = 1;
			shadow.mode = Dynamic;
			shadow.minDist = 0.1;
			shadow.maxDist = 200;
			shadow.bias = 0;

			var sunlight = new DirLight(sunDirection, scene);
			sunlight.color = directionalColor;
			return;
		}
	}

	public function loadMission(misname:String, onFinish:() -> Void, physics:Bool = false) {
		if (currentMission == misname) {
			onFinish();
			return;
		}
		_loadToken++;
		var groupName = (misname + "group").toLowerCase();
		var group = levelGroups.get(groupName);
		if (group != null) {
			destroyAllObjects();
			this.currentMission = misname;
			this.instanceManager = new InstanceManager(scene);
			if (physics)
				this.collisionWorld = new CollisionWorld();
			else
				this.collisionWorld = null;

			var p = new h3d.prim.Cube(0.001, 0.001, 0.001);
			p.addUVs();
			p.addTangents();
			var mat = Material.create();
			var m = new h3d.scene.Mesh(p, mat, scene);

			var itrpaths = [];
			var shapeDbs = [];
			for (elem in group.elements) {
				if (elem._type == InteriorInstance) {
					var itrElem:MissionElementInteriorInstance = cast elem;
					itrpaths.push(itrElem);
				}
				if (elem._type == StaticShape) {
					var shapeElem:MissionElementStaticShape = cast elem;
					shapeDbs.push(shapeElem);
				}
				if (elem._type == SpawnSphere) {
					var shapeElem:MissionElementSpawnSphere = cast elem;
					if (shapeElem.datablock.toLowerCase() == 'cameraspawnspheremarker') {
						// Set camera position
						var camPos = MisParser.parseVector3(shapeElem.position);
						camPos.x *= -1;
						var camRot = MisParser.parseRotation(shapeElem.rotation);
						camRot.x *= -1;
						camRot.w *= -1;

						var camMat = camRot.toMatrix();

						var off = new Vector(0, 0, 1.5);
						off.transform3x3(camMat);

						var directionVector = new Vector(0, 1, 0);
						directionVector.transform3x3(camMat);

						scene.camera.setFovX(90, Settings.optionsSettings.screenWidth / Settings.optionsSettings.screenHeight);

						scene.camera.up.set(0, 0, 1);
						scene.camera.pos.load(camPos.add(off));
						scene.camera.target.load(scene.camera.pos.add(directionVector));
					}
				}
			}

			var difficulty = "beginner";
			var mis = MissionList.missionsFilenameLookup.get((misname + '.mis').toLowerCase());
			if (misname == "marblepicker")
				difficulty = "advanced";
			else
				difficulty = ["beginner", "intermediate", "advanced"][mis.difficultyIndex];

			var curToken = _loadToken;

			var worker = new ResourceLoaderWorker(onFinish);

			worker.addTask(fwd -> {
				if (_loadToken != curToken)
					fwd();
				else
					addScenery(difficulty, fwd);
			});
			itrAddTime = 0;
			for (elem in itrpaths) {
				worker.addTask(fwd -> {
					if (_loadToken != curToken)
						fwd();
					else {
						var startTime = Console.time();
						addInteriorFromMis(cast elem, curToken, () -> {
							itrAddTime += Console.time() - startTime;
							fwd();
						}, physics);
					}
				});
			}
			for (elem in shapeDbs) {
				worker.addTask(fwd -> {
					if (_loadToken != curToken)
						fwd();
					else
						addStaticShape(cast elem, curToken, fwd);
				});
			}
			worker.addTask(fwd -> {
				timeState.timeSinceLoad = 0;
				timeState.dt = 0;
				Console.log('ITR ADD TIME: ' + itrAddTime);
				fwd();
			});
			worker.run();
		} else {
			onFinish();
		}
	}

	function addScenery(difficulty:String, onFinish:() -> Void) {
		var worker = new ResourceLoaderWorker(onFinish);
		var astrolabe = new Astrolabe();
		astrolabe.setPosition(0, 0, -612.988);
		worker.addTask(fwd -> {
			astrolabe.init(null, () -> {
				scene.addChild(astrolabe);
				dtsObjects.push(astrolabe);
				fwd();
			});
		});
		var clouds = new shapes.Sky('astrolabeclouds' + difficulty + 'shape');
		worker.addTask(fwd -> {
			clouds.init(null, () -> {
				scene.addChild(clouds);
				fwd();
			});
		});

		var skyElem = new MissionElementSky();
		skyElem.fogcolor = "0.600000 0.600000 0.600000 1.000000";
		skyElem.skysolidcolor = "0.600000 0.600000 0.600000 1.000000";

		var skyDml = "data/skies/sky_" + difficulty + '.dml';

		sky = new Sky();
		sky.dmlPath = ResourceLoader.getProperFilepath(skyDml);
		worker.addTask(fwd -> {
			sky.init(null, () -> {
				scene.addChild(sky);
				fwd();
			}, skyElem);
		});

		worker.run();
	}

	public function destroyAllObjects() {
		currentMission = null;
		collisionWorld = null;
		for (itr in interiors) {
			itr.dispose();
		}
		for (shape in dtsObjects) {
			shape.dispose();
		}
		for (marb in marbles) {
			marb.dispose();
		}
		interiors = [];
		dtsObjects = [];
		marbles = [];
		scene.removeChildren();
	}

	public function addInteriorFromMis(element:MissionElementInteriorInstance, token:Int, onFinish:Void->Void, physics:Bool = false) {
		var difPath = getDifPath(element.interiorfile);
		if (difPath == "" || token != _loadToken) {
			onFinish();
			return;
		}
		Console.log('Adding interior: ${difPath}');
		var interior = new InteriorObject();
		interior.interiorFile = difPath;
		interior.isCollideable = physics;
		// DifBuilder.loadDif(difPath, interior);
		// this.interiors.push(interior);
		this.addInterior(interior, token, () -> {
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
			interior.isCollideable = hasCollision && physics;
			onFinish();
		}, physics);
	}

	function addInterior(obj:InteriorObject, token:Int, onFinish:Void->Void, physics:Bool = false) {
		if (token != _loadToken) {
			onFinish();
			return;
		}
		this.interiors.push(obj);
		obj.init(null, () -> {
			if (token != _loadToken) {
				onFinish();
				return;
			}
			if (obj.useInstancing)
				this.instanceManager.addObject(obj);
			else
				this.scene.addChild(obj);
			if (physics) {
				this.collisionWorld.addEntity(obj.collider);
				obj.collisionWorld = this.collisionWorld;
			}
			onFinish();
		});
	}

	public function addStaticShape(element:MissionElementStaticShape, token:Int, onFinish:Void->Void) {
		if (token != _loadToken) {
			onFinish();
			return;
		}
		var shape:DtsObject = null;

		// Add the correct shape based on type
		var dataBlockLowerCase = element.datablock.toLowerCase();
		if (dataBlockLowerCase == "") {} // Make sure we don't do anything if there's no data block
		else if (dataBlockLowerCase == "startpad")
			shape = new StartPad();
		else if (dataBlockLowerCase == "endpad") {
			shape = new EndPad();
		} else if (StringTools.startsWith(dataBlockLowerCase, "arrow"))
			shape = new SignPlain(cast element);
		else if (StringTools.startsWith(dataBlockLowerCase, "gemitem")) {
			shape = new Gem(cast element);
		} else if (dataBlockLowerCase == "superjumpitem")
			shape = new SuperJump(cast element);
		else if (StringTools.startsWith(dataBlockLowerCase, "signcaution"))
			shape = new SignCaution(cast element);
		else if (dataBlockLowerCase == "roundbumper")
			shape = new RoundBumper();
		else if (dataBlockLowerCase == "helicopteritem")
			shape = new Helicopter(cast element);
		else if (dataBlockLowerCase == "eastereggitem")
			shape = new EasterEgg(cast element);
		else if (dataBlockLowerCase == "checkpointshape") {
			shape = new Checkpoint(cast element);
		} else if (dataBlockLowerCase == "ductfan")
			shape = new DuctFan();
		else if (dataBlockLowerCase == "smallductfan")
			shape = new SmallDuctFan();
		else if (dataBlockLowerCase == "antigravityitem")
			shape = new AntiGravity(cast element);
		else if (dataBlockLowerCase == "norespawnantigravityitem")
			shape = new AntiGravity(cast element, true);
		else if (dataBlockLowerCase == "superspeeditem")
			shape = new SuperSpeed(cast element);
		else if (dataBlockLowerCase == "timetravelitem" || dataBlockLowerCase == "timepenaltyitem")
			shape = new TimeTravel(cast element);
		else if (dataBlockLowerCase == "blastitem")
			shape = new Blast(cast element);
		else if (dataBlockLowerCase == "megamarbleitem")
			shape = new MegaMarble(cast element);
		else if (dataBlockLowerCase == "trapdoor")
			shape = new Trapdoor();
		else if ([
			"glass_3shape",
			"glass_6shape",
			"glass_9shape",
			"glass_12shape",
			"glass_15shape",
			"glass_18shape"
		].contains(dataBlockLowerCase))
			shape = new Glass(cast element);
		else if ([
			"astrolabecloudsbeginnershape",
			"astrolabecloudsintermediateshape",
			"astrolabecloudsadvancedshape"
		].contains(dataBlockLowerCase))
			shape = new shapes.Sky(dataBlockLowerCase);
		else if (dataBlockLowerCase == "astrolabeshape")
			shape = new shapes.Astrolabe();
		else {
			Console.error("Unknown item: " + element.datablock);
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

		shape.isCollideable = false;
		shape.isBoundingBoxCollideable = false;

		this.addDtsObject(shape, token, () -> {
			if (token != _loadToken) {
				onFinish();
				return;
			}
			shape.setTransform(mat);
			onFinish();
		});
	}

	public function addDtsObject(obj:DtsObject, token:Int, onFinish:Void->Void, isTsStatic:Bool = false) {
		if (token != _loadToken) {
			onFinish();
			return;
		}
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
			if (token != _loadToken) {
				onFinish();
				return;
			}
			var dtsFile = ResourceLoader.loadDts(obj.dtsPath);
			var texToLoad = obj.getPreloadMaterials(dtsFile.resource);

			var worker = new ResourceLoaderWorker(() -> {
				obj.isTSStatic = isTsStatic;
				this.dtsObjects.push(obj);
				obj.init(null, () -> {
					if (token != _loadToken) {
						onFinish();
						return;
					}
					obj.update(this.timeState);
					if (obj.useInstancing) {
						this.instanceManager.addObject(obj);
					} else
						this.scene.addChild(obj);

					onFinish();
				});
			});

			for (texPath in texToLoad) {
				worker.loadFile(texPath);
			}

			worker.run();
		});
	}

	function getDifPath(rawElementPath:String) {
		if (StringTools.contains(rawElementPath, "$usermods")) {
			rawElementPath = rawElementPath.split("@").slice(1).map(x -> {
				var a = StringTools.trim(x);
				a = Util.unescape(a.substr(1, a.length - 2));
				return a;
			}).join('');
		}
		var fname = rawElementPath.substring(rawElementPath.lastIndexOf('/') + 1);
		rawElementPath = rawElementPath.toLowerCase();
		if (StringTools.startsWith(rawElementPath, "./")) {
			rawElementPath = rawElementPath.substring(2);
			rawElementPath = 'data/missions/' + rawElementPath;
		}
		var path = StringTools.replace(rawElementPath.substring(rawElementPath.indexOf('data/')), "\"", "");
		#if (js || android)
		path = StringTools.replace(path, "data/", "");
		#end
		if (!StringTools.endsWith(path, ".dif"))
			path += ".dif";
		if (ResourceLoader.exists(path))
			return path;
		if (StringTools.contains(path, 'interiors_mbg/'))
			path = StringTools.replace(path, 'interiors_mbg/', 'interiors/');
		var dirpath = path.substring(0, path.lastIndexOf('/') + 1);
		if (ResourceLoader.exists(path))
			return path;
		if (ResourceLoader.exists(dirpath + fname))
			return dirpath + fname;
		path = StringTools.replace(path, "lbinteriors", "interiors"); // This shit ew
		if (ResourceLoader.exists(path))
			return path;
		Console.error("Interior resource not found: " + rawElementPath);
		return "";
	}

	public function spawnMarble(onFinish:Marble->Void) {
		var marb = new Marble();
		marb.controllable = false;
		marb.init(null, () -> {
			marb.collisionWorld = this.collisionWorld;
			this.collisionWorld.addMovingEntity(marb.collider);
			this.scene.addChild(marb);
			this.marbles.push(marb);
			onFinish(marb);
		});
	}

	public function removeMarble(marb:Marble) {
		if (this.marbles.remove(marb)) {
			this.scene.removeChild(marb);
			this.collisionWorld.removeMovingEntity(marb.collider);
			marb.dispose();
		}
	}

	public function update(dt:Float) {
		timeState.dt = dt;
		timeState.timeSinceLoad += dt;
		for (dts in dtsObjects) {
			dts.update(timeState);
		}
		for (marb in marbles) {
			marb.update(timeState, this.collisionWorld, []);
		}
		this.instanceManager.render();
	}

	public function render(e:h3d.Engine) {
		for (marble in marbles) {
			if (marble != null && marble.cubemapRenderer != null) {
				marble.cubemapRenderer.position.load(marble.getAbsPos().getPosition());
				marble.cubemapRenderer.render(e, 0.002);
			}
		}
	}
}
