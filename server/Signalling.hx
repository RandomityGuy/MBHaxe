import haxe.Json;
import hx.ws.SocketImpl;
import hx.ws.WebSocketHandler;
import hx.ws.WebSocketServer;

using Lambda;

class SignallingHandler extends WebSocketHandler {
	static var clients:Array<SignallingHandler> = [];

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
