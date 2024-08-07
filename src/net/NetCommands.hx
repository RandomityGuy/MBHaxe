package net;

import gui.MPMessageGui;
import gui.MessageBoxOkDlg;
import gui.JoinServerGui;
import gui.MPExitGameDlg;
import gui.MPEndGameGui;
import gui.MPPreGameDlg;
import gui.MPPlayMissionGui;
import net.ClientConnection.NetPlatform;
import gui.EndGameGui;
import modes.HuntMode;
import net.ClientConnection.GameplayState;
import net.Net.NetPacketType;
import src.MarbleGame;
import src.MissionList;
import src.Console;
import src.Marbleland;
import src.Settings;
import src.Util;
import src.AudioManager;
import src.ResourceLoader;

@:build(net.RPCMacro.build())
class NetCommands {
	@:rpc(server) public static function setLobbyLevelIndex(category:String, i:Int) {
		if (MPPlayMissionGui.setLevelFn == null) {
			MPPlayMissionGui.currentCategoryStatic = category;
			MPPlayMissionGui.currentSelectionStatic = i;
		} else {
			MPPlayMissionGui.currentCategoryStatic = category;
			MPPlayMissionGui.currentSelectionStatic = i;
			MPPlayMissionGui.setLevelFn(category, i);
		}
	}

	// @:rpc(server) public static function setLobbyCustLevelName(str:String) {
	// 	if (MPPlayMissionGui.setLevelFn != null) {
	// 		MPPlayMissionGui.setLevelStr(str);
	// 	} else {
	// 		MultiplayerLevelSelectGui.custSelected = true;
	// 		MultiplayerLevelSelectGui.custPath = str;
	// 	}
	// }

	@:rpc(server) public static function playLevel(category:String, levelIndex:Int) {
		MPPlayMissionGui.playSelectedLevel(category, levelIndex);
		if (Net.isHost) {
			Net.serverInfo.state = "WAITING";
			MasterServerClient.instance.sendServerInfo(Net.serverInfo); // notify the server of the wait state
		}
	}

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
		if (Net.isClient) {
			MissionList.buildMissionList();
			if (category == "custom") {
				var curMission = Marbleland.multiplayerMissions[levelIndex];
				MarbleGame.instance.playMission(curMission, true);
			} else {
				var difficultyMissions = MissionList.missionList['multiplayer'][category];
				var curMission = difficultyMissions[levelIndex];
				MarbleGame.instance.playMission(curMission, true);
			}
			@:privateAccess MarbleGame.instance.world._skipPreGame = true;
		}
	}

	// @:rpc(server) public static function playCustomLevelMidJoin(path:String) {
	// 	if (Net.isClient) {
	// 		playCustomLevel(path);
	// 	}
	// }

	@:rpc(server) public static function enterLobby() {
		if (Net.isClient) {
			MarbleGame.canvas.setContent(new MPPlayMissionGui(false));
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
			if (MarbleGame.canvas.content is MPPlayMissionGui) {
				cast(MarbleGame.canvas.content, MPPlayMissionGui).updateLobbyNames();
			}
			if (MarbleGame.canvas.children[MarbleGame.canvas.children.length - 1] is MPPreGameDlg) {
				cast(MarbleGame.canvas.children[MarbleGame.canvas.children.length - 1], MPPreGameDlg).updatePlayerList();
			}
			var b = Net.sendPlayerInfosBytes();
			for (cc in Net.clients) {
				cc.sendBytes(b);
			}

			if (allReady && Net.lobbyHostReady) {
				// if (MultiplayerLevelSelectGui.custSelected) {
				//	NetCommands.playCustomLevel(MultiplayerLevelSelectGui.custPath);
				// } else
				if (MarbleGame.instance.world == null) {
					NetCommands.playLevel(MPPlayMissionGui.currentCategoryStatic, MPPlayMissionGui.currentSelectionStatic);
				} else {}
			}
		}
	}

	@:rpc(client) public static function toggleSpectate(clientId:Int) {
		if (Net.isHost) {
			if (clientId == 0)
				Net.hostSpectate = !Net.hostSpectate;
			else
				Net.clientIdMap[clientId].toggleSpectate();

			if (MarbleGame.canvas.content is MPPlayMissionGui) {
				cast(MarbleGame.canvas.content, MPPlayMissionGui).updateLobbyNames();
			}
			if (MarbleGame.canvas.children[MarbleGame.canvas.children.length - 1] is MPPreGameDlg) {
				cast(MarbleGame.canvas.children[MarbleGame.canvas.children.length - 1], MPPreGameDlg).updatePlayerList();
			}
			var b = Net.sendPlayerInfosBytes();
			for (cc in Net.clients) {
				cc.sendBytes(b);
			}
		}
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
				var packets = MarbleGame.instance.world.getWorldStateForClientJoin();
				var c = Net.clientIdMap[clientId];

				for (packet in packets) {
					c.sendBytes(packet);
				}
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
				} else {
					// Send the start ticks
					NetCommands.setStartTicksMidJoinClient(c, MarbleGame.instance.world.serverStartTicks, MarbleGame.instance.world.timeState.ticks);
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

			if (MarbleGame.canvas.children[MarbleGame.canvas.children.length - 1] is MPPreGameDlg) {
				MarbleGame.canvas.popDialog(MarbleGame.canvas.children[MarbleGame.canvas.children.length - 1]);
				MarbleGame.instance.world.setCursorLock(true);
				if (Util.isTouchDevice()) {
					MarbleGame.canvas.render(MarbleGame.canvas.scene2d);
					MarbleGame.instance.touchInput.setControlsEnabled(true);
				}
				MarbleGame.instance.world.marble.camera.stopOverview();
				AudioManager.playSound(ResourceLoader.getAudio('data/sound/spawn.wav').resource);
			}

			if (Net.clientSpectate || Net.hostSpectate) {
				MarbleGame.instance.world.marble.camera.enableSpectate();
			} else {
				MarbleGame.instance.world.marble.camera.stopSpectate();
			}
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
		}
		Net.clientIdMap.remove(clientId);
		if (MarbleGame.canvas.content is MPPlayMissionGui) {
			cast(MarbleGame.canvas.content, MPPlayMissionGui).updateLobbyNames();
		}
		if (MarbleGame.canvas.children[MarbleGame.canvas.children.length - 1] is MPPreGameDlg) {
			cast(MarbleGame.canvas.children[MarbleGame.canvas.children.length - 1], MPPreGameDlg).updatePlayerList();
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
			MarbleGame.canvas.setContent(new MPMessageGui("Info", "Server closed"));
		}
	}

	@:rpc(server) public static function getKicked() {
		if (Net.isClient) {
			Net.disconnect();
			MarbleGame.canvas.setContent(new MPMessageGui("Info", "You have been kicked from the server"));
		}
	}

	@:rpc(client) public static function setPlayerData(clientId:Int, name:String, marble:Int, marbleCat:Int, needRetransmit:Bool) {
		if (Net.isHost) {
			Net.clientIdMap[clientId].setName(name);
			Net.clientIdMap[clientId].setMarbleId(marble, marbleCat);
			if (MarbleGame.canvas.content is MPPlayMissionGui) {
				cast(MarbleGame.canvas.content, MPPlayMissionGui).updateLobbyNames();
			}
			if (needRetransmit) {
				var b = Net.sendPlayerInfosBytes();
				for (cc in Net.clients) {
					cc.sendBytes(b);
				}
			}
		}
	}

	@:rpc(client) public static function transmitPlatform(clientId:Int, platform:Int) {
		if (Net.isHost) {
			Net.clientIdMap[clientId].platform = platform;
			if (MarbleGame.canvas.content is MPPlayMissionGui) {
				cast(MarbleGame.canvas.content, MPPlayMissionGui).updateLobbyNames();
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
			var b = Net.sendPlayerInfosBytes();
			for (cc in Net.clients) {
				cc.sendBytes(b);
			}
		}
	}

	@:rpc(server) public static function completeRestartGame() {
		if (Net.isClient) {
			var gui = MarbleGame.canvas.children[MarbleGame.canvas.children.length - 1];
			if (gui is MPEndGameGui || gui is MPExitGameDlg) {
				MarbleGame.instance.paused = false;
				MarbleGame.canvas.popDialog(gui);
				// egg.retryFunc(null);
			}
		}
		var world = MarbleGame.instance.world;
		world.completeRestart();
		if (Net.isClient) {
			world.restartMultiplayerState();
		}
	}

	@:rpc(server) public static function partialRestartGame() {
		if (Net.isClient) {
			var gui = MarbleGame.canvas.children[MarbleGame.canvas.children.length - 1];
			if (gui is MPEndGameGui || gui is MPExitGameDlg) {
				MarbleGame.instance.paused = false;
				MarbleGame.canvas.popDialog(gui);
				// egg.retryFunc(null);
			}
		}
		var world = MarbleGame.instance.world;
		world.partialRestart();
		if (Net.isClient) {
			world.restartMultiplayerState();
		}
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
				@:privateAccess MarbleGame.instance.world.playGui.addChatMessage(msg);
			}
		} else {
			// if (MarbleGame.canvas.content is MultiplayerLevelSelectGui) {
			// 	cast(MarbleGame.canvas.content, MultiplayerLevelSelectGui).addChatMessage(msg);
			// }
		}
		MPPlayMissionGui.addChatMessage(msg);
	}

	@:rpc(server) public static function setCompetitiveTimerStartTicks(ticks:Int) {
		if (MarbleGame.instance.world != null) {
			var huntMode = cast(MarbleGame.instance.world.gameMode, HuntMode);
			huntMode.setCompetitiveTimerStartTicks(ticks);
		}
	}
}
