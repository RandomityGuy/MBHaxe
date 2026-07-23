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

	public function new(element:MissionElementStaticShape) {
		super();
		this.dtsPath = element.datablock.toLowerCase() == "checkpoint_pq" ? "data/shapes_pq/gameplay/pads/checkpoint.dts" :
			"data/shapes/buttons/checkpoint.dts";
		this.isCollideable = true;
		this.isTSStatic = false;
		// Instancing batches by `identifier`, and the PQ variant uses a different mesh - keep the
		// dtsPath in the identifier so it doesn't get batched with the vanilla mesh.
		this.identifier = "Checkpoint" + this.dtsPath;
		this.element = element;

		this.disableOOB = element.fields.exists('disableOob') ? MisParser.parseBoolean(element.fields['disableOob'][0]) : false;
	}

	public override function init(level:src.MarbleWorld, onFinish:() -> Void) {
		super.init(level, () -> {
			var worker = new ResourceLoaderWorker(onFinish);
			AudioManager.preloadPitchedSound("checkpoint", worker);
			worker.run();
		});
	}

	public override function onMarbleContact(marble:src.Marble, time:src.TimeState, ?contact:CollisionInfo) {
		this.level.saveCheckpointState({
			obj: this,
			elem: this.element
		}, null);
	}
}
