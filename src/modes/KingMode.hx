package modes;

import net.BitStream.OutputBitStream;
import net.NetPacket.KingInfoPacket;
import net.NetPacket.ScoreboardPacket;
import net.Net;
import net.NetCommands;
import rewind.RewindManager;
import rewind.RewindableState;
import modes.GameMode.ScoreType;
import mis.MissionElement.MissionElementType;
import mis.MissionElement.MissionElementSimGroup;
import mis.MissionElement.MissionElementSpawnSphere;
import mis.MisParser;
import src.AudioManager;
import src.ResourceLoader;
import src.Settings;
import src.Marble;
import src.TimeState;
import src.Mission;
import h3d.Vector;
import h3d.Quat;

@:publicFields
class KingState implements RewindableState {
	var kingClientId:Int = -1;
	var kingTickAccum:Int = 0;
	var scores:Map<Int, Int>;

	public function new() {
		scores = new Map();
	}

	public function apply(level:src.MarbleWorld) {
		var mode:KingMode = cast level.gameMode;
		mode.applyRewindState(this);
	}

	public function clone():RewindableState {
		var c = new KingState();
		c.kingClientId = kingClientId;
		c.kingTickAccum = kingTickAccum;
		c.scores = [for (k => v in scores) k => v];
		return c;
	}

	public function getSize():Int {
		var count = 0;
		for (_ in scores)
			count++;
		return 1 + 4 + 1 + count * 3; // kingClientId(1) + tickAccum(4) + count(1) + entries(3 each)
	}

	public function serialize(rm:RewindManager, bw:haxe.io.BytesOutput) {
		bw.writeByte(kingClientId + 1); // shift by 1 so -1 → 0
		bw.writeInt32(kingTickAccum);
		var count = 0;
		for (_ in scores)
			count++;
		bw.writeByte(count);
		for (k => v in scores) {
			bw.writeByte(k);
			bw.writeUInt16(v);
		}
	}

	public function deserialize(rm:RewindManager, br:haxe.io.BytesInput) {
		kingClientId = br.readByte() - 1;
		kingTickAccum = br.readInt32();
		var count = br.readByte();
		scores = new Map();
		for (i in 0...count) {
			var k = br.readByte();
			var v = br.readUInt16();
			scores.set(k, v);
		}
	}
}

class KingMode extends NullMode {
	var playerSpawnPoints:Array<MissionElementSpawnSphere> = [];
	var spawnPointTaken:Array<Bool> = [];

	public var kingClientId:Int = -1; // -1 = no king

	var scores:Map<Int, Int> = new Map();
	var kingTickAccum:Int = 0;
	var contactCooldown:Int = 0; // ticks until another king change is allowed
	var lastKnownScore:Int = 0;

	static final POINTS_PER_SECOND = 2;
	static final TICKS_PER_SECOND = 32; // 32ms * 32 ticks ≈ 1 second

	override function missionScan(mission:Mission) {
		function scan(simGroup:MissionElementSimGroup) {
			for (element in simGroup.elements) {
				if (element._type == MissionElementType.SpawnSphere) {
					var s:MissionElementSpawnSphere = cast element;
					if (s.datablock.toLowerCase() == "spawnspheremarker") {
						playerSpawnPoints.push(s);
						spawnPointTaken.push(false);
					}
				} else if (element._type == MissionElementType.SimGroup) {
					scan(cast element);
				}
			}
		}
		scan(mission.root);
	}

	override function getSpawnTransform() {
		if (playerSpawnPoints.length == 0)
			return super.getSpawnTransform();
		for (i in 0...playerSpawnPoints.length) {
			if (!spawnPointTaken[i]) {
				spawnPointTaken[i] = true;
				return spawnFromPoint(playerSpawnPoints[i]);
			}
		}
		return spawnFromPoint(playerSpawnPoints[0]);
	}

	override function getRespawnTransform(marble:Marble) {
		return getSpawnTransform();
	}

	function spawnFromPoint(spawn:MissionElementSpawnSphere) {
		var pos = MisParser.parseVector3(spawn.position);
		pos.x *= -1;
		var rot = MisParser.parseRotation(spawn.rotation);
		rot.x *= -1;
		rot.w *= -1;
		var up = rot.toMatrix().up();
		pos = pos.add(up.multiply(0.727843 / 3));
		return {position: pos, orientation: rot, up: up};
	}

	override function getStartTime():Float {
		return level.mission.qualifyTime;
	}

	override function timeMultiplier():Float {
		return -1.0;
	}

	override function getScoreType():ScoreType {
		return Score;
	}

	override function onRestart() {
		scores = new Map();
		kingClientId = -1;
		kingTickAccum = 0;
		contactCooldown = 0;
		for (i in 0...playerSpawnPoints.length)
			spawnPointTaken[i] = false;
	}

	override function onClientRestart() {
		kingClientId = -1;
		scores = new Map();
	}

	// Called when multiplayer game officially starts (all players ready)
	override function onMultiplayerStart() {
		for (i in 0...playerSpawnPoints.length)
			spawnPointTaken[i] = false;
		if (Net.isHost)
			pickNewKing();
	}

	// Called every host tick after all marble updates
	override function onHostTick(timeState:TimeState) {
		if (!level.isMultiplayer || !Net.isHost)
			return;

		if (contactCooldown > 0)
			contactCooldown--;

		// If king disconnected or invalid, pick a new one
		if (kingClientId < 0 || getMarbleByClientId(kingClientId) == null) {
			if (level.marbles.length > 0)
				pickNewKing();
			return;
		}

		// Award 2 points per second to king
		kingTickAccum++;
		if (kingTickAccum >= TICKS_PER_SECOND) {
			kingTickAccum = 0;
			var s = scores.get(kingClientId);
			scores.set(kingClientId, (s != null ? s : 0) + POINTS_PER_SECOND);
			broadcastScoreboard();
		}
	}

	// Called when marble `attacker` physically contacts or blasts marble `victim` (host only)
	override function onMarbleContact(attacker:Marble, victim:Marble) {
		if (!level.isMultiplayer || !Net.isHost)
			return;
		if (contactCooldown > 0)
			return;

		var victimId = victim.getConnectionId();
		var attackerId = attacker.getConnectionId();

		// King change only occurs when the current king is hit by someone else
		if (victimId != kingClientId || attackerId == kingClientId)
			return;

		setNewKing(attackerId);
	}

	function pickNewKing() {
		if (level.marbles.length == 0)
			return;
		var idx = Std.int(Math.random() * level.marbles.length);
		setNewKing(level.marbles[idx].getConnectionId());
	}

	function setNewKing(newKingId:Int) {
		var oldKingId = kingClientId;
		kingClientId = newKingId;
		kingTickAccum = 0;
		contactCooldown = 10; // ~320ms cooldown to prevent rapid re-triggers

		// Notify all clients via RPC
		NetCommands.setKingMarble(newKingId, oldKingId);
		// Update display on host too
		onKingChanged(newKingId, oldKingId);
	}

	// Called on all clients (and host) when king changes
	public function onKingChanged(newKingId:Int, oldKingId:Int) {
		kingClientId = newKingId;
		var myId = Net.isHost ? 0 : Net.clientId;
		if (newKingId == myId) {
			@:privateAccess level.playGui.addMiddleMessage("You are the King!", 0xFFD700);
		} else if (oldKingId == myId) {
			@:privateAccess level.playGui.addMiddleMessage("You lost the crown!", 0xFF4444);
		}
	}

	public function onScoreboardUpdate(newScores:Map<Int, Int>) {
		var myId = Net.isHost ? 0 : Net.clientId;
		var newScore = newScores.get(myId);
		if (newScore == null)
			newScore = 0;
		if (newScore > lastKnownScore && kingClientId == myId)
			@:privateAccess level.playGui.addMiddleMessage('+${newScore - lastKnownScore}', 0xFFD700);
		lastKnownScore = newScore;
	}

	function getMarbleByClientId(clientId:Int):Marble {
		for (marble in level.marbles)
			if (marble.getConnectionId() == clientId)
				return marble;
		return null;
	}

	function broadcastScoreboard() {
		var bs = new OutputBitStream();
		bs.writeByte(NetPacketType.ScoreBoardInfo);
		var sbPacket = new ScoreboardPacket();
		for (k => v in scores)
			sbPacket.scoreBoard.set(k, v);
		sbPacket.serialize(bs);
		Net.sendPacketToIngame(bs);
		@:privateAccess level.playGui.updatePlayerScores(sbPacket);
		onScoreboardUpdate(scores);
	}

	// Packets to send to a client joining mid-game
	override function getWorldJoinPackets():Array<haxe.io.Bytes> {
		var packets:Array<haxe.io.Bytes> = [];

		// Send current king
		var bs = new OutputBitStream();
		bs.writeByte(NetPacketType.KingInfo);
		var kingPacket = new KingInfoPacket();
		kingPacket.kingClientId = kingClientId;
		kingPacket.serialize(bs);
		packets.push(bs.getBytes());

		// Send current scores
		var bs2 = new OutputBitStream();
		bs2.writeByte(NetPacketType.ScoreBoardInfo);
		var sbPacket = new ScoreboardPacket();
		for (k => v in scores)
			sbPacket.scoreBoard.set(k, v);
		sbPacket.serialize(bs2);
		packets.push(bs2.getBytes());

		return packets;
	}

	override function onTimeExpire() {
		if (level.finishTime != null)
			return;

		AudioManager.playSound(ResourceLoader.getResource('data/sound/finish.wav', ResourceLoader.getAudio, @:privateAccess level.soundResources));
		level.finishTime = level.timeState.clone();
		level.marble.setMode(Start);
		level.marble.camera.finish = true;
		level.finishYaw = level.marble.camera.CameraYaw;
		level.finishPitch = level.marble.camera.CameraPitch;

		if (level.isMultiplayer) {
			@:privateAccess level.playGui.doMPEndGameMessage();
		} else {
			level.displayAlert("Congratulations! You've finished!");
		}

		level.cancel(@:privateAccess level.oobSchedule);
		level.cancel(@:privateAccess level.marble.oobSchedule);

		if (!level.isWatching) {
			if (level.isMultiplayer) {
				for (marble in level.marbles) {
					marble.setMode(Start);
					level.cancel(@:privateAccess marble.oobSchedule);
				}
				if (Net.isHost)
					NetCommands.timerRanOut();
				if (!level.isWatching)
					@:privateAccess level.schedule(level.timeState.currentAttemptTime + 5, () -> cast level.mpFinish());
			} else {
				var myScore = {name: "Player", time: getFinishScore()};
				var misPath = level.mission.isClaMission ? 'custom/mbu/${level.mission.id}' : level.mission.path;
				if (!level.cheatsUsed)
					Settings.saveScore(misPath, myScore, getScoreType());
				@:privateAccess level.schedule(level.timeState.currentAttemptTime + 5, () -> cast level.showFinishScreen());
			}
		}

		if (@:privateAccess level.timeTravelSound != null) {
			@:privateAccess level.timeTravelSound.stop();
			@:privateAccess level.timeTravelSound = null;
		}
	}

	// Called on clients when host broadcasts timer ran out
	public function doTimerRunOut() {
		AudioManager.playSound(ResourceLoader.getResource('data/sound/finish.wav', ResourceLoader.getAudio, @:privateAccess level.soundResources));
		level.finishTime = level.timeState.clone();
		level.marble.setMode(Start);
		level.marble.camera.finish = true;
		level.finishYaw = level.marble.camera.CameraYaw;
		level.finishPitch = level.marble.camera.CameraPitch;
		level.displayAlert("Congratulations! You've finished!");
		if (!level.isWatching)
			@:privateAccess level.schedule(level.timeState.currentAttemptTime, () -> cast level.showFinishScreen());
		if (@:privateAccess level.timeTravelSound != null) {
			@:privateAccess level.timeTravelSound.stop();
			@:privateAccess level.timeTravelSound = null;
		}
	}

	override function getFinishScore():Float {
		if (!level.isMultiplayer)
			return super.getFinishScore();
		var myId = Net.isHost ? 0 : Net.clientId;
		var s = scores.get(myId);
		return s != null ? s : 0;
	}

	override function getRewindState():RewindableState {
		var s = new KingState();
		s.kingClientId = kingClientId;
		s.kingTickAccum = kingTickAccum;
		s.scores = [for (k => v in scores) k => v];
		return s;
	}

	override function applyRewindState(state:RewindableState) {
		var s:KingState = cast state;
		kingClientId = s.kingClientId;
		kingTickAccum = s.kingTickAccum;
		scores = s.scores;
	}

	override function constructRewindState():RewindableState {
		return new KingState();
	}

	override function getPreloadFiles():Array<String> {
		return ['sound/finish.wav'];
	}
}
