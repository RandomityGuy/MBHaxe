package modes;

import net.NetCommands;
import net.NetPacket.GemPickupPacket;
import haxe.Exception;
import net.BitStream.OutputBitStream;
import net.NetPacket.GemSpawnPacket;
import net.Net;
import rewind.RewindManager;
import hxd.Rand;
import rewind.RewindableState;
import gui.AchievementsGui;
import modes.GameMode.ScoreType;
import shapes.GemBeam;
import shapes.Gem;
import src.Console;
import h3d.col.Bounds;
import octree.IOctreeObject.RayIntersectionData;
import octree.Octree;
import octree.IOctreeObject.IOctreeObject;
import mis.MisParser;
import h3d.Vector;
import h3d.Quat;
import mis.MissionElement.MissionElementType;
import mis.MissionElement;
import src.Mission;
import mis.MissionElement.MissionElementSpawnSphere;
import src.AudioManager;
import src.ResourceLoader;
import src.Settings;
import src.Marble;

@:publicFields
class GemSpawnSphere {
	var netIndex:Int;
	var position:Vector;
	var rotation:Quat;
	var element:MissionElementSpawnSphere;
	var gem:Gem;
	var gemBeam:GemBeam;
	var gemColor:String;

	public function new(elem:MissionElementSpawnSphere) {
		position = MisParser.parseVector3(elem.position);
		position.x *= -1;
		rotation = MisParser.parseRotation(elem.rotation);
		rotation.x *= -1;
		rotation.w *= -1;
		element = elem;
		gemColor = "red";
		if (elem.gemdatablock != null) {
			switch (elem.gemdatablock.toLowerCase()) {
				case "gemitem_2pts":
					gemColor = "yellow";
				case "gemitem_5pts":
					gemColor = "blue";
				default:
					gemColor = "red";
			}
		}
	}
}

class GemOctreeElem implements IOctreeObject {
	public var boundingBox:Bounds;
	public var spawn:GemSpawnSphere;
	public var spawnIndex:Int;

	var priority:Int;

	public function new(vec:Vector, spawn:GemSpawnSphere, spawnIndex:Int) {
		boundingBox = new Bounds();
		boundingBox.addPoint(vec.add(new Vector(-0.5, -0.5, -0.5)).toPoint());
		boundingBox.addPoint(vec.add(new Vector(0.5, 0.5, 0.5)).toPoint());
		this.spawn = spawn;
		this.spawnIndex = spawnIndex;
	}

	public function getElementType() {
		return 2;
	}

	public function setPriority(priority:Int) {
		this.priority = priority;
	}

	public function rayCast(rayOrigin:Vector, rayDirection:Vector):Array<RayIntersectionData> {
		throw new haxe.exceptions.NotImplementedException(); // Not applicable
	}
}

@:publicFields
class HuntState implements RewindableState {
	var activeGemSpawnGroup:Array<Int>;
	var activeGems:Array<Gem>;
	var points:Int;
	var rngState:Int;
	var rngState2:Int;

	public function new() {}

	public function apply(level:src.MarbleWorld) {
		var mode:HuntMode = cast level.gameMode;
		mode.applyRewindState(this);
	}

	public function clone():RewindableState {
		var c = new HuntState();
		c.activeGemSpawnGroup = activeGemSpawnGroup.copy();
		c.points = points;
		c.activeGems = activeGems.copy();
		c.rngState = rngState;
		c.rngState2 = rngState2;
		return c;
	}

	public function getSize():Int {
		var size = 2;
		size += 2 + activeGemSpawnGroup.length * 2;
		size += 2 + activeGems.length * 2;
		size += 4;
		size += 4;
		size += 4;
		return size;
	}

	public function serialize(rm:RewindManager, bw:haxe.io.BytesOutput) {
		bw.writeUInt16(points);
		bw.writeUInt16(activeGemSpawnGroup.length);
		for (elem in activeGemSpawnGroup) {
			bw.writeUInt16(elem);
		}
		bw.writeUInt16(activeGems.length);
		for (elem in activeGems) {
			bw.writeUInt16(rm.allocGO(elem));
		}
		bw.writeInt32(rngState);
		bw.writeInt32(rngState2);
	}

	public function deserialize(rm:RewindManager, br:haxe.io.BytesInput) {
		points = br.readUInt16();
		activeGemSpawnGroup = [];
		var len = br.readUInt16();
		for (i in 0...len) {
			activeGemSpawnGroup.push(br.readUInt16());
		}
		activeGems = [];
		var len = br.readUInt16();
		for (i in 0...len) {
			var uid = br.readUInt16();
			activeGems.push(cast rm.getGO(uid));
		}
		rngState = br.readInt32();
		rngState2 = br.readInt32();
	}
}

class HuntMode extends NullMode {
	var gemSpawnPoints:Array<GemSpawnSphere> = [];
	var playerSpawnPoints:Array<MissionElementSpawnSphere> = [];
	var spawnPointTaken = [];

	var gemOctree:Octree;
	var gemGroupRadius:Float;
	var maxGemsPerGroup:Int;
	var activeGemSpawnGroup:Array<Int>;
	var activeGems:Array<Gem> = [];
	var gemBeams:Array<GemBeam> = [];
	var gemToBeamMap:Map<Gem, GemBeam> = [];
	var rng:RandomLCG = new RandomLCG(100);
	var rng2:RandomLCG = new RandomLCG(100);

	var points:Int = 0;

	override function missionScan(mission:Mission) {
		function scanMission(simGroup:MissionElementSimGroup) {
			for (element in simGroup.elements) {
				if ([MissionElementType.SpawnSphere].contains(element._type)) {
					var spawnSphere:MissionElementSpawnSphere = cast element;
					var dbname = spawnSphere.datablock.toLowerCase();
					if (dbname == "spawnspheremarker") {
						playerSpawnPoints.push(spawnSphere);
						spawnPointTaken.push(false);
					}
					if (dbname == "gemspawnspheremarker") {
						var sphere = new GemSpawnSphere(spawnSphere);
						sphere.netIndex = gemSpawnPoints.length;
						gemSpawnPoints.push(sphere);
						if (level.isMultiplayer) {
							@:privateAccess level.gemPredictions.alloc();
						}
					}
				} else if (element._type == MissionElementType.SimGroup) {
					scanMission(cast element);
				}
			}
		}
		scanMission(mission.root);
	};

	override function getSpawnTransform() {
		var idx = Math.floor(rng2.randRange(0, playerSpawnPoints.length - 1));
		while (spawnPointTaken[idx]) {
			idx = Math.floor(rng2.randRange(0, playerSpawnPoints.length - 1));
		}
		spawnPointTaken[idx] = true;
		var randomSpawn = playerSpawnPoints[idx];
		var spawnPos = MisParser.parseVector3(randomSpawn.position);
		spawnPos.x *= -1;
		var spawnRot = MisParser.parseRotation(randomSpawn.rotation);
		spawnRot.x *= -1;
		spawnRot.w *= -1;
		var spawnMat = spawnRot.toMatrix();
		var up = spawnMat.up();
		spawnPos = spawnPos.add(up.multiply(0.727843 / 3)); // 1.5 -> 0.5
		return {
			position: spawnPos,
			orientation: spawnRot,
			up: up
		}
	}

	override function getRespawnTransform() {
		var lastContactPos = this.level.marble.lastContactPosition;
		// Pick closest spawn point
		var closestSpawn:MissionElementSpawnSphere = null;
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
			spawnPos = spawnPos.add(up.multiply(0.727843 / 3)); // 1.5 -> 0.5

			return {
				position: spawnPos,
				orientation: spawnRot,
				up: up
			}
		}
		return null;
	}

	override function onRespawn(marble:Marble) {
		if (activeGemSpawnGroup.length != 0) {
			var gemAvg = new Vector();
			for (gi in activeGemSpawnGroup) {
				var g = gemSpawnPoints[gi];
				gemAvg = gemAvg.add(g.position);
			}
			gemAvg.scale(1 / activeGemSpawnGroup.length);
			var delta = gemAvg.sub(marble.getAbsPos().getPosition());
			var gravFrame = level.getOrientationQuat(0).toMatrix();
			var v1 = gravFrame.front();
			var v2 = gravFrame.right();
			var deltaRot = new Vector(delta.dot(v2), delta.dot(v1));
			if (deltaRot.length() >= 0.001) {
				var ang = Math.atan2(deltaRot.x, deltaRot.y);
				marble.camera.CameraYaw = ang;
				marble.camera.nextCameraYaw = ang;
			}
		}
	}

	override public function getStartTime() {
		return level.mission.qualifyTime;
	}

	override public function timeMultiplier() {
		return -1;
	}

	override function onRestart() {
		if (!this.level.isMultiplayer || Net.isHost) {
			rng.setSeed(100);
			rng2.setSeed(100);
			if (Settings.optionsSettings.huntRandom || Net.isMP) {
				rng.setSeed(cast Math.random() * 10000);
				rng2.setSeed(cast Math.random() * 10000);
			}
			setupGems();
		}
		points = 0;
		@:privateAccess level.playGui.formatGemHuntCounter(points);
	}

	override function onClientRestart() {
		for (gi in 0...gemSpawnPoints.length) {
			var gemSpawn = gemSpawnPoints[gi];
			var vec = gemSpawn.position;
			if (gemSpawn.gem != null) {
				gemSpawn.gem.setHide(true);
				gemSpawn.gem.pickedUp = true;
				gemSpawn.gemBeam.setHide(true);
			}
		}
	}

	override function onGemPickup(marble:Marble, gem:Gem) {
		if (@:privateAccess !marble.isNetUpdate) {
			if (marble == level.marble)
				AudioManager.playSound(ResourceLoader.getResource('data/sound/gem_collect.wav', ResourceLoader.getAudio,
					@:privateAccess this.level.soundResources));
			else
				AudioManager.playSound(ResourceLoader.getResource('data/sound/opponent_gem_collect.wav', ResourceLoader.getAudio,
					@:privateAccess this.level.soundResources));
		}
		activeGems.remove(gem);
		var beam = gemToBeamMap.get(gem);
		beam.setHide(true);

		if (!this.level.isMultiplayer || Net.isHost) {
			refillGemGroups();
		}

		var incr = 0;
		switch (gem.gemColor) {
			case "red.gem":
				incr = 1;
			case "yellow.gem":
				incr = 2;
			case "blue.gem":
				incr = 5;
		}

		if (@:privateAccess !marble.isNetUpdate) {
			if (marble == level.marble) {
				switch (gem.gemColor) {
					case "red.gem":
						points += 1;
						@:privateAccess level.playGui.addMiddleMessage('+1', 0xFF6666);
					case "yellow.gem":
						points += 2;
						@:privateAccess level.playGui.addMiddleMessage('+2', 0xFFFF66);
					case "blue.gem":
						points += 5;
						@:privateAccess level.playGui.addMiddleMessage('+5', 0x6666FF);
				}
				@:privateAccess level.playGui.formatGemHuntCounter(points);
			}
		}

		if (this.level.isMultiplayer && Net.isHost) {
			var packet = new GemPickupPacket();
			packet.clientId = @:privateAccess marble.connection == null ? 0 : @:privateAccess marble.connection.id;
			packet.gemId = gem.netIndex;
			packet.serverTicks = level.timeState.ticks;
			packet.scoreIncr = incr;
			var os = new OutputBitStream();
			os.writeByte(GemPickup);
			packet.serialize(os);
			Net.sendPacketToAll(os);

			@:privateAccess level.playGui.incrementPlayerScore(packet.clientId, packet.scoreIncr);
		}
	}

	function setupGems() {
		gemGroupRadius = 20.0;
		maxGemsPerGroup = 4;
		if (level.mission.missionInfo.gemgroupradius != null && level.mission.missionInfo.gemgroupradius != "")
			gemGroupRadius = Std.parseFloat(level.mission.missionInfo.gemgroupradius);
		if (level.mission.missionInfo.maxgemspergroup != null && level.mission.missionInfo.maxgemspergroup != "")
			maxGemsPerGroup = Std.parseInt(level.mission.missionInfo.maxgemspergroup);

		gemOctree = new Octree();
		for (gi in 0...gemSpawnPoints.length) {
			var gemSpawn = gemSpawnPoints[gi];
			var vec = gemSpawn.position;
			gemOctree.insert(new GemOctreeElem(vec, gemSpawn, gi));
			if (gemSpawn.gem != null) {
				gemSpawn.gem.setHide(true);
				gemSpawn.gem.pickedUp = true;
				gemSpawn.gemBeam.setHide(true);
			}
		}

		if (activeGemSpawnGroup != null) {
			for (gemSpawnIndex in activeGemSpawnGroup) {
				var gemSpawn = gemSpawnPoints[gemSpawnIndex];
				if (gemSpawn.gem != null) {
					gemSpawn.gem.pickedUp = true;
					gemSpawn.gem.setHide(true);
					gemSpawn.gemBeam.setHide(true);
				}
			}
		}
		activeGemSpawnGroup = [];

		activeGems = [];
		refillGemGroups();

		var gemAvg = new Vector();
		for (gi in activeGemSpawnGroup) {
			var g = gemSpawnPoints[gi];
			gemAvg = gemAvg.add(g.position);
		}
		gemAvg.scale(1 / activeGemSpawnGroup.length);
		var delta = gemAvg.sub(level.marble.getAbsPos().getPosition());
		var gravFrame = level.getOrientationQuat(0).toMatrix();
		var v1 = gravFrame.front();
		var v2 = gravFrame.right();
		var deltaRot = new Vector(delta.dot(v2), delta.dot(v1));
		if (deltaRot.length() >= 0.001) {
			var ang = Math.atan2(deltaRot.x, deltaRot.y);
			level.marble.camera.CameraYaw = ang;
			level.marble.camera.nextCameraYaw = ang;
		}
	}

	function refillGemGroups() {
		if (activeGems.length == 0) {
			var spawnGroup = pickGemSpawnGroup();
			activeGemSpawnGroup = spawnGroup;
			fillGemGroup(spawnGroup);
			@:privateAccess level.radar.blink();

			if (level.isMultiplayer && Net.isHost) {
				var bs = new OutputBitStream();
				bs.writeByte(GemSpawn);
				var packet = new GemSpawnPacket();
				packet.gemIds = spawnGroup;
				packet.serialize(bs);
				Net.sendPacketToAll(bs);
			}
		}
	}

	function fillGemGroup(group:Array<Int>) {
		for (gi in group) {
			var gemSpawn = gemSpawnPoints[gi];
			if (gemSpawn.gem != null) {
				gemSpawn.gem.pickedUp = false;
				gemSpawn.gem.setHide(false);
				gemSpawn.gemBeam.setHide(false);
				this.activeGems.push(gemSpawn.gem);
			} else {
				var melem = new MissionElementItem();
				melem.datablock = "GemItem" + gemSpawn.gemColor;
				var gem = new Gem(melem);
				gem.netIndex = gi;
				gemSpawn.gem = gem;
				gem.setPosition(gemSpawn.position.x, gemSpawn.position.y, gemSpawn.position.z);
				gem.setRotationQuat(gemSpawn.rotation);
				this.activeGems.push(gem);

				var gemBeam = new GemBeam();
				gemBeam.setPosition(gemSpawn.position.x, gemSpawn.position.y, gemSpawn.position.z);
				gemBeam.setRotationQuat(gemSpawn.rotation);
				this.gemBeams.push(gemBeam);

				gemSpawn.gemBeam = gemBeam;
				this.gemToBeamMap.set(gem, gemBeam);

				level.addDtsObject(gemBeam, () -> {
					level.addDtsObject(gem, () -> {
						level.gems.push(gem);
					}); // Please be fast lol
				});
			}
		}
	}

	public function setActiveSpawnSphere(spawnGroup:Array<Int>) {
		Console.log("Got new gem spawn from server!");
		if (activeGemSpawnGroup != null) {
			for (agem in activeGemSpawnGroup) {
				var gemSpawn = gemSpawnPoints[agem];
				if (gemSpawn.gem != null) {
					gemSpawn.gem.pickedUp = true;
					gemSpawn.gem.setHide(true);
					gemSpawn.gemBeam.setHide(true);
					activeGems.remove(gemSpawn.gem);
				}
			}
		}
		for (sphereId in spawnGroup) {
			Console.log('Spawning gem id ${sphereId}');
			var gemSpawn = gemSpawnPoints[sphereId];
			if (gemSpawn.gem != null) {
				gemSpawn.gem.pickedUp = false;
				gemSpawn.gem.setHide(false);
				gemSpawn.gemBeam.setHide(false);
				this.activeGems.push(gemSpawn.gem);
			} else {
				var melem = new MissionElementItem();
				melem.datablock = "GemItem" + gemSpawn.gemColor;
				var gem = new Gem(melem);
				gem.netIndex = sphereId;
				gemSpawn.gem = gem;
				gem.setPosition(gemSpawn.position.x, gemSpawn.position.y, gemSpawn.position.z);
				gem.setRotationQuat(gemSpawn.rotation);
				this.activeGems.push(gem);

				var gemBeam = new GemBeam();
				gemBeam.setPosition(gemSpawn.position.x, gemSpawn.position.y, gemSpawn.position.z);
				gemBeam.setRotationQuat(gemSpawn.rotation);
				this.gemBeams.push(gemBeam);

				gemSpawn.gemBeam = gemBeam;
				this.gemToBeamMap.set(gem, gemBeam);

				level.addDtsObject(gemBeam, () -> {
					level.addDtsObject(gem, () -> {
						level.gems.push(gem);
					}); // Please be fast lol
				});
			}
		}
		activeGemSpawnGroup = spawnGroup;
	}

	public inline function setGemHiddenStatus(gemId:Int, status:Bool) {
		var gemSpawn = gemSpawnPoints[gemId];
		if (gemSpawn.gem != null) {
			gemSpawn.gem.pickedUp = status;
			gemSpawn.gem.setHide(status);
			gemSpawn.gemBeam.setHide(status);
			if (status)
				this.activeGems.push(gemSpawn.gem);
			else
				this.activeGems.remove(gemSpawn.gem);
		} else {
			throw new Exception("Setting gem status for non existent gem!");
		}
	}

	function pickGemSpawnGroup() {
		var searchRadius = gemGroupRadius * 2;

		for (i in 0...6) {
			var groupMainPt = new Vector();
			var group = findGemSpawnGroup(groupMainPt);
			if (group.length == 0) {
				Console.log("Gem spawn group has no spawn points!");
				continue;
			}

			var ok = true;
			if (activeGemSpawnGroup != null) {
				for (gi in activeGemSpawnGroup) {
					var gemSpawn = gemSpawnPoints[gi];
					if (gemSpawn.position.distance(groupMainPt) < searchRadius) {
						ok = false;
						break;
					}
				}
			}
			if (!ok)
				continue;
			return group;
		}
		Console.log("Unable to find spawn group that works with active gem groups, using random!");
		var groupMainPt = new Vector();
		return findGemSpawnGroup(groupMainPt);
	}

	function findGemSpawnGroup(outSpawnPoint:Vector) {
		// Pick random spawn point
		var rnd:Int = Std.int(rng.randRange(0, gemSpawnPoints.length - 1));
		if (level.isRecording)
			level.replay.recordRandomGenState(rnd);
		if (level.isWatching)
			rnd = level.replay.getRandomGenState();
		var spawnPoint = gemSpawnPoints[rnd];
		var pos = spawnPoint.position;

		var results = [];
		var search = gemOctree.radiusSearch(pos, gemGroupRadius);
		for (elem in search) {
			var gemElem:GemOctreeElem = cast elem;
			results.push(gemElem.spawnIndex);
			if (results.length >= maxGemsPerGroup)
				break;
		}
		outSpawnPoint.load(pos);
		return results;
	}

	override function getPreloadFiles():Array<String> {
		return [
			'data/shapes/items/yellow.gem.png',
			"data/skies/gemCubemapUp2.png",
			'data/shapes/items/blue.gem.png',
			"data/skies/gemCubemapUp3.png",
			'data/shapes/items/red.gem.png',
			"data/skies/gemCubemapUp.png",
			'sound/gem_collect.wav',
			'sound/opponent_gem_collect.wav'
		];
	}

	override function getScoreType():ScoreType {
		return Score;
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
				if (Net.isHost) {
					for (marble in level.marbles) {
						marble.setMode(Start);
						level.cancel(@:privateAccess marble.oobSchedule);
					}

					NetCommands.timerRanOut();
				}
				if (!level.isWatching) {
					@:privateAccess level.schedule(level.timeState.currentAttemptTime, () -> cast level.showFinishScreen());
				}
			} else {
				var myScore = {
					name: "Player",
					time: getFinishScore()
				};
				Settings.saveScore(level.mission.path, myScore, getScoreType());
				var notifies = AchievementsGui.check();
				var delay = 5.0;
				var achDelay = 0.0;
				for (i in 0...9) {
					if (notifies & (1 << i) > 0)
						achDelay += 3;
				}
				if (notifies > 0)
					achDelay += 0.5;
				@:privateAccess level.schedule(level.timeState.currentAttemptTime + Math.max(delay, achDelay), () -> cast level.showFinishScreen());
			}
		}
		// Stop the ongoing sounds
		if (@:privateAccess level.timeTravelSound != null) {
			@:privateAccess level.timeTravelSound.stop();
			@:privateAccess level.timeTravelSound = null;
		}
	}

	public function doTimerRunOut() {
		AudioManager.playSound(ResourceLoader.getResource('data/sound/finish.wav', ResourceLoader.getAudio, @:privateAccess level.soundResources));
		level.finishTime = level.timeState.clone();
		level.marble.setMode(Start);
		level.marble.camera.finish = true;
		level.finishYaw = level.marble.camera.CameraYaw;
		level.finishPitch = level.marble.camera.CameraPitch;
		level.displayAlert("Congratulations! You've finished!");
		if (!level.isWatching) {
			@:privateAccess level.schedule(level.timeState.currentAttemptTime, () -> cast level.showFinishScreen());
		}
		// Stop the ongoing sounds
		if (@:privateAccess level.timeTravelSound != null) {
			@:privateAccess level.timeTravelSound.stop();
			@:privateAccess level.timeTravelSound = null;
		}
	}

	override function getFinishScore():Float {
		return points;
	}

	override function getRewindState():RewindableState {
		var s = new HuntState();
		s.points = points;
		s.activeGemSpawnGroup = activeGemSpawnGroup;
		s.activeGems = activeGems.copy();
		s.rngState = @:privateAccess rng.seed;
		s.rngState2 = @:privateAccess rng2.seed;
		return s;
	}

	override function applyRewindState(state:RewindableState) {
		var s:HuntState = cast state;
		points = s.points;
		@:privateAccess level.playGui.formatGemHuntCounter(points);
		for (gem in activeGems) {
			gem.pickedUp = true;
			gem.setHide(true);
			var gemBeam = gemToBeamMap.get(gem);
			gemBeam.setHide(true);
		}
		activeGemSpawnGroup = s.activeGemSpawnGroup;
		activeGems = s.activeGems;
		for (gem in activeGems) {
			gem.pickedUp = false;
			gem.setHide(false);
			var gemBeam = gemToBeamMap.get(gem);
			gemBeam.setHide(false);
		}
		if (!Settings.optionsSettings.huntRandom) {
			rng.setSeed(s.rngState);
			rng2.setSeed(s.rngState2);
		}
	}

	override function constructRewindState():RewindableState {
		return new HuntState();
	};
}
