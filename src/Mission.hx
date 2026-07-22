package src;

import mis.MissionElement.MissionElementSpawnSphere;
import h3d.Vector;
import mis.MissionElement.MissionElementTrigger;
import shapes.Checkpoint;
import mis.MissionElement.MissionElementStaticShape;
import mis.MissionElement.MissionElementSky;
import src.Http.HttpRequest;
import gui.Canvas;
import gui.MessageBoxOkDlg;
import haxe.Json;
import mis.MissionElement.MissionElementItem;
import haxe.io.BytesBuffer;
import h2d.Tile;
import hxd.BitmapData;
import mis.MisParser;
import mis.MissionElement.MissionElementScriptObject;
import mis.MissionElement.MissionElementType;
import mis.MisFile;
import mis.MissionElement.MissionElementSimGroup;
import src.ResourceLoader;
import hxd.res.Image;
import src.Resource;
import src.Util;
import src.Console;
import src.Marbleland;
import src.MarbleGame;
import src.Http;
import src.MPCustoms;

class Mission {
	public var root:MissionElementSimGroup;
	public var title:String;
	public var artist:String;
	public var description:String;
	public var qualifyTime = Math.POSITIVE_INFINITY;
	public var goldTime:Float = 0;
	public var ultimateTime:Float = 0;
	public var type:String;
	public var path:String;
	public var missionInfo:MissionElementScriptObject;
	public var index:Int;
	public var difficultyIndex:Int;
	public var id:Int;
	public var isClaMission:Bool;
	public var game:String;
	public var hasEgg:Bool;
	public var isCustom:Bool;
	public var marbleAttributes:Map<String, String>;
	public var customSource:String; // Marbleland or MPCustom
	public var gameMode:String;

	var next:Mission;

	var imageResources:Array<Resource<Image>> = [];

	var imgFileEntry:hxd.fs.FileEntry;

	#if sys
	static var _previewRequest:HttpRequest;
	#else
	static var _previewRequest:Int;
	#end
	static var _previewCache:Map<Mission, h2d.Tile> = [];

	public function new() {}

	public function load() {
		var entry = ResourceLoader.getFileEntry(this.path).entry;
		var misText = Util.toASCII(entry.getBytes());

		var misParser = new MisParser(misText);
		var contents = misParser.parse();
		root = contents.root;
		marbleAttributes = contents.marbleAttributes;

		function scanMission(simGroup:MissionElementSimGroup) {
			for (element in simGroup.elements) {
				if (this.hasEgg)
					break;
				if (element._type == MissionElementType.Item) {
					var so:MissionElementItem = cast element;
					if (so.datablock.toLowerCase() == 'easteregg')
						this.hasEgg = true;
				} else if (element._type == MissionElementType.SimGroup && !this.hasEgg) {
					scanMission(cast element);
				}
				if (element._name == 'MissionInfo')
					missionInfo = cast element;
			}
		};

		scanMission(root); // Scan for egg
		if (this.isClaMission)
			postProcessFromMarbleland();

		if (this.customSource == "MPCustoms") {
			// Fill the few details from missionInfo
			if (missionInfo.time != null && missionInfo.time != "0")
				this.qualifyTime = MisParser.parseNumber(missionInfo.time) / 1000;
			if (missionInfo.goldtime != null) {
				this.goldTime = MisParser.parseNumber(missionInfo.goldtime) / 1000;
			}
			this.type = missionInfo.type.toLowerCase();
		}
	}

	public function dispose() {
		for (imageResource in imageResources) {
			imageResource.release();
		}
	}

	public static function fromMissionInfo(path:String, mInfo:MissionElementScriptObject) {
		var mission = new Mission();
		mission.path = path;
		mission.missionInfo = mInfo;

		var missionInfo = mInfo;

		mission.title = missionInfo.name;
		mission.artist = missionInfo.artist == null ? '' : missionInfo.artist;
		mission.description = missionInfo.desc == null ? '' : missionInfo.desc;
		if (missionInfo.time != null && missionInfo.time != "0")
			mission.qualifyTime = MisParser.parseNumber(missionInfo.time) / 1000;
		if (missionInfo.goldtime != null) {
			mission.goldTime = MisParser.parseNumber(missionInfo.goldtime) / 1000;
		}
		if (missionInfo.ultimatetime != null) {
			mission.ultimateTime = MisParser.parseNumber(missionInfo.ultimatetime) / 1000;
		}
		mission.type = missionInfo.type.toLowerCase();
		mission.missionInfo = missionInfo;
		return mission;
	}

	public function toJSON() {
		return Json.stringify({
			artist: this.artist,
			description: this.description,
			goldTime: this.goldTime,
			ultimateTime: this.ultimateTime,
			qualifyTime: this.qualifyTime,
			hasEgg: this.hasEgg,
			title: this.title,
			type: this.type,
			path: this.path,
		});
	}

	public static function fromJSON(jsonData:String) {
		var jdata = Json.parse(jsonData);
		var mission = new Mission();
		mission.artist = jdata.artist;
		mission.description = jdata.description;
		mission.goldTime = jdata.goldTime;
		mission.ultimateTime = jdata.ultimateTime;
		mission.qualifyTime = jdata.qualifyTime;
		mission.hasEgg = jdata.hasEgg;
		mission.title = jdata.title;
		mission.type = jdata.type;
		mission.path = jdata.path;
		return mission;
	}

	public function getNextMission() {
		return this.next;
	}

	public function getPreviewImage(onLoaded:h2d.Tile->Void) {
		if (!this.isClaMission) {
			var basename = haxe.io.Path.withoutExtension(this.path);
			if (ResourceLoader.fileSystem.exists(basename + ".png")) {
				imgFileEntry = ResourceLoader.fileSystem.get(basename + ".png");
				#if hl
				var ret = ResourceLoader.getResource(basename + ".png", ResourceLoader.getImage, this.imageResources).toTile();
				onLoaded(ret);
				#end
				#if js
				imgFileEntry.load(() -> {
					var ret = ResourceLoader.getResource(basename + ".png", ResourceLoader.getImage, this.imageResources).toTile();
					onLoaded(ret);
				});
				#end
				return imgFileEntry.path;
			}
			if (ResourceLoader.fileSystem.exists(basename + ".jpg")) {
				imgFileEntry = ResourceLoader.fileSystem.get(basename + ".jpg");
				#if hl
				var ret = ResourceLoader.getResource(basename + ".jpg", ResourceLoader.getImage, this.imageResources).toTile();
				onLoaded(ret);
				#end
				#if js
				imgFileEntry.load(() -> {
					var ret = ResourceLoader.getResource(basename + ".jpg", ResourceLoader.getImage, this.imageResources).toTile();
					onLoaded(ret);
				});
				#end
				return imgFileEntry.path;
			}
			Console.error("Preview image not found for " + this.path);
			var img = new BitmapData(1, 1);
			img.setPixel(0, 0, 0);
			onLoaded(Tile.fromBitmap(img));
			return null;
		} else {
			if (_previewRequest != null #if sys && !_previewRequest.fulfilled #end) {
				Http.cancel(_previewRequest); // Cancel the previous request to save dequeing
			}
			if (_previewCache.exists(this)) {
				var t = _previewCache.get(this);
				onLoaded(t);
				return t.getTexture().name;
			}
			_previewRequest = Marbleland.getMissionImage(this.id, (im) -> {
				if (im != null) {
					var t = im.toTile();
					_previewCache.set(this, t);
					onLoaded(t);
				} else {
					Console.error("Preview image not found for " + this.path);
					var img = new BitmapData(1, 1);
					img.setPixel(0, 0, 0);
					onLoaded(Tile.fromBitmap(img));
				}
			});

			return null;
		}
	}

	public function getDifPath(rawElementPath:String) {
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
			rawElementPath = haxe.io.Path.directory(this.path) + '/' + rawElementPath;
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
		if (game == 'gold') {
			path = StringTools.replace(path, 'interiors/', 'interiors_mbg/');
			if (ResourceLoader.exists(path))
				return path;
		}
		path = StringTools.replace(path, "lbinteriors", "interiors"); // This shit ew
		if (ResourceLoader.exists(path))
			return path;
		Console.error("Interior resource not found: " + rawElementPath);
		return "";
	}

	public function download(onFinish:Void->Void) {
		if (this.isClaMission) {
			if (this.customSource == "Marbleland") {
				Marbleland.download(this.id, (zipEntries) -> {
					if (zipEntries != null) {
						ResourceLoader.loadZip(zipEntries, '');
						onFinish();
					} else {
						MarbleGame.canvas.pushDialog(new MessageBoxOkDlg("Failed to download mission"));
					}
				});
			}
			if (this.customSource == "MPCustoms") {
				MPCustoms.download({
					id: this.id,
					title: this.title,
					path: this.path,
					description: this.description,
					artist: this.artist
				}, () -> {
					onFinish();
				}, () -> {
					MarbleGame.canvas.pushDialog(new MessageBoxOkDlg("Failed to download mission"));
				});
			}
		}
	}

	function postProcessFromMarbleland() {
		// Since the mission is from Marbleland, we must postprocess it to port it to MBU formats.

		var skyEl:MissionElementSky = null;
		var skyMaterialList = null;

		var processFunctions = [];
		var cloudType = "none";

		var hasAstrolabe = false;

		var isHunt = false;

		if (missionInfo.gamemode != null && missionInfo.gamemode == "hunt") {
			missionInfo.gamemode = "scrum";
			isHunt = true;
		}

		function postprocessMission(simGroup:MissionElementSimGroup) {
			for (element in simGroup.elements) {
				if (element._type == MissionElementType.Sky) {
					// Change the sky!!
					skyEl = cast(element, MissionElementSky);

					var skyMaterial = skyEl.materiallist.toLowerCase();
					switch (skyMaterial) {
						case "~/data/skies/cloudy/cloudy.dml" | "~/data/skies/mbu/sky_beginner.dml" | "~/data/skies_mbu/beginner/sky_beginner.dml":
							skyMaterialList = "~/data/skies/sky_beginner.dml";
							cloudType = "beginner";

						case "~/data/skies/mbu/sky_intermediate.dml" | "~/data/skies_mbu/intermediate/sky_intermediate.dml":
							skyMaterialList = "~/data/skies/sky_intermediate.dml";
							cloudType = "intermediate";

						case "~/data/skies/mbu/sky_advanced.dml" | "~/data/skies_mbu/advanced/sky_advanced.dml":
							skyMaterialList = "~/data/skies/sky_advanced.dml";
							cloudType = "advanced";
					}
				}
				if (element._type == MissionElementType.Trigger) {
					var trigger = cast(element, MissionElementTrigger);
					var db = trigger.datablock.toLowerCase();
					switch (db) {
						case "spawntrigger":
							// replace this with a spawnsphere entity
							var sg = simGroup;
							processFunctions.push(() -> {
								sg.elements.remove(trigger);
								var spawnSphereEl = new MissionElementSpawnSphere();
								spawnSphereEl._name = trigger._name;
								spawnSphereEl.position = trigger.position;
								spawnSphereEl.rotation = trigger.rotation;
								spawnSphereEl.scale = trigger.scale;
								spawnSphereEl.datablock = "spawnspheremarker";
								spawnSphereEl.fields = [];
								sg.elements.push(spawnSphereEl);
							});
					}
				}
				if (element._type == MissionElementType.StaticShape) {
					var ss = cast(element, MissionElementStaticShape);

					var db = ss.datablock.toLowerCase();
					switch (db) {
						case "clear":
							skyMaterialList = "~/data/skies/sky_beginner.dml";
							cloudType = "beginner";

						case "dusk":
							skyMaterialList = "~/data/skies/sky_intermediate.dml";
							cloudType = "intermediate";

						case "wintry":
							skyMaterialList = "~/data/skies/sky_advanced.dml";
							cloudType = "advanced";

						case "astrolabe":
							hasAstrolabe = true;

						case "glass_3shape" | "glass_6shape" | "glass_9shape" | "glass_12shape" | "glass_15shape" | "glass_18shape":
							var pos = MisParser.parseVector3(ss.position);
							var rot = MisParser.parseRotation(ss.rotation);

							var quat = new h3d.Quat();
							quat.initRotateAxis(0, 0, 1, Math.PI / 2);
							rot.multiply(rot, quat);

							var offset = new Vector(-3, -0.25, 0);
							offset.transform3x3(rot.toMatrix());
							pos.load(pos.sub(offset));
							ss.position = '${pos.x} ${pos.y} ${pos.z}';

							var angle = 2 * Math.acos(rot.w);
							var s = Math.sqrt(1 - rot.w * rot.w);
							var x, y, z;
							if (s < 0.001) {
								x = rot.x;
								y = rot.y;
								z = rot.z;
							} else {
								x = rot.x / s;
								y = rot.y / s;
								z = rot.z / s;
							}
							angle = (angle * -180.0 / Math.PI) % 360.0;
							ss.rotation = '${x} ${y} ${z} ${angle}';

						case "checkpoint" | "checkpoint_mbu":
							// need to make a new simgroup for this checkpoint, and move the triggers that affect it into that simgroup
							var sg = simGroup;
							processFunctions.push(() -> {
								// First remove this element
								sg.elements.remove(ss);
								// Then add add the actual checkpoint shape
								var checkpointEl = new MissionElementStaticShape();
								checkpointEl._name = ss._name;
								checkpointEl.position = ss.position;
								checkpointEl.rotation = ss.rotation;
								checkpointEl.scale = ss.scale;
								checkpointEl.datablock = "checkPointShape";
								checkpointEl.fields = [];

								// create new simgroup
								var checkpointSG = new MissionElementSimGroup();
								checkpointSG._name = null;
								checkpointSG.elements = [];
								checkpointSG.elements.push(checkpointEl);
								checkpointSG.fields = [];

								// Find the checkpoint triggers affecting this checkpoint
								var affectedTriggers = sg.elements.filter(x -> x._type == MissionElementType.Trigger)
									.filter(y -> cast(y, MissionElementTrigger).respawnpoint == ss._name);

								for (triggerEl in affectedTriggers) {
									var trigger = cast(triggerEl, MissionElementTrigger);
									// remove trigger from its current simgroup
									sg.elements.remove(trigger);
									// add trigger to checkpoint simgroup
									checkpointSG.elements.push(trigger);
								}

								sg.elements.push(checkpointSG);
							});
					}
				}
				if (element._type == MissionElementType.Item) {
					var ss = cast(element, MissionElementItem);
					var db = ss.datablock.toLowerCase();
					switch (db) {
						case "gemitemred" | "gemitemyellow" | "gemitemblue" | "gemitemred_mbu" | "gemitemyellow_mbu" | "gemitemblue_mbu":
							// replace them with spawnspheres if its a hunt level
							if (isHunt) {
								var sg = simGroup;
								var datablock = switch (db) {
									case "gemitemred" | "gemitemred_mbu": "gemitem";
									case "gemitemyellow" | "gemitemyellow_mbu": "gemitem_2pts";
									case "gemitemblue" | "gemitemblue_mbu": "gemitem_5pts";
									case _: null;
								};
								processFunctions.push(() -> {
									// First remove this element
									sg.elements.remove(ss);

									// then add the spawnsphere
									var spawnSphereEl = new MissionElementSpawnSphere();
									spawnSphereEl._name = ss._name;
									spawnSphereEl.position = ss.position;
									spawnSphereEl.rotation = ss.rotation;
									spawnSphereEl.scale = ss.scale;
									spawnSphereEl.datablock = "gemspawnspheremarker";
									spawnSphereEl.fields = [];
									spawnSphereEl.gemdatablock = datablock;
									sg.elements.push(spawnSphereEl);
								});
							}
					}
				}
				if (element._type == MissionElementType.TSStatic) {
					var ts = cast(element, mis.MissionElement.MissionElementTSStatic);
					var shapeName = ts.shapename.toLowerCase();
					switch (shapeName) {
						case "~/data/shapes/glass/3x3.dts" | "~/data/shapes/glass/6x3.dts" | "~/data/shapes/glass/9x3.dts" | "~/data/shapes/glass/12x3.dts" |
							"~/data/shapes/glass/15x3.dts" | "~/data/shapes/glass/18x3.dts":
							var pos = MisParser.parseVector3(ts.position);
							var rot = MisParser.parseRotation(ts.rotation);

							var quat = new h3d.Quat();
							quat.initRotateAxis(0, 0, 1, Math.PI / 2);
							rot.multiply(rot, quat);

							var offset = new Vector(-3, -0.25, 0);
							offset.transform3x3(rot.toMatrix());
							pos.load(pos.sub(offset));
							var newPos = '${pos.x} ${pos.y} ${pos.z}';

							var angle = 2 * Math.acos(rot.w);
							var s = Math.sqrt(1 - rot.w * rot.w);
							var x, y, z;
							if (s < 0.001) {
								x = rot.x;
								y = rot.y;
								z = rot.z;
							} else {
								x = rot.x / s;
								y = rot.y / s;
								z = rot.z / s;
							}
							angle = (angle * -180.0 / Math.PI) % 360.0;
							var newRot = '${x} ${y} ${z} ${angle}';

							var datablockName = switch (shapeName) {
								case "~/data/shapes/glass/3x3.dts": "glass_3shape";
								case "~/data/shapes/glass/6x3.dts": "glass_6shape";
								case "~/data/shapes/glass/9x3.dts": "glass_9shape";
								case "~/data/shapes/glass/12x3.dts": "glass_12shape";
								case "~/data/shapes/glass/15x3.dts": "glass_15shape";
								case "~/data/shapes/glass/18x3.dts": "glass_18shape";
								case _:
									Console.error("Unknown glass shape: " + shapeName);
									"glass_3shape";
							};

							var sg = simGroup;
							processFunctions.push(() -> {
								var glassEl = new MissionElementStaticShape();
								glassEl._name = ts._name;
								glassEl.position = newPos;
								glassEl.rotation = newRot;
								glassEl.scale = ts.scale;
								glassEl.datablock = datablockName;
								glassEl.fields = [];

								sg.elements.remove(ts);
								sg.elements.push(glassEl);
							});

						case "~/data/shapes_mbu/signs/arrowsign_side.dts":
							// this one is a sign
							var sg = simGroup;
							processFunctions.push(() -> {
								var signEl = new MissionElementStaticShape();
								signEl._name = ts._name;
								signEl.position = ts.position;
								signEl.rotation = ts.rotation;
								signEl.scale = ts.scale;
								signEl.datablock = "ArrowSide";
								signEl.fields = [];

								sg.elements.remove(ts);
								sg.elements.push(signEl);
							});

						case "~/data/shapes_mbu/signs/arrowsign_up.dts":
							// this one is a sign
							var sg = simGroup;
							processFunctions.push(() -> {
								var signEl = new MissionElementStaticShape();
								signEl._name = ts._name;
								signEl.position = ts.position;
								signEl.rotation = ts.rotation;
								signEl.scale = ts.scale;
								signEl.datablock = "ArrowUp";
								signEl.fields = [];

								sg.elements.remove(ts);
								sg.elements.push(signEl);
							});

						case "~/data/shapes_mbu/signs/arrowsign_down.dts":
							// this one is a sign
							var sg = simGroup;
							processFunctions.push(() -> {
								var signEl = new MissionElementStaticShape();
								signEl._name = ts._name;
								signEl.position = ts.position;
								signEl.rotation = ts.rotation;
								signEl.scale = ts.scale;
								signEl.datablock = "ArrowDown";
								signEl.fields = [];

								sg.elements.remove(ts);
								sg.elements.push(signEl);
							});

						case "~/data/shapes/buttons/checkpoint.dts":
							// This one needs to be changed to a "checkpoint"
							var sg = simGroup;
							processFunctions.push(() -> {
								// First remove this element
								sg.elements.remove(ts);
								// Then add add the actual checkpoint shape
								var checkpointEl = new MissionElementStaticShape();
								checkpointEl._name = ts._name;
								checkpointEl.position = ts.position;
								checkpointEl.rotation = ts.rotation;
								checkpointEl.scale = ts.scale;
								checkpointEl.datablock = "checkPointShape";
								checkpointEl.fields = [];

								// create new simgroup
								var checkpointSG = new MissionElementSimGroup();
								checkpointSG._name = null;
								checkpointSG.elements = [];
								checkpointSG.elements.push(checkpointEl);
								checkpointSG.fields = [];

								// Find the checkpoint triggers affecting this checkpoint
								var affectedTriggers = sg.elements.filter(x -> x._type == MissionElementType.Trigger)
									.filter(y -> cast(y, MissionElementTrigger).respawnpoint == ts._name);

								for (triggerEl in affectedTriggers) {
									var trigger = cast(triggerEl, MissionElementTrigger);
									// remove trigger from its current simgroup
									sg.elements.remove(trigger);
									// add trigger to checkpoint simgroup
									checkpointSG.elements.push(trigger);
								}

								sg.elements.push(checkpointSG);
							});
					}
				}
				if (element._type == MissionElementType.Item) {} else if (element._type == MissionElementType.SimGroup) {
					postprocessMission(cast element);
				}
			}
		};

		postprocessMission(root);

		if (skyMaterialList != null)
			skyEl.materiallist = skyMaterialList;

		// Add astrolabe, because it does not exist
		if (!hasAstrolabe) {
			var astrolabeEl = new MissionElementStaticShape();
			astrolabeEl._name = "Astrolabe";
			astrolabeEl.position = "0 0 -600";
			astrolabeEl.rotation = "1 0 0 0";
			astrolabeEl.scale = "1 1 1";
			astrolabeEl.datablock = "astrolabeShape";
			astrolabeEl.fields = [];
			root.elements.push(astrolabeEl);
		}

		// Add the clouds
		var cloudEl = new MissionElementStaticShape();
		cloudEl._name = "CloudLayer";
		cloudEl.position = "0 0 0";
		cloudEl.rotation = "1 0 0 0";
		cloudEl.scale = "1 1 1";
		cloudEl.datablock = 'astrolabeClouds${cloudType}Shape';
		cloudEl.fields = [];
		root.elements.push(cloudEl);

		for (f in processFunctions) {
			f();
		}
	}
}
