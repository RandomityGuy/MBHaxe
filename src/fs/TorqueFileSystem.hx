package fs;

import hxd.fs.LocalFileSystem;

#if hl
class TorqueFileEntry extends LocalEntry {
	override function load(?onReady:Void->Void):Void {
		#if macro
		onReady();
		#else
		// if (Settings.optionsSettings.fastLoad)
		if (onReady != null)
			haxe.Timer.delay(onReady, 1);
		// else {
		// 	if (onReady != null)
		// 		haxe.Timer.delay(onReady, 1);
		// }
		#end
	}
}
#end

class TorqueFileSystem extends LocalFileSystem {
	#if hl
	public function new(dir:String, configuration:String) {
		super(dir, configuration);
		baseDir = dir;
		if (configuration == null)
			configuration = "default";

		#if (macro && haxe_ver >= 4.0)
		var exePath = null;
		#elseif (haxe_ver >= 3.3)
		var pr = Sys.programPath();
		var exePath = pr == null ? null : pr.split("\\").join("/").split("/");
		#else
		var exePath = Sys.executablePath().split("\\").join("/").split("/");
		#end

		if (exePath != null)
			exePath.pop();
		var froot = exePath == null ? baseDir : sys.FileSystem.fullPath(exePath.join("/") + "/" + baseDir);
		if (froot == null || !sys.FileSystem.exists(froot) || !sys.FileSystem.isDirectory(froot)) {
			froot = sys.FileSystem.fullPath(baseDir);
			if (froot == null || !sys.FileSystem.exists(froot) || !sys.FileSystem.isDirectory(froot))
				throw "Could not find dir " + dir;
		}
		baseDir = froot.split("\\").join("/");
		if (!StringTools.endsWith(baseDir, "/"))
			baseDir += "/";
		root = new TorqueFileEntry(this, "root", null, baseDir);
	}

	override function checkPath(path:String) {
		// make sure the file is loaded with correct case !
		var baseDir = new haxe.io.Path(path).dir;
		var c = directoryCache.get(baseDir.toLowerCase());
		var isNew = false;
		if (c == null) {
			isNew = true;
			c = new Map();
			for (f in try
				sys.FileSystem.readDirectory(baseDir)
			catch (e:Dynamic)
				[])
				c.set(f.toLowerCase(), true);
			directoryCache.set(baseDir.toLowerCase(), c);
		}
		if (!c.exists(path.substr(baseDir.length + 1).toLowerCase())) {
			// added since then?
			if (!isNew) {
				directoryCache.remove(baseDir.toLowerCase());
				return checkPath(path);
			}
			return false;
		}
		return true;
	}

	override function open(path:String, check = true) {
		var r = fileCache.get(path.toLowerCase());
		if (r != null)
			return r.r;
		var e = null;
		var f = sys.FileSystem.fullPath(baseDir + path);
		if (f == null)
			return null;
		f = f.split("\\").join("/");
		if (!check || (sys.FileSystem.exists(f) && checkPath(f))) {
			e = new TorqueFileEntry(this, path.split("/").pop(), path, f);
			convert.run(e);
			if (e.file == null)
				e = null;
		}
		fileCache.set(path.toLowerCase(), {r: e});
		return e;
	}
	#end
}
