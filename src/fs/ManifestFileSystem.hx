// MIT License
// Copyright (c) 2018 Pavel Alexandrov
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
package fs;

import hxd.fs.FileInput;
import hxd.net.BinaryLoader;
import hxd.impl.ArrayIterator;
import hxd.fs.LoadedBitmap;
import hxd.fs.NotFound;
import hxd.fs.FileEntry;
import hxd.fs.FileSystem;
import haxe.io.Encoding;
import haxe.io.Path;
import haxe.io.Bytes;
#if android
import zygame.utils.hl.AssetsTools;
#end

@:allow(fs.ManifestFileSystem)
class ManifestEntry extends FileEntry {
	private var fs:ManifestFileSystem;
	private var relPath:String;

	private var isDir:Bool;
	private var contents:Array<ManifestEntry>;

	private var file:String;
	private var originalFile:String;
	#if (sys && !android)
	private var fio:sys.io.FileInput;
	#else
	private var bytes:Bytes;
	private var readPos:Int;
	private var loaded:Bool;
	#end

	public function new(fs:ManifestFileSystem, name:String, relPath:String, file:String, ?originalFile:String) {
		this.fs = fs;
		this.name = name;
		this.relPath = relPath;
		this.originalFile = originalFile;
		this.file = file;
		if (file == null) {
			isDir = true;
			contents = new Array();
		}
	}

	override public function getSign():Int {
		#if (sys && !android)
		var old = if (fio == null) -1 else fio.tell();
		open();
		var i = fio.readInt32();
		if (old < 0)
			close()
		else
			fio.seek(old, SeekBegin);
		return i;
		#else
		return bytes.get(0) | (bytes.get(1) << 8) | (bytes.get(2) << 16) | (bytes.get(3) << 24);
		#end
	}

	override public function getBytes():Bytes {
		#if (sys && !android)
		return sys.io.File.getBytes(file);
		#elseif android
		bytes = AssetsTools.getBytes(file);
		return bytes;
		#else
		return bytes;
		#end
	}

	override function readBytes(out:haxe.io.Bytes, outPos:Int, pos:Int, len:Int):Int {
		if (this.bytes == null) {
			this.bytes = getBytes();
		}
		if (pos + len > bytes.length)
			len = bytes.length - pos;
		if (len < 0)
			len = 0;
		out.blit(outPos, bytes, pos, len);
		return len;
	}

	override public function open() {
		return @:privateAccess new FileInput(this);
	}

	public function fancyLoad(onReady:() -> Void, onProgress:(cur:Int, max:Int) -> Void) {
		#if js
		if (loaded) {
			haxe.Timer.delay(onReady, 1);
		} else {
			var br:BinaryLoader = new BinaryLoader(file);
			br.onLoaded = (b) -> {
				loaded = true;
				bytes = b;
				onReady();
			}
			br.onProgress = onProgress;
			br.load();
		}
		#else
		load(onReady);
		#end
	}

	override public function load(?onReady:() -> Void) {
		#if macro
		onReady();
		#elseif js
		if (loaded) {
			if (onReady != null)
				onReady();
		} else {
			js.Browser.window.fetch(file).then((res:js.html.Response) -> {
				return res.arrayBuffer();
			}).then((buf:js.lib.ArrayBuffer) -> {
				loaded = true;
				bytes = Bytes.ofData(buf);
				if (onReady != null)
					onReady();
			});
		}
		#else
		if (onReady != null) {
			onReady();
			// haxe.Timer.delay(onReady, 1);
		}
		#end
	}

	override public function loadBitmap(onLoaded:LoadedBitmap->Void) {
		#if sys
		var bmp = new hxd.res.Image(this).toBitmap();
		onLoaded(new hxd.fs.LoadedBitmap(bmp));
		#elseif js
		load(() -> {
			var img:js.html.Image = new js.html.Image();
			img.onload = (_) -> onLoaded(new LoadedBitmap(img));
			img.src = file;
		});
		#else
		throw "Unsupported platform";
		#end
	}

	override public function exists(name:String):Bool {
		return _exists(name);
	}

	override public function get(name:String):FileEntry {
		return _get(name);
	}

	private function _exists(name:String):Bool {
		if (isDir) {
			for (c in contents)
				if (c.name.toLowerCase() == name.toLowerCase())
					return true;
		}
		return false;
	}

	private function _get(name:String):ManifestEntry {
		if (isDir) {
			for (c in contents)
				if (c.name.toLowerCase() == name.toLowerCase())
					return c;
		}
		return null;
	}

	override public function iterator():ArrayIterator<FileEntry> {
		if (isDir)
			return new ArrayIterator(cast contents);
		return null;
	}

	#if !sys
	override private function get_isAvailable():Bool {
		return loaded;
	}
	#end

	override private function get_isDirectory():Bool {
		return isDir;
	}

	override private function get_path():String {
		return relPath == "." ? "<root>" : relPath;
	}

	override private function get_size():Int {
		#if (sys && !android)
		return sys.FileSystem.stat(file).size;
		#elseif android
		var fb = AssetsTools.getBytes(file);
		return fb != null ? fb.length : 0;
		#else
		return bytes != null ? bytes.length : 0;
		#end
	}

	private function dispose():Void {
		if (isDir) {
			for (c in contents)
				c.dispose();
			contents = null;
		}
		#if (sys && !android)
		close();
		#else
		bytes = null;
		#end
	}
}

class ManifestFileSystem implements FileSystem {
	private var baseDir:String;

	public var manifest:Map<String, ManifestEntry>;

	var root:ManifestEntry;

	public function new(dir:String, _manifest:Bytes) {
		this.baseDir = Path.addTrailingSlash(dir);
		this.root = new ManifestEntry(this, "<root>", ".", null);

		this.manifest = new Map();

		inline function insert(path:String, file:String, original:String):Void {
			var dir:Array<String> = Path.directory(original).split('/');
			var r:ManifestEntry = root;
			for (n in dir) {
				if (n == "")
					continue;
				var found:Bool = false;
				for (c in r.contents) {
					if (c.name == n) {
						r = c;
						found = true;
						break;
					}
				}
				if (!found) {
					var dirEntry = new ManifestEntry(this, n, r.relPath + "/" + n, null);
					r.contents.push(dirEntry);
					r = dirEntry;
				}
			}
			var entry:ManifestEntry = new ManifestEntry(this, Path.withoutDirectory(original), original, file, original);
			r.contents.push(entry);
			manifest.set(path, entry);
		}

		switch (_manifest.get(0)) {
			case 0:
				// binary
				throw "Binary manifest not yet supported!";
			case 1:
				// serialized
				throw "Serialized manifest not yet supported!";
			case 'm'.code:
				// id:path mapping
				throw "Mapping manifest not yet supported";
			// var mapping:Array<String> = _manifest.getString(2, _manifest.length - 2, Encoding.UTF8).split("\n");
			// for (map in mapping)
			// {
			//   var idx:Int = map.indexOf(":");
			//   insert(map.substr(0, idx), baseDir + map.substr(idx+1));
			// }
			case 'l'.code:
				// path mapping
				throw "List manifest not yet supported";
			// var mapping:Array<String> = _manifest.getString(2, _manifest.length - 2, Encoding.UTF8).split("\n");
			// for (path in mapping)
			// {
			//   insert(path, baseDir + path);
			// }
			case '['.code:
				// JSON
				var json:Array<{path:String, original:String}> = haxe.Json.parse(_manifest.toString());
				for (entry in json) {
					insert(entry.path, baseDir + entry.path, entry.original);
				}
		}
	}

	public function getRoot():FileEntry {
		return root;
	}

	private function splitPath(path:String) {
		return path == "." ? [] : path.split("/");
	}

	private function find(path:String):ManifestEntry {
		var r = root;
		for (p in splitPath(path.toLowerCase())) {
			r = r._get(p.toLowerCase());
			if (r == null)
				return null;
		}
		return r;
	}

	public function exists(path:String) {
		return find(path) != null;
	}

	public function get(path:String) {
		var entry:ManifestEntry = find(path);
		if (entry == null)
			throw new NotFound(path);
		return entry;
	}

	public function dispose() {
		root.dispose();
		root = null;
	}

	public function dir(path:String):Array<FileEntry> {
		var entry:ManifestEntry = find(path.toLowerCase());
		if (entry == null)
			throw new NotFound(path);
		return cast entry.contents.copy();
	}
}
/*

	using haxe.io.Path;

	class BytesFileEntry extends FileEntry {

	  var fullPath : String;
	  var bytes : haxe.io.Bytes;
	  var pos : Int;

	  public function new(path, bytes) {
	this.fullPath = path;
	this.name = path.split("/").pop();
	this.bytes = bytes;
	  }

	  override function get_path() {
	return fullPath;
	  }

	  override function getSign() : Int {
	return bytes.get(0) | (bytes.get(1) << 8) | (bytes.get(2) << 16) | (bytes.get(3) << 24);
	  }

	  override function getBytes() : haxe.io.Bytes {
	return bytes;
	  }

	  override function open() {
	pos = 0;
	  }

	  override function skip( nbytes : Int ) {
	pos += nbytes;
	  }
	  override function readByte() : Int {
	return bytes.get(pos++);
	  }

	  override function read( out : haxe.io.Bytes, pos : Int, size : Int ) {
	out.blit(pos, bytes, this.pos, size);
	this.pos += size;
	  }

	  override function close() {
	  }

	  override function load( ?onReady : Void -> Void ) : Void {
	haxe.Timer.delay(onReady, 1);
	  }

	  override function loadBitmap( onLoaded : LoadedBitmap -> Void ) : Void {
	#if flash
	var loader = new flash.display.Loader();
	loader.contentLoaderInfo.addEventListener(flash.events.IOErrorEvent.IO_ERROR, function(e:flash.events.IOErrorEvent) {
	  throw Std.string(e) + " while loading " + fullPath;
	});
	loader.contentLoaderInfo.addEventListener(flash.events.Event.COMPLETE, function(_) {
	  var content : flash.display.Bitmap = cast loader.content;
	  onLoaded(new hxd.fs.LoadedBitmap(content.bitmapData));
	  loader.unload();
	});
	loader.loadBytes(bytes.getData());
	#elseif js
	var mime = switch fullPath.extension().toLowerCase() {
	  case 'jpg' | 'jpeg': 'image/jpeg';
	  case 'png': 'image/png';
	  case 'gif': 'image/gif';
	  case _: throw 'Cannot determine image encoding, try adding an extension to the resource path';
	}
	var img = new js.html.Image();
	img.onload = function() onLoaded(new hxd.fs.LoadedBitmap(img));
	img.src = 'data:$mime;base64,' + haxe.crypto.Base64.encode(bytes);
	#else
	throw "Not implemented";
	#end
	  }

	  override function exists( name : String ) : Bool return false;
	  override function get( name : String ) : FileEntry return null;

	  override function iterator() : hxd.impl.ArrayIterator<FileEntry> return new hxd.impl.ArrayIterator(new Array<FileEntry>());

	  override function get_size() return bytes.length;

	}

	class BytesFileSystem implements FileSystem {


}*/
