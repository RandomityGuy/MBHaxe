package src;

import src.Console;
import sys.thread.FixedThreadPool;

typedef HttpRequest = {
	var url:String;
	var callback:haxe.io.Bytes->Void;
	var errCallback:String->Void;
};

class Http {
	#if sys
	static var threadPool:sys.thread.FixedThreadPool;
	static var requests:sys.thread.Deque<HttpRequest> = new sys.thread.Deque<HttpRequest>();
	static var responses:sys.thread.Deque<() -> Void> = new sys.thread.Deque<() -> Void>();
	#end

	public static function init() {
		#if sys
		threadPool = new sys.thread.FixedThreadPool(4);
		threadPool.run(() -> threadLoop());
		threadPool.run(() -> threadLoop());
		threadPool.run(() -> threadLoop());
		threadPool.run(() -> threadLoop());
		#end
	}

	#if sys
	static function threadLoop() {
		while (true) {
			var req = requests.pop(true);
			var http = new sys.Http(req.url);
			http.onError = (e) -> {
				responses.add(() -> req.errCallback(e));
			};
			http.onBytes = (b) -> {
				responses.add(() -> req.callback(b));
			};
			hl.Gc.blocking(true); // Wtf is this shit
			http.request(false);
			hl.Gc.blocking(false);
		}
	}
	#end

	public static function get(url:String, callback:haxe.io.Bytes->Void, errCallback:String->Void):Void {
		var req = {
			url: url,
			callback: callback,
			errCallback: errCallback
		};
		#if sys
		requests.add(req);
		#else
		js.Browser.window.fetch(url).then(r -> r.arrayBuffer().then(b -> callback(haxe.io.Bytes.ofData(b))), e -> errCallback(e.toString()));
		#end
	}

	public static function loop() {
		#if sys
		var resp = responses.pop(false);
		if (resp != null) {
			resp();
		}
		#end
	}
}
