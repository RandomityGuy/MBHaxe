package net;

import modes.HuntMode;
import net.ClientConnection.GameplayState;
import net.Net.NetPacketType;
import gui.MultiplayerLevelSelectGui;
import src.MarbleGame;

@:build(net.RPCMacro.build())
class NetCommands {
	@:rpc(server) public static function setLobbyLevelIndex(i:Int) {
		MultiplayerLevelSelectGui.setLevelFn(i);
	}

	@:rpc(server) public static function playLevel() {
		MultiplayerLevelSelectGui.playSelectedLevel();
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

	@:rpc(client) public static function clientIsReady(clientId:Int) {
		if (Net.isHost) {
			Net.clientIdMap[clientId].ready();
			var allReady = true;
			for (id => client in Net.clientIdMap) {
				if (client.state != GameplayState.GAME)
					allReady = false;
			}
			if (allReady) {
				if (MarbleGame.instance.world != null) {
					MarbleGame.instance.world.allClientsReady();
				}
			}
		}
	}

	@:rpc(server) public static function setStartTime(t:Float) {
		if (MarbleGame.instance.world != null) {
			if (Net.isClient) {
				t -= cast(Net.clientIdMap[0], ClientConnection).rtt / 2; // Subtract receving time
			}
			MarbleGame.instance.world.startRealTime = MarbleGame.instance.world.timeState.timeSinceLoad + t;
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
		}
	}
}
