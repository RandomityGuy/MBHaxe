import hx.ws.WebSocket;
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

@:publicFields
class ServerInfo {
	var socket:SignallingHandler;
	var name:String;
	var players:Int;
	var maxPlayers:Int;
	var privateSlots:Int;
	var privateServer:Bool;
	var inviteCode:Int;
	var state:String;
	var platform:String;

	public function new(socket:SignallingHandler, name:String, players:Int, maxPlayers:Int, privateSlots:Int, privateServer:Bool, inviteCode:Int,
			state:String, platform:String) {
		this.socket = socket;
		this.name = name;
		this.players = players;
		this.maxPlayers = maxPlayers;
		this.privateSlots = privateSlots;
		this.privateServer = privateServer;
		this.inviteCode = inviteCode;
		this.state = state;
		this.platform = platform;
	}
}

class SignallingHandler extends WebSocketHandler {
	static var clients:Array<SignallingHandler> = [];

	static var servers:Array<ServerInfo> = [];

	static var joiningClients:Map<Int, SignallingHandler> = [];

	static var clientId = 0;

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
			servers = servers.filter(x -> x.socket != this); // remove server
			for (key => val in joiningClients) {
				if (val == this) {
					joiningClients.remove(key);
					break;
				}
			}
			clients.remove(this);
		}
		onmessage = (m) -> {
			switch (m) {
				case StrMessage(content):
					var conts = Json.parse(content);
					trace('Received ${conts.type}');
					if (conts.type == "serverInfo") {
						var serverInfo = new ServerInfo(this, conts.name, conts.players, conts.maxPlayers, conts.privateSlots, conts.privateServer,
							conts.inviteCode, conts.state, conts.platform);
						if (servers.find(x -> x.name == serverInfo.name) == null) {
							servers.push(serverInfo);
						} else {
							servers = servers.filter(x -> x.socket != this);
							servers.push(serverInfo); // update server
						}
					}
					if (conts.type == "connect") {
						var serverInfo = servers.find(x -> x.name == conts.serverName);
						if (serverInfo != null) {
							if (serverInfo.players >= serverInfo.maxPlayers) {
								this.send(Json.stringify({
									type: "connectFailed",
									reason: "The server is full"
								}));
							} else {
								var cid = clientId++;
								joiningClients.set(cid, this);
								serverInfo.socket.send(Json.stringify({
									type: "connect",
									sdp: conts.sdp,
									clientId: cid
								}));
							}
						} else {
							this.send(Json.stringify({
								type: "connectFailed",
								reason: "Server not found"
							}));
						}
					}
					if (conts.type == "connectResponse") {
						var client = joiningClients.get(conts.clientId);
						if (client != null) {
							var success = conts.success;
							if (!success) {
								client.send(Json.stringify({
									type: "connectFailed",
									reason: conts.reason
								}));
							} else {
								client.send(Json.stringify({
									type: "connectResponse",
									sdp: conts.sdp
								}));
							}
						}
					}
					if (conts.type == "serverList") {
						this.send(Json.stringify({
							type: "serverList",
							servers: servers.filter(x -> !x.privateServer && x.state == "Lobby").map(x -> {
								return {
									name: x.name,
									players: x.players,
									maxPlayers: x.maxPlayers,
									platform: x.platform
								}
							})
						}));
					}
				case _: {}
			}
		}
	}
}

class MasterServer {
	static function main() {
		var ws = new WebSocketServer<SignallingHandler>("0.0.0.0", 8080, 2);
		ws.start();
	}
}
