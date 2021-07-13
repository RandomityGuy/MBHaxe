package src;

import fs.ManifestLoader;
import fs.ManifestBuilder;
import hxd.res.Image;
import hxd.res.Sound;
import h3d.mat.Texture;
import h3d.scene.Object;
import haxe.io.Path;
import dts.DtsFile;
import dif.Dif;
import hxd.fs.LocalFileSystem;
import hxd.fs.FileSystem;
import hxd.res.Loader;
import fs.ManifestProgress;

class ResourceLoader {
	#if hl
	public static var fileSystem:FileSystem = new LocalFileSystem(".", null);
	#end
	#if js
	public static var fileSystem:FileSystem = null;
	#end
	#if hl
	public static var loader = new Loader(fileSystem);
	#end
	#if js
	public static var loader:Loader = null;
	#end
	static var interiorResources:Map<String, Dif> = new Map();
	static var dtsResources:Map<String, DtsFile> = new Map();
	static var textureCache:Map<String, Texture> = new Map();
	static var imageCache:Map<String, Image> = new Map();
	static var audioCache:Map<String, Sound> = new Map();

	// static var threadPool:FixedThreadPool = new FixedThreadPool(4);

	public static function init(scene2d:h2d.Scene, onLoadedFunc:Void->Void) {
		#if js
		var mfileSystem = ManifestBuilder.create("data");
		var mloader = new ManifestLoader(mfileSystem);

		var preloader = new ManifestProgress(mloader, () -> {
			loader = mloader;
			fileSystem = mfileSystem;
			onLoadedFunc();
		}, scene2d);
		preloader.start();
		#end
		#if hl
		onLoadedFunc();
		#end
	}

	public static function loadInterior(path:String) {
		#if js
		path = StringTools.replace(path, "data/", "");
		#end
		if (interiorResources.exists(path))
			return interiorResources.get(path);
		else {
			var itr:Dif;
			// var lock = new Lock();
			// threadPool.run(() -> {
			itr = Dif.LoadFromBuffer(fileSystem.get(path).getBytes());
			interiorResources.set(path, itr);
			//	lock.release();
			// });
			// lock.wait();
			return itr;
		}
	}

	public static function loadDts(path:String) {
		#if js
		path = StringTools.replace(path, "data/", "");
		#end
		if (dtsResources.exists(path))
			return dtsResources.get(path);
		else {
			var dts = new DtsFile();
			// var lock = new Lock();
			// threadPool.run(() -> {
			dts.read(path);
			dtsResources.set(path, dts);
			//	lock.release();
			// });
			// lock.wait();
			return dts;
		}
	}

	public static function getTexture(path:String) {
		#if js
		path = StringTools.replace(path, "data/", "");
		#end
		if (textureCache.exists(path))
			return textureCache.get(path);
		if (fileSystem.exists(path)) {
			var img = loader.load(path).toImage();
			Image.setupTextureFlags = (texObj) -> {
				texObj.flags.set(MipMapped);
			}
			var tex = img.toTexture();
			tex.mipMap = Nearest;
			// tex.filter = Nearest;
			textureCache.set(path, tex);

			return tex;
		}
		return null;
	}

	public static function getImage(path:String) {
		#if js
		path = StringTools.replace(path, "data/", "");
		#end
		if (imageCache.exists(path))
			return imageCache.get(path);
		if (fileSystem.exists(path)) {
			var tex = loader.load(path).toImage();
			imageCache.set(path, tex);
			return tex;
		}
		return null;
	}

	public static function getAudio(path:String) {
		#if js
		path = StringTools.replace(path, "data/", "");
		#end
		if (audioCache.exists(path))
			return audioCache.get(path);
		if (fileSystem.exists(path)) {
			var snd = loader.load(path).toSound();
			audioCache.set(path, snd);
			return snd;
		}
		return null;
	}

	public static function getFileEntry(path:String) {
		#if js
		path = StringTools.replace(path, "data/", "");
		#end
		var file = loader.load(path);
		return file;
	}

	public static function clearInteriorResources() {
		interiorResources = new Map();
	}

	public static function clearDtsResources() {
		dtsResources = new Map();
	}

	public static function getFullNamesOf(path:String) {
		#if js
		path = StringTools.replace(path, "data/", "");
		#end
		var files = fileSystem.dir(Path.directory(path)); // FileSystem.readDirectory(Path.directory(path));
		var names = [];
		var fname = Path.withoutDirectory(path).toLowerCase();
		for (file in files) {
			var fname2 = file.name;
			if (Path.withoutExtension(fname2).toLowerCase() == fname)
				names.push(file.path);
		}
		return names;
	}
}
