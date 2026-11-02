package modes;

import net.ClientConnection.DummyConnection;
import net.BitStream.OutputBitStream;
import net.NetPacket.ScoreboardPacket;
import net.NetPacket.SoccerStatePacket;
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
class SoccerState implements RewindableState {
	var redScore:Int = 0;
	var blueScore:Int = 0;
	var overtime:Bool = false;
	var overtimeTicks:Int = 0;
	var goalCooldown:Int = 0;

	public function new() {}

	public function apply(level:src.MarbleWorld) {
		var mode:SoccerMode = cast level.gameMode;
		mode.applyRewindState(this);
	}

	public function clone():RewindableState {
		var c = new SoccerState();
		c.redScore = redScore;
		c.blueScore = blueScore;
		c.overtime = overtime;
		c.overtimeTicks = overtimeTicks;
		c.goalCooldown = goalCooldown;
		return c;
	}

	public function getSize():Int {
		return 13;
	}

	public function serialize(rm:RewindManager, bw:haxe.io.BytesOutput) {
		bw.writeUInt16(redScore);
		bw.writeUInt16(blueScore);
		bw.writeByte(overtime ? 1 : 0);
		bw.writeInt32(overtimeTicks);
		bw.writeInt32(goalCooldown);
	}

	public function deserialize(rm:RewindManager, br:haxe.io.BytesInput) {
		redScore = br.readUInt16();
		blueScore = br.readUInt16();
		overtime = br.readByte() == 1;
		overtimeTicks = br.readInt32();
		goalCooldown = br.readInt32();
	}
}

class SoccerMode extends NullMode implements TeamsMode {
	static final FOOTBALL_NET_ID = 32;
	static final TICKS_PER_SECOND = 32;
	static final OVERTIME_DURATION_TICKS = 120 * TICKS_PER_SECOND; // 2 minutes
	static final GOAL_COOLDOWN_TICKS = TICKS_PER_SECOND * 3; // 3 seconds

	var redSpawnPoints:Array<MissionElementSpawnSphere> = [];
	var blueSpawnPoints:Array<MissionElementSpawnSphere> = [];
	var allSpawnPoints:Array<MissionElementSpawnSphere> = [];
	var spawnIdx:Int = 0;

	var footballSpawnPos:Vector = null;

	public var football:Marble = null;

	var footballSpawning:Bool = false;

	var teamScores:Array<Int> = [0, 0];

	public var overtime:Bool = false;

	var overtimeTicks:Int = 0;
	var goalCooldown:Int = 0;
	var timerPausedTicks:Int = 0;
	var goalPauseStartTick:Int = -1;
	var goalPauseDurationTicks:Int = 0;

	var lastTouchMarble:Marble = null;

	inline function getTeam(clientId:Int):Int {
		var team = Net.getTeamId(clientId);
		if (team == 0 || team == 1)
			return team;
		// Fallback for unassigned players
		return Std.int(Math.abs(clientId)) % 2;
	}

	public function getTeamCount():Int {
		return 2;
	}

	public function getTeamName(team:Int):String {
		return TeamInfo.getName(team);
	}

	public function getTeamColor(team:Int):Int {
		return TeamInfo.getColor(team);
	}

	public function getTeamScore(team:Int):Int {
		return (team >= 0 && team < teamScores.length) ? teamScores[team] : 0;
	}

	public function showsIndividualScores():Bool {
		return false;
	}

	override function missionScan(mission:Mission) {
		function scan(simGroup:MissionElementSimGroup) {
			for (element in simGroup.elements) {
				if (element._type == MissionElementType.SpawnSphere) {
					var s:MissionElementSpawnSphere = cast element;
					switch (s.datablock.toLowerCase()) {
						case "spawnspheremarker_red":
							redSpawnPoints.push(s);
						case "spawnspheremarker_blue":
							blueSpawnPoints.push(s);
						case "footballspawnsphere":
							var pos = MisParser.parseVector3(s.position);
							pos.x *= -1;
							footballSpawnPos = pos;
						case "spawnspheremarker":
							allSpawnPoints.push(s);
					}
				} else if (element._type == MissionElementType.SimGroup) {
					scan(cast element);
				}
			}
		}
		scan(mission.root);

		// If no team-specific spawn points, split generic ones between teams
		if (redSpawnPoints.length == 0 && blueSpawnPoints.length == 0) {
			for (i in 0...allSpawnPoints.length) {
				if (i % 2 == 0)
					redSpawnPoints.push(allSpawnPoints[i]);
				else
					blueSpawnPoints.push(allSpawnPoints[i]);
			}
		}
	}

	function spawnPointToTransform(s:MissionElementSpawnSphere) {
		var pos = MisParser.parseVector3(s.position);
		pos.x *= -1;
		var rot = MisParser.parseRotation(s.rotation);
		rot.x *= -1;
		rot.w *= -1;
		var up = rot.toMatrix().up();
		pos = pos.add(up.multiply(0.727843 / 3));
		return {position: pos, orientation: rot, up: up};
	}

	override function getSpawnTransform() {
		var team = spawnIdx % 2;
		var points = team == 0 ? redSpawnPoints : blueSpawnPoints;
		if (points.length == 0)
			points = redSpawnPoints.length > 0 ? redSpawnPoints : blueSpawnPoints;
		if (points.length == 0)
			return super.getSpawnTransform();
		var idx = (spawnIdx >> 1) % points.length;
		spawnIdx++;
		return spawnPointToTransform(points[idx]);
	}

	override function getRespawnTransform(marble:Marble):{up:Vector, position:Vector, orientation:Quat} {
		if (marble == football)
			return footballSpawnPos != null ? {
				position: footballSpawnPos.clone(),
				orientation: new Quat(),
				up: new Vector(0, 0, 1)
			} : super.getRespawnTransform(marble);
		var clientId = marble.getConnectionId();
		var team = getTeam(clientId);
		var points = team == 0 ? redSpawnPoints : blueSpawnPoints;
		if (points.length == 0)
			points = redSpawnPoints.length > 0 ? redSpawnPoints : blueSpawnPoints;
		if (points.length == 0)
			return super.getRespawnTransform(marble);
		// Use the player's position within the team instead of spawn-call order,
		// so every peer puts the same player on the same team spawn point.
		var idx = getTeamSpawnIndex(team, clientId) % points.length;
		return spawnPointToTransform(points[idx]);
	}

	function getTeamSpawnIndex(team:Int, clientId:Int):Int {
		var ids:Array<Int> = [];
		if (!Net.hostSpectate && Net.hostTeam == team)
			ids.push(0);
		if (Net.isClient && Net.clientTeam == team)
			ids.push(Net.clientId);
		for (id => conn in Net.clientIdMap) {
			if (conn.spectator)
				continue;
			if (id == 0)
				continue; // host is handled above
			if (Net.isClient && id == Net.clientId)
				continue; // local client is handled above
			if (conn.teamId == team)
				ids.push(id);
		}
		ids.sort((a, b) -> a - b);
		var idx = ids.indexOf(clientId);
		return idx < 0 ? 0 : idx;
	}

	override function getInitialSpawnTransform(marble:Marble):{up:Vector, position:Vector, orientation:Quat} {
		return getRespawnTransform(marble);
	}

	override function getStartTime():Float {
		return level.mission.qualifyTime + getPausedTicks() * 0.032;
	}

	override function timeMultiplier():Float {
		return goalCooldown > 0 ? 0.0 : -1.0;
	}

	inline function getCurrentTick():Int {
		if (Net.isHost)
			return level.timeState.ticks;
		var serverTick = level.marble != null ? @:privateAccess level.marble.serverTicks : 0;
		if (serverTick > 0)
			return serverTick;
		// Before the first marble update arrives (e.g. right after a mid-game
		// join), timeState.ticks was seeded with the host's current tick.
		return level.timeState.ticks;
	}

	function getPausedTicks():Int {
		var paused = timerPausedTicks;
		if (goalPauseStartTick >= 0) {
			var elapsed = getCurrentTick() - goalPauseStartTick;
			if (elapsed < 0)
				elapsed = 0;
			if (elapsed > goalPauseDurationTicks)
				elapsed = goalPauseDurationTicks;
			paused += elapsed;
		}
		return paused;
	}

	override function update(t:TimeState) {
		if (goalPauseStartTick >= 0) {
			var remaining = goalPauseStartTick + goalPauseDurationTicks - getCurrentTick();
			if (remaining <= 0) {
				goalCooldown = 0;
				timerPausedTicks += goalPauseDurationTicks;
				goalPauseStartTick = -1;
				if (Net.isHost)
					resetAfterGoal();
			} else {
				goalCooldown = remaining;
			}
		}
	}

	override function getScoreType():ScoreType {
		return Score;
	}

	override function onRestart() {
		teamScores = [0, 0];
		overtime = false;
		overtimeTicks = 0;
		goalCooldown = 0;
		timerPausedTicks = 0;
		goalPauseStartTick = -1;
		goalPauseDurationTicks = 0;
		spawnIdx = 0;
		lastTouchMarble = null;
		spawnFootball();
		if (football != null)
			resetBall();
		faceBall(level.marble);
		if (@:privateAccess level.playGui != null)
			@:privateAccess level.playGui.refreshScoreboard();
	}

	override function onClientRestart() {
		teamScores = [0, 0];
		overtime = false;
		overtimeTicks = 0;
		goalCooldown = 0;
		timerPausedTicks = 0;
		goalPauseStartTick = -1;
		goalPauseDurationTicks = 0;
		lastTouchMarble = null;
		spawnFootball();
		if (football != null)
			resetBall();
		faceBall(level.marble);
		if (@:privateAccess level.playGui != null)
			@:privateAccess level.playGui.refreshScoreboard();
	}

	override function onMultiplayerStart() {
		spawnFootball();
	}

	function faceBall(marble:Marble) {
		if (marble == null || (football == null && footballSpawnPos == null))
			return;
		var target = football != null ? football.getAbsPos().getPosition() : footballSpawnPos;
		var pos = marble.getAbsPos().getPosition();
		var dir = target.sub(pos);
		if (dir.x == 0 && dir.y == 0)
			return;
		// Camera yaw is applied to the +X axis in CameraController.
		var yaw = Math.atan2(dir.y, dir.x);
		marble.camera.CameraYaw = yaw;
		marble.camera.nextCameraYaw = yaw;
	}

	override function onRespawn(marble:Marble) {
		if (marble.controllable)
			faceBall(marble);
	}

	public function spawnFootball() {
		if (football != null || footballSpawning)
			return;
		footballSpawning = true;
		var f = new Marble();
		f.controllable = false;
		f.startInvulnerable = false;
		if (!Net.clientIdMap.exists(FOOTBALL_NET_ID)) {
			Net.addGhost(FOOTBALL_NET_ID);
			Net.clientIdMap[FOOTBALL_NET_ID].setMarbleId(33);
		}
		level.addMarble(f, Net.clientIdMap[FOOTBALL_NET_ID], () -> {
			football = f;
			footballSpawning = false;
			@:privateAccess level.clientMarbles.set(football.connection, football);
			resetBall();
		});
	}

	function resetBall() {
		if (football == null || footballSpawnPos == null)
			return;
		football.setMarblePosition(footballSpawnPos.x, footballSpawnPos.y, footballSpawnPos.z);
		football.velocity.load(new Vector(0, 0, 0));
		football.omega.load(new Vector(0, 0, 0));
		football._radius = 1.86;
		@:privateAccess football._defaultRadius = 1.86;
		@:privateAccess football._renderScale = 1.86 / 0.2;
		@:privateAccess football._marbleScale = 1.86 / 0.2;
		@:privateAccess football._defaultScale = 1.86 / 0.2;
		football.getChildAt(0).setScale(1.86 / 0.2);
		football._mass = 0.75;
		football.collider.radius = 1.86;
		@:privateAccess football._kineticFriction = 0.7 * 0.66;
		@:privateAccess football._staticFriction = 1.1 * 0.66;
		@:privateAccess football._bounceKineticFriction = 0.2 * 0.66;

		football.setMode(Play);
	}

	override function onHostTick(timeState:TimeState) {
		if (!level.isMultiplayer || !Net.isHost)
			return;

		if (goalCooldown > 0)
			return;

		if (overtime) {
			overtimeTicks++;
			if (overtimeTicks >= OVERTIME_DURATION_TICKS) {
				overtime = false; // prevent re-entry
				NetCommands.timerRanOut();
				doEndGame();
			}
		}
	}

	override function onMarbleContact(attacker:Marble, victim:Marble) {
		if (!level.isMultiplayer || !Net.isHost)
			return;

		if (attacker == football && victim != football) {
			// store the player who last touched the ball
			lastTouchMarble = victim;
		}
		if (victim == football && attacker != football) {
			// store the player who last touched the ball
			lastTouchMarble = attacker;
		}
	}

	public function onBallEnterGoal(marble:Marble, goalTeam:Int) {
		if (marble != football)
			return;
		if (goalCooldown > 0)
			return;
		// Scoring team is the one that kicked it INTO the opposing team's goal
		var scoringTeam = 1 - goalTeam;
		var scorerId = lastTouchMarble != null ? lastTouchMarble.getConnectionId() : -1;

		teamScores[scoringTeam]++;
		var startTick = level.timeState.ticks;
		onGoalPauseStarted(GOAL_COOLDOWN_TICKS, startTick);
		NetCommands.soccerGoalScored(scoringTeam, teamScores[0], teamScores[1], GOAL_COOLDOWN_TICKS, startTick, scorerId);
		onGoalNotification(scoringTeam, teamScores[0], teamScores[1], scorerId);
	}

	public function onGoalPauseStarted(pauseTicks:Int, startTick:Int) {
		goalPauseStartTick = startTick;
		goalPauseDurationTicks = pauseTicks;
		goalCooldown = pauseTicks;
	}

	function resetAfterGoal() {
		lastTouchMarble = null;
		resetBall();
		for (m in level.marbles) {
			if (m == football)
				continue;
			level.restart(m);
		}
	}

	public function onGoalNotification(scoringTeam:Int, redScore:Int, blueScore:Int, scorerId:Int) {
		teamScores[0] = redScore;
		teamScores[1] = blueScore;
		if (@:privateAccess level.playGui != null)
			@:privateAccess level.playGui.refreshScoreboard();
		var teamName = scoringTeam == 0 ? "Red" : "Blue";
		var color = scoringTeam == 0 ? 0xFF4444 : 0x4444FF;
		var scorerName = getPlayerName(scorerId);
		if (scorerName != null)
			level.displayAlert('${scorerName} has scored a goal!');

		@:privateAccess level.playGui.addMiddleMessage('GOAL!  $redScore - $blueScore', color);

		// Pause the marble!
		football.setMode(Start);

		AudioManager.playSound(ResourceLoader.getResource('data/sound/finish.wav', ResourceLoader.getAudio, @:privateAccess this.level.soundResources));
		broadcastScoreboard();
	}

	function getPlayerName(clientId:Int):String {
		if (clientId < 0)
			return null;
		if (Net.isHost && clientId == 0)
			return Settings.highscoreName;
		if (Net.isClient && clientId == Net.clientId)
			return Settings.highscoreName;
		var conn = Net.clientIdMap.get(clientId);
		return conn != null ? conn.getName() : null;
	}

	function broadcastScoreboard() {
		var bs = new OutputBitStream();
		bs.writeByte(NetPacketType.ScoreBoardInfo);
		var sbPacket = new ScoreboardPacket();
		for (marble in level.marbles) {
			if (marble == football)
				continue;
			var clientId = marble.getConnectionId();
			sbPacket.scoreBoard.set(clientId, teamScores[getTeam(clientId)]);
		}
		sbPacket.serialize(bs);
		Net.sendPacketToIngame(bs);
		@:privateAccess level.playGui.updatePlayerScores(sbPacket);
	}

	override function onTimeExpire() {
		if (level.finishTime != null)
			return;

		if (Net.isHost) {
			if (!overtime && teamScores[0] == teamScores[1]) {
				overtime = true;
				overtimeTicks = 0;
				NetCommands.soccerOvertime();
				onOvertimeStarted();
				return;
			}
			NetCommands.timerRanOut();
		}
		doEndGame();
	}

	public function onOvertimeStarted() {
		level.displayAlert("Match going into overtime! First team to score a goal wins!");
	}

	public function doEndGame() {
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
			var winner = teamScores[0] > teamScores[1] ? "Red" : (teamScores[1] > teamScores[0] ? "Blue" : "Nobody");
			level.displayAlert('$winner wins! ${teamScores[0]} - ${teamScores[1]}');
		}

		level.cancel(@:privateAccess level.oobSchedule);
		level.cancel(@:privateAccess level.marble.oobSchedule);

		if (!level.isWatching) {
			if (level.isMultiplayer) {
				for (marble in level.marbles) {
					if (marble == football)
						continue;
					marble.setMode(Start);
					level.cancel(@:privateAccess marble.oobSchedule);
				}
				@:privateAccess level.schedule(level.timeState.currentAttemptTime + 5, () -> cast level.mpFinish());
			} else {
				var myScore = {name: "Player", time: getFinishScore()};
				Settings.saveScore(level.mission.path, myScore, getScoreType());
				@:privateAccess level.schedule(level.timeState.currentAttemptTime + 5, () -> cast level.showFinishScreen());
			}
		}

		if (@:privateAccess level.timeTravelSound != null) {
			@:privateAccess level.timeTravelSound.stop();
			@:privateAccess level.timeTravelSound = null;
		}
	}

	override function getFinishScore():Float {
		if (!level.isMultiplayer)
			return super.getFinishScore();
		var myId = Net.isHost ? 0 : Net.clientId;
		return teamScores[getTeam(myId)];
	}

	override function getWorldJoinPackets():Array<haxe.io.Bytes> {
		var packets:Array<haxe.io.Bytes> = [];

		var bs = new OutputBitStream();
		bs.writeByte(NetPacketType.SoccerInfo);
		var packet = new SoccerStatePacket();
		packet.redScore = teamScores[0];
		packet.blueScore = teamScores[1];
		packet.overtime = overtime;
		packet.footballSpawned = football != null;
		packet.timerPausedTicks = timerPausedTicks;
		packet.goalPauseStartTick = goalPauseStartTick;
		packet.goalPauseDurationTicks = goalPauseDurationTicks;
		packet.gameplayClock = level.timeState.gameplayClock;
		packet.serialize(bs);
		packets.push(bs.getBytes());

		var bs2 = new OutputBitStream();
		bs2.writeByte(NetPacketType.ScoreBoardInfo);
		var sbPacket = new ScoreboardPacket();
		for (marble in level.marbles) {
			if (marble == football)
				continue;
			var clientId = marble.getConnectionId();
			sbPacket.scoreBoard.set(clientId, teamScores[getTeam(clientId)]);
		}
		sbPacket.serialize(bs2);
		packets.push(bs2.getBytes());

		return packets;
	}

	public function onSoccerStateReceived(packet:SoccerStatePacket) {
		teamScores[0] = packet.redScore;
		teamScores[1] = packet.blueScore;
		overtime = packet.overtime;
		timerPausedTicks = packet.timerPausedTicks;
		goalPauseStartTick = packet.goalPauseStartTick;
		goalPauseDurationTicks = packet.goalPauseDurationTicks;
		level.timeState.gameplayClock = packet.gameplayClock;
		if (goalPauseStartTick >= 0) {
			var remaining = goalPauseStartTick + goalPauseDurationTicks - getCurrentTick();
			goalCooldown = remaining > 0 ? remaining : 0;
		} else {
			goalCooldown = 0;
		}
		if (@:privateAccess level.playGui != null)
			@:privateAccess level.playGui.refreshScoreboard();
		if (packet.footballSpawned)
			spawnFootball();
	}

	override function getRewindState():RewindableState {
		var s = new SoccerState();
		s.redScore = teamScores[0];
		s.blueScore = teamScores[1];
		s.overtime = overtime;
		s.overtimeTicks = overtimeTicks;
		s.goalCooldown = goalCooldown;
		return s;
	}

	override function applyRewindState(state:RewindableState) {
		var s:SoccerState = cast state;
		teamScores[0] = s.redScore;
		teamScores[1] = s.blueScore;
		overtime = s.overtime;
		overtimeTicks = s.overtimeTicks;
		goalCooldown = s.goalCooldown;
	}

	override function constructRewindState():RewindableState {
		return new SoccerState();
	}

	override function getPreloadFiles():Array<String> {
		return ['sound/finish.wav'];
	}

	override function onDispose() {
		Net.clientIdMap.remove(FOOTBALL_NET_ID);
	}
}
