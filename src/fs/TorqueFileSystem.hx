package fs;

import hxd.fs.LocalFileSystem;

class TorqueFileSystem extends LocalFileSystem {
	#if hl
	override function checkPath(path:String) {
		// make sure the file is loaded with correct case !
		var baseDir = new haxe.io.Path(path).dir;
		var c = directoryCache.get(baseDir.toLowerCase());
		var isNew = false;
		if (c == null) {
			isNew = true;
			c = new Map();
			for (f in try sys.FileSystem.readDirectory(baseDir) catch (e:Dynamic) [])
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
			e = new LocalEntry(this, path.split("/").pop(), path, f);
			convert.run(e);
			if (e.file == null)
				e = null;
		}
		fileCache.set(path.toLowerCase(), {r: e});
		return e;
	}
	#end
}
