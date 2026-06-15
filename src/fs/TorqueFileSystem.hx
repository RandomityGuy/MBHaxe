package fs;

import hxd.fs.LocalFileSystem;

#if hl
class TorqueFileEntry extends LocalEntry {
	override function load(?onReady:Void->Void):Void {
		#if macro
		onReady();
		#else
		// if (Settings.optionsSettings.fastLoad)
		onReady();
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

	// Maps a directory (lowercased absolute path) to a map of lowercased entry name -> real on-disk name.
	// Lets us resolve a requested path to its actual casing on case-sensitive filesystems.
	var realCaseCache:Map<String, Map<String, String>> = new Map();

	function listRealCase(dir:String, refresh:Bool):Map<String, String> {
		var key = dir.toLowerCase();
		var c = refresh ? null : realCaseCache.get(key);
		if (c == null) {
			c = new Map();
			for (f in try
				sys.FileSystem.readDirectory(dir)
			catch (e:Dynamic)
				[])
				c.set(f.toLowerCase(), f);
			realCaseCache.set(key, c);
		}
		return c;
	}

	function lookupRealCase(dir:String, name:String):String {
		var lower = name.toLowerCase();
		var real = listRealCase(dir, false).get(lower);
		if (real == null) // maybe added since cached, refresh once
			real = listRealCase(dir, true).get(lower);
		return real;
	}

	// Resolves a relative path (under baseDir) to its real on-disk casing, walking it
	// component by component. Returns null if any component does not exist.
	function resolveRealPath(path:String):String {
		// Fast path: case already matches what's on disk (always true on case-insensitive
		// filesystems like Windows/NTFS), so skip the per-directory enumeration entirely.
		if (sys.FileSystem.exists(baseDir + path))
			return path;

		var current = StringTools.endsWith(baseDir, "/") ? baseDir.substr(0, baseDir.length - 1) : baseDir;
		var out = [];
		for (part in path.split("/")) {
			if (part == "" || part == ".")
				continue;
			var real = lookupRealCase(current, part);
			if (real == null)
				return null;
			out.push(real);
			current = current + "/" + real;
		}
		return out.join("/");
	}

	override function open(path:String, check = true) {
		var r = fileCache.get(path.toLowerCase());
		if (r != null)
			return r.r;
		var e = null;
		// resolve to the actual on-disk casing so lookups work on case-sensitive filesystems
		var realPath = check ? resolveRealPath(path) : path;
		if (realPath != null) {
			var f = sys.FileSystem.fullPath(baseDir + realPath);
			if (f != null) {
				f = f.split("\\").join("/");
				if (!check || sys.FileSystem.exists(f)) {
					e = new TorqueFileEntry(this, realPath.split("/").pop(), realPath, f);
					convert.run(e);
					if (e.file == null)
						e = null;
				}
			}
		}
		fileCache.set(path.toLowerCase(), {r: e});
		return e;
	}

	override public function dir(path:String):Array<hxd.fs.FileEntry> {
		var realPath = resolveRealPath(path);
		if (realPath == null || !sys.FileSystem.isDirectory(baseDir + realPath))
			throw new hxd.fs.NotFound(baseDir + path);
		var files = sys.FileSystem.readDirectory(baseDir + realPath);
		var r:Array<hxd.fs.FileEntry> = [];
		for (f in files)
			r.push(open((realPath == "" ? "" : realPath + "/") + f, false));
		return r;
	}
	#end
}
