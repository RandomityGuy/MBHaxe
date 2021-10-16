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
import src.Resource;

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
	static var interiorResources:Map<String, Resource<Dif>> = new Map();
	static var dtsResources:Map<String, Resource<DtsFile>> = new Map();
	static var textureCache:Map<String, Resource<Texture>> = new Map();
	static var imageCache:Map<String, Resource<Image>> = new Map();
	static var audioCache:Map<String, Resource<Sound>> = new Map();

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
			var itrresource = new Resource(itr, path, interiorResources, dif -> {});
			interiorResources.set(path, itrresource);
			//	lock.release();
			// });
			// lock.wait();
			return itrresource;
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
			var dtsresource = new Resource(dts, path, dtsResources, dtsFile -> {});
			dtsResources.set(path, dtsresource);
			//	lock.release();
			// });
			// lock.wait();
			return dtsresource;
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
			var textureresource = new Resource(tex, path, textureCache, tex -> tex.dispose());
			textureCache.set(path, textureresource);

			return textureresource;
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
			var imageresource = new Resource(tex, path, imageCache, img -> {});
			imageCache.set(path, imageresource);
			return imageresource;
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
			var audioresource = new Resource(snd, path, audioCache, snd -> snd.dispose());
			audioCache.set(path, audioresource);
			return audioresource;
		}
		return null;
	}

	public static function getResource<T>(path:String, resourceAcquirerer:String->Null<Resource<T>>, resourceCollector:Array<Resource<T>>) {
		var res = resourceAcquirerer(path);
		if (res != null) {
			if (!resourceCollector.contains(res)) {
				res.acquire();
				resourceCollector.push(res);
			}
			return res.resource;
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
