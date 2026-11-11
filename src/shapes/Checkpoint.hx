package shapes;

import collision.CollisionInfo;
import mis.MisParser;
import src.DtsObject;
import src.ResourceLoader;
import src.ResourceLoaderWorker;
import src.AudioManager;
import mis.MissionElement.MissionElementStaticShape;

class Checkpoint extends DtsObject {
	public var disableOOB = false;

	var element:MissionElementStaticShape;
	var isPQ:Bool;

	public function new(element:MissionElementStaticShape) {
		super();
		var datablockLower = element.datablock.toLowerCase();
		this.isPQ = datablockLower == "checkpoint_pq";
		this.dtsPath = switch (datablockLower) {
			case "checkpoint_pq": "data/shapes_pq/gameplay/pads/checkpoint.dts";
			case "checkpoint_mbu": "data/shapes_mbu/pads/checkpad.dts";
			default: "data/shapes/buttons/checkpoint.dts";
		}
		this.isCollideable = true;
		this.isTSStatic = false;
		this.identifier = "Checkpoint" + this.dtsPath;
		this.element = element;

		this.disableOOB = element.fields.exists('disableOob') ? MisParser.parseBoolean(element.fields['disableOob'][0]) : false;
	}

	public override function init(level:src.MarbleWorld, onFinish:() -> Void) {
		super.init(level, () -> {
			var worker = new ResourceLoaderWorker(onFinish);
			AudioManager.preloadPitchedSound("checkpoint", worker);
			if (this.isPQ)
				worker.addTask(fwd -> this.spawnGlass(fwd));
			worker.run();
		});
	}

	function spawnGlass(onFinish:Void->Void) {
		var glass = new DtsObject();
		glass.dtsPath = "data/shapes_pq/gameplay/pads/silly_cp_glass.dts";
		glass.identifier = "CheckpointSillyGlass";
		glass.isCollideable = false;
		glass.isBoundingBoxCollideable = false;
		glass.useInstancing = true;
		this.level.addDtsObject(glass, () -> {
			this.addChild(glass);
			onFinish();
		});
	}

	public override function onMarbleContact(marble:src.Marble, time:src.TimeState, ?contact:CollisionInfo) {
		this.level.saveCheckpointState({
			obj: this,
			elem: this.element
		}, null);
	}
}
