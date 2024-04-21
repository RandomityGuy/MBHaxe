import haxe.net.WebSocket;
import haxe.CallStack;
import haxe.net.WebSocketServer;
import haxe.Json;

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

class SignallingHandler {
	static var clients:Array<SignallingHandler> = [];

	static var servers:Array<ServerInfo> = [];

	static var joiningClients:Map<Int, SignallingHandler> = [];

	static var clientId = 0;

	static var _nextId = 0;

	var _id = _nextId++;
	var _websocket:WebSocket;

	public function update():Bool {
		_websocket.process();
		return _websocket.readyState != Closed;
	}

	inline function sendString(str:String) {
		_websocket.sendString(str);
	}

	public function new(s:WebSocket) {
		_websocket.onopen = () -> {
			clients.push(this);
		}
		_websocket.onclose = function(?e:Dynamic) {
			trace('Removing server');
			servers = servers.filter(x -> x.socket != this); // remove server
			for (key => val in joiningClients) {
				if (val == this) {
					joiningClients.remove(key);
					break;
				}
			}
			clients.remove(this);
		}
		_websocket.onerror = (msg) -> {
			trace('Removing server');
			servers = servers.filter(x -> x.socket != this); // remove server
			for (key => val in joiningClients) {
				if (val == this) {
					joiningClients.remove(key);
					break;
				}
			}
			clients.remove(this);
		}
		_websocket.onmessageString = (content) -> {
			var conts = Json.parse(content);
			trace('Received ${conts.type}');
			if (conts.type == "serverInfo") {
				var serverInfo = new ServerInfo(this, conts.name, conts.players, conts.maxPlayers, conts.privateSlots, conts.privateServer, conts.inviteCode,
					conts.state, conts.platform);
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
						this.sendString(Json.stringify({
							type: "connectFailed",
							reason: "The server is full"
						}));
					} else {
						var cid = clientId++;
						joiningClients.set(cid, this);
						serverInfo.socket.sendString(Json.stringify({
							type: "connect",
							sdp: conts.sdp,
							clientId: cid
						}));
					}
				} else {
					this.sendString(Json.stringify({
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
						client.sendString(Json.stringify({
							type: "connectFailed",
							reason: conts.reason
						}));
					} else {
						client.sendString(Json.stringify({
							type: "connectResponse",
							sdp: conts.sdp
						}));
					}
				}
			}
			if (conts.type == "serverList") {
				this.sendString(Json.stringify({
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
		}
	}
}

class MasterServer {
	static function main() {
		var ws = WebSocketServer.create("0.0.0.0", 8080, 100, true, false);
		var handlers = [];
		while (true) {
			try {
				var websocket = ws.accept();
				if (websocket != null) {
					handlers.push(new SignallingHandler(websocket));
				}

				var toRemove = [];
				for (handler in handlers) {
					if (!handler.update()) {
						toRemove.push(handler);
					}
				}

				while (toRemove.length > 0)
					handlers.remove(toRemove.pop());

				Sys.sleep(0.1);
			} catch (e:Dynamic) {
				trace('Error', e);
				trace(CallStack.exceptionStack());
			}
		}
	}
}
