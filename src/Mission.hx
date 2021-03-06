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

	public function new() {}

	public function load() {
		var misParser = new MisParser(ResourceLoader.fileSystem.get(this.path).getText());
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
		mission.type = missionInfo.type.toLowerCase();
		mission.missionInfo = missionInfo;
		return mission;
	}

	public function getPreviewImage() {
		if (!this.isClaMission) {
			var basename = haxe.io.Path.withoutExtension(this.path);
			if (ResourceLoader.fileSystem.exists(basename + ".png")) {
				return ResourceLoader.getResource(basename + ".png", ResourceLoader.getImage, this.imageResources).toTile();
			}
			if (ResourceLoader.fileSystem.exists(basename + ".jpg")) {
				return ResourceLoader.getResource(basename + ".jpg", ResourceLoader.getImage, this.imageResources).toTile();
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
		rawElementPath = rawElementPath.toLowerCase();
		var path = StringTools.replace(rawElementPath.substring(rawElementPath.indexOf('data/')), "\"", "");
		if (StringTools.contains(path, 'interiors_mbg/'))
			path = StringTools.replace(path, 'interiors_mbg/', 'interiors/');
		#if js
		path = StringTools.replace(path, "data/", "");
		#end
		if (ResourceLoader.fileSystem.exists(path))
			return path;
		return "";
	}
}
