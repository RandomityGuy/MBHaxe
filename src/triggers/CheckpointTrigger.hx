package triggers;

import h3d.Vector;
import src.MarbleWorld;
import mis.MissionElement.MissionElementTrigger;
import src.ResourceLoader;
import src.ResourceLoaderWorker;
import src.AudioManager;
import mis.MisParser;

class CheckpointTrigger extends Trigger {
	public var disableOOB = false;
	public var add:Vector = null;

	override public function new(element:MissionElementTrigger, level:MarbleWorld) {
		super(element, level);

		this.disableOOB = element.fields.exists('disableOob') ? MisParser.parseBoolean(element.fields['disableOob'][0]) : false;
		this.add = element.fields.exists('add') ? MisParser.parseVector3(element.fields['add'][0]) : null;
	}

	public override function init(onFinish:() -> Void) {
		super.init(() -> {
			var worker = new ResourceLoaderWorker(onFinish);
			AudioManager.preloadPitchedSound("checkpoint", worker);
			worker.run();
		});
	}

	public override function onMarbleEnter(marble:src.Marble, time:src.TimeState) {
		super.onMarbleEnter(marble, time);
		var shape = this.level.namedObjects.get(this.element.respawnpoint.toLowerCase());
		if (shape == null)
			return;
		this.level.saveCheckpointState(shape, this);
	}
}
