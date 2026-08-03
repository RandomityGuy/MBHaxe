package shapes;

import src.ResourceLoader;
import mis.MissionElement.MissionElementItem;
import src.TimeState;
import mis.MisParser;
import src.MarbleWorld;

class TimeTravel extends PowerUp {
	var timeBonus:Float = 5;

	/** Ported from `RespawningTimeTravelItem_PQ`'s `maxRespawns`/`respawnTime` fields (e.g.
		`Dependency.mcs`: `maxRespawns = 7`, `respawnTime = 15000` - "appears a total of 8 times",
		one initial pickup plus 7 respawns). `-1` means unlimited (every non-"respawning" variant,
		and the "respawning" ones when the field is left blank). `respawnCount` is the number of
		times this item has *respawned* so far (not pickups - the initial appearance doesn't count),
		so it stops respawning once it exceeds `maxRespawns` rather than the pickup that produced the
		`maxRespawns`th respawn immediately un-spawning it. */
	var maxRespawns:Int = -1;

	var respawnCount:Int = 0;

	// `cooldownDuration` gets permanently overwritten to `1e8` once `maxRespawns` is exhausted (see
	// `pickUp`) - this is the value to restore it to on `reset()`.
	var initialCooldownDuration:Float;

	public function new(element:MissionElementItem, noRespawn:Bool = true) {
		super(element);
		var datablockLower = element.datablock.toLowerCase();
		var isPQ = StringTools.endsWith(datablockLower, "_pq");
		if (StringTools.contains(datablockLower, "sundial"))
			this.dtsPath = "data/shapes_pq/gameplay/powerups/sundial.dts";
		else if (isPQ && StringTools.contains(datablockLower, "timepenalty"))
			this.dtsPath = "data/shapes_pq/gameplay/powerups/timepenalty.dts";
		else if (isPQ)
			this.dtsPath = "data/shapes_pq/gameplay/powerups/timetravel.dts";
		else
			this.dtsPath = "data/shapes/items/timetravel.dts";
		this.isCollideable = false;
		this.isTSStatic = false;
		// Instancing batches by `identifier`, and the sundial/timepenalty/PQ/vanilla variants use
		// different meshes - keep the dtsPath in the identifier so they don't get batched together.
		this.identifier = "TimeTravel" + this.dtsPath;

		if (element.timebonus != null) {
			this.timeBonus = MisParser.parseNumber(element.timebonus) / 1000;
		}
		if (element.timepenalty != null) {
			this.timeBonus = -MisParser.parseNumber(element.timepenalty) / 1000;
		}

		this.pickUpName = '${this.timeBonus} second Time ${this.timeBonus >= 0 ? 'Travel' : 'Penalty'}';
		if (noRespawn)
			this.cooldownDuration = 1e8;

		var respawnTimeField = element.fields.get("respawntime");
		if (respawnTimeField != null && respawnTimeField[0] != "")
			this.cooldownDuration = MisParser.parseNumber(respawnTimeField[0]) / 1000;
		var maxRespawnsField = element.fields.get("maxrespawns");
		if (maxRespawnsField != null && maxRespawnsField[0] != "")
			this.maxRespawns = Std.parseInt(maxRespawnsField[0]);

		this.useInstancing = true;
		this.autoUse = true;
		this.radarIndex = 32;

		this.initialCooldownDuration = this.cooldownDuration;
	}

	public override function reset() {
		super.reset();
		this.respawnCount = 0;
	}

	public override function init(level:MarbleWorld, onFinish:Void->Void) {
		super.init(level, () -> {
			ResourceLoader.load("sound/putimetravelvoice.wav").entry.load(() -> {
				this.pickupSound = ResourceLoader.getResource("data/sound/putimetravelvoice.wav", ResourceLoader.getAudio, this.soundResources);
				ResourceLoader.load("sound/timetravelactive.wav").entry.load(onFinish);
			});
		});
	}

	/** Re-derived every frame (rather than mutated once in `pickUp` and left that way) purely so
		that restoring `respawnCount` alone - whether via `reset()` or a live rewind snapshot of this
		object - is enough to put `cooldownDuration` back in the right state too, the same
		"recompute from restored state" pattern `FadePlatform` uses for its own cycling. */
	public override function update(timeState:TimeState) {
		super.update(timeState);
		this.cooldownDuration = (this.maxRespawns >= 0 && this.respawnCount >= this.maxRespawns) ? 1e8 : this.initialCooldownDuration;
	}

	public function pickUp(marble:src.Marble):Bool {
		// `lastPickUpTime` still holds the *previous* pickup's time here (see `PowerUp.
		// onMarbleInside`, which calls `pickUp` before updating it) - `-1` means this is the item's
		// first-ever appearance, which doesn't count against `maxRespawns`.
		if (this.maxRespawns >= 0 && this.lastPickUpTime != -1)
			this.respawnCount++;
		return true;
	}

	public function use(marble:src.Marble, time:TimeState) {
		if (!this.level.rewinding)
			level.addBonusTime(this.timeBonus);
		if (this.level.mission.activatedPackages.contains("dependency")) {
			@:privateAccess this.level.startCountdown(this.level.bonusTime);
		}
		return true;
	}
}
