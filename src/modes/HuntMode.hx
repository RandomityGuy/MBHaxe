package modes;

import modes.GameMode.ScoreType;
import shapes.StartPad;
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
import mis.MissionElement.MissionElementItem;
import octree.Octree;
import mis.MissionElement.MissionElementTrigger;
import mis.MissionElement.MissionElementType;
import src.Mission;
import src.Marble;
import src.AudioManager;
import src.ResourceLoader;
import net.Net;
import src.MarbleGame;
import src.Util;
import src.Settings;
import rewind.RewindableState;
import rewind.RewindManager;

@:publicFields
class HuntState implements RewindableState {
	var activeGemSpawnGroup:Array<Int>;
	var activeGems:Array<Gem>;
	var points:Int;
	var rngState:Int;
	var rngState2:Int;
	var groupSpawnCounts:Array<Int>;
	var lastSpawnGem:Gem;
	var gemWeights:Array<Float>;

	public function new() {}

	public function clone():RewindableState {
		var c = new HuntState();
		c.activeGemSpawnGroup = activeGemSpawnGroup.copy();
		c.activeGems = activeGems.copy();
		c.points = points;
		c.rngState = rngState;
		c.rngState2 = rngState2;
		c.groupSpawnCounts = groupSpawnCounts.copy();
		c.lastSpawnGem = lastSpawnGem;
		c.gemWeights = gemWeights.copy();
		return c;
	}

	public function getSize():Int {
		var size = 2; // points
		size += 2 + activeGemSpawnGroup.length * 2;
		size += 2 + activeGems.length * 2;
		size += 4; // rngState
		size += 4; // rngState2
		size += 2 + groupSpawnCounts.length * 2;
		size += 4; // lastSpawnGem
		size += 2 + gemWeights.length * 4;
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
		bw.writeUInt16(groupSpawnCounts.length);
		for (elem in groupSpawnCounts) {
			bw.writeUInt16(elem);
		}
		bw.writeInt32(rm.allocGO(lastSpawnGem));
		bw.writeUInt16(gemWeights.length);
		for (w in gemWeights) {
			bw.writeFloat(w);
		}
	}

	public function deserialize(rm:RewindManager, br:haxe.io.BytesInput) {
		points = br.readUInt16();
		activeGemSpawnGroup = [];
		var len = br.readUInt16();
		for (i in 0...len) {
			activeGemSpawnGroup.push(br.readUInt16());
		}
		activeGems = [];
		var len2 = br.readUInt16();
		for (i in 0...len2) {
			var uid = br.readUInt16();
			activeGems.push(cast rm.getGO(uid));
		}
		rngState = br.readInt32();
		rngState2 = br.readInt32();
		groupSpawnCounts = [];
		var len3 = br.readUInt16();
		for (i in 0...len3) {
			groupSpawnCounts.push(br.readUInt16());
		}
		lastSpawnGem = cast rm.getGO(br.readInt32());
		gemWeights = [];
		var len4 = br.readUInt16();
		for (i in 0...len4) {
			gemWeights.push(br.readFloat());
		}
	}
}

@:structInit
@:publicFields
class GemSpawnPoint implements IOctreeObject {
	var gem:Gem;
	var gemBeam:GemBeam;
	var weight:Float;

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
		this.weight = 0.0;
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

@:structInit
@:publicFields
class GemSpawnCandidate {
	var gem:Int;
	var weight:Float;
}

@:publicFields
class HuntGemGroup {
	var gemIndices:Array<Int>;
	var spawnCount:Int;

	public function new(gemIndices:Array<Int>) {
		this.gemIndices = gemIndices;
		this.spawnCount = 0;
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
	// Mission-authored gem groups (MissionInfo.gemGroups): each element is the list of
	// MissionElementItem gems found nested inside one child of the mission's "GemGroups"
	// SimGroup. Correlated to runtime GemSpawnPoints in prepareGems().
	var huntGemGroupElements:Array<Array<MissionElementItem>> = [];
	var huntGemGroups:Array<HuntGemGroup> = [];
	var huntGemGroupsMode:Int = 0;
	var isFirstGemSpawn:Bool = false;
	var gemBeams:Array<GemBeam> = [];
	var gemToBeamMap:Map<Gem, GemBeam> = [];
	var gemToBlackBeamMap:Map<Gem, GemBeam> = [];
	var activeGems:Array<Gem> = [];
	var points:Int = 0;
	var gemsCentroid:Vector;
	var idealSpawnIndex:Int;
	var expiredGems:Map<Gem, Bool> = [];
	var competitiveTimerStartTicks:Int;

	function collectGemElements(group:MissionElementSimGroup, out:Array<MissionElementItem>) {
		for (element in group.elements) {
			if (element._type == MissionElementType.Item) {
				var item:MissionElementItem = cast element;
				var db = item.datablock.toLowerCase();
				if (StringTools.startsWith(db, "gemitem") || StringTools.startsWith(db, "fancygemitem"))
					out.push(item);
			} else if (element._type == MissionElementType.SimGroup) {
				collectGemElements(cast element, out);
			}
		}
	}

	override function missionScan(mission:Mission) {
		function scanMission(simGroup:MissionElementSimGroup) {
			var elToRemove = [];
			for (element in simGroup.elements) {
				if ([MissionElementType.Trigger].contains(element._type)) {
					var spawnSphere:MissionElementTrigger = cast element;
					var dbname = spawnSphere.datablock.toLowerCase();
					if (dbname == "spawntrigger") {
						playerSpawnPoints.push(spawnSphere);
						spawnPointTaken.push(false);
					}
				} else if (element._type == MissionElementType.SimGroup) {
					var scanPls = true;
					if (element._name.toLowerCase() == "gemgroups") {
						var gemGroupsGroup:MissionElementSimGroup = cast element;
						for (child in gemGroupsGroup.elements) {
							if (child._type == MissionElementType.SimGroup) {
								var groupElements:Array<MissionElementItem> = [];
								collectGemElements(cast child, groupElements);
								if (groupElements.length > 0)
									huntGemGroupElements.push(groupElements);
							}
						}
					}
					if (Net.isMP && Net.connectedServerInfo.oldSpawns) {
						if (element._name.toLowerCase() == "newversion") {
							// Remove this
							elToRemove.push(element);
							scanPls = false;
						}
					} else {
						if (element._name.toLowerCase() == "oldversion") {
							// Remove this
							elToRemove.push(element);
							scanPls = false;
						}
					}
					if (scanPls)
						scanMission(cast element);
				}
			}
			while (elToRemove.length > 0) {
				simGroup.elements.remove(elToRemove.pop());
			}
		}
		scanMission(mission.root);
	};

	override function getSpawnTransform() {
		var idx = (Net.isMP && Net.connectedServerInfo.competitiveMode) ? idealSpawnIndex : nextRandomInt(rng2, 0, playerSpawnPoints.length - 1);
		if (!(Net.isMP && Net.connectedServerInfo.competitiveMode)) {
			var allTaken = true;
			for (spw in spawnPointTaken) {
				if (!spw) {
					allTaken = false;
					break;
				}
			}
			if (!allTaken) {
				while (spawnPointTaken[idx]) {
					idx = nextRandomInt(rng2, 0, playerSpawnPoints.length - 1);
				}
				spawnPointTaken[idx] = true;
			}
		}

		if (playerSpawnPoints.length == 0) {
			// The player is spawned at the last start pad in the mission file.
			var startPad = this.level.dtsObjects.filter(x -> x is StartPad).pop();
			var position:Vector;
			var quat:Quat = new Quat();
			if (startPad != null) {
				// If there's a start pad, start there
				position = startPad.getAbsPos().getPosition();
				quat = startPad.getRotationQuat().clone();
				position.z += 3;
			} else {
				position = new Vector(0, 0, 300);
			}
			return {
				position: position,
				orientation: quat,
				up: new Vector(0, 0, 1)
			};
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
		if (playerSpawnPoints.length == 0) {
			// The player is spawned at the last start pad in the mission file.
			var startPad = this.level.dtsObjects.filter(x -> x is StartPad).pop();
			var position:Vector;
			var quat:Quat = new Quat();
			if (startPad != null) {
				// If there's a start pad, start there
				position = startPad.getAbsPos().getPosition();
				quat = startPad.getRotationQuat().clone();
				position.z += 3;
			} else {
				position = new Vector(0, 0, 300);
			}
			return {
				position: position,
				orientation: quat,
				up: new Vector(0, 0, 1)
			};
		}

		var lastContactPos = marble.lastContactPosition;
		if (lastContactPos == null) {
			var idx = nextRandomInt(rng2, 0, playerSpawnPoints.length - 1);
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

			huntGemGroupsMode = (level.mission.missionInfo.gemgroups != null
				&& level.mission.missionInfo.gemgroups != "") ? Std.parseInt(level.mission.missionInfo.gemgroups) : 0;
			huntGemGroups = [];
			for (elements in huntGemGroupElements) {
				var indices = [];
				for (gsp in gemSpawnPoints) {
					if (elements.indexOf(gsp.gem.element) != -1)
						indices.push(gsp.netIndex);
				}
				if (indices.length > 0)
					huntGemGroups.push(new HuntGemGroup(indices));
			}
		}
		for (i in 0...spawnPointTaken.length) {
			spawnPointTaken[i] = false;
		}
	}

	override function getPreloadFiles() {
		var files = [
			'data/sound/opponentdiamond.wav',
			'data/shapes/items/blue.gem.png',
			'data/shapes/items/red.gem.png',
			'data/shapes/items/yellow.gem.png',
			'data/shapes/items/platinum.gem.png'
		];
		for (key in AudioManager.pitchKeys) {
			files.push('data/sound/firewrks/$key.wav');
			files.push('data/sound/gotdiamond/$key.wav');
		}
		files.push('data/sound/gotdiamond/a_flat_5.wav');
		files.push('data/sound/gotdiamond/f_5.wav');
		return files;
	}

	inline function nextRandomInt(rng:RandomLCG, lo:Int, hi:Int):Int {
		if (this.level.isWatching)
			return this.level.replay.getRandomGenState();
		var v = Std.int(rng.randRange(lo, hi));
		if (this.level.isRecording && !this.level.rewinding)
			this.level.replay.recordRandomGenState(v);
		return v;
	}

	inline function nextRandomFloat():Float {
		if (this.level.isWatching)
			return this.level.replay.getRandomFloatState();
		var v = Math.random();
		if (this.level.isRecording && !this.level.rewinding)
			this.level.replay.recordRandomFloatState(v);
		return v;
	}

	function setupGems() {
		hideExisting();
		this.activeGems = [];
		this.activeGemSpawnGroup = [];
		this.rng.setSeed(cast Math.random() * 10000);
		this.rng2.setSeed(cast Math.random() * 10000);
		prepareGems();
		isFirstGemSpawn = true;
		spawnHuntGems();
		isFirstGemSpawn = false;
	}

	function testSpawn(gem:Gem):Bool {
		if (level.mission.missionInfo.game.toLowerCase() == "platinumquest") {
			if (Net.isMP && Net.connectedServerInfo.oldSpawns) {
				// Spawn chances!
				var chance = switch (gem.gemColor.toLowerCase()) {
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
				var choice = nextRandomFloat();
				if (choice > chance)
					return false;
			} else {
				// Spawn chances!
				var chance = switch (gem.gemColor.toLowerCase()) {
					case "red.gem":
						level.mission.missionInfo.redspawnchance != null ? Std.parseFloat(level.mission.missionInfo.redspawnchance) : 0.9;
					case "yellow.gem":
						level.mission.missionInfo.yellowspawnchance != null ? Std.parseFloat(level.mission.missionInfo.yellowspawnchance) : 0.65;
					case "blue.gem":
						level.mission.missionInfo.bluespawnchance != null ? Std.parseFloat(level.mission.missionInfo.bluespawnchance) : 0.35;
					case "platinum.gem":
						level.mission.missionInfo.platinumspawnchance != null ? Std.parseFloat(level.mission.missionInfo.platinumspawnchance) : 0.18;
					default:
						1.0;
				};
				var choice = nextRandomFloat();
				if (choice > chance)
					return false;
			}
		}
		return true;
	}

	function commitSpawnSet(spawnSet:Array<Int>, force:Bool) {
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
	}

	// Spawns every gem in a mission-authored gem group unconditionally (no radius search,
	// no spawn-chance rolls) - MissionInfo.gemGroups mode 1.
	function spawnEntireGemGroup(group:HuntGemGroup, force:Bool) {
		var spawnSet = group.gemIndices.copy();
		for (gem in spawnSet)
			spawnGem(gem);
		commitSpawnSet(spawnSet, force);
	}

	// Finds which gem group (if any) the given gem net index belongs to.
	function findGemGroup(netIndex:Int):HuntGemGroup {
		for (group in huntGemGroups) {
			if (group.gemIndices.indexOf(netIndex) != -1)
				return group;
		}
		return null;
	}

	// MissionInfo.gemGroups is set: gems are only ever spawned from within a single
	// mission-authored group at a time, either wholesale (mode 1) or via a radius search
	// scoped to that group's gems (mode 2). Which group spawns is either the group
	// containing the single highest-value gem (on the very first spawn of the mission) or
	// a random group weighted towards ones that have been spawned less recently.
	function spawnHuntGemGroupsMode(force:Bool) {
		var group:HuntGemGroup;

		if (isFirstGemSpawn) {
			var highest = 0;
			for (g in huntGemGroups)
				for (idx in g.gemIndices) {
					var w = getGemWeight(gemSpawnPoints[idx].gem);
					if (w > highest)
						highest = w;
				}
			var validCenters:Array<GemSpawnPoint> = [];
			for (g in huntGemGroups)
				for (idx in g.gemIndices)
					if (getGemWeight(gemSpawnPoints[idx].gem) == highest)
						validCenters.push(gemSpawnPoints[idx]);

			var center = validCenters[nextRandomInt(rng, 0, validCenters.length - 1)];
			group = findGemGroup(center.netIndex);
		} else if (huntGemGroups.length == 1) {
			group = huntGemGroups[0];
		} else {
			var maxSpawnCount = 0;
			for (g in huntGemGroups)
				if (g.spawnCount > maxSpawnCount)
					maxSpawnCount = g.spawnCount;
			// Weight towards groups that have been spawned less recently: a group gets
			// (maxSpawnCount - spawnCount + 2) entries in the weighted pool.
			var weighted:Array<HuntGemGroup> = [];
			for (g in huntGemGroups) {
				var repeats = maxSpawnCount - g.spawnCount + 2;
				for (i in 0...repeats)
					weighted.push(g);
			}
			group = weighted[nextRandomInt(rng, 0, weighted.length - 1)];
		}

		group.spawnCount++;

		if (huntGemGroupsMode == 2) {
			spawnHuntGemsFromPool([for (idx in group.gemIndices) gemSpawnPoints[idx]], force);
		} else {
			spawnEntireGemGroup(group, force);
		}
	}

	function spawnHuntGems(force:Bool = false) {
		if (activeGems.length != 0 && !force)
			return;

		if (huntGemGroupsMode > 0 && huntGemGroups.length > 0) {
			spawnHuntGemGroupsMode(force);
			return;
		}

		spawnHuntGemsFromPool(gemSpawnPoints, force);
	}

	function spawnHuntGemsFromPool(pool:Array<GemSpawnPoint>, force:Bool = false) {
		var gemGroupRadius = 15.0;
		var maxGemsPerSpawn = 7;
		if (level.mission.missionInfo.maxgemsperspawn != null && level.mission.missionInfo.maxgemsperspawn != "")
			maxGemsPerSpawn = Std.parseInt(level.mission.missionInfo.maxgemsperspawn);
		if (level.mission.missionInfo.radiusfromgem != null && level.mission.missionInfo.radiusfromgem != "")
			gemGroupRadius = Std.parseFloat(level.mission.missionInfo.radiusfromgem);
		var spawnBlock = gemGroupRadius * 2;
		if (level.mission.missionInfo.spawnblock != null && level.mission.missionInfo.spawnblock != "")
			spawnBlock = Std.parseFloat(level.mission.missionInfo.spawnblock);

		var minPointsPerSpawn = 5;
		if (level.mission.missionInfo.minpointsperspawn != null && level.mission.missionInfo.minpointsperspawn != "")
			minPointsPerSpawn = Std.parseInt(level.mission.missionInfo.minpointsperspawn);
		var minGemsPerSpawn = 3;
		if (level.mission.missionInfo.mingemsperspawn != null && level.mission.missionInfo.mingemsperspawn != "")
			minGemsPerSpawn = Std.parseInt(level.mission.missionInfo.mingemsperspawn);
		var maxSpawnSearchLoops = 15;
		var maxPoints = 9999.0;

		var lastPos = null;
		if (lastSpawn != null)
			lastPos = lastSpawn.gem.getAbsPos().getPosition();

		// On MP, instead of blocking around the last gem, block around the player
		// currently in the lead. This should create closer games and discourage
		// camping for gems.
		if (@:privateAccess level.playGui.playerList.length > 1) {
			var leadName = @:privateAccess level.playGui.playerList[0].name;
			var leadMarble = null;
			if (Settings.highscoreName == leadName) {
				leadMarble = level.marble;
			} else {
				for (marble in level.marbles) {
					if (@:privateAccess marble.connection != null && @:privateAccess marble.connection.name == leadName) {
						leadMarble = marble;
						break;
					}
				}
			}
			if (leadMarble != null)
				lastPos = leadMarble.getAbsPos().getPosition();

			var blockFactor = Util.clamp((((@:privateAccess level.playGui.playerList[0].score / Math.max(@:privateAccess
				level.playGui.playerList[@:privateAccess level.playGui.playerList.length - 1].score, 1.0)) - 1) * 2), 0, 3);

			spawnBlock *= blockFactor;
		}

		// Find every candidate that's far enough from lastPos (blockCenter), sampling
		// up to 10 random gems. Unlike a single "first hit wins" search, ALL valid
		// candidates found are collected so the center can be chosen randomly among them.
		var furthestDist = 0.0;
		var furthest:GemSpawnPoint = null;
		var validCenters:Array<GemSpawnPoint> = [];

		for (i in 0...10) {
			var gem = pool[nextRandomInt(rng, 0, pool.length - 1)];
			if (lastPos != null) {
				var dist = gem.gem.getAbsPos().getPosition().distance(lastPos) + gem.weight;
				if (dist < spawnBlock) {
					if (validCenters.length == 0 && dist > furthestDist) {
						furthestDist = dist - gem.weight;
						furthest = gem;
					}
				} else {
					validCenters.push(gem);
				}
			} else {
				validCenters.push(gem);
			}
		}
		if (furthest != null)
			validCenters.push(furthest);

		var validGem:GemSpawnPoint = null;
		if (validCenters.length > 0) {
			// Draw 5 times from validCenters and keep the last draw (there's only ever
			// a single spawn center, so the "furthest from previous centers" distance
			// PQ tracks is always 0, which means every draw overwrites the last).
			for (j in 0...5) {
				validGem = validCenters[nextRandomInt(rng, 0, validCenters.length - 1)];
			}
		}
		if (validGem == null) {
			validGem = pool[nextRandomInt(rng, 0, pool.length - 1)];
		}
		var pos = validGem.gem.getAbsPos().getPosition();

		// Gather every gem within range of the center as a spawn candidate (growing the
		// search radius until we have enough points/gems, or we've looped twice).
		var spawnables:Array<GemSpawnCandidate> = [];
		var spawnablesSet:Map<Int, Bool> = [];
		var gatherPoints = 1 + getGemWeight(validGem.gem);
		var gatherLoops = 0;
		var searchRadius = gemGroupRadius;
		while ((gatherPoints < minPointsPerSpawn || spawnables.length < minGemsPerSpawn) && gatherLoops < 2) {
			for (gemElem in pool) {
				if (gemElem == validGem)
					continue;
				if (spawnablesSet.exists(gemElem.netIndex))
					continue;
				var gemPos = gemElem.gem.getAbsPos().getPosition();
				var delta = gemPos.sub(pos);
				if (delta.length() < searchRadius) {
					spawnablesSet.set(gemElem.netIndex, true);
					var weight = searchRadius - delta.length() - Math.abs(delta.z) + nextRandomInt(rng, 0, getGemWeight(gemElem.gem) + 3);
					spawnables.push({gem: gemElem.netIndex, weight: weight});
					gatherPoints += getGemWeight(gemElem.gem) + 1;
				}
			}
			searchRadius *= 2;
			gatherLoops++;
		}
		spawnables.sort((a, b) -> {
			if (a.weight > b.weight)
				return -1;
			if (a.weight < b.weight)
				return 1;
			return 0;
		});

		// Gems already active from a previous cluster (only relevant on a forced re-roll)
		// are skipped rather than re-selected.
		var activeSet:Map<Int, Bool> = [];
		if (force)
			for (idx in activeGemSpawnGroup)
				activeSet.set(idx, true);

		// Select gems from the sorted candidates, re-rolling the spawn chance each retry
		// loop, until we have enough points/gems or we've looped too many times. Note
		// that selPoints/spawned are bumped every successful pass regardless of whether
		// the candidate was already selected on an earlier loop, matching PQ's behavior.
		// The center itself is excluded from the candidate pool above, so it's seeded
		// into the spawn set directly here
		var spawnSet:Array<Int> = [validGem.netIndex];
		var spawned = 1;
		var selPoints = 1 + getGemWeight(validGem.gem);
		var selLoops = 0;
		while ((selPoints < minPointsPerSpawn || spawned < minGemsPerSpawn) && selLoops < maxSpawnSearchLoops) {
			var count = Std.int(Math.min(spawnables.length, maxGemsPerSpawn - 1));
			for (i in 0...count) {
				var cand = spawnables[i];
				if (activeSet.exists(cand.gem))
					continue;
				if (!testSpawn(gemSpawnPoints[cand.gem].gem))
					continue;
				var value = 1 + getGemWeight(gemSpawnPoints[cand.gem].gem);
				if (selPoints + value > maxPoints)
					continue;
				if (spawnSet.indexOf(cand.gem) == -1)
					spawnSet.push(cand.gem);
				selPoints += value;
				spawned++;
			}
			selLoops++;
		}

		// Get the furthest gem
		var maxDist = 0.0;
		for (gem in spawnSet) {
			var dist = gemSpawnPoints[gem].gem.getAbsPos().getPosition().distance(pos);
			if (dist > maxDist)
				maxDist = dist;
		}

		// Apply spawn weights
		for (gem in spawnSet) {
			var dist = gemSpawnPoints[gem].gem.getAbsPos().getPosition().distance(pos);
			dist /= maxDist;
			dist = Math.floor((1 - dist) * 10);
			gemSpawnPoints[gem].weight += dist;
		}

		// Fix spawn weights so we don't get gems with 10000 spawn weight
		var min = 9999.0;
		for (gem in gemSpawnPoints) {
			if (gem.weight < min) {
				min = gem.weight;
			}
		}

		for (gem in gemSpawnPoints) {
			gem.weight -= min;
		}

		for (gem in spawnSet) {
			spawnGem(gem);
		}
		commitSpawnSet(spawnSet, force);

		lastSpawn = validGem;
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
		if (level.mission.qualifyTime == 0 || level.mission.qualifyTime == Math.POSITIVE_INFINITY)
			return 600.0; // 5 minutes default
		return level.mission.qualifyTime;
	}

	override function onRespawn(marble:Marble) {
		if (marble.controllable && activeGemSpawnGroup.length != 0) {
			var gemAvg = new Vector();
			for (gi in activeGemSpawnGroup) {
				var g = gemSpawnPoints[gi];
				gemAvg = gemAvg.add(g.boundingBox.getCenter().toVector());
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

	override function onRestart() {
		setupGems();
		points = 0;
		competitiveTimerStartTicks = 0;
		@:privateAccess level.playGui.formatGemHuntCounter(points);
		if (gemSpawnPoints != null)
			for (gem in gemSpawnPoints) {
				gem.weight = 0.0;
			}
	}

	override function onMissionLoad() {
		prepareGems();
		competitiveTimerStartTicks = 0;
	}

	override function onClientRestart() {
		prepareGems();
		competitiveTimerStartTicks = 0;
	}

	override function getFinishScore():{score:Float, type:ScoreType} {
		return {score: this.points, type: Score};
	}

	override function canFinish(marble:Marble):Bool {
		return true;
	}

	override function onTimeExpire() {
		if (level.finishTime != null)
			return;

		if (!level.isMultiplayer) {
			@:privateAccess level.touchFinish();
			return;
		}

		AudioManager.playPitchedSound("firewrks", @:privateAccess level.soundResources);
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

		if (@:privateAccess level.alarmSound != null) {
			@:privateAccess level.alarmSound.stop();
			@:privateAccess level.alarmSound = null;
		}

		level.schedule(level.timeState.currentAttemptTime + 2, () -> {
			if (Util.isTouchDevice()) {
				MarbleGame.instance.touchInput.setControlsEnabled(false);
			}
			#if js
			var pointercontainer = js.Browser.document.querySelector("#pointercontainer");
			pointercontainer.hidden = false;
			#end
			MarbleGame.canvas.pushDialog(new MPEndGameGui());
			level.setCursorLock(false);
			return 0;
		});
	}

	override function onGemPickup(marble:Marble, gem:Gem) {
		if ((@:privateAccess !marble.isNetUpdate && Net.isHost) || !Net.isMP) {
			if (marble == level.marble)
				AudioManager.playPitchedSound("gotDiamond", @:privateAccess this.level.soundResources);
			else
				AudioManager.playSound(ResourceLoader.getResource('data/sound/opponentdiamond.wav', ResourceLoader.getAudio,
					@:privateAccess this.level.soundResources));
		}
		activeGems.remove(gem);

		var wasExpiredGem = false;

		if (expiredGems.exists(gem)) {
			wasExpiredGem = true;
		}
		if (gemToBlackBeamMap.exists(gem)) {
			gemToBlackBeamMap.get(gem).setHide(true);
		}

		var beam = gemToBeamMap.get(gem);
		beam.setHide(true);

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
					spawnNextGemCluster();
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
		if (wasExpiredGem)
			expiredGems.remove(gem);
		if (this.level.isMultiplayer && Net.isClient) {
			gem.pickUpClient = @:privateAccess marble.connection == null ? Net.clientId : @:privateAccess marble.connection.id;
		}
		if (!this.level.isMultiplayer || Net.isHost) {
			spawnHuntGems();
		}

		return true;
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
		if (this.level.isMultiplayer && Net.connectedServerInfo.competitiveMode) {
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

	override function getRewindState():RewindableState {
		var s = new HuntState();
		s.points = points;
		s.activeGemSpawnGroup = activeGemSpawnGroup.copy();
		s.activeGems = activeGems.copy();
		s.rngState = @:privateAccess rng.seed;
		s.rngState2 = @:privateAccess rng2.seed;
		s.groupSpawnCounts = [for (g in huntGemGroups) g.spawnCount];
		s.lastSpawnGem = lastSpawn != null ? lastSpawn.gem : null;
		s.gemWeights = [for (g in gemSpawnPoints) g.weight];
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
			if (gemBeam != null)
				gemBeam.setHide(true);
		}
		activeGemSpawnGroup = s.activeGemSpawnGroup;
		activeGems = s.activeGems;
		for (gem in activeGems) {
			gem.pickedUp = false;
			gem.setHide(false);
			var gemBeam = gemToBeamMap.get(gem);
			if (gemBeam != null)
				gemBeam.setHide(false);
		}
		rng.setSeed(s.rngState);
		rng2.setSeed(s.rngState2);
		lastSpawn = s.lastSpawnGem != null ? gemSpawnPoints[s.lastSpawnGem.netIndex] : null;
		for (i in 0...gemSpawnPoints.length)
			gemSpawnPoints[i].weight = s.gemWeights[i];
		for (i in 0...huntGemGroups.length)
			huntGemGroups[i].spawnCount = s.groupSpawnCounts[i];
	}

	override function constructRewindState():RewindableState {
		return new HuntState();
	}
}
