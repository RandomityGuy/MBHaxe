package src;

import gui.MessageBoxOkDlg;
import src.ResourceLoader;
import src.MarbleGame;

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
		#if (!android)
		paralleltasks.push(task);
		#else
		tasks.push(task);
		#end
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
			try {
				task(() -> {
					if (tasks.length > 0) {
						run();
					} else {
						onFinish();
					}
				});
			} catch (e) {
				var errorTxt = new h2d.Text(hxd.res.DefaultFont.get());
				errorTxt.setPosition(20, 20);
				errorTxt.text = e.toString();
				errorTxt.textColor = 0xFFFFFF;
				MarbleGame.canvas.scene2d.addChild(errorTxt);
			}
		} else {
			try {
				onFinish();
			} catch (e) {
				var errorTxt = new h2d.Text(hxd.res.DefaultFont.get());
				errorTxt.setPosition(20, 20);
				errorTxt.text = e.toString();
				errorTxt.textColor = 0xFFFFFF;
				MarbleGame.canvas.scene2d.addChild(errorTxt);
			}
		}
	}

	public function loadFile(path:String) {
		#if (!android)
		paralleltasks.push(fwd -> {
			try {
				ResourceLoader.load(path).entry.load(fwd);
			} catch (e) {
				var errorTxt = new h2d.Text(hxd.res.DefaultFont.get());
				errorTxt.setPosition(20, 20);
				errorTxt.text = e.toString();
				errorTxt.textColor = 0xFFFFFF;
				MarbleGame.canvas.scene2d.addChild(errorTxt);
			}
		});
		#else
		tasks.push(fwd -> {
			try {
				ResourceLoader.load(path).entry.load(fwd);
			} catch (e) {
				var errorTxt = new h2d.Text(hxd.res.DefaultFont.get());
				errorTxt.setPosition(20, 20);
				errorTxt.text = e.toString();
				errorTxt.textColor = 0xFFFFFF;
				MarbleGame.canvas.scene2d.addChild(errorTxt);
			}
		});
		#end
	}
}
