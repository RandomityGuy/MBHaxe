package shapes;

import src.ResourceLoader;
import mis.MissionElement.MissionElementItem;
import src.TimeState;
import mis.MisParser;
import src.MarbleWorld;

class TimeTravel extends PowerUp {
	var timeBonus:Float = 5;

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

		this.pickUpName = '${this.timeBonus} second Time ${this.timeBonus >= 0 ? 'Modifier' : 'Penalty'}';
		if (noRespawn)
			this.cooldownDuration = 1e8;
		this.useInstancing = true;
		this.autoUse = true;
		this.radarIndex = 32;
	}

	public override function init(level:MarbleWorld, onFinish:Void->Void) {
		super.init(level, () -> {
			ResourceLoader.load("sound/putimetravelvoice.wav").entry.load(() -> {
				this.pickupSound = ResourceLoader.getResource("data/sound/putimetravelvoice.wav", ResourceLoader.getAudio, this.soundResources);
				ResourceLoader.load("sound/timetravelactive.wav").entry.load(onFinish);
			});
		});
	}

	public function pickUp(marble:src.Marble):Bool {
		return true;
	}

	public function use(marble:src.Marble, time:TimeState) {
		if (!this.level.rewinding)
			level.addBonusTime(this.timeBonus);
		return true;
	}
}
