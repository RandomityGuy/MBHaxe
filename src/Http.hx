package src;

import src.Console;

typedef HttpRequest = {
	var url:String;
	var callback:haxe.io.Bytes->Void;
	var errCallback:String->Void;
	var cancelled:Bool;
	var fulfilled:Bool;
};

class Http {
	#if sys
	static var threadPool:sys.thread.FixedThreadPool;
	static var requests:sys.thread.Deque<HttpRequest> = new sys.thread.Deque<HttpRequest>();
	static var responses:sys.thread.Deque<() -> Void> = new sys.thread.Deque<() -> Void>();
	static var cancellationMutex:sys.thread.Mutex = new sys.thread.Mutex();
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
			cancellationMutex.acquire();
			if (req.cancelled) {
				cancellationMutex.release();
				continue;
			}
			cancellationMutex.release();
			var http = new sys.Http(req.url);
			http.onError = (e) -> {
				trace('HTTP Request Failed: ' + req.url);
				responses.add(() -> req.errCallback(e));
				req.fulfilled = true;
			};
			http.onBytes = (b) -> {
				trace('HTTP Request Succeeded: ' + req.url);
				responses.add(() -> req.callback(b));
				req.fulfilled = true;
			};
			#if !MACOS_BUNDLE
			hl.Gc.blocking(true); // Wtf is this shit
			trace('HTTP Request: ' + req.url);
			#end
			http.request(false);
			#if !MACOS_BUNDLE
			hl.Gc.blocking(false);
			#end
		}
	}
	#end

	// Returns HTTPRequest on sys, Int on js
	public static function get(url:String, callback:haxe.io.Bytes->Void, errCallback:String->Void) {
		var req = {
			url: url,
			callback: callback,
			errCallback: errCallback,
			cancelled: false,
			fulfilled: false
		};
		#if sys
		requests.add(req);
		return req;
		#else
		return js.Browser.window.setTimeout(() -> {
			js.Browser.window.fetch(url).then(r -> r.arrayBuffer().then(b -> callback(haxe.io.Bytes.ofData(b))), e -> errCallback(e.toString()));
		}, 75);
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

	#if sys
	public static function cancel(req:HttpRequest) {
		cancellationMutex.acquire();
		req.cancelled = true;
		cancellationMutex.release();
	}
	#else
	public static function cancel(req:Int) {
		js.Browser.window.clearTimeout(req);
	}
	#end
}
