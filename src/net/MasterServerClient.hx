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

	public function new(onOpenFunc:() -> Void) {
		ws = WebSocket.create(serverIp);
		ws.onopen = () -> {
			open = true;
			onOpenFunc();
		}
		ws.onmessageString = (m) -> {
			handleMessage(m);
		}
		ws.onerror = (m) -> {
			MarbleGame.canvas.pushDialog(new MessageBoxOkDlg("Failed to connect to master server: " + m));
			open = false;
			ws = null;
			instance = null;
		}
	}

	public static function process() {
		#if sys
		if (instance != null)
			instance.ws.process();
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
				instance = null;
				instance = new MasterServerClient(onConnect);
			}
		}
	}

	public static function disconnectFromMasterServer() {
		if (instance != null) {
			instance.ws.close();
			instance = null;
		}
	}

	public function heartBeat() {
		ws.sendString(Json.stringify({
			type: "heartbeat"
		}));
	}

	public function sendServerInfo(serverInfo:ServerInfo) {
		ws.sendString(Json.stringify({
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
			ws.sendString(Json.stringify({
				type: "connect",
				serverName: serverName,
				sdp: sdp
			}));
		} else {
			ws.sendString(Json.stringify({
				type: "connectInvite",
				sdp: sdp,
				inviteCode: serverName
			}));
		}
	}

	public function getServerList(serverListCb:Array<RemoteServerInfo>->Void) {
		this.serverListCb = serverListCb;
		ws.sendString(Json.stringify({
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
				ws.sendString(Json.stringify({
					type: "connectFailed",
					success: false,
					reason: "The server has shut down"
				}));
				return;
			}
			var joiningPrivate = conts.isPrivate;

			if (Net.serverInfo.players >= Net.serverInfo.maxPlayers) {
				ws.sendString(Json.stringify({
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
				ws.sendString(Json.stringify({
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
				ws.sendString(Json.stringify({
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
