package src;

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
			Marbleland.download(this.id, (zipEntries) -> {
				if (zipEntries != null) {
					ResourceLoader.loadZip(zipEntries, game);
					onFinish();
				} else {
					MarbleGame.canvas.pushDialog(new MessageBoxOkDlg("Failed to download mission"));
				}
			});
		}
	}
}
