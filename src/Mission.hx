package src;

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

	var next:Mission;

	var imageResources:Array<Resource<Image>> = [];

	var imgFileEntry:hxd.fs.FileEntry;

	static var doingLoadPreviewTimeout = false;

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
				imgFileEntry.load(() -> {
					var ret = ResourceLoader.getResource(basename + ".png", ResourceLoader.getImage, this.imageResources).toTile();
					onLoaded(ret);
				});
				return imgFileEntry.path;
			}
			if (ResourceLoader.fileSystem.exists(basename + ".jpg")) {
				imgFileEntry = ResourceLoader.fileSystem.get(basename + ".jpg");
				imgFileEntry.load(() -> {
					var ret = ResourceLoader.getResource(basename + ".jpg", ResourceLoader.getImage, this.imageResources).toTile();
					onLoaded(ret);
				});
				return imgFileEntry.path;
			}
			Console.error("Preview image not found for " + this.path);
			var img = new BitmapData(1, 1);
			img.setPixel(0, 0, 0);
			onLoaded(Tile.fromBitmap(img));
			return null;
		} else {
			Marbleland.getMissionImage(this.id, (im) -> {
				if (im != null) {
					onLoaded(im.toTile());
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
		var path = StringTools.replace(rawElementPath.substring(rawElementPath.indexOf('data/')), "\"", "");
		#if (js || android)
		path = StringTools.replace(path, "data/", "");
		#end
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
		Console.error("Interior resource not found: " + rawElementPath);
		return "";
	}

	/** Computes the clock time in MBP when the user should be warned that they're about to exceed the par time. */
	public function computeAlarmStartTime() {
		var alarmStart = this.qualifyTime;
		if (this.missionInfo.alarmstarttime != null)
			alarmStart -= MisParser.parseNumber(this.missionInfo.alarmstarttime);
		else {
			alarmStart -= 15;
		}
		alarmStart = Math.max(0, alarmStart);

		return alarmStart;
	}

	public function download(onFinish:Void->Void) {
		if (this.isClaMission) {
			Marbleland.download(this.id, (zipEntries) -> {
				if (zipEntries != null) {
					ResourceLoader.loadZip(zipEntries);
					onFinish();
				} else {
					MarbleGame.canvas.pushDialog(new MessageBoxOkDlg("Failed to download mission"));
				}
			});
		}
	}
}
