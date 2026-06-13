package fs;

import hxd.fs.LocalFileSystem;
import src.Settings;

class TorqueFileEntry extends LocalEntry {
	override function load(?onReady:Void->Void):Void {
		if (Settings.optionsSettings.fastLoad) {
			if (onReady != null)
				onReady();
		} else {
			if (onReady != null)
				haxe.Timer.delay(onReady, 1);
		}
	}
}

class TorqueFileSystem extends LocalFileSystem {
	static function normalizePath(path:String):String {
		if (path == null)
			return path;

		while (StringTools.startsWith(path, "/"))
			path = path.substr(1);

		if (StringTools.startsWith(path, "ata/"))
			path = "d" + path;

		return path;
	}

	public function new(dir:String, configuration:String) {
		super(".", configuration);

		// iOS/app bundle mode:
		// main.m already chdir()s into MBHaxe.app.
		// Empty baseDir makes paths stay "data/..." instead of "/data/...".
		baseDir = "";

		root = new TorqueFileEntry(this, "root", null, baseDir);
	}
	override function checkPath(path:String) {
		path = normalizePath(path);

		// iOS bundle mode: do not do baseDir substr checks.
		// The file already exists check happens in open().
		return true;
	}

	override function open(path:String, check = true) {
		path = normalizePath(path);

		var r = fileCache.get(path.toLowerCase());
		if (r != null)
			return r.r;
		var e = null;

		// iOS safety: never allow game asset paths to become /data/...

		var f = path;
		if (f == null)
			return null;
		f = f.split("\\").join("/");
		if (!check || (sys.FileSystem.exists(f) && checkPath(f))) {
			e = new TorqueFileEntry(this, f.split("/").pop(), f, f);
			#if ios
			// iOS bundle mode: files are already packaged.
			// Do not run FileConverter because it tries to create /data or /tmp cache paths.
			#else
			convert.run(e);
			if (e.file == null)
				e = null;
			#end
		}
		fileCache.set(path.toLowerCase(), {r: e});
		return e;
	}
}
