package src;

import src.ResourceLoader;

class ResourceLoaderWorker {
	var tasks:Array<(() -> Void)->Void> = [];

	var paralleltasks:Array<(() -> Void)->Void> = [];

	var onFinish:() -> Void;

	var parallelstarted:Bool = false;

	public function new(onFinish:() -> Void) {
		this.onFinish = onFinish;
	}

	public function addTask(task:(() -> Void)->Void) {
		tasks.push(task);
	}

	public function run() {
		if (!parallelstarted && paralleltasks.length > 0) {
			parallelstarted = true;
			var taskcount = paralleltasks.length;
			var tasksdone = 0;
			for (task in paralleltasks) {
				task(() -> {
					tasksdone++;
					if (tasksdone == taskcount) {
						this.run();
					}
				});
			}
			return;
		}

		if (tasks.length > 0) {
			var task = tasks.shift();
			task(() -> {
				if (tasks.length > 0) {
					run();
				} else {
					onFinish();
				}
			});
		} else {
			onFinish();
		}
	}

	public function loadFile(path:String) {
		paralleltasks.push(fwd -> ResourceLoader.load(path).entry.load(fwd));
	}
}
