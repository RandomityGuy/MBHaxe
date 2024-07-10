package modes;

import gui.MPEndGameGui;
import net.NetCommands;
import net.BitStream.OutputBitStream;
import net.NetPacket.GemPickupPacket;
import net.NetPacket.GemSpawnPacket;
import octree.IOctreeObject;
import octree.IOctreeObject.RayIntersectionData;
import h3d.col.Bounds;
import octree.IOctreeElement;
import shapes.GemBeam;
import h3d.Quat;
import h3d.Vector;
import shapes.Gem;
import mis.MisParser;
import mis.MissionElement.MissionElementSimGroup;
import octree.Octree;
import mis.MissionElement.MissionElementTrigger;
import mis.MissionElement.MissionElementType;
import src.Mission;
import src.Marble;
import src.AudioManager;
import src.ResourceLoader;
import net.Net;
import src.MarbleGame;

@:structInit
@:publicFields
class GemSpawnPoint implements IOctreeObject {
	var gem:Gem;
	var gemBeam:GemBeam;

	var boundingBox:Bounds;
	var netIndex:Int;

	var priority:Int;

	public function new(vec:Vector, spawn:Gem, netIndex:Int) {
		boundingBox = new Bounds();
		boundingBox.addPoint(vec.add(new Vector(-0.5, -0.5, -0.5)).toPoint());
		boundingBox.addPoint(vec.add(new Vector(0.5, 0.5, 0.5)).toPoint());
		this.gem = spawn;
		this.netIndex = netIndex;
		this.gem.netIndex = netIndex;
	}

	public function getElementType() {
		return 2;
	}

	public function setPriority(priority:Int) {
		this.priority = priority;
	}

	public function rayCast(rayOrigin:Vector, rayDirection:Vector, resultSet:Array<RayIntersectionData>, bestT:Float):Float {
		throw new haxe.exceptions.NotImplementedException(); // Not applicable
	}
}

class HuntMode extends NullMode {
	var playerSpawnPoints:Array<MissionElementTrigger> = [];
	var spawnPointTaken = [];
	var gemOctree:Octree;
	var gemGroupRadius:Float;
	var maxGemsPerGroup:Int;
	var rng:RandomLCG = new RandomLCG(100);
	var rng2:RandomLCG = new RandomLCG(100);
	var gemSpawnPoints:Array<GemSpawnPoint>;
	var lastSpawn:GemSpawnPoint;
	var activeGemSpawnGroup:Array<Int>;
	var gemBeams:Array<GemBeam> = [];
	var gemToBeamMap:Map<Gem, GemBeam> = [];
	var gemToBlackBeamMap:Map<Gem, GemBeam> = [];
	var activeGems:Array<Gem> = [];
	var points:Int = 0;
	var gemsCentroid:Vector;
	var idealSpawnIndex:Int;
	var expiredGems:Map<Gem, Bool> = [];
	var competitiveTimerStartTicks:Int;

	override function missionScan(mission:Mission) {
		function scanMission(simGroup:MissionElementSimGroup) {
			for (element in simGroup.elements) {
				if ([MissionElementType.Trigger].contains(element._type)) {
					var spawnSphere:MissionElementTrigger = cast element;
					var dbname = spawnSphere.datablock.toLowerCase();
					if (dbname == "spawntrigger") {
						playerSpawnPoints.push(spawnSphere);
						spawnPointTaken.push(false);
					}
				} else if (element._type == MissionElementType.SimGroup) {
					scanMission(cast element);
				}
			}
		}
		scanMission(mission.root);
	};

	override function getSpawnTransform() {
		var idx = Net.connectedServerInfo.competitiveMode ? idealSpawnIndex : Math.floor(rng2.randRange(0, playerSpawnPoints.length - 1));
		if (!Net.connectedServerInfo.competitiveMode) {
			while (spawnPointTaken[idx]) {
				idx = Math.floor(rng2.randRange(0, playerSpawnPoints.length - 1));
			}
			spawnPointTaken[idx] = true;
		}

		var randomSpawn = playerSpawnPoints[idx];
		var spawnPos = MisParser.parseVector3(randomSpawn.position);
		spawnPos.x *= -1;
		var spawnRot = MisParser.parseRotation(randomSpawn.rotation);
		spawnRot.x *= -1;
		spawnRot.w *= -1;
		var spawnMat = spawnRot.toMatrix();
		var up = spawnMat.up();

		if (MisParser.parseBoolean(randomSpawn.g))
			up.load(up.multiply(-1));

		spawnPos = spawnPos.add(up); // 1.5 -> 0.5
		return {
			position: spawnPos,
			orientation: spawnRot,
			up: up
		}
	}

	public function freeSpawns() {
		for (i in 0...playerSpawnPoints.length) {
			spawnPointTaken[i] = false;
		}
	}

	override function getRespawnTransform(marble:Marble) {
		var lastContactPos = marble.lastContactPosition;
		if (lastContactPos == null) {
			var idx = Math.floor(rng2.randRange(0, playerSpawnPoints.length - 1));
			var randomSpawn = playerSpawnPoints[idx];
			var spawnPos = MisParser.parseVector3(randomSpawn.position);
			spawnPos.x *= -1;
			var spawnRot = MisParser.parseRotation(randomSpawn.rotation);
			spawnRot.x *= -1;
			spawnRot.w *= -1;
			var spawnMat = spawnRot.toMatrix();
			var up = spawnMat.up();
			if (MisParser.parseBoolean(randomSpawn.g))
				up.load(up.multiply(-1));

			spawnPos = spawnPos.add(up); // 1.5 -> 0.5
			return {
				position: spawnPos,
				orientation: spawnRot,
				up: up
			}
		}
		// Pick closest spawn point
		var closestSpawn:MissionElementTrigger = null;
		var closestDistance = 1e10;
		for (spawn in playerSpawnPoints) {
			var pos = MisParser.parseVector3(spawn.position);
			pos.x *= -1;
			var dist = pos.distance(lastContactPos);
			if (dist < closestDistance) {
				closestDistance = dist;
				closestSpawn = spawn;
			}
		}
		if (closestSpawn != null) {
			var spawnPos = MisParser.parseVector3(closestSpawn.position);
			spawnPos.x *= -1;
			var spawnRot = MisParser.parseRotation(closestSpawn.rotation);
			spawnRot.x *= -1;
			spawnRot.w *= -1;
			var spawnMat = spawnRot.toMatrix();
			var up = spawnMat.up();
			if (MisParser.parseBoolean(closestSpawn.g))
				up.load(up.multiply(-1));

			spawnPos = spawnPos.add(up); // 1.5 -> 0.5

			return {
				position: spawnPos,
				orientation: spawnRot,
				up: up
			}
		}
		return null;
	}

	function prepareGems() {
		if (this.gemSpawnPoints == null) {
			this.gemOctree = new Octree();
			this.gemSpawnPoints = [];
			this.gemsCentroid = new Vector();
			for (gem in this.level.gems) {
				var spawn:GemSpawnPoint = new GemSpawnPoint(gem.getAbsPos().getPosition(), gem, gemSpawnPoints.length);
				gem.setHide(true);
				gem.pickedUp = true;
				this.gemSpawnPoints.push(spawn);
				this.gemOctree.insert(spawn);
				gem.setHide(true);
				this.level.collisionWorld.removeEntity(gem.boundingCollider); // remove from octree to make it easy
				if (level.isMultiplayer) {
					@:privateAccess level.gemPredictions.alloc();
				}
				gemsCentroid.load(gemsCentroid.add(gem.getAbsPos().getPosition()));
			}
			if (gemSpawnPoints.length > 0)
				gemsCentroid.load(gemsCentroid.multiply(1.0 / gemSpawnPoints.length));

			var closestSpawnIndex = 0;
			var closestSpawnDistance = 1e8;
			for (i in 0...playerSpawnPoints.length) {
				var spawn = playerSpawnPoints[i];
				var spawnPos = MisParser.parseVector3(spawn.position);
				spawnPos.x *= -1;
				if (spawnPos.distance(gemsCentroid) < closestSpawnDistance) {
					closestSpawnDistance = spawnPos.distance(gemsCentroid);
					closestSpawnIndex = i;
				}
			}
			idealSpawnIndex = closestSpawnIndex;
		}
		for (i in 0...spawnPointTaken.length) {
			spawnPointTaken[i] = false;
		}
	}

	override function getPreloadFiles() {
		return ['data/sound/opponentdiamond.wav', 'data/sound/firewrks.wav'];
	}

	function setupGems() {
		hideExisting();
		this.activeGems = [];
		this.activeGemSpawnGroup = [];
		this.rng.setSeed(cast Math.random() * 10000);
		this.rng2.setSeed(cast Math.random() * 10000);
		prepareGems();
		spawnHuntGems();
	}

	function spawnHuntGems(force:Bool = false) {
		if (activeGems.length != 0 && !force)
			return;
		var gemGroupRadius = 15.0;
		var maxGemsPerSpawn = 7;
		if (level.mission.missionInfo.maxgemsperspawn != null && level.mission.missionInfo.maxgemsperspawn != "")
			maxGemsPerSpawn = Std.parseInt(level.mission.missionInfo.maxgemsperspawn);
		if (level.mission.missionInfo.radiusfromgem != null && level.mission.missionInfo.radiusfromgem != "")
			gemGroupRadius = Std.parseFloat(level.mission.missionInfo.radiusfromgem);
		var spawnBlock = gemGroupRadius * 2;
		if (level.mission.missionInfo.spawnblock != null && level.mission.missionInfo.spawnblock != "")
			spawnBlock = Std.parseFloat(level.mission.missionInfo.spawnblock);

		var lastPos = null;
		if (lastSpawn != null)
			lastPos = lastSpawn.gem.getAbsPos().getPosition();

		var furthestDist = 0.0;
		var furthest = null;

		for (i in 0...6) {
			var gem = gemSpawnPoints[Std.int(rng.randRange(0, gemSpawnPoints.length - 1))];
			if (lastPos != null) {
				var dist = gem.gem.getAbsPos().getPosition().distance(lastPos);
				if (dist < spawnBlock) {
					if (dist > furthestDist) {
						furthestDist = dist;
						furthest = gem;
					}
					continue;
				} else {
					break;
				}
			} else {
				furthest = gem;
				break;
			}
		}
		if (furthest == null) {
			furthest = gemSpawnPoints[Std.int(rng.randRange(0, gemSpawnPoints.length - 1))];
		}
		var pos = furthest.gem.getAbsPos().getPosition();

		var results = [];
		while (results.length == 0) {
			var search = gemOctree.radiusSearch(pos, gemGroupRadius);
			for (elem in search) {
				var gemElem:GemSpawnPoint = cast elem;
				var gemPos = gemElem.gem.getAbsPos().getPosition();

				if (level.mission.missionInfo.game == "PlatinumQuest") {
					// Spawn chances!
					var chance = switch (gemElem.gem.gemColor.toLowerCase()) {
						case "red.gem":
							level.mission.missionInfo.spawnchancered != null ? Std.parseFloat(level.mission.missionInfo.spawnchancered) : 0.9;
						case "yellow.gem":
							level.mission.missionInfo.spawnchanceyellow != null ? Std.parseFloat(level.mission.missionInfo.spawnchanceyellow) : 0.65;
						case "blue.gem":
							level.mission.missionInfo.spawnchanceblue != null ? Std.parseFloat(level.mission.missionInfo.spawnchanceblue) : 0.35;
						case "platinum.gem":
							level.mission.missionInfo.spawnchanceplatinum != null ? Std.parseFloat(level.mission.missionInfo.spawnchanceplatinum) : 0.18;
						default:
							1.0;
					};
					var choice = Math.random();
					if (choice > chance)
						continue; // Don't spawn!
				}

				results.push({
					gem: gemElem.netIndex,
					weight: this.gemGroupRadius - gemPos.distance(pos) + rng.randRange(0, getGemWeight(gemElem.gem) + 3)
				});
			}
		}
		results.sort((a, b) -> {
			if (a.weight > b.weight)
				return -1;
			if (a.weight < b.weight)
				return 1;
			return 0;
		});
		var spawnSet = results.slice(0, maxGemsPerSpawn).map(x -> x.gem);

		if (force) {
			for (activeGem in activeGemSpawnGroup)
				spawnSet.remove(activeGem);
		}

		for (gem in spawnSet) {
			spawnGem(gem);
		}
		if (!force)
			activeGemSpawnGroup = spawnSet;
		else {
			var uncollectedGems = [];
			for (g in activeGemSpawnGroup) {
				if (!gemSpawnPoints[g].gem.pickedUp)
					uncollectedGems.push(g);
			}
			activeGemSpawnGroup = uncollectedGems.concat(spawnSet);
		}

		if (level.isMultiplayer && Net.isHost) {
			var bs = new OutputBitStream();
			bs.writeByte(GemSpawn);
			var packet = new GemSpawnPacket();
			packet.gemIds = activeGemSpawnGroup;
			packet.expireds = [];
			for (i in 0...packet.gemIds.length) {
				if (expiredGems.exists(gemSpawnPoints[packet.gemIds[i]].gem)) {
					packet.expireds.push(true);
				} else {
					packet.expireds.push(false);
				}
			}
			packet.serialize(bs);
			Net.sendPacketToIngame(bs);
		}

		lastSpawn = furthest;
	}

	function spawnGem(spawn:Int, expired:Bool = false) {
		var gem = gemSpawnPoints[spawn];
		gem.gem.setHide(false);
		gem.gem.pickedUp = false;
		this.level.collisionWorld.addEntity(gem.gem.boundingCollider);
		activeGems.push(gem.gem);
		if (!expired) {
			if (gem.gemBeam == null) {
				gem.gemBeam = new GemBeam(StringTools.replace(gem.gem.gemColor, '.gem', ''));

				var gemPos = gem.gem.getAbsPos().getPosition();

				gem.gemBeam.setPosition(gemPos.x, gemPos.y, gemPos.z);
				gem.gemBeam.setRotationQuat(gem.gem.getRotationQuat().clone());
				// gem.gemBeam.setOpacity(0.99);
				this.gemBeams.push(gem.gemBeam);

				this.gemToBeamMap.set(gem.gem, gem.gemBeam);

				level.addDtsObject(gem.gemBeam, () -> {
					// Please be fast lol
				});
			} else {
				gem.gemBeam.setHide(false);
			}
		} else {
			if (gemToBlackBeamMap.exists(gem.gem)) {
				gemToBlackBeamMap.get(gem.gem).setHide(false);
			} else {
				var blackBeam = new GemBeam("black");
				var pos = gem.gem.getAbsPos().getPosition();
				blackBeam.setPosition(gem.gem.x, gem.gem.y, gem.gem.z);
				blackBeam.setRotationQuat(gem.gem.getRotationQuat().clone());
				blackBeam.setHide(false);
				level.addDtsObject(blackBeam, () -> {});
				gemToBlackBeamMap.set(gem.gem, blackBeam);
			}
		}
	}

	public inline function setGemHiddenStatus(gemId:Int, status:Bool) {
		var gemSpawn = gemSpawnPoints[gemId];
		if (gemSpawn.gem != null) {
			gemSpawn.gem.pickedUp = status;
			gemSpawn.gem.setHide(status);

			if (expiredGems.exists(gemSpawn.gem)) {
				var blackBeam = gemToBlackBeamMap.get(gemSpawn.gem);
				blackBeam.setHide(status);
				gemSpawn.gemBeam.setHide(true);
			} else {
				gemSpawn.gemBeam.setHide(status);
			}
			if (status)
				this.activeGems.push(gemSpawn.gem);
			else
				this.activeGems.remove(gemSpawn.gem);
		} else {
			throw new haxe.Exception("Setting gem status for non existent gem!");
		}
	}

	public function setActiveSpawnSphere(gems:Array<Int>, expireds:Array<Bool>) {
		hideExisting();
		expiredGems = [];
		for (i in 0...gems.length) {
			var gem = gems[i];
			spawnGem(gem, expireds[i]);
			if (expireds[i]) {
				expiredGems.set(gemSpawnPoints[gem].gem, true);
			}
		}
		activeGemSpawnGroup = gems;
	}

	function getGemWeight(gem:Gem) {
		var col = gem.gemColor.toLowerCase();
		if (col == "red.gem")
			return 0;
		if (col == "yellow.gem")
			return 1;
		if (col == "blue.gem")
			return 4;
		if (col == "platinum.gem")
			return 9;
		return 0;
	}

	function hideExisting() {
		lastSpawn = null;
		if (gemSpawnPoints != null) {
			for (gs in gemSpawnPoints) {
				gs.gem.setHide(true);
				gs.gem.pickedUp = true;
				if (gs.gemBeam != null) {
					gs.gemBeam.setHide(true);
				}
				if (gemToBlackBeamMap.exists(gs.gem)) {
					gemToBlackBeamMap.get(gs.gem).setHide(true);
				}
			}
		}
	}

	override public function getStartTime() {
		return level.mission.qualifyTime;
	}

	override function onRestart() {
		setupGems();
		points = 0;
		competitiveTimerStartTicks = 0;
		@:privateAccess level.playGui.formatGemHuntCounter(points);
	}

	override function onMissionLoad() {
		prepareGems();
		competitiveTimerStartTicks = 0;
	}

	override function onClientRestart() {
		prepareGems();
		competitiveTimerStartTicks = 0;
	}

	override function onTimeExpire() {
		if (level.finishTime != null)
			return;

		AudioManager.playSound(ResourceLoader.getResource("data/sound/firewrks.wav", ResourceLoader.getAudio, @:privateAccess level.soundResources));
		// AudioManager.playSound(ResourceLoader.getResource('data/sound/finish.wav', ResourceLoader.getAudio, @:privateAccess level.soundResources));
		level.finishTime = level.timeState.clone();
		level.marble.setMode(Finish);
		level.marble.camera.finish = true;
		level.finishYaw = level.marble.camera.CameraYaw;
		level.finishPitch = level.marble.camera.CameraPitch;
		// if (level.isMultiplayer) {
		// 	@:privateAccess level.playGui.doMPEndGameMessage();
		// } else {
		// 	level.displayAlert("Congratulations! You've finished!");
		// }
		level.cancel(@:privateAccess level.oobSchedule);
		level.cancel(@:privateAccess level.marble.oobSchedule);
		for (marble in level.marbles) {
			marble.setMode(Finish);
			level.cancel(@:privateAccess marble.oobSchedule);
		}
		if (Net.isHost)
			NetCommands.timerRanOut();

		// Stop the ongoing sounds
		if (@:privateAccess level.timeTravelSound != null) {
			@:privateAccess level.timeTravelSound.stop();
			@:privateAccess level.timeTravelSound = null;
		}

		level.schedule(level.timeState.currentAttemptTime + 2, () -> {
			MarbleGame.canvas.pushDialog(new MPEndGameGui());
			level.setCursorLock(false);
			return 0;
		});
	}

	override function onGemPickup(marble:Marble, gem:Gem) {
		if ((@:privateAccess !marble.isNetUpdate && Net.isHost) || !Net.isMP) {
			if (marble == level.marble)
				AudioManager.playSound(ResourceLoader.getResource('data/sound/gotgem.wav', ResourceLoader.getAudio, @:privateAccess this.level.soundResources));
			else
				AudioManager.playSound(ResourceLoader.getResource('data/sound/opponentdiamond.wav', ResourceLoader.getAudio,
					@:privateAccess this.level.soundResources));
		}
		activeGems.remove(gem);

		var wasExpiredGem = false;

		if (expiredGems.exists(gem)) {
			wasExpiredGem = true;
			expiredGems.remove(gem);
		}
		if (gemToBlackBeamMap.exists(gem)) {
			gemToBlackBeamMap.get(gem).setHide(true);
		}

		var beam = gemToBeamMap.get(gem);
		beam.setHide(true);

		if (!this.level.isMultiplayer || Net.isHost) {
			spawnHuntGems();
		}

		var incr = 0;
		switch (gem.gemColor.toLowerCase()) {
			case "red.gem":
				incr = 1;
			case "yellow.gem":
				incr = 2;
			case "blue.gem":
				incr = 5;
			case "platinum.gem":
				incr = 10;
		}

		if (@:privateAccess !marble.isNetUpdate) {
			if (marble == level.marble) {
				switch (gem.gemColor.toLowerCase()) {
					case "red.gem":
						points += 1;
						@:privateAccess level.playGui.addMiddleMessage('+1', 0xFF6666);
					case "yellow.gem":
						points += 2;
						@:privateAccess level.playGui.addMiddleMessage('+2', 0xFFFF66);
					case "blue.gem":
						points += 5;
						@:privateAccess level.playGui.addMiddleMessage('+5', 0x6666FF);
					case "platinum.gem":
						points += 10;
						@:privateAccess level.playGui.addMiddleMessage('+10', 0xdddddd);
				}
				@:privateAccess level.playGui.formatGemHuntCounter(points);
			}
		}

		if (this.level.isMultiplayer && Net.isHost) {
			if (Net.connectedServerInfo.competitiveMode && !wasExpiredGem) {
				if (competitiveTimerStartTicks == 0) {
					NetCommands.setCompetitiveTimerStartTicks(this.level.timeState.ticks);
				}
				var remaining = 0;
				for (g in activeGems)
					if (!expiredGems.exists(g))
						remaining++;
				if (remaining == 3) {
					var currentTime = level.timeState.ticks;
					var endTime = competitiveTimerStartTicks + (20000 >> 5);
					var remainingTicks = (endTime - currentTime);
					if (remainingTicks > (15000 >> 5)) {
						NetCommands.setCompetitiveTimerStartTicks(currentTime - (5000 >> 5));
					}
				}
				if (remaining == 2) {
					var currentTime = level.timeState.ticks;
					var endTime = competitiveTimerStartTicks + (20000 >> 5);
					var remainingTicks = (endTime - currentTime);
					if (remainingTicks > (10000 >> 5)) {
						NetCommands.setCompetitiveTimerStartTicks(currentTime - (10000 >> 5));
					}
				}
				if (remaining == 1) {
					var currentTime = level.timeState.ticks;
					var endTime = competitiveTimerStartTicks + (20000 >> 5);
					var remainingTicks = (endTime - currentTime);
					if (remainingTicks > (5000 >> 5)) {
						NetCommands.setCompetitiveTimerStartTicks(currentTime - (15000 >> 5));
					}
				}
				if (remaining == 0) {
					NetCommands.setCompetitiveTimerStartTicks(0);
				}
			}

			var packet = new GemPickupPacket();
			packet.clientId = @:privateAccess marble.connection == null ? 0 : @:privateAccess marble.connection.id;
			packet.gemId = gem.netIndex;
			packet.serverTicks = level.timeState.ticks;
			packet.scoreIncr = incr;
			var os = new OutputBitStream();
			os.writeByte(GemPickup);
			packet.serialize(os);
			Net.sendPacketToIngame(os);

			// Settings.playStatistics.totalMPScore += incr;

			@:privateAccess level.playGui.incrementPlayerScore(packet.clientId, packet.scoreIncr);
		}
		if (this.level.isMultiplayer && Net.isClient) {
			gem.pickUpClient = @:privateAccess marble.connection == null ? Net.clientId : @:privateAccess marble.connection.id;
		}
	}

	public function setCompetitiveTimerStartTicks(ticks:Int) {
		competitiveTimerStartTicks = ticks;
	}

	function spawnNextGemCluster() {
		// Expire all existing
		for (g in activeGems) {
			expiredGems.set(g, true);
			var gemBeam = gemToBeamMap.get(g);
			gemBeam.setHide(true);
			if (gemToBlackBeamMap.exists(g)) {
				gemToBlackBeamMap.get(g).setHide(false);
			} else {
				var blackBeam = new GemBeam("black");
				var pos = g.getAbsPos().getPosition();
				blackBeam.setPosition(g.x, g.y, g.z);
				blackBeam.setRotationQuat(g.getRotationQuat().clone());
				blackBeam.setHide(false);
				level.addDtsObject(blackBeam, () -> {});
				gemToBlackBeamMap.set(g, blackBeam);
			}
		}
		spawnHuntGems(true);
	}

	override function update(t:src.TimeState) {
		if (Net.connectedServerInfo.competitiveMode) {
			if (competitiveTimerStartTicks != 0) {
				var currentTime = Net.isHost ? t.ticks : @:privateAccess level.marble.serverTicks;
				var endTime = competitiveTimerStartTicks + (20000 >> 5);
				@:privateAccess level.playGui.formatCountdownTimer(Math.max(0, (endTime - currentTime) * 0.032), 0);
				if (Net.isHost && endTime < currentTime) {
					spawnNextGemCluster();
					NetCommands.setCompetitiveTimerStartTicks(0);
				}
			} else {
				@:privateAccess level.playGui.formatCountdownTimer(0, 0);
			}
		}
	}

	override public function timeMultiplier() {
		return -1;
	}
}
