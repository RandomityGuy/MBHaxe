package net;

import net.ClientConnection.NetPlatform;
import gui.EndGameGui;
import modes.HuntMode;
import net.ClientConnection.GameplayState;
import net.Net.NetPacketType;
import gui.MultiplayerLevelSelectGui;
import src.MarbleGame;
import gui.MultiplayerLoadingGui;
import src.MissionList;
import src.Console;

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
		if (Net.isHost) {
			Net.serverInfo.state = "WAITING";
			MasterServerClient.instance.sendServerInfo(Net.serverInfo); // notify the server of the wait state
		}
	}

	@:rpc(server) public static function playLevelMidJoin(index:Int) {
		if (Net.isClient) {
			var difficultyMissions = MissionList.missionList['ultra']["multiplayer"];
			var curMission = difficultyMissions[index];
			MarbleGame.instance.playMission(curMission, true);
		}
	}

	@:rpc(server) public static function enterLobby() {
		if (Net.isClient) {
			MarbleGame.canvas.setContent(new MultiplayerLevelSelectGui(false));
		}
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
			if (Net.serverInfo.state == "WAITING" && MarbleGame.instance.world != null) {
				if (clientId != -1)
					Net.clientIdMap[clientId].ready();
				else
					Net.hostReady = true;
				var allReady = true;
				for (id => client in Net.clientIdMap) {
					if (client.state != GameplayState.GAME) {
						allReady = false;
						break;
					}
				}
				if (allReady && Net.hostReady) {
					if (MarbleGame.instance.world != null) {
						MarbleGame.instance.world.allClientsReady();
					}
					Net.serverInfo.state = "PLAYING";
					MasterServerClient.instance.sendServerInfo(Net.serverInfo); // notify the server of the playing state
				}
			} else {
				// Mid game join
				Console.log("Mid game join for client " + clientId);
				// Send em our present world state
				if (MarbleGame.instance.world != null) {
					var packets = MarbleGame.instance.world.getWorldStateForClientJoin();
					var c = Net.clientIdMap[clientId];
					for (packet in packets) {
						c.sendBytes(packet);
					}
					Net.clientIdMap[clientId].ready();

					if (MarbleGame.instance.world.serverStartTicks == 0) {
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
					} else {
						// Send the start ticks
						NetCommands.setStartTicksMidJoinClient(c, MarbleGame.instance.world.serverStartTicks, MarbleGame.instance.world.timeState.ticks);
					}
				}
			}
		}
	}

	@:rpc(server) public static function addMidGameJoinMarble(cc:Int) {
		if (Net.isClient) {
			if (MarbleGame.instance.world != null) {
				MarbleGame.instance.world.addJoiningClientGhost(Net.clientIdMap[cc], () -> {});
			}
		}
	}

	@:rpc(server) public static function setStartTicks(ticks:Int) {
		if (MarbleGame.instance.world != null) {
			MarbleGame.instance.world.serverStartTicks = ticks + 1; // Extra tick so we don't get 0
			if (Net.isClient) {
				@:privateAccess MarbleGame.instance.world.marble.serverTicks = ticks;
			}
			MarbleGame.instance.world.startTime = MarbleGame.instance.world.timeState.timeSinceLoad + 3.5 + 0.032; // 1 extra tick
		}
	}

	@:rpc(server) public static function setStartTicksMidJoin(startTicks:Int, currentTicks:Int) {
		if (MarbleGame.instance.world != null) {
			MarbleGame.instance.world.serverStartTicks = startTicks + 1; // Extra tick so we don't get 0
			MarbleGame.instance.world.startTime = MarbleGame.instance.world.timeState.timeSinceLoad + 0.032; // 1 extra tick
			MarbleGame.instance.world.timeState.ticks = currentTicks;
		}
	}

	@:rpc(server) public static function timerRanOut() {
		if (Net.isClient && MarbleGame.instance.world != null) {
			if (MarbleGame.instance.paused) {
				MarbleGame.instance.handlePauseGame(); // Unpause
			}
			var huntMode:HuntMode = cast MarbleGame.instance.world.gameMode;
			huntMode.onTimeExpire();
		}
		if (Net.isHost) {
			Net.serverInfo.state = "WAITING";
			MasterServerClient.instance.sendServerInfo(Net.serverInfo); // notify the server of the playing state
		}
	}

	@:rpc(server) public static function clientDisconnected(clientId:Int) {
		var conn = Net.clientIdMap.get(clientId);
		if (MarbleGame.instance.world != null) {
			MarbleGame.instance.world.removePlayer(conn);

			var allReady = true;
			for (id => client in Net.clientIdMap) {
				if (client.state != GameplayState.GAME) {
					allReady = false;
					break;
				}
			}
			if (allReady && MarbleGame.instance.world.serverStartTicks == 0) {
				MarbleGame.instance.world.allClientsReady();
			}
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

	@:rpc(client) public static function setPlayerData(clientId:Int, name:String, marble:Int) {
		if (Net.isHost) {
			Net.clientIdMap[clientId].setName(name);
			Net.clientIdMap[clientId].setMarbleId(marble);
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
		for (c => v in Net.clientIdMap) {
			v.state = LOBBY;
			v.lobbyReady = false;
		}
		if (Net.isClient) {
			if (MarbleGame.instance.world != null) {
				MarbleGame.instance.quitMission();
			}
		}
		if (Net.isHost) {
			Net.lobbyHostReady = false;
			Net.hostReady = false;

			Net.serverInfo.state = "LOBBY";
			MasterServerClient.instance.sendServerInfo(Net.serverInfo); // notify the server of the playing state
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

	@:rpc(server) public static function ping(sendTime:Float) {
		if (Net.isClient) {
			pingBack(Console.time() - sendTime);
		}
	}

	@:rpc(client) public static function pingBack(ping:Float) {
		// Do nothing???
	}

	@:rpc(client) public static function requestPing() {
		if (Net.isHost) {
			ping(Console.time());
		}
	}
}
