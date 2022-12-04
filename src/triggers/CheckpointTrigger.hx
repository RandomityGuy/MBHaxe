package triggers;

import h3d.Vector;
import src.MarbleWorld;
import mis.MissionElement.MissionElementTrigger;
import src.ResourceLoader;
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
			ResourceLoader.load("sound/checkpoint.wav").entry.load(onFinish);
		});
	}

	public override function onMarbleEnter(time:src.TimeState) {
		super.onMarbleEnter(time);
		var shape = this.level.namedObjects.get(this.element.respawnpoint);
		if (shape == null)
			return;
		this.level.saveCheckpointState(shape, this);
	}
}
