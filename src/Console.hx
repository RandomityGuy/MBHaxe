package src;

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

	public function new() {
		if (instance == null) {
			instance = this;
		}
		entries = [];
		consumers = [];
		timeSinceStart = haxe.Timer.stamp();
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
}
