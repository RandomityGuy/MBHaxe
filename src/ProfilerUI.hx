package src;

import h3d.Vector;
import hxd.res.DefaultFont;
import h2d.Text;

class ProfilerUI {
	var fpsCounter:Text;
	var debugProfiler:h3d.impl.Benchmark;
	var s2d:h2d.Scene;

	public var fps:Float;

	public static var instance:ProfilerUI;

	static var enabled:Bool = false;

	public function new(s2d:h2d.Scene) {
		if (instance != null)
			return;

		instance = this;
		this.s2d = s2d;
	}

	public static function begin() {
		if (!enabled)
			return;
		instance.debugProfiler.begin();
	}

	public static function measure(name:String) {
		if (!enabled)
			return;
		instance.debugProfiler.measure(name);
	}

	public static function end() {
		if (!enabled)
			return;
		instance.debugProfiler.end();
	}

	public static function update(fps:Float) {
		instance.fps = fps;
		if (!enabled)
			return;
		instance.fpsCounter.text = "FPS: " + fps;
	}

	public static function setEnabled(val:Bool) {
		enabled = val;
		if (enabled) {
			if (instance.debugProfiler != null) {
				instance.debugProfiler.remove();
				instance.debugProfiler = null;
			}
			if (instance.fpsCounter != null) {
				instance.fpsCounter.remove();
				instance.fpsCounter = null;
			}
			instance.debugProfiler = new h3d.impl.Benchmark(instance.s2d);
			instance.debugProfiler.y = 40;

			instance.fpsCounter = new Text(DefaultFont.get(), instance.s2d);
			instance.fpsCounter.y = 80;
			instance.fpsCounter.color = new Vector(1, 1, 1, 1);
		} else {
			instance.debugProfiler.remove();
			instance.fpsCounter.remove();
			instance.debugProfiler = null;
			instance.fpsCounter = null;
		}
	}
}
