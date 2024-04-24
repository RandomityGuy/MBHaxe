package net;

import net.ClientConnection.NetPlatform;
import gui.EndGameGui;
import modes.HuntMode;
import net.ClientConnection.GameplayState;
import net.Net.NetPacketType;
import gui.MultiplayerLevelSelectGui;
import src.MarbleGame;
import gui.MultiplayerLoadingGui;

@:build(net.RPCMacro.build())
class NetCommands {
	@:rpc(server) public static function setLobbyLevelIndex(i:Int) {
		if (MultiplayerLevelSelectGui.setLevelFn == null) {
			MultiplayerLevelSelectGui.currentSelectionStatic = i;
		} else {
			MultiplayerLevelSelectGui.setLevelFn(i);
		}
	}

	@:rpc(server) public static function playLevel(levelIndex:Int) {
		MultiplayerLevelSelectGui.playSelectedLevel(levelIndex);
	}

	@:rpc(server) public static function setNetworkRNG(rng:Float) {
		Net.networkRNG = rng;
		if (MarbleGame.instance.world != null) {
			var gameMode = MarbleGame.instance.world.gameMode;
			if (gameMode is modes.HuntMode) {
				var hunt:modes.HuntMode = cast gameMode;
				@:privateAccess hunt.rng.setSeed(cast rng);
				@:privateAccess hunt.rng2.setSeed(cast rng);
			}
		}
	}

	@:rpc(client) public static function toggleReadiness(clientId:Int) {
		if (Net.isHost) {
			if (clientId == 0)
				Net.lobbyHostReady = !Net.lobbyHostReady;
			else
				Net.clientIdMap[clientId].toggleLobbyReady();
			var allReady = true;
			for (id => client in Net.clientIdMap) {
				if (!client.lobbyReady) {
					allReady = false;
					break;
				}
			}
			if (MarbleGame.canvas.content is MultiplayerLevelSelectGui) {
				cast(MarbleGame.canvas.content, MultiplayerLevelSelectGui).updateLobbyNames();
			}
			var b = Net.sendPlayerInfosBytes();
			for (cc in Net.clients) {
				cc.sendBytes(b);
			}

			if (allReady && Net.lobbyHostReady) {
				NetCommands.playLevel(MultiplayerLevelSelectGui.currentSelectionStatic);
			}
		}
	}

	@:rpc(client) public static function clientIsReady(clientId:Int) {
		if (Net.isHost) {
			Net.clientIdMap[clientId].ready();
			var allReady = true;
			for (id => client in Net.clientIdMap) {
				if (client.state != GameplayState.GAME) {
					allReady = false;
					break;
				}
			}
			if (allReady) {
				if (MarbleGame.instance.world != null) {
					MarbleGame.instance.world.allClientsReady();
				}
			}
		}
	}

	@:rpc(server) public static function setStartTicks(ticks:Int) {
		if (MarbleGame.instance.world != null) {
			MarbleGame.instance.world.serverStartTicks = ticks + 1; // Extra tick so we don't get 0
			MarbleGame.instance.world.startTime = MarbleGame.instance.world.timeState.timeSinceLoad + 3.5 + 0.032; // 1 extra tick
		}
	}

	@:rpc(server) public static function timerRanOut() {
		if (Net.isClient && MarbleGame.instance.world != null) {
			var huntMode:HuntMode = cast MarbleGame.instance.world.gameMode;
			huntMode.onTimeExpire();
		}
	}

	@:rpc(server) public static function clientDisconnected(clientId:Int) {
		var conn = Net.clientIdMap.get(clientId);
		if (MarbleGame.instance.world != null) {
			MarbleGame.instance.world.removePlayer(conn);
		}
		Net.clientIdMap.remove(clientId);
		if (MarbleGame.canvas.content is MultiplayerLevelSelectGui) {
			cast(MarbleGame.canvas.content, MultiplayerLevelSelectGui).updateLobbyNames();
		}
	}

	@:rpc(server) public static function clientJoin(clientId:Int) {}

	@:rpc(client) public static function clientLeave(clientId:Int) {
		if (Net.isHost) {
			@:privateAccess Net.onClientLeave(cast Net.clientIdMap[clientId]);
		}
	}

	@:rpc(server) public static function serverClosed() {
		if (Net.isClient) {
			if (MarbleGame.instance.world != null) {
				MarbleGame.instance.quitMission();
			}
			var loadGui = new MultiplayerLoadingGui("Server closed");
			MarbleGame.canvas.setContent(loadGui);
			loadGui.setErrorStatus("Server closed");
		}
	}

	@:rpc(client) public static function setPlayerName(clientId:Int, name:String) {
		if (Net.isHost) {
			Net.clientIdMap[clientId].setName(name);
			if (MarbleGame.canvas.content is MultiplayerLevelSelectGui) {
				cast(MarbleGame.canvas.content, MultiplayerLevelSelectGui).updateLobbyNames();
			}
		}
	}

	@:rpc(client) public static function transmitPlatform(clientId:Int, platform:Int) {
		if (Net.isHost) {
			Net.clientIdMap[clientId].platform = platform;
			if (MarbleGame.canvas.content is MultiplayerLevelSelectGui) {
				cast(MarbleGame.canvas.content, MultiplayerLevelSelectGui).updateLobbyNames();
			}
		}
	}

	@:rpc(server) public static function endGame() {
		if (Net.isClient) {
			if (MarbleGame.instance.world != null) {
				MarbleGame.instance.quitMission();
			}
		}
		if (Net.isHost) {
			for (c => v in Net.clientIdMap) {
				v.state = LOBBY;
				v.lobbyReady = false;
			}
			Net.lobbyHostReady = false;
		}
	}

	@:rpc(server) public static function restartGame() {
		var world = MarbleGame.instance.world;
		if (Net.isHost) {
			world.startTime = 1e8;
			haxe.Timer.delay(() -> world.allClientsReady(), 1500);
		}
		if (Net.isClient) {
			var gui = MarbleGame.canvas.children[MarbleGame.canvas.children.length - 1];
			if (gui is EndGameGui) {
				var egg = cast(gui, EndGameGui);
				egg.retryFunc(null);
				world.restartMultiplayerState();
			}
		}
		world.multiplayerStarted = false;
	}
}
