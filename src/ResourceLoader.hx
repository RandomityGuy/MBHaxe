package src;

import hxd.res.Any;
import hxd.fs.BytesFileSystem.BytesFileEntry;
#if (js || android)
import fs.ManifestLoader;
import fs.ManifestBuilder;
import fs.ManifestProgress;
#end
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
import src.Resource;
import src.ResourceLoaderWorker;
import fs.TorqueFileSystem;
import src.Settings;
import src.Console;

class ResourceLoader {
	#if (hl && !android)
	#if MACOS_BUNDLE
	public static var fileSystem:FileSystem = new TorqueFileSystem(Path.normalize(Path.join([Path.directory(Sys.programPath()), "..", "Resources"])), null);
	#else
	public static var fileSystem:FileSystem = new TorqueFileSystem(".", null);
	#end
	#end
	#if (js || android)
	public static var fileSystem:FileSystem = null;
	#end
	#if (hl && !android)
	public static var loader = new Loader(fileSystem);
	#end
	#if (js || android)
	public static var loader:Loader = null;
	#end
	static var interiorResources:Map<String, Resource<Dif>> = new Map();
	static var dtsResources:Map<String, Resource<DtsFile>> = new Map();
	static var textureCache:Map<String, Resource<Texture>> = new Map();
	static var imageCache:Map<String, Resource<Image>> = new Map();
	static var audioCache:Map<String, Resource<Sound>> = new Map();
	static var zipFilesystem:Map<String, BytesFileEntry> = new Map();

	// static var threadPool:FixedThreadPool = new FixedThreadPool(4);

	public static function init(scene2d:h2d.Scene, onLoadedFunc:Void->Void) {
		Console.log("Initializing filesystem");
		#if hl
		@:privateAccess @:privateAccess cast(fileSystem, TorqueFileSystem).convert.tmpDir = "data/tmp/";
		Console.log("Filesystem Path: " + @:privateAccess cast(fileSystem, TorqueFileSystem).baseDir);
		#end
		hxd.res.Resource.LIVE_UPDATE = false; // Disable live update to save frames
		@:privateAccess hxd.res.Image.ENABLE_AUTO_WATCH = false;
		@:privateAccess hxd.res.Sound.ENABLE_AUTO_WATCH = false;
		haxe.MainLoop.add(() -> {});
		#if (js || android)
		var mfileSystem = ManifestBuilder.create("data");
		var mloader:ManifestLoader = new ManifestLoader(mfileSystem);

		var preloader = new ManifestProgress(mloader, () -> {
			loader = mloader;
			fileSystem = mfileSystem;
			onLoadedFunc();
		}, scene2d);
		loader = mloader;
		fileSystem = mfileSystem;
		var loadg = new h2d.Text(hxd.res.DefaultFont.get());
		loadg.textAlign = Center;
		loadg.textColor = 0xffffff;
		loadg.y = scene2d.height / 2;
		loadg.x = scene2d.width / 2;
		loadg.scale(2.5);
		scene2d.addChild(loadg);

		var worker = new ResourceLoaderWorker(onLoadedFunc);
		worker.addTask(fwd -> {
			loadg.text = "Loading UI..";
			fwd();
		});
		worker.addTask(fwd -> preloadUI(fwd));
		worker.addTask(fwd -> {
			loadg.text = "Loading Missions..";
			fwd();
		});
		worker.addTask(fwd -> preloadMisFiles(fwd));
		worker.addTask(fwd -> {
			loadg.text = "Loading Music..";
			fwd();
		});
		worker.addTask(fwd -> preloadMusic(fwd));
		worker.addTask(fwd -> {
			loadg.text = "Loading Sounds..";
			fwd();
		});
		worker.addTask(fwd -> preloadUISounds(fwd));
		worker.addTask(fwd -> {
			loadg.text = "Loading Shapes..";
			fwd();
		});
		worker.addTask(fwd -> preloadShapes(fwd));
		worker.addTask(fwd -> {
			scene2d.removeChild(loadg);
			fwd();
		});
		worker.run();
		// preloader.start();
		#end
		#if (hl && !android)
		onLoadedFunc();
		#end
	}

	static function preloadUI(onFinish:Void->Void) {
		var toloadfiles = [];
		var toloaddirs = [];
		var filestats = fileSystem.dir("font").concat(fileSystem.dir("ui"));
		for (file in filestats) {
			if (file.isDirectory) {
				toloaddirs.push(file);
			} else {
				toloadfiles.push(file);
			}
		}
		while (toloaddirs.length > 0) {
			var nextdir = toloaddirs.pop();
			for (file in fileSystem.dir(nextdir.path.substring(2))) {
				if (file.isDirectory) {
					toloaddirs.push(file);
				} else {
					toloadfiles.push(file);
				}
			}
		}
		var worker = new ResourceLoaderWorker(onFinish);
		for (file in toloadfiles) {
			worker.addTaskParallel((fwd) -> file.load(fwd));
		}
		worker.run();
	}

	static function preloadMisFiles(onFinish:Void->Void) {
		var toloadfiles = [];
		var toloaddirs = [];
		var filestats = fileSystem.dir("missions");
		for (file in filestats) {
			if (file.isDirectory) {
				toloaddirs.push(file);
			} else {
				toloadfiles.push(file);
			}
		}
		filestats = fileSystem.dir("missions_mbg");
		for (file in filestats) {
			if (file.isDirectory) {
				toloaddirs.push(file);
			} else {
				toloadfiles.push(file);
			}
		}
		filestats = fileSystem.dir("missions_mbp");
		for (file in filestats) {
			if (file.isDirectory) {
				toloaddirs.push(file);
			} else {
				toloadfiles.push(file);
			}
		}
		filestats = fileSystem.dir("missions_mbu");
		for (file in filestats) {
			if (file.isDirectory) {
				toloaddirs.push(file);
			} else {
				toloadfiles.push(file);
			}
		}
		while (toloaddirs.length > 0) {
			var nextdir = toloaddirs.pop();
			for (file in fileSystem.dir(nextdir.path.substring(2))) {
				if (file.isDirectory) {
					toloaddirs.push(file);
				} else {
					if (file.extension == "mis")
						toloadfiles.push(file);
				}
			}
		}
		var worker = new ResourceLoaderWorker(onFinish);
		for (file in toloadfiles) {
			worker.addTaskParallel((fwd) -> file.load(fwd));
		}
		worker.run();
	}

	static function preloadMusic(onFinish:Void->Void) {
		var worker = new ResourceLoaderWorker(onFinish);
		worker.loadFile("sound/music/shell.ogg");
		worker.loadFile("sound/music/pianoforte.ogg");
		worker.run();
	}

	static function preloadUISounds(onFinish:Void->Void) {
		var worker = new ResourceLoaderWorker(onFinish);
		worker.loadFile("sound/testing.wav");
		worker.loadFile("sound/buttonover.wav");
		worker.loadFile("sound/buttonpress.wav");
		worker.run();
	}

	static function preloadShapes(onFinish:Void->Void) {
		var toloadfiles = [
			StringTools.replace(Settings.optionsSettings.marbleModel, "data/", ""),
			(Settings.optionsSettings.marbleCategoryIndex == 0)
			? "shapes/balls/" + Settings.optionsSettings.marbleSkin + ".marble.png" : "shapes/balls/pack1/" + Settings.optionsSettings.marbleSkin +
			".marble.png"
		];
		// var toloaddirs = [];
		// var filestats = fileSystem.dir("shapes");
		// for (file in filestats) {
		// 	if (file.isDirectory) {
		// 		toloaddirs.push(file);
		// 	} else {
		// 		toloadfiles.push(file);
		// 	}
		// }
		// while (toloaddirs.length > 0) {
		// 	var nextdir = toloaddirs.pop();
		// 	for (file in fileSystem.dir(nextdir.path.substring(2))) {
		// 		if (file.isDirectory) {
		// 			toloaddirs.push(file);
		// 		} else {
		// 			toloadfiles.push(file);
		// 		}
		// 	}
		// }
		// var teleportPad = fileSystem.get("interiors_mbp/teleportpad.dts");
		// var teleportTexture = fileSystem.get("interiors_mbp/repairbay.jpg");
		// toloadfiles.push(teleportPad); // Because its not in the shapes folder like wtf
		// toloadfiles.push(teleportTexture);
		var worker = new ResourceLoaderWorker(onFinish);
		for (file in toloadfiles) {
			worker.loadFile(file);
		}
		worker.run();
	}

	public static function getProperFilepath(rawElementPath:String) {
		var fname = rawElementPath.substring(rawElementPath.lastIndexOf('/') + 1);
		rawElementPath = rawElementPath.toLowerCase();
		var path = StringTools.replace(rawElementPath.substring(rawElementPath.indexOf('data/')), "\"", "");
		if (StringTools.contains(path, 'interiors_mbg/'))
			path = StringTools.replace(path, 'interiors_mbg/', 'interiors/');
		var dirpath = path.substring(0, path.lastIndexOf('/') + 1);
		#if (js || android)
		path = StringTools.replace(path, "data/", "");
		#end
		if (ResourceLoader.exists(path))
			return path;
		if (ResourceLoader.exists(dirpath + fname))
			return dirpath + fname;
		return "";
	}

	public static function load(path:String) {
		#if hl
		if (!StringTools.startsWith(path, "data/"))
			path = "data/" + path;
		#end
		#if (js || android)
		path = StringTools.replace(path, "data/", "");
		#end
		if (zipFilesystem.exists(path.toLowerCase())) {
			return new hxd.res.Any(loader, zipFilesystem.get(path.toLowerCase()));
		}
		return ResourceLoader.loader.load(path);
	}

	public static function loadInterior(path:String) {
		#if (js || android)
		path = StringTools.replace(path, "data/", "");
		#end
		if (interiorResources.exists(path))
			return interiorResources.get(path);
		else {
			var itr:Dif;
			// var lock = new Lock();
			// threadPool.run(() -> {
			if (zipFilesystem.exists(path.toLowerCase()))
				itr = Dif.LoadFromBuffer(zipFilesystem.get(path.toLowerCase()).getBytes());
			else
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
		path = getProperFilepath(path);

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
		path = getProperFilepath(path);
		return getTextureRealpath(path);
	}

	public static function getTextureRealpath(path:String) {
		if (zipFilesystem.exists(path.toLowerCase())) {
			if (StringTools.endsWith(path.toLowerCase(), ".bmp")) { // Handle bmp specially
				var bmpContents = zipFilesystem.get(path.toLowerCase());
				var bmpreader = new format.bmp.Reader(new haxe.io.BytesInput(bmpContents.getBytes()));
				var bmpdata = bmpreader.read();

				var bbuf = new haxe.io.BytesBuffer();
				var i = 0;
				while (i < bmpdata.pixels.length) {
					bbuf.addByte(bmpdata.pixels.get(i));
					bbuf.addByte(bmpdata.pixels.get(i + 1));
					bbuf.addByte(bmpdata.pixels.get(i + 2));
					bbuf.addByte(1);
					i += 3;
				}

				var pixs = new hxd.Pixels(bmpdata.header.width, bmpdata.header.height, bbuf.getBytes(), hxd.PixelFormat.BGRA);
				var tex = h3d.mat.Texture.fromPixels(pixs);
				tex.mipMap = Nearest;
				tex.flags.set(MipMapped);

				var textureresource = new Resource(tex, path, textureCache, tex -> tex.dispose());
				textureCache.set(path, textureresource);

				return textureresource;
			} else {
				var img = new hxd.res.Image(zipFilesystem.get(path.toLowerCase()));
				Image.setupTextureFlags = (texObj) -> {
					texObj.flags.set(MipMapped);
				}
				var tex = img.toTexture();
				tex.mipMap = Nearest;
				var textureresource = new Resource(tex, path, textureCache, tex -> tex.dispose());
				textureCache.set(path, textureresource);

				return textureresource;
			}
		}
		if (textureCache.exists(path))
			return textureCache.get(path);
		if (fileSystem.exists(path)) {
			if (StringTools.endsWith(path.toLowerCase(), ".bmp")) { // Handle bmp specially
				var bmpContents = zipFilesystem.get(path.toLowerCase());
				var bmpreader = new format.bmp.Reader(new haxe.io.BytesInput(bmpContents.getBytes()));
				var bmpdata = bmpreader.read();

				var bbuf = new haxe.io.BytesBuffer();
				var i = 0;
				while (i < bmpdata.pixels.length) {
					bbuf.addByte(bmpdata.pixels.get(i));
					bbuf.addByte(bmpdata.pixels.get(i + 1));
					bbuf.addByte(bmpdata.pixels.get(i + 2));
					bbuf.addByte(1);
					i += 3;
				}
				var pixs = new hxd.Pixels(bmpdata.header.width, bmpdata.header.height, bbuf.getBytes(), hxd.PixelFormat.BGRA);
				pixs.setFlip(true);
				var tex = h3d.mat.Texture.fromPixels(pixs);
				tex.mipMap = Nearest;
				tex.flags.set(MipMapped);

				var textureresource = new Resource(tex, path, textureCache, tex -> tex.dispose());
				textureCache.set(path, textureresource);

				return textureresource;
			} else {
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
		}
		return null;
	}

	public static function getImagePixels(path:String) {
		if (zipFilesystem.exists(path.toLowerCase())) {
			if (StringTools.endsWith(path.toLowerCase(), ".bmp")) { // Handle bmp specially
				var bmpContents = zipFilesystem.get(path.toLowerCase());
				var bmpreader = new format.bmp.Reader(new haxe.io.BytesInput(bmpContents.getBytes()));
				var bmpdata = bmpreader.read();

				var bbuf = new haxe.io.BytesBuffer();
				var i = 0;
				while (i < bmpdata.pixels.length) {
					bbuf.addByte(bmpdata.pixels.get(i));
					bbuf.addByte(bmpdata.pixels.get(i + 1));
					bbuf.addByte(bmpdata.pixels.get(i + 2));
					bbuf.addByte(1);
					i += 3;
				}

				var pixs = new hxd.Pixels(bmpdata.header.width, bmpdata.header.height, bbuf.getBytes(), hxd.PixelFormat.BGRA);
				return pixs;
			} else {
				var img = new hxd.res.Image(zipFilesystem.get(path.toLowerCase()));
				return img.getPixels();
			}
		}
		if (fileSystem.exists(path)) {
			if (StringTools.endsWith(path.toLowerCase(), ".bmp")) { // Handle bmp specially
				var bmpContents = zipFilesystem.get(path.toLowerCase());
				var bmpreader = new format.bmp.Reader(new haxe.io.BytesInput(bmpContents.getBytes()));
				var bmpdata = bmpreader.read();

				var bbuf = new haxe.io.BytesBuffer();
				var i = 0;
				while (i < bmpdata.pixels.length) {
					bbuf.addByte(bmpdata.pixels.get(i));
					bbuf.addByte(bmpdata.pixels.get(i + 1));
					bbuf.addByte(bmpdata.pixels.get(i + 2));
					bbuf.addByte(1);
					i += 3;
				}
				var pixs = new hxd.Pixels(bmpdata.header.width, bmpdata.header.height, bbuf.getBytes(), hxd.PixelFormat.BGRA);
				return pixs;
			} else {
				var img = loader.load(path).toImage();
				return img.getPixels();
			}
		}
		return null;
	}

	public static function getImage(path:String) {
		#if (js || android)
		path = StringTools.replace(path, "data/", "");
		#end
		if (zipFilesystem.exists(path.toLowerCase())) {
			var fentry = new hxd.res.Image(zipFilesystem.get(path.toLowerCase()));
			var imageresource = new Resource(fentry, path, imageCache, img -> {});
			imageCache.set(path, imageresource);
			return imageresource;
		}
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
		#if (js || android)
		path = StringTools.replace(path, "data/", "");
		#end
		if (audioCache.exists(path))
			return audioCache.get(path);
		if (fileSystem.exists(path)) {
			var snd = loader.load(path).toSound();
			// @:privateAccess snd.watchCallb();
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
		#if (js || android)
		path = StringTools.replace(path, "data/", "");
		#end
		if (zipFilesystem.exists(path.toLowerCase())) {
			var fentry = zipFilesystem.get(path.toLowerCase());
			return new hxd.res.Any(loader, fentry);
		}
		var file = loader.load(path);
		return file;
	}

	public static function exists(path:String) {
		if (zipFilesystem.exists(path.toLowerCase()))
			return true;
		return fileSystem.exists(path);
	}

	public static function clearInteriorResources() {
		interiorResources = new Map();
	}

	public static function clearDtsResources() {
		dtsResources = new Map();
	}

	public static function getFullNamesOf(path:String) {
		#if (js || android)
		path = StringTools.replace(path, "data/", "");
		#end
		if (zipFilesystem.exists(path.toLowerCase() + ".jpg")) {
			return [path + ".jpg"];
		}
		if (zipFilesystem.exists(path.toLowerCase() + ".png")) {
			return [path + ".png"];
		}
		if (zipFilesystem.exists(path.toLowerCase() + ".bmp")) {
			return [path + ".bmp"];
		}
		if (zipFilesystem.exists(path.toLowerCase() + ".dds")) {
			return [path + ".dds"];
		}
		var files = fileSystem.dir(Path.directory(path)); // FileSystem.readDirectory(Path.directory(path));
		var names = [];
		var fname = Path.withoutDirectory(path).toLowerCase();
		for (file in files) {
			var fname2 = file.name;
			if (Path.withoutExtension(fname2).toLowerCase() == fname || fname2.toLowerCase() == fname)
				names.push(file.path);
		}
		return names;
	}

	public static function loadZip(entries:Array<haxe.zip.Entry>, game:String) {
		zipFilesystem.clear(); // We are only allowed to load one zip
		for (entry in entries) {
			var fname = entry.fileName.toLowerCase();
			#if sys
			fname = "data/" + fname;
			#end
			if (game == 'gold')
				fname = StringTools.replace(fname, 'interiors/', 'interiors_mbg/');
			fname = StringTools.replace(fname, "lbinteriors", "interiors"); // Normalize
			if (exists(fname))
				continue;
			Console.log("Loaded zip entry: " + fname);
			var zfe = new BytesFileEntry(fname, entry.data);
			zipFilesystem.set(fname, zfe);
		}
	}
}
