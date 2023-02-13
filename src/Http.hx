package src;

import src.Console;
import sys.thread.FixedThreadPool;

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
				responses.add(() -> req.errCallback(e));
				req.fulfilled = true;
			};
			http.onBytes = (b) -> {
				responses.add(() -> req.callback(b));
				req.fulfilled = true;
			};
			hl.Gc.blocking(true); // Wtf is this shit
			http.request(false);
			hl.Gc.blocking(false);
		}
	}
	#end

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

	public static function cancel(req:HttpRequest) {
		#if sys
		cancellationMutex.acquire();
		req.cancelled = true;
		cancellationMutex.release();
		#end
	}
}
