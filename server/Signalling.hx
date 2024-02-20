import haxe.Json;
import hx.ws.SocketImpl;
import hx.ws.WebSocketHandler;
import hx.ws.WebSocketServer;
import hx.ws.State;
import hx.ws.Log;
import hx.ws.HttpHeader;
import hx.ws.HttpResponse;
import hx.ws.HttpRequest;

using Lambda;

class SignallingHandler extends WebSocketHandler {
	static var clients:Array<SignallingHandler> = [];

	public override function handshake(httpRequest:HttpRequest) {
		var httpResponse = new HttpResponse();

		httpResponse.headers.set(HttpHeader.SEC_WEBSOSCKET_VERSION, "13");
		httpResponse.headers.set("Access-Control-Allow-Origin", "*"); // Enable CORS pls, why do i have to override this entire function for a single line
		if (httpRequest.method != "GET" || httpRequest.httpVersion != "HTTP/1.1") {
			httpResponse.code = 400;
			httpResponse.text = "Bad";
			httpResponse.headers.set(HttpHeader.CONNECTION, "close");
			httpResponse.headers.set(HttpHeader.X_WEBSOCKET_REJECT_REASON, 'Bad request');
		} else if (httpRequest.headers.get(HttpHeader.SEC_WEBSOSCKET_VERSION) != "13") {
			httpResponse.code = 426;
			httpResponse.text = "Upgrade";
			httpResponse.headers.set(HttpHeader.CONNECTION, "close");
			httpResponse.headers.set(HttpHeader.X_WEBSOCKET_REJECT_REASON,
				'Unsupported websocket client version: ${httpRequest.headers.get(HttpHeader.SEC_WEBSOSCKET_VERSION)}, Only version 13 is supported.');
		} else if (httpRequest.headers.get(HttpHeader.UPGRADE) != "websocket") {
			httpResponse.code = 426;
			httpResponse.text = "Upgrade";
			httpResponse.headers.set(HttpHeader.CONNECTION, "close");
			httpResponse.headers.set(HttpHeader.X_WEBSOCKET_REJECT_REASON, 'Unsupported upgrade header: ${httpRequest.headers.get(HttpHeader.UPGRADE)}.');
		} else if (httpRequest.headers.get(HttpHeader.CONNECTION).indexOf("Upgrade") == -1) {
			httpResponse.code = 426;
			httpResponse.text = "Upgrade";
			httpResponse.headers.set(HttpHeader.CONNECTION, "close");
			httpResponse.headers.set(HttpHeader.X_WEBSOCKET_REJECT_REASON, 'Unsupported connection header: ${httpRequest.headers.get(HttpHeader.CONNECTION)}.');
		} else {
			Log.debug('Handshaking', id);
			var key = httpRequest.headers.get(HttpHeader.SEC_WEBSOCKET_KEY);
			var result = makeWSKeyResponse(key);
			Log.debug('Handshaking key - ${result}', id);

			httpResponse.code = 101;
			httpResponse.text = "Switching Protocols";
			httpResponse.headers.set(HttpHeader.UPGRADE, "websocket");
			httpResponse.headers.set(HttpHeader.CONNECTION, "Upgrade");
			httpResponse.headers.set(HttpHeader.SEC_WEBSOSCKET_ACCEPT, result);
		}

		sendHttpResponse(httpResponse);

		if (httpResponse.code == 101) {
			_onopenCalled = false;
			state = State.Head;
			Log.debug('Connected', id);
		} else {
			close();
		}
	}

	public function new(s:SocketImpl) {
		super(s);
		onopen = () -> {
			clients.push(this);
		}
		onclose = () -> {
			clients.remove(this);
		}
		onmessage = (m) -> {
			switch (m) {
				case StrMessage(content):
					var conts = Json.parse(content);
					if (conts.type == "connect") {
						trace('Connect received');
						var other = clients.find(x -> x != this);
						other.send(Json.stringify(conts.sdpObj));
					}
				case _: {}
			}
		}
	}
}

class Signalling {
	static function main() {
		var ws = new WebSocketServer<SignallingHandler>("0.0.0.0", 8080, 2);
		ws.start();
	}
}
