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

import hxd.res.EmbedOptions;
import haxe.io.Path;
import haxe.io.Bytes;

typedef ManifestFileInfo = {
	var path:String;
	var original:String;
}

class ManifestBuilder {
	public static macro function initManifest(?basePath:String, ?options:hxd.res.EmbedOptions, ?storeManifest:String) {
		var data = makeManifest(basePath, options, storeManifest);
		if (basePath == null)
			basePath = "res";
		return macro {
			var loader = new fs.ManifestLoader(@:privateAccess new fs.ManifestFileSystem($v{basePath}, haxe.io.Bytes.ofString($v{data.manifest.toString()})));
			hxd.Res.loader = loader;
			loader;
		}
	}

	public static macro function generate(?basePath:String, ?options:hxd.res.EmbedOptions, ?storeManifest:String) {
		var data = makeManifest(basePath, options, storeManifest);
		return macro {};
	}

	public static macro function create(?basePath:String, ?options:hxd.res.EmbedOptions, ?storeManifest:String) {
		var data = makeManifest(basePath, options, storeManifest);

		// var types = {
		//   expr : haxe.macro.Expr.ExprDef.EBlock([for( t in data.types ) haxe.macro.MacroStringTools.toFieldExpr(t.split("."))]),
		//   pos : haxe.macro.Context.currentPos(),
		// };

		return macro @:privateAccess new fs.ManifestFileSystem($v{basePath}, haxe.io.Bytes.ofString($v{data.manifest.toString()}));
	}

	#if macro
	private static function makeManifest(?basePath:String, ?options:hxd.res.EmbedOptions, ?storeManifest:String) {
		var f = new hxd.res.FileTree(basePath);
		var manifest:Bytes = build(f, options);

		if (storeManifest != null) {
			if (!haxe.macro.Context.defined("display")) {
				#if !display
				var tmp:String = Path.join([@:privateAccess f.paths[0], storeManifest + ".manifest"]);
				sys.io.File.saveBytes(tmp, manifest);
				#end
			}
		}
		return {tree: f, manifest: manifest};
	}

	// private static function makeTree(t:hxd.res.FileTree.FileTreeData, out:Array<ManifestFileInfo>):Void
	// {
	//   for (f in t.files) out.push(f.relPath);
	//   for (d in t.dirs) makeTree(d, out);
	// }

	public static function build(tree:hxd.res.FileTree, ?options:hxd.res.EmbedOptions, ?manifestOptions:ManifestOptions):Bytes {
		var manifest:Array<ManifestFileInfo> = new Array();
		var data = scan(tree, options, manifest);
		// makeTree(data, manifest);

		if (manifestOptions == null) {
			manifestOptions = {format: ManifestFormat.Json};
		}
		if (manifestOptions.format == null)
			manifestOptions.format = ManifestFormat.List;

		switch (manifestOptions.format) {
			// case ManifestFormat.List:
			//   return haxe.io.Bytes.ofString("l\n" + manifest.join("\n"));
			case Json:
				return haxe.io.Bytes.ofString(haxe.Json.stringify(manifest));
			case v:
				// case ManifestFormat.KeyValue:

				// case ManifestFormat.Serialized:

				// case ManifestFormat.Json:
				throw "unsupported manifest foramt: " + v;
		}
	}

	static var options:EmbedOptions;

	static function scan(t:hxd.res.FileTree, options:EmbedOptions, out:Array<ManifestFileInfo>) {
		if (options == null)
			options = {};
		// if( options.compressAsMp3 == null ) options.compressAsMp3 = options.compressSounds && !(haxe.macro.Context.defined("stb_ogg_sound") || hxd.res.Config.platform == HL);
		ManifestBuilder.options = options;

		var tree = @:privateAccess t.scan();

		for (path in @:privateAccess t.paths) {
			var fs = new hxd.fs.LocalFileSystem(path, options.configuration);
			// if( options.compressAsMp3 )
			//   fs.addConvert(new hxd.fs.Convert.ConvertWAV2MP3());
			// else if( options.compressSounds )
			//   fs.addConvert(new hxd.fs.Convert.ConvertWAV2MP3());
			@:privateAccess fs.convert.tmpDir = "tmp/";
			fs.convert.onConvert = function(f) Sys.println("Converting " + f.srcPath);
			convertRec(tree, path, fs, out);
		}
		return tree;
	}

	static function convertRec(tree:hxd.res.FileTree.FileTreeData, basePath:String, fs:hxd.fs.LocalFileSystem, out:Array<ManifestFileInfo>) {
		@:privateAccess for (file in tree.files) {
			// try later with another fs
			if (!StringTools.startsWith(file.fullPath, basePath))
				continue;
			var info = {path: file.relPath, original: file.relPath};
			out.push(info);
			var f = fs.get(file.relPath); // convert
			if (f.originalFile != null && f.originalFile != f.file) {
				info.original = f.relPath;
				info.path = StringTools.startsWith(f.file, fs.baseDir) ? f.file.substr(fs.baseDir.length) : f.file;
			}
		}

		for (t in tree.dirs)
			convertRec(t, basePath, fs, out);
	}
	#end
}

typedef ManifestOptions = {
	@:optional var format:ManifestFormat;
}

enum ManifestFormat {
	KeyValue;
	List;
	Serialized;
	Json;
}
