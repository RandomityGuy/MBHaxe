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

	public function addTaskParallel(task:(() -> Void)->Void) {
		paralleltasks.push(task);
	}

	public function run() {
		if (!parallelstarted && paralleltasks.length > 0) {
			parallelstarted = true;
			var taskcount = paralleltasks.length;
			var tasksdone = 0;
			var doneTasks = new Map();
			var i = 0;
			for (task in paralleltasks) {
				var taskIndex = i;
				task(() -> {
					if (doneTasks.exists(taskIndex)) {
						trace('Warning: Task already marked as done!');
					} else {
						doneTasks.set(taskIndex, true);
						tasksdone++;
					}
					if (tasksdone == taskcount) {
						this.run();
					}
				});
				i++;
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
		// if its a jpg, png or gif, load it as bitmap else load as file
		var fileExtension = path.split('.').pop();
		if (fileExtension != null) {
			fileExtension = fileExtension.toLowerCase();
			if (fileExtension == "jpg" || fileExtension == "png" || fileExtension == "bmp") {
				paralleltasks.push(fwd -> {
					var file = ResourceLoader.load(path);
					file.entry.loadBitmap(v -> {
						fwd();
					});
				});
			} else if (fileExtension != "") {
				paralleltasks.push(fwd -> ResourceLoader.load(path).entry.load(fwd));
			}
		} else {
			paralleltasks.push(fwd -> ResourceLoader.load(path).entry.load(fwd));
		}
	}
}
