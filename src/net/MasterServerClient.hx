package net;

import gui.MessageBoxOkDlg;
import src.MarbleGame;
import haxe.Json;
import net.Net.ServerInfo;
import hx.ws.WebSocket;
import src.Console;
import hx.ws.Types.MessageType;

typedef RemoteServerInfo = {
	name:String,
	players:Int,
	maxPlayers:Int,
	platform:String,
}

class MasterServerClient {
	static var serverIp = "ws://89.58.58.191:8080";
	public static var instance:MasterServerClient;

	var ws:WebSocket;
	var serverListCb:Array<RemoteServerInfo>->Void;

	var open = false;

	public function new(onOpenFunc:() -> Void) {
		ws = new WebSocket(serverIp);
		ws.onopen = () -> {
			open = true;
			onOpenFunc();
		}
		ws.onmessage = (m) -> {
			switch (m) {
				case StrMessage(content):
					handleMessage(content);
				case _:
					return;
			}
		}
	}

	public static function connectToMasterServer(onConnect:() -> Void) {
		if (instance == null)
			instance = new MasterServerClient(onConnect);
		else
			onConnect();
	}

	public static function disconnectFromMasterServer() {
		if (instance != null) {
			instance.ws.close();
			instance = null;
		}
	}

	public function sendServerInfo(serverInfo:ServerInfo) {
		ws.send(Json.stringify({
			type: "serverInfo",
			name: serverInfo.name,
			players: serverInfo.players,
			maxPlayers: serverInfo.maxPlayers,
			privateSlots: serverInfo.privateSlots,
			privateServer: serverInfo.privateServer,
			inviteCode: serverInfo.inviteCode,
			state: serverInfo.state
		}));
	}

	public function sendConnectToServer(serverName:String, sdp:String) {
		ws.send(Json.stringify({
			type: "connect",
			serverName: serverName,
			sdp: sdp
		}));
	}

	public function getServerList(serverListCb:Array<RemoteServerInfo>->Void) {
		this.serverListCb = serverListCb;
		ws.send(Json.stringify({
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
				ws.send(Json.stringify({
					type: "connectResponse",
					success: false,
					reason: "The server has shut down"
				}));
				return;
			}
			if (Net.serverInfo.players >= Net.serverInfo.maxPlayers) {
				ws.send(Json.stringify({
					type: "connectResponse",
					success: false,
					reason: "The server is full"
				}));
				return;
			}
			Net.addClientFromSdp(conts.sdp, (sdpReply) -> {
				ws.send(Json.stringify({
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
			@:privateAccess Net.client.setRemoteDescription(sdpObj.sdp, sdpObj.type);
		}
		if (conts.type == "connectFailed") {
			MarbleGame.canvas.pushDialog(new MessageBoxOkDlg(conts.reason));
		}
	}
}
