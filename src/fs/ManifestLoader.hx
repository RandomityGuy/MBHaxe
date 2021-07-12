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

import fs.ManifestFileSystem.ManifestEntry;

@:allow(hxd.res.ManifestLoader.LoaderTask)
class ManifestLoader extends hxd.res.Loader {
	/**
		Amount of concurrent file loadings. Defaults to 4 on JS and to 1 native (since there's no threaded loading implemented for native)
	**/
	public static var concurrentFiles:Int = #if js 32 #else 1 #end;

	public var mfs:ManifestFileSystem;

	public var totalFiles(default, null):Int;
	public var loadedFiles(default, null):Int;
	public var loading(default, null):Bool;

	var entries:Iterator<ManifestEntry>;
	var current:ManifestEntry;

	/**
		List of loading tasks used during loading.
	**/
	public var tasks:Array<LoaderTask>;

	public function new(fs:ManifestFileSystem) {
		super(fs);
		mfs = fs;
		totalFiles = 0;
		for (f in fs.manifest)
			totalFiles++;
		loadedFiles = 0;
		loading = false;
	}

	public function loadManifestFiles() {
		if (!loading) {
			tasks = new Array();
			for (i in 0...concurrentFiles)
				tasks.push(@:privateAccess new LoaderTask(i, this));
			loading = true;
			entries = mfs.manifest.iterator();
			for (t in tasks) {
				if (entries.hasNext())
					t.load(entries.next());
				else
					break;
			}
		}
	}

	private function next(task:LoaderTask):Void {
		loadedFiles++;
		onFileLoaded(task);
		if (entries.hasNext())
			task.load(entries.next());
		else {
			for (t in tasks)
				if (t.busy)
					return;
			loading = false;
			tasks = null;
			onLoaded();
		}
	}

	// Called when loader starts loading of specific file.
	public dynamic function onFileLoadStarted(task:LoaderTask):Void {}

	// Called during file loading. loaded and total refer to loaded bytes and total file size.
	public dynamic function onFileProgress(task:LoaderTask):Void {}

	// Called when file is loaded.
	public dynamic function onFileLoaded(task:LoaderTask):Void {}

	public dynamic function onLoaded():Void {}
}

class LoaderTask {
	public var entry(default, null):ManifestEntry;

	/** Loading slot occupied by this task **/
	public var slot(default, null):Int;

	public var loaded(default, null):Int;
	public var total(default, null):Int;
	public var owner(default, null):ManifestLoader;
	public var busy(default, null):Bool;

	function new(slot:Int, owner:ManifestLoader) {
		this.slot = slot;
		this.owner = owner;
	}

	public function load(entry:ManifestEntry):Void {
		this.entry = entry;
		this.loaded = 0;
		this.total = 1;
		busy = true;
		owner.onFileLoadStarted(this);
		entry.fancyLoad(ready, progress);
	}

	function ready() {
		busy = false;
		@:privateAccess owner.next(this);
	}

	function progress(l:Int, t:Int) {
		loaded = l;
		total = t;
		owner.onFileProgress(this);
	}
}
