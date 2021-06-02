package src;

import sys.FileSystem;
import sys.io.File;
import haxe.io.Path;
import dts.DtsFile;
import dif.Dif;

class ResourceLoader {
	static var interiorResources:Map<String, Dif> = new Map();
	static var dtsResources:Map<String, DtsFile> = new Map();

	public static function loadInterior(path:String) {
		if (interiorResources.exists(path))
			return interiorResources.get(path);
		else {
			var itr = Dif.Load(path);
			interiorResources.set(path, itr);
			return itr;
		}
	}

	public static function loadDts(path:String) {
		if (dtsResources.exists(path))
			return dtsResources.get(path);
		else {
			var dts = new DtsFile();
			dts.read(path);
			dtsResources.set(path, dts);
			return dts;
		}
	}

	public static function clearInteriorResources() {
		interiorResources = new Map();
	}

	public static function clearDtsResources() {
		dtsResources = new Map();
	}

	public static function getFullNamesOf(path:String) {
		var files = FileSystem.readDirectory(Path.directory(path));
		var names = [];
		var fname = Path.withoutExtension(Path.withoutDirectory(path)).toLowerCase();
		for (file in files) {
			if (Path.withoutExtension(Path.withoutDirectory(file)).toLowerCase() == fname)
				names.push(file);
		}
		return names;
	}
}
