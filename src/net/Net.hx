package net;

import gui.MultiplayerLevelSelectGui;
import gui.Canvas;
import net.MasterServerClient.RemoteServerInfo;
import gui.MultiplayerLoadingGui;
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
import src.Console;
import net.NetCommands;
import src.MarbleGame;
import src.Settings;

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
	var platform:NetPlatform;

	public function new(name:String, players:Int, maxPlayers:Int, privateSlots:Int, privateServer:Bool, inviteCode:Int, state:String, platform:NetPlatform) {
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

	public static var isMP:Bool;
	public static var isHost:Bool;
	public static var isClient:Bool;

	public static var lobbyHostReady:Bool;
	public static var lobbyClientReady:Bool;

	public static var clientId:Int;
	public static var networkRNG:Float;
	public static var clients:Map<RTCPeerConnection, GameConnection> = [];
	public static var clientIdMap:Map<Int, GameConnection> = [];
	public static var clientConnection:ClientConnection;
	public static var serverInfo:ServerInfo;
	public static var remoteServerInfo:RemoteServerInfo;

	public static function hostServer(name:String, maxPlayers:Int, privateSlots:Int, privateServer:Bool, onHosted:() -> Void) {
		serverInfo = new ServerInfo(name, 1, maxPlayers, privateSlots, privateServer, Std.int(999999 * Math.random()), "Lobby", getPlatform());
		MasterServerClient.connectToMasterServer(() -> {
			isHost = true;
			isClient = false;
			clientId = 0;
			isMP = true;
			MasterServerClient.instance.sendServerInfo(serverInfo);
			onHosted();
		});
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
				var loadGui:MultiplayerLoadingGui = cast MarbleGame.canvas.content;
				if (loadGui != null) {
					loadGui.setLoadingStatus("Handshaking");
				}
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
				var weLeftOurselves = !Net.isClient; // If we left ourselves, this would be set to false due to order of ops, disconnect being called first, and then the datachannel closing
				disconnect();
				if (MarbleGame.instance.world != null) {
					MarbleGame.instance.quitMission();
				}
				if (!weLeftOurselves) {
					if (!(MarbleGame.canvas.content is MultiplayerLoadingGui)) {
						var loadGui = new MultiplayerLoadingGui("Server closed");
						MarbleGame.canvas.setContent(loadGui);
						loadGui.setErrorStatus("Server closed");
					}
				}
			}
			clientDatachannel.onError = (msg) -> {
				Console.log('Errored out due to ${msg}');
				disconnect();
				if (MarbleGame.instance.world != null) {
					MarbleGame.instance.quitMission();
				}
				var loadGui = new MultiplayerLoadingGui("Connection error");
				MarbleGame.canvas.setContent(loadGui);
				loadGui.setErrorStatus("Connection error");
			}

			isMP = true;
			isHost = false;
			isClient = true;
		});
	}

	public static function disconnect() {
		if (Net.isClient) {
			NetCommands.clientLeave(Net.clientId);
			Net.isMP = false;
			Net.isClient = false;
			Net.isHost = false;
			if (Net.client != null)
				Net.client.close();
			Net.client = null;
			Net.clientId = 0;
			Net.clientIdMap.clear();
			Net.clientConnection = null;
			Net.serverInfo = null;
			Net.remoteServerInfo = null;
			Net.lobbyHostReady = false;
			Net.lobbyClientReady = false;
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
			Net.serverInfo = null;
			Net.remoteServerInfo = null;
			Net.lobbyHostReady = false;
			Net.lobbyClientReady = false;
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

		if (MarbleGame.canvas.content is MultiplayerLevelSelectGui) {
			cast(MarbleGame.canvas.content, MultiplayerLevelSelectGui).updateLobbyNames();
		}
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

		AudioManager.playSound(ResourceLoader.getAudio("data/sound/infotutorial.wav").resource);

		if (MarbleGame.canvas.content is MultiplayerLevelSelectGui) {
			cast(MarbleGame.canvas.content, MultiplayerLevelSelectGui).updateLobbyNames();
		}
	}

	public static function sendPlayerInfosBytes() {
		var b = new haxe.io.BytesOutput();
		b.writeByte(PlayerInfo);
		var cnt = 0;
		for (c in clientIdMap)
			cnt++;
		b.writeByte(cnt + 1); // all + host
		for (c => v in clientIdMap) {
			b.writeByte(c);
			b.writeByte(v.lobbyReady ? 1 : 0);
			b.writeByte(v.platform);
			b.writeByte(v.marbleId);
			var name = v.getName();
			b.writeByte(name.length);
			for (i in 0...name.length) {
				b.writeByte(StringTools.fastCodeAt(name, i));
			}
		}
		// Write host data
		b.writeByte(0);
		b.writeByte(Net.lobbyHostReady ? 1 : 0);
		b.writeByte(getPlatform());
		b.writeByte(Settings.optionsSettings.marbleIndex);
		var name = Settings.highscoreName;
		b.writeByte(name.length);
		for (i in 0...name.length) {
			b.writeByte(StringTools.fastCodeAt(name, i));
		}
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
				NetCommands.setPlayerData(clientId, Settings.highscoreName, Settings.optionsSettings.marbleIndex); // Send our player name to the server
				NetCommands.transmitPlatform(clientId, getPlatform()); // send our platform too

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
						// Send our current mission to connecting client
						NetCommands.setLobbyLevelIndexClient(conn, MultiplayerLevelSelectGui.currentSelectionStatic);
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
				if (cc.state == GAME)
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
					var cready = input.readByte() == 1;
					var platform = input.readByte();
					var marble = input.readByte();
					if (id != 0 && id != Net.clientId && !clientIdMap.exists(id)) {
						Console.log('Adding ghost connection ${id}');
						addGhost(id);
						newP = true;
					}
					var nameLength = input.readByte();
					var name = "";
					for (j in 0...nameLength) {
						name += String.fromCharCode(input.readByte());
					}
					if (clientIdMap.exists(id)) {
						clientIdMap[id].setName(name);
						clientIdMap[id].setMarbleId(marble);
						clientIdMap[id].lobbyReady = cready;
						clientIdMap[id].platform = platform;
					}
					if (Net.clientId == id) {
						Net.lobbyClientReady = cready;
					}
				}
				if (newP) {
					AudioManager.playSound(ResourceLoader.getAudio("sounds/spawn_alternate.wav").resource);
				}
				if (MarbleGame.canvas.content is MultiplayerLevelSelectGui) {
					cast(MarbleGame.canvas.content, MultiplayerLevelSelectGui).updateLobbyNames();
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

	public static function sendPacketToClient(client:GameConnection, packetData:OutputBitStream) {
		var bytes = packetData.getBytes();
		client.sendBytes(bytes);
	}

	public static function addDummyConnection() {
		if (Net.isHost) {
			addGhost(Net.clientId++);
		}
	}

	public static inline function getPlatform() {
		#if js
		return NetPlatform.Web;
		#end
		#if hl
		#if MACOS_BUNDLE
		return NetPlatform.MacOS;
		#else
		#if android
		return NetPlatform.Android;
		#else
		return NetPlatform.PC;
		#end
		#end
		#end
	}
}
