package net;

import src.ResourceLoader;
import src.AudioManager;
import net.NetPacket.GemPickupPacket;
import net.NetPacket.GemSpawnPacket;
import net.BitStream.InputBitStream;
import net.BitStream.OutputBitStream;
import net.NetPacket.PowerupPickupPacket;
import net.ClientConnection;
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

enum abstract NetPacketType(Int) from Int to Int {
	var NullPacket;
	var ClientIdAssign;
	var NetCommand;
	var Ping;
	var PingBack;
	var MarbleUpdate;
	var MarbleMove;
	var PowerupPickup;
	var GemSpawn;
	var GemPickup;
	var PlayerInfo;
}

@:publicFields
class ServerInfo {
	var name:String;
	var players:Int;
	var maxPlayers:Int;
	var privateSlots:Int;
	var privateServer:Bool;
	var inviteCode:Int;
	var state:String;
	var platform:String;

	public function new(name:String, players:Int, maxPlayers:Int, privateSlots:Int, privateServer:Bool, inviteCode:Int, state:String, platform:String) {
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
	public static var clients:Map<RTCPeerConnection, GameConnection> = [];
	public static var clientIdMap:Map<Int, GameConnection> = [];
	public static var clientConnection:ClientConnection;
	public static var serverInfo:ServerInfo;

	public static function hostServer(name:String, maxPlayers:Int, privateSlots:Int, privateServer:Bool) {
		serverInfo = new ServerInfo(name, 1, maxPlayers, privateSlots, privateServer, Std.int(999999 * Math.random()), "Lobby", getPlatform());
		MasterServerClient.connectToMasterServer(() -> {
			isHost = true;
			isClient = false;
			clientId = 0;
			isMP = true;
			MasterServerClient.instance.sendServerInfo(serverInfo);
		});

		// host = new RTCPeerConnection(["stun.l.google.com:19302"], "0.0.0.0");
		// host.bind("127.0.0.1", 28000, (c) -> {
		// 	onClientConnect(c);
		// 	isMP = true;
		// });
		// isHost = true;
		// isClient = false;
		// clientId = 0;
		// masterWs = new WebSocket("ws://localhost:8080");

		// masterWs.onmessage = (m) -> {
		// 	switch (m) {
		// 		case StrMessage(content):
		// 			var conts = Json.parse(content);
		// 			var peer = new RTCPeerConnection(["stun:stun.l.google.com:19302"], "0.0.0.0");
		// 			peer.setRemoteDescription(conts.sdp, conts.type);
		// 			addClient(peer);

		// 		case BytesMessage(content): {}
		// 	}
		// }

		// isMP = true;
	}

	public static function addClientFromSdp(sdpString:String, onFinishSdp:String->Void) {
		var peer = new RTCPeerConnection(["stun:stun.l.google.com:19302"], "0.0.0.0");
		var sdpObj = Json.parse(sdpString);
		peer.setRemoteDescription(sdpObj.sdp, sdpObj.type);
		addClient(peer, onFinishSdp);
	}

	static function addClient(peer:RTCPeerConnection, onFinishSdp:String->Void) {
		var candidates = [];
		peer.onLocalCandidate = (c) -> {
			if (c != "")
				candidates.push('a=${c}');
		}
		peer.onGatheringStateChange = (s) -> {
			if (s == RTC_GATHERING_COMPLETE) {
				var sdpObj = StringTools.trim(peer.localDescription);
				sdpObj = sdpObj + '\r\n' + candidates.join('\r\n') + '\r\n';
				onFinishSdp(Json.stringify({
					sdp: sdpObj,
					type: "answer"
				}));
			}
		}
		peer.onDataChannel = (dc:datachannel.RTCDataChannel) -> {
			onClientConnect(peer, dc);
		}
	}

	static function addGhost(id:Int) {
		var ghost = new DummyConnection(id);
		clientIdMap[id] = ghost;
	}

	public static function joinServer(serverName:String, connectedCb:() -> Void) {
		MasterServerClient.connectToMasterServer(() -> {
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
					sdpObj = sdpObj + '\r\n' + candidates.join('\r\n') + '\r\n';
					MasterServerClient.instance.sendConnectToServer(serverName, Json.stringify({
						sdp: sdpObj,
						type: "offer"
					}));
				}
			}

			clientDatachannel = client.createDatachannel("mp");
			clientDatachannel.onOpen = (n) -> {
				Console.log("Successfully connected!");
				clients.set(client, new ClientConnection(0, client, clientDatachannel)); // host is always 0
				clientIdMap[0] = clients[client];
				clientConnection = cast clients[client];
				onConnectedToServer();
				haxe.Timer.delay(() -> connectedCb(), 1500); // 1.5 second delay to do the RTT calculation
			}
			clientDatachannel.onMessage = (b) -> {
				onPacketReceived(client, clientDatachannel, new InputBitStream(b));
			}
			clientDatachannel.onClosed = () -> {
				disconnect();
				if (MarbleGame.instance.world != null) {
					MarbleGame.instance.quitMission();
				}
			}
			clientDatachannel.onError = (msg) -> {
				Console.log('Errored out due to ${msg}');
				disconnect();
				if (MarbleGame.instance.world != null) {
					MarbleGame.instance.quitMission();
				}
			}

			isMP = true;
			isHost = false;
			isClient = true;
		});
		// masterWs = new WebSocket("ws://localhost:8080");
		// masterWs.onopen = () -> {
		// 	client = new RTCPeerConnection(["stun:stun.l.google.com:19302"], "0.0.0.0");
		// 	var candidates = [];

		// 	client.onLocalCandidate = (c) -> {
		// 		if (c != "")
		// 			candidates.push('a=${c}');
		// 	}
		// 	client.onGatheringStateChange = (s) -> {
		// 		if (s == RTC_GATHERING_COMPLETE) {
		// 			Console.log("Local Description Set!");
		// 			var sdpObj = StringTools.trim(client.localDescription);
		// 			sdpObj = sdpObj + '\r\n' + candidates.join('\r\n') + '\r\n';
		// 			masterWs.send(Json.stringify({
		// 				type: "connect",
		// 				sdpObj: {
		// 					sdp: sdpObj,
		// 					type: "offer"
		// 				}
		// 			}));
		// 		}
		// 	}

		// 	masterWs.onmessage = (m) -> {
		// 		switch (m) {
		// 			case StrMessage(content):
		// 				Console.log("Remote Description Received!");
		// 				var conts = Json.parse(content);
		// 				client.setRemoteDescription(conts.sdp, conts.type);
		// 			case _: {}
		// 		}
		// 	}

		// 	clientDatachannel = client.createDatachannel("mp");
		// 	clientDatachannel.onOpen = (n) -> {
		// 		Console.log("Successfully connected!");
		// 		clients.set(client, new ClientConnection(0, client, clientDatachannel)); // host is always 0
		// 		clientIdMap[0] = clients[client];
		// 		clientConnection = cast clients[client];
		// 		onConnectedToServer();
		// 		haxe.Timer.delay(() -> connectedCb(), 1500); // 1.5 second delay to do the RTT calculation
		// 	}
		// 	clientDatachannel.onMessage = (b) -> {
		// 		onPacketReceived(client, clientDatachannel, new InputBitStream(b));
		// 	}

		// 	isMP = true;
		// 	isHost = false;
		// 	isClient = true;
		// }
	}

	public static function disconnect() {
		if (Net.isClient) {
			NetCommands.clientLeave(Net.clientId);
			Net.isMP = false;
			Net.isClient = false;
			Net.isHost = false;
			Net.client.close();
			Net.client = null;
			Net.clientId = 0;
			Net.clientIdMap.clear();
			Net.clientConnection = null;
		}
		if (Net.isHost) {
			NetCommands.serverClosed();
			for (client => gc in clients) {
				client.close();
			}
			Net.isMP = false;
			Net.isClient = false;
			Net.isHost = false;
			Net.clients.clear();
			Net.clientIdMap.clear();
			MasterServerClient.disconnectFromMasterServer();
		}
	}

	static function onClientConnect(c:RTCPeerConnection, dc:RTCDataChannel) {
		clientId += 1;
		var cc = new ClientConnection(clientId, c, dc);
		clients.set(c, cc);
		clientIdMap[clientId] = clients[c];
		dc.onMessage = (msgBytes) -> {
			onPacketReceived(c, dc, new InputBitStream(msgBytes));
		}
		dc.onClosed = () -> {
			clients.remove(c);
			onClientLeave(cc);
		}
		dc.onError = (msg) -> {
			clients.remove(c);
			Console.log('Client ${cc.id} errored out due to: ${msg}');
			onClientLeave(cc);
		}
		var b = haxe.io.Bytes.alloc(2);
		b.set(0, ClientIdAssign);
		b.set(1, clientId);
		dc.sendBytes(b);
		Console.log("Client has connected!");
		// Send the ping packet to calculcate the RTT
		var b = haxe.io.Bytes.alloc(2);
		b.set(0, Ping);
		b.set(1, 3); // Count
		cast(clients[c], ClientConnection).pingSendTime = Console.time();
		dc.sendBytes(b);
		Console.log("Sending ping packet!");

		AudioManager.playSound(ResourceLoader.getAudio("data/sound/spawn_alternate.wav").resource);

		serverInfo.players++;
		MasterServerClient.instance.sendServerInfo(serverInfo); // notify the server of the new player
	}

	static function onConnectedToServer() {
		Console.log("Connected to the server!");
		// Send the ping packet to calculate the RTT
		var b = haxe.io.Bytes.alloc(2);
		b.set(0, Ping);
		b.set(1, 3); // Count
		cast(clients[client], ClientConnection).pingSendTime = Console.time();
		clientDatachannel.sendBytes(b);
		Console.log("Sending ping packet!");
	}

	static function onClientLeave(cc:ClientConnection) {
		if (!Net.isMP)
			return;
		serverInfo.players--;
		MasterServerClient.instance.sendServerInfo(serverInfo); // notify the server of the player leave
		NetCommands.clientDisconnected(cc.id);
	}

	static function sendPlayerInfosBytes() {
		var b = new haxe.io.BytesOutput();
		b.writeByte(PlayerInfo);
		var cnt = 0;
		for (c in clientIdMap)
			cnt++;
		b.writeByte(cnt);
		for (c => v in clientIdMap)
			b.writeByte(c);
		return b.getBytes();
	}

	static function onPacketReceived(c:RTCPeerConnection, dc:RTCDataChannel, input:InputBitStream) {
		if (!Net.isMP)
			return; // only for MP
		var packetType = input.readByte();
		switch (packetType) {
			case NetCommand:
				NetCommands.readPacket(input);

			case ClientIdAssign:
				clientId = input.readByte(); // 8 bit client id, hopefully we don't exceed this
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
				var conn:ClientConnection = cast clients[c];
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
					if (Net.isHost) {
						var b = sendPlayerInfosBytes();
						for (cc in clients) {
							cc.sendBytes(b);
						}
					}
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
				cc.queueMove(movePacket.move);

			case PowerupPickup:
				var powerupPickupPacket = new PowerupPickupPacket();
				powerupPickupPacket.deserialize(input);
				if (MarbleGame.instance.world != null) {
					var m = @:privateAccess MarbleGame.instance.world.powerupPredictions;
					m.acknowledgePowerupPickup(powerupPickupPacket, MarbleGame.instance.world.timeState, clientConnection.moveManager.getQueueSize());
				}

			case GemSpawn:
				var gemSpawnPacket = new GemSpawnPacket();
				gemSpawnPacket.deserialize(input);
				if (MarbleGame.instance.world != null) {
					MarbleGame.instance.world.spawnHuntGemsClientSide(gemSpawnPacket.gemIds);
					@:privateAccess MarbleGame.instance.world.gemPredictions.acknowledgeGemSpawn(gemSpawnPacket);
				}

			case GemPickup:
				var gemPickupPacket = new GemPickupPacket();
				gemPickupPacket.deserialize(input);
				if (MarbleGame.instance.world != null) {
					@:privateAccess MarbleGame.instance.world.playGui.incrementPlayerScore(gemPickupPacket.clientId, gemPickupPacket.scoreIncr);
					@:privateAccess MarbleGame.instance.world.gemPredictions.acknowledgeGemPickup(gemPickupPacket);
				}

			case PlayerInfo:
				var count = input.readByte();
				var newP = false;
				for (i in 0...count) {
					var id = input.readByte();
					if (id != 0 && id != Net.clientId && !clientIdMap.exists(id)) {
						Console.log('Adding ghost connection ${id}');
						addGhost(id);
						newP = true;
					}
				}
				if (newP) {
					AudioManager.playSound(ResourceLoader.getAudio("sounds/spawn_alternate.wav").resource);
				}

			case _:
				Console.log("unknown command: " + packetType);
		}
	}

	public static function sendPacketToAll(packetData:OutputBitStream) {
		var bytes = packetData.getBytes();
		for (c => v in clients) {
			v.sendBytes(bytes);
		}
	}

	public static function sendPacketToHost(packetData:OutputBitStream) {
		if (clientDatachannel.state == Open) {
			var bytes = packetData.getBytes();
			clientDatachannel.sendBytes(bytes);
		}
	}

	public static function addDummyConnection() {
		if (Net.isHost) {
			addGhost(Net.clientId++);
		}
	}

	public static function getPlatform() {
		#if js
		return "Browser";
		#end
		#if hl
		#if MACOS_BUNDLE
		return "MacOS";
		#else
		return "Windows";
		#end
		#end
	}
}
