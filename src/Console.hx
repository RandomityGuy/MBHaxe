package src;

import mis.MisParser;
import src.Settings;
import src.Debug;

@:publicFields
class ConsoleEntry {
	var time:Float;
	var type:String;
	var text:String;

	public function new(time:Float, type:String, text:String) {
		this.time = time;
		this.type = type;
		this.text = text;
	}
}

class Console {
	public static var instance:Console;

	public var entries:Array<ConsoleEntry>;

	var consumers:Array<ConsoleEntry->Void>;
	var timeSinceStart:Float;

	#if hl
	var consoleFileHandle:sys.io.FileOutput;
	#end

	public function new() {
		if (instance == null) {
			instance = this;
		}
		entries = [];
		consumers = [];
		timeSinceStart = haxe.Timer.stamp();
		#if hl
		consoleFileHandle = sys.io.File.write(haxe.io.Path.join([Settings.settingsDir, "console.log"]), false);
		#end
	}

	public function clear() {
		entries = [];
	}

	function getTime() {
		return Std.int((haxe.Timer.stamp() - timeSinceStart) * 1000) / 1000;
	}

	function addEntry(type:String, msg:String) {
		var e = new ConsoleEntry(getTime(), type, msg);
		entries.push(e);
		#if hl
		consoleFileHandle.writeString('[${e.time}] ${e.text}\n');
		#end
		for (c in consumers) {
			c(e);
		}
	}

	function _log(t:String) {
		addEntry("log", t);
	}

	function _warn(t:String) {
		addEntry("warn", t);
	}

	function _error(t:String) {
		addEntry("error", t);
	}

	function _debug(t:String) {
		addEntry("debug", t);
	}

	public static function log(t:String) {
		instance._log(t);
	}

	public static function warn(t:String) {
		instance._warn(t);
	}

	public static function error(t:String) {
		instance._error(t);
	}

	public static function debug(t:String) {
		instance._debug(t);
	}

	public static function addConsumer(c:ConsoleEntry->Void) {
		instance.consumers.push(c);
	}

	public static function removeConsumer(c:ConsoleEntry->Void) {
		instance.consumers.remove(c);
	}

	public static function eval(cmd:String) {
		var cmdSplit = cmd.split(" ");
		if (cmdSplit.length != 0) {
			var cmdType = cmdSplit[0];
			if (cmdType == "help") {
				log("Available commands:");
				log("help");
				log("timeScale <scale>");
				log("drawBounds <true/false>");
				log("wireframe <true/false>");
			} else if (cmdType == "timeScale") {
				if (cmdSplit.length == 2) {
					var scale = Std.parseFloat(cmdSplit[1]);
					if (Math.isNaN(scale))
						scale = 1;
					Debug.timeScale = scale;
					log("Time scale set to " + scale);
				} else {
					error("Expected one argument, got " + (cmdSplit.length - 1));
				}
			} else if (cmdType == "drawBounds") {
				if (cmdSplit.length == 2) {
					var scale = MisParser.parseBoolean(cmdSplit[1]);
					Debug.drawBounds = scale;
					log("Debug.drawBounds set to " + scale);
				} else {
					error("Expected one argument, got " + (cmdSplit.length - 1));
				}
			} else if (cmdType == "wireframe") {
				if (cmdSplit.length == 2) {
					var scale = MisParser.parseBoolean(cmdSplit[1]);
					Debug.wireFrame = scale;
					log("Debug.wireframe set to " + scale);
				} else {
					error("Expected one argument, got " + (cmdSplit.length - 1));
				}
			} else {
				error("Unknown command");
			}

			return;
		}
		error("Unknown command");
	}
}
