package src;

import h3d.mat.Texture;
import h3d.scene.Object;
import sys.FileSystem;
import sys.io.File;
import haxe.io.Path;
import dts.DtsFile;
import dif.Dif;
import hxd.fs.LocalFileSystem;
import hxd.fs.FileSystem;
import hxd.res.Loader;

class ResourceLoader {
	public static var fileSystem:FileSystem = new LocalFileSystem(".", null);
	public static var loader = new Loader(fileSystem);
	static var interiorResources:Map<String, Dif> = new Map();
	static var dtsResources:Map<String, DtsFile> = new Map();
	static var textureCache:Map<String, Texture> = new Map();

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

	public static function getTexture(path:String) {
		if (textureCache.exists(path))
			return textureCache.get(path);
		if (fileSystem.exists(path)) {
			var tex = loader.load(path).toTexture();
			textureCache.set(path, tex);
			return tex;
		}
		return null;
	}

	public static function clearInteriorResources() {
		interiorResources = new Map();
	}

	public static function clearDtsResources() {
		dtsResources = new Map();
	}

	public static function getFullNamesOf(path:String) {
		var files = fileSystem.dir(Path.directory(path)); // FileSystem.readDirectory(Path.directory(path));
		var names = [];
		var fname = Path.withoutExtension(Path.withoutDirectory(path)).toLowerCase();
		for (file in files) {
			var fname2 = file.name;
			if (Path.withoutExtension(fname2).toLowerCase() == fname)
				names.push(file.path);
		}
		return names;
	}
}
