package net;

import gui.MessageBoxOkDlg;
import src.MarbleGame;
import haxe.Json;
import net.Net.ServerInfo;
import haxe.net.WebSocket;
import src.Console;
import gui.MultiplayerLoadingGui;

typedef RemoteServerInfo = {
	name:String,
	players:Int,
	maxPlayers:Int,
	platform:Int,
}

class MasterServerClient {
	static var serverIp = "ws://89.58.58.191:8080";
	public static var instance:MasterServerClient;

	var ws:WebSocket;
	var serverListCb:Array<RemoteServerInfo>->Void;

	var open = false;

	#if hl
	var wsThread:sys.thread.Thread;

	static var responses:sys.thread.Deque<() -> Void> = new sys.thread.Deque<() -> Void>();

	var toSend:sys.thread.Deque<String> = new sys.thread.Deque<String>();
	var stopping:Bool = false;
	var stopMutex:sys.thread.Mutex = new sys.thread.Mutex();
	#end

	public function new(onOpenFunc:() -> Void) {
		#if hl
		wsThread = sys.thread.Thread.create(() -> {
			hl.Gc.enable(false);
			hl.Gc.blocking(true); // Wtf is this shit
		#end

			ws = WebSocket.create(serverIp);
			#if hl
			hl.Gc.enable(true);
			hl.Gc.blocking(false);
			#end
			ws.onopen = () -> {
				open = true;
				#if hl
				responses.add(() -> onOpenFunc());
				#end
				#if js
				onOpenFunc();
				#end
			}
			ws.onmessageString = (m) -> {
				#if hl
				responses.add(() -> handleMessage(m));
				#end
				#if js
				handleMessage(m);
				#end
			}
			ws.onerror = (m) -> {
				#if hl
				responses.add(() -> {
					MarbleGame.canvas.pushDialog(new MessageBoxOkDlg("Failed to connect to master server: " + m));
				});
				#end
				#if js
				MarbleGame.canvas.pushDialog(new MessageBoxOkDlg("Failed to connect to master server: " + m));
				#end
				#if hl
				stopMutex.acquire();
				#end
				open = false;
				ws = null;
				instance = null;
				#if hl
				stopMutex.acquire();
				stopping = true;
				stopMutex.release();
				wsThread = null;
				#end
			}
			ws.onclose = (?e) -> {
				#if hl
				stopMutex.acquire();
				#end
				open = false;
				ws = null;
				instance = null;
				#if hl
				stopping = true;
				stopMutex.release();
				wsThread = null;
				#end
			}
			#if hl
			while (true) {
				stopMutex.acquire();
				if (stopping)
					break;
				while (true) {
					var s = toSend.pop(false);
					if (s == null)
						break;
					#if hl
					hl.Gc.blocking(true);
					#end
					ws.sendString(s);
					#if hl
					hl.Gc.blocking(false);
					#end
				}

				#if hl
				hl.Gc.blocking(true);
				#end
				ws.process();
				#if hl
				hl.Gc.blocking(false);
				#end
				stopMutex.release();
				Sys.sleep(0.1);
			}
			#end
		#if hl
		});
		#end
	}

	public static function process() {
		#if sys
		var resp = responses.pop(false);
		if (resp != null) {
			resp();
		}
		#end
	}

	public static function connectToMasterServer(onConnect:() -> Void) {
		if (instance == null)
			instance = new MasterServerClient(onConnect);
		else {
			if (instance.open)
				onConnect();
			else {
				instance.ws.close();
				instance = new MasterServerClient(onConnect);
			}
		}
	}

	public static function disconnectFromMasterServer() {
		if (instance != null) {
			instance.ws.close();
		}
	}

	function queueMessage(m:String) {
		#if hl
		toSend.add(m);
		#end
		#if js
		ws.sendString(m);
		#end
	}

	public function heartBeat() {
		queueMessage(Json.stringify({
			type: "heartbeat"
		}));
	}

	public function sendServerInfo(serverInfo:ServerInfo) {
		queueMessage(Json.stringify({
			type: "serverInfo",
			name: serverInfo.name,
			players: serverInfo.players,
			maxPlayers: serverInfo.maxPlayers,
			privateSlots: serverInfo.privateSlots,
			privateServer: serverInfo.privateServer,
			inviteCode: serverInfo.inviteCode,
			state: serverInfo.state,
			platform: serverInfo.platform
		}));
	}

	public function sendConnectToServer(serverName:String, sdp:String, isInvite:Bool = false) {
		if (!isInvite) {
			queueMessage(Json.stringify({
				type: "connect",
				serverName: serverName,
				sdp: sdp
			}));
		} else {
			queueMessage(Json.stringify({
				type: "connectInvite",
				sdp: sdp,
				inviteCode: serverName
			}));
		}
	}

	public function getServerList(serverListCb:Array<RemoteServerInfo>->Void) {
		this.serverListCb = serverListCb;
		queueMessage(Json.stringify({
			type: "serverList"
		}));
	}

	function handleMessage(message:String) {
		var conts = Json.parse(message);
		Console.log('Received ${conts.type}');
		if (conts.type == "serverList") {
			if (serverListCb != null) {
				serverListCb(conts.servers);
			}
		}
		if (conts.type == "connect") {
			if (!Net.isHost) {
				queueMessage(Json.stringify({
					type: "connectFailed",
					success: false,
					reason: "The server has shut down"
				}));
				return;
			}
			var joiningPrivate = conts.isPrivate;

			if (Net.serverInfo.players >= Net.serverInfo.maxPlayers) {
				queueMessage(Json.stringify({
					type: "connectFailed",
					success: false,
					reason: "The server is full"
				}));
				return;
			}
			var pubSlotsAvail = Net.serverInfo.maxPlayers - Net.serverInfo.privateSlots;
			var privSlotsAvail = Net.serverInfo.privateSlots;

			var pubCount = 1; // Self
			var privCount = 0;
			for (cid => cc in Net.clientIdMap) {
				if (cc.isPrivate) {
					privCount++;
				} else {
					pubCount++;
				}
			}

			if (!joiningPrivate && pubCount >= pubSlotsAvail) {
				queueMessage(Json.stringify({
					type: "connectFailed",
					success: false,
					reason: "The server is full"
				}));
				return;
			}

			if (joiningPrivate && privCount >= privSlotsAvail) {
				joiningPrivate = false; // Join publicly
			}

			Net.addClientFromSdp(conts.sdp, joiningPrivate, (sdpReply) -> {
				queueMessage(Json.stringify({
					success: true,
					type: "connectResponse",
					sdp: sdpReply,
					clientId: conts.clientId
				}));
			});
		}
		if (conts.type == "connectResponse") {
			Console.log("Remote Description Received!");
			var sdpObj = Json.parse(conts.sdp);
			if (@:privateAccess Net.client != null)
				@:privateAccess Net.client.setRemoteDescription(sdpObj.sdp, sdpObj.type);
		}
		if (conts.type == "connectFailed") {
			var loadGui:MultiplayerLoadingGui = cast MarbleGame.canvas.content;
			if (loadGui != null) {
				loadGui.setErrorStatus(conts.reason);
			}
		}
		if (conts.type == "turnserver") {
			Net.turnServer = conts.server; // Turn server!
		}
	}
}
