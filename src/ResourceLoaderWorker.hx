package src;

import src.ResourceLoader;

class ResourceLoaderWorker {
	var tasks:Array<(() -> Void)->Void> = [];

	var onFinish:() -> Void;

	public function new(onFinish:() -> Void) {
		this.onFinish = onFinish;
	}

	public function addTask(task:(() -> Void)->Void) {
		tasks.push(task);
	}

	public function run() {
		var task = tasks.shift();
		task(() -> {
			if (tasks.length > 0) {
				run();
			} else {
				onFinish();
			}
		});
	}

	public function loadFile(path:String) {
		addTask(fwd -> ResourceLoader.loader.load(path).entry.load(fwd));
	}
}
