package net;

import gui.MessageBoxOkDlg;
import net.ClientConnection.NetPlatform;
import gui.EndGameGui;
import net.ClientConnection.GameplayState;
import net.Net.NetPacketType;
import src.MarbleGame;
import src.Console;
import src.Marbleland;
import src.Settings;
import src.Util;
import src.AudioManager;
import src.ResourceLoader;

@:build(net.RPCMacro.build())
class NetCommands {
	@:rpc(server) public static function setLobbyLevelIndex(category:String, i:Int) {}

	// @:rpc(server) public static function setLobbyCustLevelName(str:String) {
	// 	if (MPPlayMissionGui.setLevelFn != null) {
	// 		MPPlayMissionGui.setLevelStr(str);
	// 	} else {
	// 		MultiplayerLevelSelectGui.custSelected = true;
	// 		MultiplayerLevelSelectGui.custPath = str;
	// 	}
	// }

	@:rpc(server) public static function playLevel(category:String, levelIndex:Int) {}

	// @:rpc(server) public static function playCustomLevel(levelPath:String) {
	// 	var levelEntry = MPCustoms.missionList.filter(x -> x.path == levelPath)[0];
	// 	MarbleGame.canvas.setContent(new MultiplayerLoadingGui("Downloading", false));
	// 	MPCustoms.play(levelEntry, () -> {}, () -> {
	// 		MarbleGame.canvas.setContent(new MultiplayerGui());
	// 		Net.disconnect(); // disconnect from the server
	// 	});
	// 	if (Net.isHost) {
	// 		Net.serverInfo.state = "WAITING";
	// 		MasterServerClient.instance.sendServerInfo(Net.serverInfo); // notify the server of the wait state
	// 	}
	// }

	@:rpc(server) public static function playLevelMidJoin(category:String, levelIndex:Int) {
		if (Net.isClient) {}
	}

	// @:rpc(server) public static function playCustomLevelMidJoin(path:String) {
	// 	if (Net.isClient) {
	// 		playCustomLevel(path);
	// 	}
	// }

	@:rpc(server) public static function enterLobby() {
		if (Net.isClient) {}
	}

	@:rpc(server) public static function setNetworkRNG(rng:Float) {
		Net.networkRNG = rng;
		if (MarbleGame.instance.world != null) {
			var gameMode = MarbleGame.instance.world.gameMode;
		}
	}

	@:rpc(client) public static function toggleReadiness(clientId:Int) {
		if (Net.isHost) {}
	}

	@:rpc(client) public static function toggleSpectate(clientId:Int) {
		if (Net.isHost) {}
	}

	@:rpc(client) public static function clientIsReady(clientId:Int) {
		if (Net.isHost) {
			Net.clientIdMap[clientId].state = GAME;
		}
	}

	@:rpc(client) public static function requestMidGameJoinState(clientId:Int) {
		if (Net.isHost) {
			// Mid game join
			Console.log("Mid game join for client " + clientId);
			// Send em our present world state
			if (MarbleGame.instance.world != null) {
				Net.clientIdMap[clientId].ready();

				if (Settings.serverSettings.forceSpectators) {
					Net.clientIdMap[clientId].spectator = true;
					var b = Net.sendPlayerInfosBytes();
					for (cc in Net.clients) {
						cc.sendBytes(b);
					}
				}

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

	@:rpc(server) public static function timerRanOut() {}

	@:rpc(server) public static function clientDisconnected(clientId:Int) {}

	@:rpc(server) public static function clientJoin(clientId:Int) {}

	@:rpc(client) public static function clientLeave(clientId:Int) {}

	@:rpc(server) public static function serverClosed() {}

	@:rpc(server) public static function getKicked() {}

	@:rpc(client) public static function setPlayerData(clientId:Int, name:String, marble:Int, marbleCat:Int, needRetransmit:Bool) {}

	@:rpc(client) public static function transmitPlatform(clientId:Int, platform:Int) {}

	@:rpc(server) public static function endGame() {}

	@:rpc(server) public static function completeRestartGame() {}

	@:rpc(server) public static function partialRestartGame() {}

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

	@:rpc(server) public static function sendServerSettings(name:String, desc:String, quickRespawn:Bool, forceSpectator:Bool, competitive:Bool,
			oldSpawns:Bool) {
		Net.connectedServerInfo = {
			name: name,
			description: desc,
			quickRespawn: quickRespawn,
			forceSpectator: forceSpectator,
			competitiveMode: competitive,
			oldSpawns: oldSpawns
		};
	}

	@:rpc(client) public static function sendChatMessage(msg:String) {
		if (Net.isHost) {
			sendServerChatMessage(msg);
		}
	}

	@:rpc(server) public static function sendServerChatMessage(msg:String) {
		if (MarbleGame.instance.world != null) {
			if (MarbleGame.instance.world._ready) {
				// @:privateAccess MarbleGame.instance.world.playGui.addChatMessage(msg);
			}
		} else {
			// if (MarbleGame.canvas.content is MultiplayerLevelSelectGui) {
			// 	cast(MarbleGame.canvas.content, MultiplayerLevelSelectGui).addChatMessage(msg);
			// }
		}
	}

	@:rpc(server) public static function setCompetitiveTimerStartTicks(ticks:Int) {
		if (MarbleGame.instance.world != null) {}
	}
}
