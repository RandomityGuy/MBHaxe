package fs;

#if android
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

#end
#if ios
package fs;

import hxd.fs.LocalFileSystem;
import src.Settings;

class TorqueFileEntry extends LocalEntry {
	override function load(?onReady:Void->Void):Void {
		if (onReady != null)
			haxe.Timer.delay(onReady, 1);
	}
}

class TorqueFileSystem extends LocalFileSystem {
	// Cache of directory listings: lowercase dir path -> (lowercase entry name -> actual entry name)
	var dirListCache:Map<String, Map<String, String>> = new Map();

	static function normalizePath(path:String):String {
		if (path == null)
			return path;

		while (StringTools.startsWith(path, "/"))
			path = path.substr(1);

		if (StringTools.startsWith(path, "ata/"))
			path = "d" + path;

		return path;
	}

	// Look up the real, case-correct name of `name` inside `dir`, or null if absent.
	function lookupActual(dir:String, name:String):String {
		var key = dir.toLowerCase();
		var c = dirListCache.get(key);
		if (c == null) {
			c = new Map();
			for (f in try
				sys.FileSystem.readDirectory(dir)
			catch (e:Dynamic)
				[])
				c.set(f.toLowerCase(), f);
			dirListCache.set(key, c);
		}
		return c.get(name.toLowerCase());
	}

	// Resolve `path` against the real filesystem case-insensitively, returning the
	// actual case-correct path, or null if no matching file exists.
	function resolveCasePath(path:String):String {
		if (path == null || path == "")
			return path;

		// Fast path: case already matches what's on disk.
		if (sys.FileSystem.exists(path))
			return path;

		var parts = path.split("/");
		var resolved = "";
		for (part in parts) {
			if (part == "")
				continue;
			var dir = resolved == "" ? "." : resolved;
			var actual = lookupActual(dir, part);
			if (actual == null)
				return null;
			resolved = resolved == "" ? actual : resolved + "/" + actual;
		}
		return resolved;
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

		// Resolve the path case-insensitively so files open regardless of the
		// input casing (iOS uses a case-sensitive filesystem).
		var resolved = resolveCasePath(f);
		var file = resolved != null ? resolved : f;

		if (!check || resolved != null) {
			e = new TorqueFileEntry(this, f.split("/").pop(), f, file);
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

	override function dir(path:String):Array<hxd.fs.FileEntry> {
		path = normalizePath(path);

		// Resolve the directory case-insensitively (iOS uses a case-sensitive
		// filesystem, so "data/skies/beginner" must map to "data/skies/Beginner").
		var resolved = resolveCasePath(path);
		if (resolved == null || !sys.FileSystem.isDirectory(resolved))
			throw new hxd.fs.NotFound(path);

		var files = sys.FileSystem.readDirectory(resolved);
		var r:Array<hxd.fs.FileEntry> = [];
		for (f in files)
			r.push(open(resolved + "/" + f, false));
		return r;
	}
}
#end
