package src;

import h3d.Vector;
import hxd.res.DefaultFont;
import h2d.Text;

class ProfilerUI {
	var fpsCounter:Text;
	var debugProfiler:h3d.impl.Benchmark;

	public var fps:Float;

	public static var instance:ProfilerUI;

	public function new(s2d:h2d.Scene) {
		if (instance != null)
			return;

		instance = this;
		// debugProfiler = new h3d.impl.Benchmark(s2d);
		// debugProfiler.y = 40;

		// fpsCounter = new Text(DefaultFont.get(), s2d);
		// fpsCounter.y = 80;
		// fpsCounter.color = new Vector(1, 1, 1, 1);
	}

	public static function begin() {
		// instance.debugProfiler.begin();
	}

	public static function measure(name:String) {
		// instance.debugProfiler.measure(name);
	}

	public static function end() {
		// instance.debugProfiler.end();
	}

	public static function update(fps:Float) {
		instance.fps = fps;
		// instance.fpsCounter.text = "FPS: " + fps;
	}
}
