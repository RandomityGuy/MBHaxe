package net;

import gui.MPMessageGui;
import gui.JoinServerGui;
import gui.MessageBoxOkDlg;
import src.MarbleGame;
import haxe.Json;
import net.Net.ServerInfo;
import haxe.net.WebSocket;
import src.Console;

typedef RemoteServerInfo = {
	name:String,
	host:String,
	description:String,
	players:Int,
	maxPlayers:Int,
	platform:Int,
	version:String,
	passworded:Bool
}

class MasterServerClient {
	// #if js
	// static var serverIp = "wss://mbomaster.randomityguy.me:8443";
	// #else
	static var serverIp = "ws://89.58.58.191:8084";
	// #end
	public static var instance:MasterServerClient;

	var ws:WebSocket;
	var serverListCb:Array<RemoteServerInfo>->Void;

	var open = false;

	static var wsToken:Int = 0;

	#if hl
	var wsThread:sys.thread.Thread;

	static var responses:sys.thread.Deque<() -> Void> = new sys.thread.Deque<() -> Void>();

	var toSend:sys.thread.Deque<String> = new sys.thread.Deque<String>();
	var stopping:Bool = false;
	var stopMutex:sys.thread.Mutex = new sys.thread.Mutex();
	#end

	public function new(onOpenFunc:() -> Void, onErrorFunc:() -> Void) {
		#if hl
		wsThread = sys.thread.Thread.create(() -> {
			hl.Gc.enable(false);
			hl.Gc.blocking(true); // Wtf is this shit
		#end
			wsToken++;

			var myToken = wsToken;

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
				if (onErrorFunc != null)
					responses.add(() -> {
						onErrorFunc();
					});
				#end
				#if js
				MarbleGame.canvas.pushDialog(new MessageBoxOkDlg("Failed to connect to master server: " + m));
				if (onErrorFunc != null)
					onErrorFunc();
				#end
				#if hl
				stopMutex.acquire();
				#end
				if (myToken == wsToken) {
					open = false;
					ws = null;
					instance = null;
				}
				#if hl
				stopMutex.acquire();
				stopping = true;
				stopMutex.release();
				if (myToken == wsToken) {
					wsThread = null;
				}
				#end
			}
			ws.onclose = (?e) -> {
				#if hl
				stopMutex.acquire();
				#end
				if (myToken == wsToken) {
					open = false;
					ws = null;
					instance = null;
				}
				#if hl
				stopping = true;
				stopMutex.release();
				if (myToken == wsToken) {
					wsThread = null;
				}
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

	public static function connectToMasterServer(onConnect:() -> Void, onError:() -> Void = null) {
		if (instance == null)
			instance = new MasterServerClient(onConnect, onError);
		else {
			if (instance.open)
				onConnect();
			else {
				if (instance != null && instance.ws != null)
					instance.ws.close();
				instance = new MasterServerClient(onConnect, onError);
			}
		}
	}

	public static function disconnectFromMasterServer() {
		if (instance != null && instance.ws != null) {
			instance.ws.close();
			if (instance != null) {
				instance.open = false;
				instance.ws = null;
				instance = null;
			}
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
			host: serverInfo.hostname,
			description: serverInfo.description,
			players: serverInfo.players,
			maxPlayers: serverInfo.maxPlayers,
			password: serverInfo.password,
			state: serverInfo.state,
			platform: serverInfo.platform,
			version: MarbleGame.currentVersion
		}));
	}

	public function sendConnectToServer(serverName:String, sdp:String, password:String) {
		queueMessage(Json.stringify({
			type: "connect",
			serverName: serverName,
			sdp: sdp,
			password: password
		}));
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

			var pubCount = 1; // Self
			for (cid => cc in Net.clientIdMap) {
				pubCount++;
			}

			if (!joiningPrivate && pubCount >= Net.serverInfo.maxPlayers) {
				queueMessage(Json.stringify({
					type: "connectFailed",
					success: false,
					reason: "The server is full"
				}));
				return;
			}

			Net.addClientFromSdp(conts.sdp, (sdpReply) -> {
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
			if (MarbleGame.canvas.content is MPMessageGui) {
				var loadGui:MPMessageGui = cast MarbleGame.canvas.content;
				if (loadGui != null) {
					loadGui.setTexts("Error", conts.reason);
				}
			}
		}
		if (conts.type == "turnserver") {
			Net.turnServer = conts.server; // Turn server!
		}
	}
}
