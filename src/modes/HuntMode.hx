package modes;

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

@:publicFields
class GemSpawnSphere {
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

	var priority:Int;

	public function new(vec:Vector, spawn:GemSpawnSphere) {
		boundingBox = new Bounds();
		boundingBox.addPoint(vec.add(new Vector(-0.5, -0.5, -0.5)).toPoint());
		boundingBox.addPoint(vec.add(new Vector(0.5, 0.5, 0.5)).toPoint());
		this.spawn = spawn;
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

class HuntMode extends NullMode {
	var gemSpawnPoints:Array<GemSpawnSphere> = [];
	var playerSpawnPoints:Array<MissionElementSpawnSphere> = [];

	var gemOctree:Octree;
	var gemGroupRadius:Float;
	var maxGemsPerGroup:Int;
	var activeGemSpawnGroup:Array<GemSpawnSphere>;
	var activeGems:Array<Gem> = [];
	var gemBeams:Array<GemBeam> = [];
	var gemToBeamMap:Map<Gem, GemBeam> = [];

	var points:Int = 0;

	override function missionScan(mission:Mission) {
		function scanMission(simGroup:MissionElementSimGroup) {
			for (element in simGroup.elements) {
				if ([MissionElementType.SpawnSphere].contains(element._type)) {
					var spawnSphere:MissionElementSpawnSphere = cast element;
					var dbname = spawnSphere.datablock.toLowerCase();
					if (dbname == "spawnspheremarker")
						playerSpawnPoints.push(spawnSphere);
					if (dbname == "gemspawnspheremarker")
						gemSpawnPoints.push(new GemSpawnSphere(spawnSphere));
				} else if (element._type == MissionElementType.SimGroup) {
					scanMission(cast element);
				}
			}
		}
		scanMission(mission.root);
	};

	override function getSpawnTransform() {
		var randomSpawn = playerSpawnPoints[Math.floor(Math.random() * playerSpawnPoints.length)];
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

	override public function getStartTime() {
		return level.mission.qualifyTime;
	}

	override public function timeMultiplier() {
		return -1;
	}

	override function onRestart() {
		setupGems();
		points = 0;
		@:privateAccess level.playGui.formatGemHuntCounter(points);
	}

	override function onGemPickup(gem:Gem) {
		AudioManager.playSound(ResourceLoader.getResource('data/sound/gem_collect.wav', ResourceLoader.getAudio, @:privateAccess this.level.soundResources));
		activeGems.remove(gem);
		var beam = gemToBeamMap.get(gem);
		beam.setHide(true);
		refillGemGroups();

		switch (gem.gemColor) {
			case "red.gem":
				points += 1;
			case "yellow.gem":
				points += 2;
			case "blue.gem":
				points += 5;
		}
		@:privateAccess level.playGui.formatGemHuntCounter(points);
	}

	function setupGems() {
		gemGroupRadius = 20.0;
		maxGemsPerGroup = 4;
		if (level.mission.missionInfo.gemgroupradius != null && level.mission.missionInfo.gemgroupradius != "")
			gemGroupRadius = Std.parseFloat(level.mission.missionInfo.gemgroupradius);
		if (level.mission.missionInfo.maxgemspergroup != null && level.mission.missionInfo.maxgemspergroup != "")
			maxGemsPerGroup = Std.parseInt(level.mission.missionInfo.maxgemspergroup);

		gemOctree = new Octree();
		for (gemSpawn in gemSpawnPoints) {
			var vec = gemSpawn.position;
			gemOctree.insert(new GemOctreeElem(vec, gemSpawn));
		}

		if (activeGemSpawnGroup != null) {
			for (gemSpawn in activeGemSpawnGroup) {
				if (gemSpawn.gem != null) {
					gemSpawn.gem.pickedUp = true;
					gemSpawn.gem.setHide(true);
					gemSpawn.gemBeam.setHide(true);
				}
			}
		}

		activeGems = [];
		refillGemGroups();
	}

	function refillGemGroups() {
		if (activeGems.length == 0) {
			var spawnGroup = pickGemSpawnGroup();
			activeGemSpawnGroup = spawnGroup;
			fillGemGroup(spawnGroup);
			@:privateAccess level.radar.blink();
		}
	}

	function fillGemGroup(group:Array<GemSpawnSphere>) {
		for (gemSpawn in group) {
			if (gemSpawn.gem != null) {
				gemSpawn.gem.pickedUp = false;
				gemSpawn.gem.setHide(false);
				gemSpawn.gemBeam.setHide(false);
				this.activeGems.push(gemSpawn.gem);
			} else {
				var melem = new MissionElementItem();
				melem.datablock = "GemItem" + gemSpawn.gemColor;
				var gem = new Gem(melem);
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
				for (gemSpawn in activeGemSpawnGroup) {
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
		var spawnPoint = gemSpawnPoints[Math.floor(Math.random() * gemSpawnPoints.length)];
		var pos = spawnPoint.position;

		var results = [];
		var search = gemOctree.radiusSearch(pos, gemGroupRadius);
		for (elem in search) {
			var gemElem:GemOctreeElem = cast elem;
			results.push(gemElem.spawn);
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
			'sound/gem_collect.wav'
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
		level.displayAlert("Congratulations! You've finished!");
		if (!level.isWatching) {
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
		// Stop the ongoing sounds
		if (@:privateAccess level.timeTravelSound != null) {
			@:privateAccess level.timeTravelSound.stop();
			@:privateAccess level.timeTravelSound = null;
		}
	}

	override function getFinishScore():Float {
		return points;
	}
}
