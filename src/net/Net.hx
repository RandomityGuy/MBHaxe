package net;

import net.NetPacket.MarbleUpdatePacket;
import net.NetPacket.MarbleMovePacket;
import haxe.Json;
import datachannel.RTCPeerConnection;
import datachannel.RTCDataChannel;
import hx.ws.WebSocket;
import src.Console;
import net.NetCommands;
import src.MarbleGame;
import hx.ws.Types.MessageType;

enum abstract GameplayState(Int) from Int to Int {
	var UNKNOWN;
	var LOBBY;
	var GAME;
}

enum abstract NetPacketType(Int) from Int to Int {
	var NullPacket;
	var ClientIdAssign;
	var NetCommand;
	var Ping;
	var PingBack;
	var MarbleUpdate;
	var MarbleMove;
}

@:publicFields
class ClientConnection {
	var id:Int;
	var socket:RTCPeerConnection;
	var datachannel:RTCDataChannel;
	var state:GameplayState;
	var moveManager:MoveManager;
	var rtt:Float;
	var pingSendTime:Float;
	var _rttRecords:Array<Float> = [];

	public function new(id:Int, socket:RTCPeerConnection, datachannel:RTCDataChannel) {
		this.socket = socket;
		this.datachannel = datachannel;
		this.id = id;
		this.state = GameplayState.LOBBY;
		this.rtt = 0;
		this.moveManager = new MoveManager(this);
	}

	public function ready() {
		state = GameplayState.GAME;
	}
}

class Net {
	static var client:RTCPeerConnection;
	static var clientDatachannel:RTCDataChannel;

	static var masterWs:WebSocket;

	public static var isMP:Bool;
	public static var isHost:Bool;
	public static var isClient:Bool;

	public static var startMP:Bool;

	public static var clientId:Int;
	public static var networkRNG:Float;
	public static var clients:Map<RTCPeerConnection, ClientConnection> = [];
	public static var clientIdMap:Map<Int, ClientConnection> = [];
	public static var clientConnection:ClientConnection;

	public static function hostServer() {
		// host = new RTCPeerConnection(["stun.l.google.com:19302"], "0.0.0.0");
		// host.bind("127.0.0.1", 28000, (c) -> {
		// 	onClientConnect(c);
		// 	isMP = true;
		// });
		isHost = true;
		isClient = false;
		clientId = 0;
		masterWs = new WebSocket("ws://localhost:8080");

		masterWs.onmessage = (m) -> {
			switch (m) {
				case StrMessage(content):
					var conts = Json.parse(content);
					var peer = new RTCPeerConnection(["stun:stun.l.google.com:19302"], "0.0.0.0");
					peer.setRemoteDescription(conts.sdp, conts.type);
					addClient(peer);

				case BytesMessage(content): {}
			}
		}

		isMP = true;
	}

	static function addClient(peer:RTCPeerConnection) {
		var candidates = [];
		peer.onLocalCandidate = (c) -> {
			if (c != "")
				candidates.push('a=${c}');
		}
		peer.onGatheringStateChange = (s) -> {
			if (s == RTC_GATHERING_COMPLETE) {
				var sdpObj = StringTools.trim(peer.localDescription);
				sdpObj = sdpObj + '\r\n' + candidates.join('\r\n');
				masterWs.send(Json.stringify({
					type: "connect",
					sdpObj: {
						sdp: sdpObj,
						type: "answer"
					}
				}));
			}
		}
		peer.onDataChannel = (dc:datachannel.RTCDataChannel) -> {
			onClientConnect(peer, dc);
		}
	}

	public static function joinServer(connectedCb:() -> Void) {
		masterWs = new WebSocket("ws://localhost:8080");
		masterWs.onopen = () -> {
			client = new RTCPeerConnection(["stun:stun.l.google.com:19302"], "0.0.0.0");
			var candidates = [];

			client.onLocalCandidate = (c) -> {
				if (c != "")
					candidates.push('a=${c}');
			}
			client.onGatheringStateChange = (s) -> {
				if (s == RTC_GATHERING_COMPLETE) {
					Console.log("Local Description Set!");
					var sdpObj = StringTools.trim(client.localDescription);
					sdpObj = sdpObj + '\r\n' + candidates.join('\r\n');
					masterWs.send(Json.stringify({
						type: "connect",
						sdpObj: {
							sdp: sdpObj,
							type: "offer"
						}
					}));
				}
			}

			masterWs.onmessage = (m) -> {
				switch (m) {
					case StrMessage(content):
						Console.log("Remote Description Received!");
						var conts = Json.parse(content);
						client.setRemoteDescription(conts.sdp, conts.type);
					case _: {}
				}
			}

			clientDatachannel = client.createDatachannel("mp");
			clientDatachannel.onOpen = (n) -> {
				Console.log("Successfully connected!");
				clients.set(client, new ClientConnection(0, client, clientDatachannel)); // host is always 0
				clientIdMap[0] = clients[client];
				clientConnection = clients[client];
				onConnectedToServer();
				haxe.Timer.delay(() -> connectedCb(), 1500); // 1.5 second delay to do the RTT calculation
			}
			clientDatachannel.onMessage = (b) -> {
				onPacketReceived(client, clientDatachannel, new haxe.io.BytesInput(b));
			}

			isMP = true;
			isHost = false;
			isClient = true;
		}
	}

	static function onClientConnect(c:RTCPeerConnection, dc:RTCDataChannel) {
		clientId += 1;
		clients.set(c, new ClientConnection(clientId, c, dc));
		clientIdMap[clientId] = clients[c];
		dc.onMessage = (msgBytes) -> {
			onPacketReceived(c, dc, new haxe.io.BytesInput(msgBytes));
		}
		var b = haxe.io.Bytes.alloc(3);
		b.set(0, ClientIdAssign);
		b.setUInt16(1, clientId);
		dc.sendBytes(b);
		Console.log("Client has connected!");
		// Send the ping packet to calculcate the RTT
		var b = haxe.io.Bytes.alloc(2);
		b.set(0, Ping);
		b.set(1, 3); // Count
		clients[c].pingSendTime = Console.time();
		dc.sendBytes(b);
		Console.log("Sending ping packet!");
	}

	static function onConnectedToServer() {
		Console.log("Connected to the server!");
		// Send the ping packet to calculate the RTT
		var b = haxe.io.Bytes.alloc(2);
		b.set(0, Ping);
		b.set(1, 3); // Count
		clients[client].pingSendTime = Console.time();
		clientDatachannel.sendBytes(b);
		Console.log("Sending ping packet!");
	}

	static function onPacketReceived(c:RTCPeerConnection, dc:RTCDataChannel, input:haxe.io.BytesInput) {
		var packetType = input.readByte();
		switch (packetType) {
			case NetCommand:
				NetCommands.readPacket(input);

			case ClientIdAssign:
				clientId = input.readUInt16();
				Console.log('Client ID set to ${clientId}');

			case Ping:
				var pingLeft = input.readByte();
				Console.log("Got ping packet!");
				var b = haxe.io.Bytes.alloc(2);
				b.set(0, PingBack);
				b.set(1, pingLeft);
				dc.sendBytes(b);

			case PingBack:
				var pingLeft = input.readByte();
				Console.log("Got pingback packet!");
				var conn = clients[c];
				var now = Console.time();
				conn._rttRecords.push((now - conn.pingSendTime));
				if (pingLeft > 0) {
					conn.pingSendTime = now;
					var b = haxe.io.Bytes.alloc(2);
					b.set(0, Ping);
					b.set(1, pingLeft - 1);
					dc.sendBytes(b);
				} else {
					for (r in conn._rttRecords)
						conn.rtt += r;
					conn.rtt /= conn._rttRecords.length;
					Console.log('Got RTT ${conn.rtt} for client ${conn.id}');
				}

			case MarbleUpdate:
				var marbleUpdatePacket = new MarbleUpdatePacket();
				marbleUpdatePacket.deserialize(input);
				var cc = marbleUpdatePacket.clientId;
				if (MarbleGame.instance.world != null) {
					var m = MarbleGame.instance.world.lastMoves;
					m.enqueue(marbleUpdatePacket);
				}

			case MarbleMove:
				var movePacket = new MarbleMovePacket();
				movePacket.deserialize(input);
				var cc = clientIdMap[movePacket.clientId];
				cc.moveManager.queueMove(movePacket.move);

			case _:
				trace("unknown command: " + packetType);
		}
	}

	public static function sendPacketToAll(packetData:haxe.io.BytesOutput) {
		var bytes = packetData.getBytes();
		for (c => v in clients) {
			v.datachannel.sendBytes(packetData.getBytes());
		}
	}

	public static function sendPacketToHost(packetData:haxe.io.BytesOutput) {
		var bytes = packetData.getBytes();
		clientDatachannel.sendBytes(bytes);
	}
}
