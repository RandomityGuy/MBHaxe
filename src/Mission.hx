package src;

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

class Mission {
	public var root:MissionElementSimGroup;
	public var title:String;
	public var artist:String;
	public var description:String;
	public var qualifyTime = Math.POSITIVE_INFINITY;
	public var goldTime:Float = 0;
	public var type:String;
	public var path:String;
	public var missionInfo:MissionElementScriptObject;
	public var index:Int;
	public var difficultyIndex:Int;
	public var id:Int;
	public var isClaMission:Bool;

	var imageResources:Array<Resource<Image>> = [];

	var imgFileEntry:hxd.fs.FileEntry;

	static var doingLoadPreviewTimeout = false;

	public function new() {}

	public function load() {
		var entry = ResourceLoader.fileSystem.get(this.path);
		var misText = Util.toASCII(entry.getBytes());

		var misParser = new MisParser(misText);
		var contents = misParser.parse();
		root = contents.root;
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
		mission.type = missionInfo.type != null ? missionInfo.type.toLowerCase() : "custom";
		mission.missionInfo = missionInfo;
		return mission;
	}

	public function getPreviewImage(onLoaded:h2d.Tile->Void) {
		if (!this.isClaMission) {
			var basename = haxe.io.Path.withoutExtension(this.path);
			if (ResourceLoader.fileSystem.exists(basename + ".png")) {
				#if (!android)
				imgFileEntry = ResourceLoader.fileSystem.get(basename + ".png");
				imgFileEntry.load(() -> {
				#end
					var ret = ResourceLoader.getResource(basename + ".png", ResourceLoader.getImage, this.imageResources).toTile();
					onLoaded(ret);
				#if (!android)
				});
				#end
			}
			if (ResourceLoader.fileSystem.exists(basename + ".jpg")) {
				#if (!android)
				imgFileEntry = ResourceLoader.fileSystem.get(basename + ".jpg");
				imgFileEntry.load(() -> {
				#end
					var ret = ResourceLoader.getResource(basename + ".jpg", ResourceLoader.getImage, this.imageResources).toTile();
					onLoaded(ret);
				#if (!android)
				});
				#end
			}
			var img = new BitmapData(1, 1);
			img.setPixel(0, 0, 0);
			onLoaded(Tile.fromBitmap(img));
		} else {
			var img = new BitmapData(1, 1);
			img.setPixel(0, 0, 0);
			onLoaded(Tile.fromBitmap(img));
		}
	}

	public function getPreviewImageSync() {
		if (!this.isClaMission) {
			var basename = haxe.io.Path.withoutExtension(this.path);
			if (ResourceLoader.fileSystem.exists(basename + ".png")) {
				var ret = ResourceLoader.getResource(basename + ".png", ResourceLoader.getImage, this.imageResources).toTile();
				return ret; 
			}
			if (ResourceLoader.fileSystem.exists(basename + ".jpg")) {
				var ret = ResourceLoader.getResource(basename + ".jpg", ResourceLoader.getImage, this.imageResources).toTile();
				return ret;
			}
			var img = new BitmapData(1, 1);
			img.setPixel(0, 0, 0);
			return Tile.fromBitmap(img);
		} else {
			var img = new BitmapData(1, 1);
			img.setPixel(0, 0, 0);
			return Tile.fromBitmap(img);
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
		if (StringTools.contains(path, 'interiors_mbg/'))
			path = StringTools.replace(path, 'interiors_mbg/', 'interiors/');
		#if (js || android)
		path = StringTools.replace(path, "data/", "");
		#end
		if (!StringTools.endsWith(path, ".dif"))
			path += ".dif";
		if (ResourceLoader.fileSystem.exists(path))
			return path;
		return "";
	}
}
