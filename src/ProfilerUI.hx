package src;

import net.Net;
import src.MarbleGame;
import h3d.Vector;
import hxd.res.DefaultFont;
import h2d.Text;

class ProfilerUI {
	var fpsCounter:Text;
	var networkStats:Text;
	var debugProfiler:h3d.impl.Benchmark;
	var s2d:h2d.Scene;

	public var fps:Float;

	public static var instance:ProfilerUI;

	static var enabled:Bool = false;
	static var mode:Int = 0;

	public function new(s2d:h2d.Scene) {
		if (instance != null)
			return;

		instance = this;
		this.s2d = s2d;
	}

	public static function begin(type:Int) {
		if (!enabled)
			return;
		if (type == mode)
			instance.debugProfiler.begin();
	}

	public static function measure(name:String, type:Int) {
		if (!enabled)
			return;
		if (type == mode)
			instance.debugProfiler.measure(name);
	}

	public static function end(type:Int) {
		if (!enabled)
			return;
		if (type == mode)
			instance.debugProfiler.end();
	}

	public static function update(fps:Float) {
		instance.fps = fps;
		if (!enabled)
			return;
		instance.fpsCounter.text = "FPS: " + fps;
		updateNetworkStats();
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
			if (instance.networkStats != null) {
				instance.networkStats.remove();
				instance.networkStats = null;
			}
			instance.debugProfiler = new h3d.impl.Benchmark(instance.s2d);
			instance.debugProfiler.y = 40;

			instance.fpsCounter = new Text(DefaultFont.get(), instance.s2d);
			instance.fpsCounter.y = 80;
			instance.fpsCounter.color = new Vector(1, 1, 1, 1);

			instance.networkStats = new Text(DefaultFont.get(), instance.s2d);
			instance.networkStats.y = 150;
			instance.networkStats.color = new Vector(1, 1, 1, 1);

			instance.debugProfiler.end(); // End current frame
		} else {
			instance.debugProfiler.remove();
			instance.fpsCounter.remove();
			instance.networkStats.remove();
			instance.debugProfiler = null;
			instance.fpsCounter = null;
			instance.networkStats = null;
		}
	}

	public static function setDisplayMode(m:Int) {
		mode = m;
		if (instance.debugProfiler != null) {
			instance.debugProfiler.end(); // End
		}
	}

	static function updateNetworkStats() {
		if (MarbleGame.instance.world != null && MarbleGame.instance.world.isMultiplayer) {
			static var lastSentMove = 0;
			if (Net.isClient && Net.clientConnection.getQueuedMovesLength() > 0) {
				lastSentMove = @:privateAccess Net.clientConnection.moveManager.queuedMoves[Net.clientConnection.moveManager.queuedMoves.length - 1].id;
			}

			if (Net.isClient) {
				instance.networkStats.text = 'Client World Ticks: ${MarbleGame.instance.world.timeState.ticks}\n'
					+ 'Client Marble Ticks: ${@:privateAccess MarbleGame.instance.world.marble.serverTicks}\n'
					+ 'Server Ticks: ${@:privateAccess MarbleGame.instance.world.lastMoves.myMarbleUpdate.serverTicks}\n'
					+ 'Client Move Queue Size: ${Net.isClient ? Net.clientConnection.getQueuedMovesLength() : 0}\n'
					+ 'Server Move Queue Size: ${Net.isClient ? @:privateAccess MarbleGame.instance.world.lastMoves.myMarbleUpdate.moveQueueSize : 0}\n'
					+ 'Last Sent Move: ${Net.isClient ? lastSentMove : 0}\n'
					+ 'Last Ack Move: ${Net.isClient ? @:privateAccess Net.clientConnection.moveManager.lastAckMoveId : 0}\n'
					+ 'Move Ack RTT: ${Net.isClient ? @:privateAccess Net.clientConnection.moveManager.ackRTT : 0}';
			}
			if (Net.isHost) {
				var strs = [];
				strs.push('World Ticks: ${MarbleGame.instance.world.timeState.ticks}');
				for (dc => cc in Net.clients) {
					strs.push('${cc.id} move: sz ${@:privateAccess cc.moveManager.getQueueSize()} avg ${@:privateAccess cc.moveManager.serverAvgMoveListSize}');
				}

				instance.networkStats.text = strs.join('\n');
			}
		} else {
			instance.networkStats.text = "";
		}
	}
}
